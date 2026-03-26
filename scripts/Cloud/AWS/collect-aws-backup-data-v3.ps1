<#
.SYNOPSIS

Script Name: collect-aws-backup-data-v3.ps1
Author: Randy Bordeaux
Date Created: 2024-06-01
Date Modified: 

Audits AWS Backup configuration and RDS databases to identify backup strategy issues and cost optimization opportunities.

.DESCRIPTION
This script collects comprehensive data from AWS Backup and RDS services, analyzes backup plans, rules, recovery points, 
and database configurations, then generates an Excel workbook with findings and recommendations. It identifies problems such as 
excessive backup frequency, redundant protection strategies, inappropriate retention periods, and stale manual snapshots.

.PARAMETER OutputDir
The directory where the audit report and raw data files will be saved. Defaults to a timestamped folder in the current location 
named 'aws-backup-audit-YYYYMMDD-HHmm'.

.PARAMETER WorkbookName
The filename of the Excel workbook to be generated. Defaults to 'aws-backup-audit.xlsx'.

.EXAMPLE
.\collect-aws-backup-data-v3.ps1 -OutputDir 'C:\audits\backup-audit-2024' -WorkbookName 'backup-findings.xlsx'

Runs the audit and saves the workbook and raw JSON data to the specified output directory.

.NOTES
- Requires the ImportExcel PowerShell module (automatically installed if missing).
- Requires AWS CLI configured with appropriate credentials and permissions to describe RDS instances, snapshots, 
    Backup vaults, plans, rules, selections, and recovery points.
- The script disables AWS pager output for cleaner JSON parsing.
- All AWS API responses are saved as JSON files in a 'raw' subdirectory for reference.
- The generated workbook includes conditional formatting on severity and priority columns for quick visual scanning.
- Uses table references in Excel formulas to automatically update dashboard metrics if data is refreshed.

.OUTPUTS
- Excel workbook with sheets: Executive Summary, Problems, Recommendations, RDS Instances, RDS Recovery Stats, 
    RDS Snapshots, Backup Plans, Backup Rules, Backup Selections, Selection Resources, Backup Vaults, and Recovery Points.
- Raw JSON files in the output directory's 'raw' subdirectory for audit trail and detailed inspection.
#>

$ErrorActionPreference = 'Stop'
$env:AWS_PAGER = ''

param(
    [string]$OutputDir = (Join-Path (Get-Location) ("aws-backup-audit-" + (Get-Date -Format 'yyyyMMdd-HHmm'))),
    [string]$WorkbookName = 'aws-backup-audit.xlsx'
)

function Get-SafeFileName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return 'unnamed' }
    return ($Name -replace '[\\/:*?"<>|]', '_')
}

function Convert-CronToDescription {
    param([string]$Cron)
    if ([string]::IsNullOrWhiteSpace($Cron)) { return '' }
    switch -Regex ($Cron) {
        '^cron\(0 \*/4 \* \* \? \*\)$' { return 'Every 4 hours (6 times/day)' }
        '^cron\(0 5 \? \* \* \*\)$' { return 'Daily at 05:00 UTC' }
        '^cron\(0 0 \? \* \* \*\)$' { return 'Daily at 00:00 UTC' }
        '^cron\(0 \*/12 \* \* \? \*\)$' { return 'Every 12 hours (2 times/day)' }
        '^cron\(0 \*/6 \* \* \? \*\)$' { return 'Every 6 hours (4 times/day)' }
        default { return $Cron }
    }
}

function Get-ScheduleExecutionsPerDay {
    param([string]$Cron)
    if ([string]::IsNullOrWhiteSpace($Cron)) { return $null }
    if ($Cron -match '^cron\(0 \*/(\d+) \* \* \? \*\)$') {
        $hours = [int]$Matches[1]
        if ($hours -gt 0) { return [math]::Floor(24 / $hours) }
    }
    if ($Cron -match '^cron\(0 \d+ \? \* \* \*\)$') { return 1 }
    return $null
}

function Get-DbNameFromArn {
    param([string]$Arn)
    if ([string]::IsNullOrWhiteSpace($Arn)) { return $null }
    if ($Arn -match 'db:([^:]+)$') { return $Matches[1] }
    return $null
}

if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    try {
        Install-Module ImportExcel -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    } catch {
        throw 'The ImportExcel PowerShell module is required. Install it with: Install-Module ImportExcel -Scope CurrentUser -Force -AllowClobber'
    }
}
Import-Module ImportExcel -ErrorAction Stop

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$rawDir = Join-Path $OutputDir 'raw'
New-Item -ItemType Directory -Path $rawDir -Force | Out-Null
$workbookPath = Join-Path $OutputDir $WorkbookName

Write-Host "Output directory: $OutputDir"
Write-Host "Workbook path: $workbookPath"

# Collect raw data
$rdsInstancesRaw = aws rds describe-db-instances --output json --no-cli-pager
$rdsInstancesRaw | Out-File -FilePath (Join-Path $rawDir 'rds-db-instances.json') -Encoding utf8
$rdsInstances = ($rdsInstancesRaw | ConvertFrom-Json).DBInstances

$rdsSnapshotsRaw = aws rds describe-db-snapshots --output json --no-cli-pager
$rdsSnapshotsRaw | Out-File -FilePath (Join-Path $rawDir 'rds-db-snapshots.json') -Encoding utf8
$rdsSnapshots = ($rdsSnapshotsRaw | ConvertFrom-Json).DBSnapshots

$vaultsRaw = aws backup list-backup-vaults --output json --no-cli-pager
$vaultsRaw | Out-File -FilePath (Join-Path $rawDir 'backup-vaults.json') -Encoding utf8
$vaults = ($vaultsRaw | ConvertFrom-Json).BackupVaultList

$plansRaw = aws backup list-backup-plans --output json --no-cli-pager
$plansRaw | Out-File -FilePath (Join-Path $rawDir 'backup-plans.json') -Encoding utf8
$plans = ($plansRaw | ConvertFrom-Json).BackupPlansList

# Build base tables
$dbInstanceRows = @()
foreach ($db in $rdsInstances) {
    $dbInstanceRows += [pscustomobject]@{
        DBInstanceIdentifier  = $db.DBInstanceIdentifier
        DBInstanceArn         = $db.DBInstanceArn
        Engine                = $db.Engine
        DBInstanceClass       = $db.DBInstanceClass
        AllocatedStorageGiB   = [double]$db.AllocatedStorage
        BackupRetentionPeriod = [int]$db.BackupRetentionPeriod
        MultiAZ               = [bool]$db.MultiAZ
        StorageType           = $db.StorageType
        Iops                  = if ($null -ne $db.Iops) { [double]$db.Iops } else { $null }
        Status                = $db.DBInstanceStatus
        IsDevelopmentLike     = [bool]($db.DBInstanceIdentifier -match '(?i)dev|develop|test|qa|stage|staging|sandbox')
    }
}

$snapshotRows = @()
foreach ($snap in $rdsSnapshots) {
    $snapshotRows += [pscustomobject]@{
        SnapshotType         = $snap.SnapshotType
        DBInstanceIdentifier = $snap.DBInstanceIdentifier
        DBSnapshotIdentifier = $snap.DBSnapshotIdentifier
        AllocatedStorageGiB  = [double]$snap.AllocatedStorage
        SnapshotCreateTime   = [datetime]$snap.SnapshotCreateTime
        Status               = $snap.Status
        Engine               = $snap.Engine
        Encrypted            = [bool]$snap.Encrypted
    }
}

$vaultRows = @()
$recoveryPointRows = @()
foreach ($vault in $vaults) {
    $vaultRows += [pscustomobject]@{
        BackupVaultName = $vault.BackupVaultName
        BackupVaultArn  = $vault.BackupVaultArn
        CreationDate    = if ($vault.CreationDate) { [datetime]$vault.CreationDate } else { $null }
        Locked          = if ($null -ne $vault.Locked) { [bool]$vault.Locked } else { $false }
    }

    $safeVault = Get-SafeFileName $vault.BackupVaultName
    $rpRaw = aws backup list-recovery-points-by-backup-vault --backup-vault-name "$($vault.BackupVaultName)" --output json --no-cli-pager
    $rpRaw | Out-File -FilePath (Join-Path $rawDir ("recovery-points-$safeVault.json")) -Encoding utf8
    $rps = ($rpRaw | ConvertFrom-Json).RecoveryPoints

    foreach ($rp in $rps) {
        $resourceName = Get-DbNameFromArn $rp.ResourceArn
        $recoveryPointRows += [pscustomobject]@{
            BackupVaultName      = $vault.BackupVaultName
            RecoveryPointArn     = $rp.RecoveryPointArn
            ResourceType         = $rp.ResourceType
            ResourceArn          = $rp.ResourceArn
            ResourceNameGuess    = $resourceName
            BackupSizeInBytes    = if ($null -ne $rp.BackupSizeInBytes) { [double]$rp.BackupSizeInBytes } else { $null }
            BackupSizeGiBApprox  = if ($null -ne $rp.BackupSizeInBytes) { [math]::Round(([double]$rp.BackupSizeInBytes / 1GB),2) } else { $null }
            CreationDate         = if ($rp.CreationDate) { [datetime]$rp.CreationDate } else { $null }
            CompletionDate       = if ($rp.CompletionDate) { [datetime]$rp.CompletionDate } else { $null }
            Status               = $rp.Status
            DeleteAfterDays      = if ($rp.Lifecycle -and $null -ne $rp.Lifecycle.DeleteAfterDays) { [int]$rp.Lifecycle.DeleteAfterDays } else { $null }
            MoveToColdAfterDays  = if ($rp.Lifecycle -and $null -ne $rp.Lifecycle.MoveToColdStorageAfterDays) { [int]$rp.Lifecycle.MoveToColdStorageAfterDays } else { $null }
            IsEncrypted          = if ($null -ne $rp.IsEncrypted) { [bool]$rp.IsEncrypted } else { $false }
        }
    }
}

$planRows = @()
$ruleRows = @()
$selectionRows = @()
$selectionResourceRows = @()
foreach ($plan in $plans) {
    $planId = $plan.BackupPlanId
    $planName = $plan.BackupPlanName
    $safePlan = Get-SafeFileName("$planName-$planId")

    $planRows += [pscustomobject]@{
        BackupPlanId   = $planId
        BackupPlanName = $planName
        CreationDate   = if ($plan.CreationDate) { [datetime]$plan.CreationDate } else { $null }
        VersionId      = $plan.VersionId
    }

    $planRaw = aws backup get-backup-plan --backup-plan-id "$planId" --output json --no-cli-pager
    $planRaw | Out-File -FilePath (Join-Path $rawDir ("backup-plan-$safePlan.json")) -Encoding utf8
    $planDetail = ($planRaw | ConvertFrom-Json).BackupPlan

    foreach ($rule in $planDetail.Rules) {
        $copyTargetVaults = @()
        if ($rule.CopyActions) { $copyTargetVaults = @($rule.CopyActions | ForEach-Object { $_.DestinationBackupVaultArn }) }
        $ruleRows += [pscustomobject]@{
            BackupPlanId            = $planId
            BackupPlanName          = $planName
            RuleName                = $rule.RuleName
            TargetBackupVaultName   = $rule.TargetBackupVaultName
            ScheduleExpression      = $rule.ScheduleExpression
            ScheduleDescription     = Convert-CronToDescription $rule.ScheduleExpression
            ExecutionsPerDay        = Get-ScheduleExecutionsPerDay $rule.ScheduleExpression
            StartWindowMinutes      = if ($null -ne $rule.StartWindowMinutes) { [int]$rule.StartWindowMinutes } else { $null }
            CompletionWindowMinutes = if ($null -ne $rule.CompletionWindowMinutes) { [int]$rule.CompletionWindowMinutes } else { $null }
            DeleteAfterDays         = if ($rule.Lifecycle -and $null -ne $rule.Lifecycle.DeleteAfterDays) { [int]$rule.Lifecycle.DeleteAfterDays } else { $null }
            MoveToColdAfterDays     = if ($rule.Lifecycle -and $null -ne $rule.Lifecycle.MoveToColdStorageAfterDays) { [int]$rule.Lifecycle.MoveToColdStorageAfterDays } else { $null }
            EnableContinuousBackup  = if ($null -ne $rule.EnableContinuousBackup) { [bool]$rule.EnableContinuousBackup } else { $false }
            CopyTargetVaults        = ($copyTargetVaults -join '; ')
        }
    }

    $selRaw = aws backup list-backup-selections --backup-plan-id "$planId" --output json --no-cli-pager
    $selRaw | Out-File -FilePath (Join-Path $rawDir ("backup-selections-$safePlan.json")) -Encoding utf8
    $selectionList = ($selRaw | ConvertFrom-Json).BackupSelectionsList

    foreach ($sel in $selectionList) {
        $selectionRows += [pscustomobject]@{
            BackupPlanId   = $planId
            BackupPlanName = $planName
            SelectionId    = $sel.SelectionId
            SelectionName  = $sel.SelectionName
        }

        $selDetailRaw = aws backup get-backup-selection --backup-plan-id "$planId" --selection-id "$($sel.SelectionId)" --output json --no-cli-pager
        $selDetailRaw | Out-File -FilePath (Join-Path $rawDir ("backup-selection-$safePlan-" + (Get-SafeFileName("$($sel.SelectionName)-$($sel.SelectionId)")) + '.json')) -Encoding utf8
        $selDetail = ($selDetailRaw | ConvertFrom-Json).BackupSelection

        if ($selDetail.Resources) {
            foreach ($resourceArn in $selDetail.Resources) {
                $dbName = Get-DbNameFromArn $resourceArn
                $selectionResourceRows += [pscustomobject]@{
                    BackupPlanId         = $planId
                    BackupPlanName       = $planName
                    SelectionId          = $sel.SelectionId
                    SelectionName        = $sel.SelectionName
                    MatchType            = 'ExplicitResource'
                    ResourceArn          = $resourceArn
                    ResourceTypeGuess    = if ($resourceArn -match ':rds:') { 'RDS' } else { '' }
                    DBInstanceIdentifier = $dbName
                    TagConditionType     = ''
                    TagKey               = ''
                    TagValue             = ''
                }
            }
        }
        if ($selDetail.ListOfTags) {
            foreach ($tag in $selDetail.ListOfTags) {
                $selectionResourceRows += [pscustomobject]@{
                    BackupPlanId         = $planId
                    BackupPlanName       = $planName
                    SelectionId          = $sel.SelectionId
                    SelectionName        = $sel.SelectionName
                    MatchType            = 'Tag'
                    ResourceArn          = ''
                    ResourceTypeGuess    = ''
                    DBInstanceIdentifier = ''
                    TagConditionType     = $tag.ConditionType
                    TagKey               = $tag.ConditionKey
                    TagValue             = $tag.ConditionValue
                }
            }
        }
    }
}

# Aggregate mappings and recommendations
$dbLookup = @{}
foreach ($db in $dbInstanceRows) { $dbLookup[$db.DBInstanceIdentifier] = $db }

$rdsRecoveryPoints = @($recoveryPointRows | Where-Object { $_.ResourceType -eq 'RDS' -or $_.ResourceArn -match ':rds:' })

$dbRecoveryStats = @()
foreach ($db in $dbInstanceRows) {
    $matches = @($rdsRecoveryPoints | Where-Object { $_.ResourceArn -eq $db.DBInstanceArn -or $_.ResourceNameGuess -eq $db.DBInstanceIdentifier })
    $stats = [pscustomobject]@{
        DBInstanceIdentifier           = $db.DBInstanceIdentifier
        DBInstanceArn                  = $db.DBInstanceArn
        AllocatedStorageGiB            = $db.AllocatedStorageGiB
        BackupRetentionPeriod          = $db.BackupRetentionPeriod
        IsDevelopmentLike              = $db.IsDevelopmentLike
        RecoveryPointCount             = $matches.Count
        TotalRecoveryPointGiBApprox    = [math]::Round((($matches | Measure-Object -Property BackupSizeGiBApprox -Sum).Sum),2)
        AvgDeleteAfterDays             = if ($matches.Count -gt 0) { [math]::Round((($matches | Where-Object { $null -ne $_.DeleteAfterDays } | Measure-Object -Property DeleteAfterDays -Average).Average),1) } else { $null }
        OldestRecoveryPoint            = if ($matches.Count -gt 0) { ($matches | Sort-Object CreationDate | Select-Object -First 1).CreationDate } else { $null }
        NewestRecoveryPoint            = if ($matches.Count -gt 0) { ($matches | Sort-Object CreationDate -Descending | Select-Object -First 1).CreationDate } else { $null }
    }
    $dbRecoveryStats += $stats
}

$dbPlanCoverage = @()
foreach ($db in $dbInstanceRows) {
    $coveringSelections = @($selectionResourceRows | Where-Object { $_.DBInstanceIdentifier -eq $db.DBInstanceIdentifier -or $_.ResourceArn -eq $db.DBInstanceArn })
    if ($coveringSelections.Count -eq 0) {
        $dbPlanCoverage += [pscustomobject]@{
            DBInstanceIdentifier = $db.DBInstanceIdentifier
            BackupPlanName       = ''
            RuleName             = ''
            ExecutionsPerDay     = $null
            EnableContinuousBackup = $false
            DeleteAfterDays      = $null
            CopyTargetVaults     = ''
        }
    } else {
        foreach ($sel in $coveringSelections) {
            $rules = @($ruleRows | Where-Object { $_.BackupPlanId -eq $sel.BackupPlanId })
            foreach ($rule in $rules) {
                $dbPlanCoverage += [pscustomobject]@{
                    DBInstanceIdentifier   = $db.DBInstanceIdentifier
                    BackupPlanName         = $sel.BackupPlanName
                    RuleName               = $rule.RuleName
                    ExecutionsPerDay       = $rule.ExecutionsPerDay
                    EnableContinuousBackup = $rule.EnableContinuousBackup
                    DeleteAfterDays        = $rule.DeleteAfterDays
                    CopyTargetVaults       = $rule.CopyTargetVaults
                }
            }
        }
    }
}

$problems = New-Object System.Collections.Generic.List[object]
$recommendations = New-Object System.Collections.Generic.List[object]

foreach ($db in $dbInstanceRows) {
    $coverage = @($dbPlanCoverage | Where-Object { $_.DBInstanceIdentifier -eq $db.DBInstanceIdentifier })
    $stats = $dbRecoveryStats | Where-Object { $_.DBInstanceIdentifier -eq $db.DBInstanceIdentifier } | Select-Object -First 1

    foreach ($rule in $coverage) {
        if ($rule.ExecutionsPerDay -ge 6 -and $db.AllocatedStorageGiB -ge 500) {
            $problems.Add([pscustomobject]@{
                Severity          = 'High'
                Category          = 'Backup Frequency'
                ResourceType      = 'RDS DB Instance'
                ResourceName      = $db.DBInstanceIdentifier
                Finding           = 'High-frequency snapshots on large database'
                Evidence          = "$($rule.BackupPlanName) / $($rule.RuleName) runs $($rule.ExecutionsPerDay)x per day for a $([math]::Round($db.AllocatedStorageGiB,0)) GiB database"
                Impact            = 'Increases ChargedBackupUsage through excessive recovery point accumulation'
                RecommendationKey = 'REDUCE_FREQUENCY'
            })
            $recommendations.Add([pscustomobject]@{
                Priority        = 'High'
                ResourceName    = $db.DBInstanceIdentifier
                Recommendation  = 'Reduce scheduled snapshot frequency to once daily'
                Reason          = 'Continuous or daily backups are typically sufficient unless a specific recovery objective requires more frequent snapshots'
                ExpectedBenefit = 'Substantial reduction in backup storage growth and ongoing RDS backup charges'
                SuggestedAction = 'Change schedule from every 4 hours to a daily cron expression such as cron(0 5 ? * * *)'
            })
        }

        if ($rule.EnableContinuousBackup -and $rule.ExecutionsPerDay -gt 1) {
            $problems.Add([pscustomobject]@{
                Severity          = 'High'
                Category          = 'Redundant Protection'
                ResourceType      = 'RDS DB Instance'
                ResourceName      = $db.DBInstanceIdentifier
                Finding           = 'Continuous backup enabled alongside frequent scheduled snapshots'
                Evidence          = "$($rule.BackupPlanName) / $($rule.RuleName) has continuous backup enabled and also runs $($rule.ExecutionsPerDay)x per day"
                Impact            = 'Can duplicate protection while materially increasing backup storage cost'
                RecommendationKey = 'SIMPLIFY_STRATEGY'
            })
            $recommendations.Add([pscustomobject]@{
                Priority        = 'High'
                ResourceName    = $db.DBInstanceIdentifier
                Recommendation  = 'Simplify the backup strategy'
                Reason          = 'Avoid combining PITR with aggressive scheduled snapshots unless there is a documented business requirement'
                ExpectedBenefit = 'Reduced backup redundancy and lower storage cost'
                SuggestedAction = 'Keep PITR for production, limit scheduled snapshots to daily, and validate retention against recovery requirements'
            })
        }

        if ($db.IsDevelopmentLike -and $rule.EnableContinuousBackup) {
            $problems.Add([pscustomobject]@{
                Severity          = 'Medium'
                Category          = 'Environment Fit'
                ResourceType      = 'RDS DB Instance'
                ResourceName      = $db.DBInstanceIdentifier
                Finding           = 'Development-like database has continuous backup enabled'
                Evidence          = "$($db.DBInstanceIdentifier) appears to be non-production and is covered by $($rule.BackupPlanName) with continuous backup enabled"
                Impact            = 'May exceed business requirements for a non-production workload'
                RecommendationKey = 'REDUCE_NONPROD_PROTECTION'
            })
            $recommendations.Add([pscustomobject]@{
                Priority        = 'Medium'
                ResourceName    = $db.DBInstanceIdentifier
                Recommendation  = 'Reduce protection level for non-production databases'
                Reason          = 'Development and test systems typically do not require the same backup profile as production'
                ExpectedBenefit = 'Lower storage cost with acceptable operational risk for non-production'
                SuggestedAction = 'Consider daily snapshots with short retention and disable PITR if not required'
            })
        }

        if ($null -ne $rule.DeleteAfterDays -and $rule.DeleteAfterDays -gt 14 -and $db.AllocatedStorageGiB -ge 500) {
            $problems.Add([pscustomobject]@{
                Severity          = 'Medium'
                Category          = 'Retention'
                ResourceType      = 'RDS DB Instance'
                ResourceName      = $db.DBInstanceIdentifier
                Finding           = 'Long recovery point retention on large database'
                Evidence          = "$($rule.BackupPlanName) / $($rule.RuleName) retains recovery points for $($rule.DeleteAfterDays) days"
                Impact            = 'Long retention increases total billed backup storage'
                RecommendationKey = 'TUNE_RETENTION'
            })
            $recommendations.Add([pscustomobject]@{
                Priority        = 'Medium'
                ResourceName    = $db.DBInstanceIdentifier
                Recommendation  = 'Tune retention to match recovery requirements'
                Reason          = 'Retention should be driven by compliance and restore needs, not defaults'
                ExpectedBenefit = 'Gradual reduction of stored recovery points and lower monthly backup charges'
                SuggestedAction = 'Use approximately 7-14 days for production and 1-3 days for development unless policy requires more'
            })
        }
    }

    if ($stats -and $stats.RecoveryPointCount -ge 10 -and $db.AllocatedStorageGiB -ge 500) {
        $problems.Add([pscustomobject]@{
            Severity          = 'High'
            Category          = 'Accumulation'
            ResourceType      = 'RDS DB Instance'
            ResourceName      = $db.DBInstanceIdentifier
            Finding           = 'Large number of recovery points present for a large database'
            Evidence          = "$($stats.RecoveryPointCount) recovery points found; approximate cumulative protected size is $($stats.TotalRecoveryPointGiBApprox) GiB"
            Impact            = 'Existing recovery points are already contributing to current ChargedBackupUsage'
            RecommendationKey = 'CLEANUP_RECOVERY_POINTS'
        })
        $recommendations.Add([pscustomobject]@{
            Priority        = 'High'
            ResourceName    = $db.DBInstanceIdentifier
            Recommendation  = 'Remove unnecessary historical recovery points'
            Reason          = 'Policy changes alone will not reduce current billed storage without cleanup or expiry'
            ExpectedBenefit = 'Immediate cost reduction once old recovery points are deleted or expire'
            SuggestedAction = 'Review vault recovery points and remove those outside the approved retention window'
        })
    }
}

$oldManualSnapshots = @($snapshotRows | Where-Object { $_.SnapshotType -eq 'manual' -and $_.SnapshotCreateTime -lt (Get-Date).AddDays(-30) })
foreach ($snap in $oldManualSnapshots) {
    $problems.Add([pscustomobject]@{
        Severity          = 'Medium'
        Category          = 'Manual Snapshots'
        ResourceType      = 'RDS Snapshot'
        ResourceName      = $snap.DBSnapshotIdentifier
        Finding           = 'Manual snapshot older than 30 days'
        Evidence          = "$($snap.DBInstanceIdentifier) manual snapshot created $($snap.SnapshotCreateTime.ToString('yyyy-MM-dd'))"
        Impact            = 'Manual snapshots do not expire automatically and may contribute to backup charges'
        RecommendationKey = 'REVIEW_MANUAL_SNAPSHOTS'
    })
    $recommendations.Add([pscustomobject]@{
        Priority        = 'Medium'
        ResourceName    = $snap.DBSnapshotIdentifier
        Recommendation  = 'Review and delete stale manual snapshots if no longer required'
        Reason          = 'Manual snapshots persist until explicitly removed'
        ExpectedBenefit = 'Potential one-time reduction in billed backup storage'
        SuggestedAction = 'Confirm retention owner and delete stale manual snapshots that are not required for rollback or compliance'
    })
}

$summaryRows = @(
    [pscustomobject]@{ Metric = 'RDS DB Instances'; Value = $dbInstanceRows.Count; Notes = 'Total databases evaluated' },
    [pscustomobject]@{ Metric = 'Backup Plans'; Value = $planRows.Count; Notes = 'AWS Backup plans discovered' },
    [pscustomobject]@{ Metric = 'Backup Rules'; Value = $ruleRows.Count; Notes = 'Rules across all plans' },
    [pscustomobject]@{ Metric = 'Backup Vaults'; Value = $vaultRows.Count; Notes = 'Vaults queried for recovery points' },
    [pscustomobject]@{ Metric = 'RDS Recovery Points'; Value = $rdsRecoveryPoints.Count; Notes = 'Recovery points mapped to RDS resources' },
    [pscustomobject]@{ Metric = 'Approx RDS Recovery Point GiB'; Value = [math]::Round((($rdsRecoveryPoints | Measure-Object -Property BackupSizeGiBApprox -Sum).Sum),2); Notes = 'Approximate sum of protected sizes reported by AWS Backup' },
    [pscustomobject]@{ Metric = 'High Severity Findings'; Value = (@($problems | Where-Object { $_.Severity -eq 'High' })).Count; Notes = 'Requires near-term action' },
    [pscustomobject]@{ Metric = 'Medium Severity Findings'; Value = (@($problems | Where-Object { $_.Severity -eq 'Medium' })).Count; Notes = 'Should be remediated after high-severity items' }
)

# De-duplicate recommendations for readability
$recommendations = $recommendations | Sort-Object Priority, ResourceName, Recommendation -Unique
$problems = $problems | Sort-Object Severity, Category, ResourceName, Finding -Unique

# Export workbook
if (Test-Path $workbookPath) { Remove-Item $workbookPath -Force }

$excelParams = @{ Path = $workbookPath; FreezeTopRow = $true; BoldTopRow = $true; AutoSize = $true; AutoFilter = $true; TableStyle = 'Medium2' }

$summaryRows | Export-Excel @excelParams -WorksheetName 'Executive Summary' -TableName 'ExecutiveSummary' -Title 'AWS Backup Audit Summary' -TitleBold -TitleSize 16 -ClearSheet
$problems | Export-Excel @excelParams -WorksheetName 'Problems' -TableName 'Problems'
$recommendations | Export-Excel @excelParams -WorksheetName 'Recommendations' -TableName 'Recommendations'
$dbInstanceRows | Export-Excel @excelParams -WorksheetName 'RDS Instances' -TableName 'RDSInstances'
$dbRecoveryStats | Export-Excel @excelParams -WorksheetName 'RDS Recovery Stats' -TableName 'RDSRecoveryStats'
$snapshotRows | Sort-Object SnapshotCreateTime | Export-Excel @excelParams -WorksheetName 'RDS Snapshots' -TableName 'RDSSnapshots'
$planRows | Export-Excel @excelParams -WorksheetName 'Backup Plans' -TableName 'BackupPlans'
$ruleRows | Export-Excel @excelParams -WorksheetName 'Backup Rules' -TableName 'BackupRules'
$selectionRows | Export-Excel @excelParams -WorksheetName 'Backup Selections' -TableName 'BackupSelections'
$selectionResourceRows | Export-Excel @excelParams -WorksheetName 'Selection Resources' -TableName 'SelectionResources'
$vaultRows | Export-Excel @excelParams -WorksheetName 'Backup Vaults' -TableName 'BackupVaults'
$rdsRecoveryPoints | Sort-Object CreationDate | Export-Excel @excelParams -WorksheetName 'Recovery Points' -TableName 'RecoveryPoints'

# Styling and formulas
$pkg = Open-ExcelPackage -Path $workbookPath

$wsSummary = $pkg.Workbook.Worksheets['Executive Summary']
$wsProblems = $pkg.Workbook.Worksheets['Problems']
$wsRecommendations = $pkg.Workbook.Worksheets['Recommendations']
$wsInstances = $pkg.Workbook.Worksheets['RDS Instances']
$wsRecoveryStats = $pkg.Workbook.Worksheets['RDS Recovery Stats']
$wsRules = $pkg.Workbook.Worksheets['Backup Rules']
$wsRecoveryPoints = $pkg.Workbook.Worksheets['Recovery Points']

foreach ($ws in $pkg.Workbook.Worksheets) {
    $ws.View.ShowGridLines = $false
    $ws.Cells.Style.Font.Name = 'Calibri'
    $ws.Cells.Style.Font.Size = 11
}

# Number formats
$wsSummary.Column(2).Style.Numberformat.Format = '#,##0.00'
$wsInstances.Column(5).Style.Numberformat.Format = '#,##0'
$wsRecoveryStats.Column(3).Style.Numberformat.Format = '#,##0'
$wsRecoveryStats.Column(6).Style.Numberformat.Format = '#,##0.00'
$wsRules.Column(7).Style.Numberformat.Format = '#,##0'
$wsRecoveryPoints.Column(6).Style.Numberformat.Format = '#,##0.00'

# Highlight problems by severity
$problemEndRow = $wsProblems.Dimension.End.Row
if ($problemEndRow -ge 2) {
    Add-ConditionalFormatting -Worksheet $wsProblems -Range "A2:A$problemEndRow" -RuleType ContainsText -ConditionValue 'High' -BackgroundColor '#F4CCCC' -ForeGroundColor '#9C0006'
    Add-ConditionalFormatting -Worksheet $wsProblems -Range "A2:A$problemEndRow" -RuleType ContainsText -ConditionValue 'Medium' -BackgroundColor '#FCE5CD' -ForeGroundColor '#7F6000'
}

$recoEndRow = $wsRecommendations.Dimension.End.Row
if ($recoEndRow -ge 2) {
    Add-ConditionalFormatting -Worksheet $wsRecommendations -Range "A2:A$recoEndRow" -RuleType ContainsText -ConditionValue 'High' -BackgroundColor '#F4CCCC' -ForeGroundColor '#9C0006'
    Add-ConditionalFormatting -Worksheet $wsRecommendations -Range "A2:A$recoEndRow" -RuleType ContainsText -ConditionValue 'Medium' -BackgroundColor '#FCE5CD' -ForeGroundColor '#7F6000'
}

$ruleEndRow = $wsRules.Dimension.End.Row
if ($ruleEndRow -ge 2) {
    Add-ConditionalFormatting -Worksheet $wsRules -Range "G2:G$ruleEndRow" -RuleType GreaterThan -ConditionValue '1' -BackgroundColor '#FCE5CD'
    Add-ConditionalFormatting -Worksheet $wsRules -Range "L2:L$ruleEndRow" -RuleType Equal -ConditionValue 'TRUE' -BackgroundColor '#D9EAD3'
}

# Add a small dashboard section on summary sheet
$wsSummary.Cells['E1'].Value = 'Key Callouts'
$wsSummary.Cells['E1'].Style.Font.Bold = $true
$wsSummary.Cells['E2'].Value = 'Problem'
$wsSummary.Cells['F2'].Value = 'Count'
$wsSummary.Cells['E2:F2'].Style.Font.Bold = $true
$wsSummary.Cells['E3'].Value = 'High Severity Findings'
$wsSummary.Cells['F3'].Formula = "COUNTIF(Problems[Severity],\"High\")"
$wsSummary.Cells['E4'].Value = 'Medium Severity Findings'
$wsSummary.Cells['F4'].Formula = "COUNTIF(Problems[Severity],\"Medium\")"
$wsSummary.Cells['E5'].Value = 'High Priority Recommendations'
$wsSummary.Cells['F5'].Formula = "COUNTIF(Recommendations[Priority],\"High\")"
$wsSummary.Cells['E6'].Value = 'Total RDS Recovery Points'
$wsSummary.Cells['F6'].Formula = "ROWS(RecoveryPoints[RecoveryPointArn])"
$wsSummary.Cells['E7'].Value = 'Approx Recovery Point GiB'
$wsSummary.Cells['F7'].Formula = "SUM(RecoveryPoints[BackupSizeGiBApprox])"
$wsSummary.Cells['F3:F7'].Style.Numberformat.Format = '#,##0.00'
$wsSummary.Cells['E1:F7'].AutoFitColumns()

# Add comments to explain interpretation
$wsSummary.Cells['A1'].AddComment('This workbook consolidates AWS Backup, RDS, plan, rule, and recovery point data into a single review package. Focus first on the Problems and Recommendations tabs.', 'ChatGPT') | Out-Null
$wsProblems.Cells['D1'].AddComment('Finding names are normalized so similar issues can be grouped for director-level review.', 'ChatGPT') | Out-Null
$wsRecommendations.Cells['F1'].AddComment('SuggestedAction provides the concrete remediation step to implement.', 'ChatGPT') | Out-Null

Close-ExcelPackage $pkg

Write-Host ''
Write-Host "Done. Workbook created: $workbookPath"
Write-Host 'Review these tabs first:'
Write-Host '  Executive Summary'
Write-Host '  Problems'
Write-Host '  Recommendations'
