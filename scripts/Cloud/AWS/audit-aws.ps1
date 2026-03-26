<#
.SYNOPSIS
    Script Name: audit-aws.ps1
    Author: Randy Bordeaux
    Date: 26-March-2026
    Version: 2.0

    Audits AWS Backup configuration and RDS databases to identify backup strategy issues and cost optimization opportunities.

.DESCRIPTION
    This script collects comprehensive data from AWS Backup and RDS services, analyzes backup plans, rules, recovery points, 
    and database configurations, then generates an Excel workbook with findings and recommendations. It identifies problems such as 
    excessive backup frequency, redundant protection strategies, inappropriate retention periods, and stale manual snapshots.

.PARAMETER AwsAccountName
    The friendly name of the AWS account being audited. Used for report naming and identification. Defaults to "Crypto - Validation".

.PARAMETER OutputDir
    The directory where the audit report and raw data files will be saved. Defaults to a timestamped folder in the current location 
    named 'aws-backup-audit-[AccountName]-YYYYMMDD-HHmm'.

.PARAMETER WorkbookName
    The filename of the Excel workbook to be generated. Defaults to 'aws-backup-audit.xlsx'.

.EXAMPLE
    .\audit-aws.ps1 -AwsAccountName "Production" -OutputDir 'C:\audits\backup-audit-2024' -WorkbookName 'backup-findings.xlsx'

    Runs the audit against the Production account and saves the workbook and raw JSON data to the specified output directory.

.NOTES
    - Requires the ImportExcel PowerShell module (automatically installed if missing).
    - Requires AWS CLI configured with appropriate credentials and permissions to describe RDS instances, snapshots, 
      Backup vaults, plans, rules, selections, and recovery points.
    - The script disables AWS pager output for cleaner JSON parsing.
    - All AWS API responses are saved as JSON files in a 'raw' subdirectory for reference and audit trail.
    - The generated workbook includes conditional formatting on severity and priority columns for quick visual scanning.
    - Uses table references in Excel formulas to automatically update dashboard metrics if data is refreshed.

.OUTPUTS
    - Excel workbook with sheets: Executive Summary, Regional Summary, Problems, Recommendations, RDS Instances, RDS Recovery Stats, 
      RDS Snapshots, Backup Plans, Backup Rules, Backup Selections, Selection Resources, Backup Vaults, Recovery Points, and Regions Scanned.
    - Raw JSON files in the output directory's 'raw' subdirectory for detailed inspection and audit trail purposes.
#>
$ErrorActionPreference = 'Stop'
$env:AWS_PAGER = ''

param(
    [Parameter(Mandatory = $true)]
    [string]$AwsAccountName = "My Account Name",
    [string]$OutputDir = (Join-Path (Get-Location) ("aws-backup-audit-" + $AwsAccountName + "-" + (Get-Date -Format 'yyyyMMdd-HHmm'))),
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

function Invoke-AwsJson {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$OutputFile
    )
    $result = & aws @Arguments
    if ($LASTEXITCODE -ne 0) { throw "AWS CLI command failed: aws $($Arguments -join ' ')" }
    $result | Out-File -FilePath $OutputFile -Encoding utf8
    if ([string]::IsNullOrWhiteSpace(($result | Out-String))) { return $null }
    return ($result | ConvertFrom-Json)
}

$safeAccountName = Get-SafeFileName $AwsAccountName
if (-not $OutputDir) {
    $OutputDir = Join-Path (Get-Location) ("aws-backup-audit-$safeAccountName-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
if (-not $WorkbookName) {
    $WorkbookName = "aws-backup-audit-$safeAccountName.xlsx"
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

Write-Host "AWS Account Name: $AwsAccountName"
Write-Host "Output directory: $OutputDir"
Write-Host "Workbook path: $workbookPath"
Write-Host 'Discovering AWS regions...'

$regionsRaw = & aws ec2 describe-regions --all-regions --query 'Regions[*].[RegionName,OptInStatus]' --output json --no-cli-pager
if ($LASTEXITCODE -ne 0) { throw 'Failed to list AWS regions.' }
$regionsRaw | Out-File -FilePath (Join-Path $rawDir 'regions.json') -Encoding utf8
$regionPairs = $regionsRaw | ConvertFrom-Json
$regions = @($regionPairs | Where-Object { $_[1] -eq 'opt-in-not-required' -or $_[1] -eq 'opted-in' } | ForEach-Object { $_[0] } | Sort-Object -Unique)
if ($regions.Count -eq 0) { throw 'No usable AWS regions were returned by describe-regions.' }

$dbInstanceRows = @()
$snapshotRows = @()
$vaultRows = @()
$recoveryPointRows = @()
$planRows = @()
$ruleRows = @()
$selectionRows = @()
$selectionResourceRows = @()
$regionInventoryRows = @()

foreach ($region in $regions) {
    Write-Host "Collecting regional data for $region..."
    $safeRegion = Get-SafeFileName $region
    $regionInventoryRows += [pscustomobject]@{
        AwsAccountName = $AwsAccountName
        Region         = $region
        Included       = $true
    }

    $rdsInstancesJson = Invoke-AwsJson -Arguments @('rds','describe-db-instances','--region',$region,'--output','json','--no-cli-pager') -OutputFile (Join-Path $rawDir ("rds-db-instances-$safeRegion.json"))
    $rdsInstances = @()
    if ($rdsInstancesJson -and $rdsInstancesJson.DBInstances) { $rdsInstances = @($rdsInstancesJson.DBInstances) }
    foreach ($db in $rdsInstances) {
        $dbInstanceRows += [pscustomobject]@{
            AwsAccountName       = $AwsAccountName
            Region               = $region
            DBInstanceIdentifier = $db.DBInstanceIdentifier
            DBInstanceArn        = $db.DBInstanceArn
            Engine               = $db.Engine
            DBInstanceClass      = $db.DBInstanceClass
            AllocatedStorageGiB  = [double]$db.AllocatedStorage
            BackupRetentionPeriod= [int]$db.BackupRetentionPeriod
            MultiAZ              = [bool]$db.MultiAZ
            StorageType          = $db.StorageType
            Iops                 = if ($null -ne $db.Iops) { [double]$db.Iops } else { $null }
            Status               = $db.DBInstanceStatus
            IsDevelopmentLike    = [bool]($db.DBInstanceIdentifier -match '(?i)dev|develop|test|qa|stage|staging|sandbox')
        }
    }

    $rdsSnapshotsJson = Invoke-AwsJson -Arguments @('rds','describe-db-snapshots','--region',$region,'--output','json','--no-cli-pager') -OutputFile (Join-Path $rawDir ("rds-db-snapshots-$safeRegion.json"))
    $rdsSnapshots = @()
    if ($rdsSnapshotsJson -and $rdsSnapshotsJson.DBSnapshots) { $rdsSnapshots = @($rdsSnapshotsJson.DBSnapshots) }
    foreach ($snap in $rdsSnapshots) {
        $snapshotRows += [pscustomobject]@{
            AwsAccountName      = $AwsAccountName
            Region              = $region
            SnapshotType        = $snap.SnapshotType
            DBInstanceIdentifier= $snap.DBInstanceIdentifier
            DBSnapshotIdentifier= $snap.DBSnapshotIdentifier
            AllocatedStorageGiB = [double]$snap.AllocatedStorage
            SnapshotCreateTime  = [datetime]$snap.SnapshotCreateTime
            Status              = $snap.Status
            Engine              = $snap.Engine
            Encrypted           = [bool]$snap.Encrypted
        }
    }

    $vaultsJson = Invoke-AwsJson -Arguments @('backup','list-backup-vaults','--region',$region,'--output','json','--no-cli-pager') -OutputFile (Join-Path $rawDir ("backup-vaults-$safeRegion.json"))
    $vaults = @()
    if ($vaultsJson -and $vaultsJson.BackupVaultList) { $vaults = @($vaultsJson.BackupVaultList) }
    foreach ($vault in $vaults) {
        $vaultRows += [pscustomobject]@{
            AwsAccountName  = $AwsAccountName
            Region          = $region
            BackupVaultName = $vault.BackupVaultName
            BackupVaultArn  = $vault.BackupVaultArn
            CreationDate    = if ($vault.CreationDate) { [datetime]$vault.CreationDate } else { $null }
            Locked          = if ($null -ne $vault.Locked) { [bool]$vault.Locked } else { $false }
        }

        $safeVault = Get-SafeFileName $vault.BackupVaultName
        $rpJson = Invoke-AwsJson -Arguments @('backup','list-recovery-points-by-backup-vault','--region',$region,'--backup-vault-name',$vault.BackupVaultName,'--output','json','--no-cli-pager') -OutputFile (Join-Path $rawDir ("recovery-points-$safeRegion-$safeVault.json"))
        $rps = @()
        if ($rpJson -and $rpJson.RecoveryPoints) { $rps = @($rpJson.RecoveryPoints) }
        foreach ($rp in $rps) {
            $resourceName = Get-DbNameFromArn $rp.ResourceArn
            $recoveryPointRows += [pscustomobject]@{
                AwsAccountName     = $AwsAccountName
                Region             = $region
                BackupVaultName    = $vault.BackupVaultName
                RecoveryPointArn   = $rp.RecoveryPointArn
                ResourceType       = $rp.ResourceType
                ResourceArn        = $rp.ResourceArn
                ResourceNameGuess  = $resourceName
                BackupSizeInBytes  = if ($null -ne $rp.BackupSizeInBytes) { [double]$rp.BackupSizeInBytes } else { $null }
                BackupSizeGiBApprox= if ($null -ne $rp.BackupSizeInBytes) { [math]::Round(([double]$rp.BackupSizeInBytes / 1GB),2) } else { $null }
                CreationDate       = if ($rp.CreationDate) { [datetime]$rp.CreationDate } else { $null }
                CompletionDate     = if ($rp.CompletionDate) { [datetime]$rp.CompletionDate } else { $null }
                Status             = $rp.Status
                DeleteAfterDays    = if ($rp.Lifecycle -and $null -ne $rp.Lifecycle.DeleteAfterDays) { [int]$rp.Lifecycle.DeleteAfterDays } else { $null }
                MoveToColdAfterDays= if ($rp.Lifecycle -and $null -ne $rp.Lifecycle.MoveToColdStorageAfterDays) { [int]$rp.Lifecycle.MoveToColdStorageAfterDays } else { $null }
                IsEncrypted        = if ($null -ne $rp.IsEncrypted) { [bool]$rp.IsEncrypted } else { $false }
            }
        }
    }

    $plansJson = Invoke-AwsJson -Arguments @('backup','list-backup-plans','--region',$region,'--output','json','--no-cli-pager') -OutputFile (Join-Path $rawDir ("backup-plans-$safeRegion.json"))
    $plans = @()
    if ($plansJson -and $plansJson.BackupPlansList) { $plans = @($plansJson.BackupPlansList) }
    foreach ($plan in $plans) {
        $planId = $plan.BackupPlanId
        $planName = $plan.BackupPlanName
        $safePlan = Get-SafeFileName("$planName-$planId")

        $planRows += [pscustomobject]@{
            AwsAccountName = $AwsAccountName
            Region         = $region
            BackupPlanId   = $planId
            BackupPlanName = $planName
            CreationDate   = if ($plan.CreationDate) { [datetime]$plan.CreationDate } else { $null }
            VersionId      = $plan.VersionId
        }

        $planDetailJson = Invoke-AwsJson -Arguments @('backup','get-backup-plan','--region',$region,'--backup-plan-id',$planId,'--output','json','--no-cli-pager') -OutputFile (Join-Path $rawDir ("backup-plan-$safeRegion-$safePlan.json"))
        $planDetail = $null
        if ($planDetailJson) { $planDetail = $planDetailJson.BackupPlan }
        if ($planDetail -and $planDetail.Rules) {
            foreach ($rule in $planDetail.Rules) {
                $copyTargetVaults = @()
                if ($rule.CopyActions) { $copyTargetVaults = @($rule.CopyActions | ForEach-Object { $_.DestinationBackupVaultArn }) }
                $ruleRows += [pscustomobject]@{
                    AwsAccountName          = $AwsAccountName
                    Region                  = $region
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
        }

        $selectionListJson = Invoke-AwsJson -Arguments @('backup','list-backup-selections','--region',$region,'--backup-plan-id',$planId,'--output','json','--no-cli-pager') -OutputFile (Join-Path $rawDir ("backup-selections-$safeRegion-$safePlan.json"))
        $selectionList = @()
        if ($selectionListJson -and $selectionListJson.BackupSelectionsList) { $selectionList = @($selectionListJson.BackupSelectionsList) }
        foreach ($sel in $selectionList) {
            $selectionRows += [pscustomobject]@{
                AwsAccountName = $AwsAccountName
                Region         = $region
                BackupPlanId   = $planId
                BackupPlanName = $planName
                SelectionId    = $sel.SelectionId
                SelectionName  = $sel.SelectionName
            }

            $selDetailJson = Invoke-AwsJson -Arguments @('backup','get-backup-selection','--region',$region,'--backup-plan-id',$planId,'--selection-id',$sel.SelectionId,'--output','json','--no-cli-pager') -OutputFile (Join-Path $rawDir ("backup-selection-$safeRegion-$safePlan-" + (Get-SafeFileName("$($sel.SelectionName)-$($sel.SelectionId)")) + '.json'))
            $selDetail = $null
            if ($selDetailJson) { $selDetail = $selDetailJson.BackupSelection }
            if ($selDetail -and $selDetail.Resources) {
                foreach ($resourceArn in $selDetail.Resources) {
                    $dbName = Get-DbNameFromArn $resourceArn
                    $selectionResourceRows += [pscustomobject]@{
                        AwsAccountName       = $AwsAccountName
                        Region               = $region
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
            if ($selDetail -and $selDetail.ListOfTags) {
                foreach ($tag in $selDetail.ListOfTags) {
                    $selectionResourceRows += [pscustomobject]@{
                        AwsAccountName       = $AwsAccountName
                        Region               = $region
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
}

$dbLookup = @{}
foreach ($db in $dbInstanceRows) { $dbLookup["$($db.Region)|$($db.DBInstanceIdentifier)"] = $db }

$rdsRecoveryPoints = @($recoveryPointRows | Where-Object { $_.ResourceType -eq 'RDS' -or $_.ResourceArn -match ':rds:' })

$dbRecoveryStats = @()
foreach ($db in $dbInstanceRows) {
    $matches = @($rdsRecoveryPoints | Where-Object { ($_.Region -eq $db.Region) -and ($_.ResourceArn -eq $db.DBInstanceArn -or $_.ResourceNameGuess -eq $db.DBInstanceIdentifier) })
    $dbRecoveryStats += [pscustomobject]@{
        AwsAccountName             = $AwsAccountName
        Region                     = $db.Region
        DBInstanceIdentifier       = $db.DBInstanceIdentifier
        DBInstanceArn              = $db.DBInstanceArn
        AllocatedStorageGiB        = $db.AllocatedStorageGiB
        BackupRetentionPeriod      = $db.BackupRetentionPeriod
        IsDevelopmentLike          = $db.IsDevelopmentLike
        RecoveryPointCount         = $matches.Count
        TotalRecoveryPointGiBApprox= [math]::Round((($matches | Measure-Object -Property BackupSizeGiBApprox -Sum).Sum),2)
        AvgDeleteAfterDays         = if ($matches.Count -gt 0) { [math]::Round((($matches | Where-Object { $null -ne $_.DeleteAfterDays } | Measure-Object -Property DeleteAfterDays -Average).Average),1) } else { $null }
        OldestRecoveryPoint        = if ($matches.Count -gt 0) { ($matches | Sort-Object CreationDate | Select-Object -First 1).CreationDate } else { $null }
        NewestRecoveryPoint        = if ($matches.Count -gt 0) { ($matches | Sort-Object CreationDate -Descending | Select-Object -First 1).CreationDate } else { $null }
    }
}

$dbPlanCoverage = @()
foreach ($db in $dbInstanceRows) {
    $coveringSelections = @($selectionResourceRows | Where-Object { ($_.Region -eq $db.Region) -and ($_.DBInstanceIdentifier -eq $db.DBInstanceIdentifier -or $_.ResourceArn -eq $db.DBInstanceArn) })
    if ($coveringSelections.Count -eq 0) {
        $dbPlanCoverage += [pscustomobject]@{
            AwsAccountName         = $AwsAccountName
            Region                 = $db.Region
            DBInstanceIdentifier   = $db.DBInstanceIdentifier
            BackupPlanName         = ''
            RuleName               = ''
            ExecutionsPerDay       = $null
            EnableContinuousBackup = $false
            DeleteAfterDays        = $null
            CopyTargetVaults       = ''
        }
    } else {
        foreach ($sel in $coveringSelections) {
            $rules = @($ruleRows | Where-Object { $_.Region -eq $db.Region -and $_.BackupPlanId -eq $sel.BackupPlanId })
            foreach ($rule in $rules) {
                $dbPlanCoverage += [pscustomobject]@{
                    AwsAccountName         = $AwsAccountName
                    Region                 = $db.Region
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
    $coverage = @($dbPlanCoverage | Where-Object { $_.Region -eq $db.Region -and $_.DBInstanceIdentifier -eq $db.DBInstanceIdentifier })
    $stats = $dbRecoveryStats | Where-Object { $_.Region -eq $db.Region -and $_.DBInstanceIdentifier -eq $db.DBInstanceIdentifier } | Select-Object -First 1

    foreach ($rule in $coverage) {
        if ($rule.ExecutionsPerDay -ge 6 -and $db.AllocatedStorageGiB -ge 500) {
            $problems.Add([pscustomobject]@{
                AwsAccountName     = $AwsAccountName
                Region             = $db.Region
                Severity           = 'High'
                Category           = 'Backup Frequency'
                ResourceType       = 'RDS DB Instance'
                ResourceName       = $db.DBInstanceIdentifier
                Finding            = 'High-frequency snapshots on large database'
                Evidence           = "$($rule.BackupPlanName) / $($rule.RuleName) runs $($rule.ExecutionsPerDay)x per day for a $([math]::Round($db.AllocatedStorageGiB,0)) GiB database in $($db.Region)"
                Impact             = 'Increases ChargedBackupUsage through excessive recovery point accumulation'
                RecommendationKey  = 'REDUCE_FREQUENCY'
            })
            $recommendations.Add([pscustomobject]@{
                AwsAccountName   = $AwsAccountName
                Region           = $db.Region
                Priority         = 'High'
                ResourceName     = $db.DBInstanceIdentifier
                Recommendation   = 'Reduce scheduled snapshot frequency to once daily'
                Reason           = 'Continuous or daily backups are typically sufficient unless a specific recovery objective requires more frequent snapshots'
                ExpectedBenefit  = 'Substantial reduction in backup storage growth and ongoing RDS backup charges'
                SuggestedAction  = 'Change schedule from every 4 hours to a daily cron expression such as cron(0 5 ? * * *)'
            })
        }

        if ($rule.EnableContinuousBackup -and $rule.ExecutionsPerDay -gt 1) {
            $problems.Add([pscustomobject]@{
                AwsAccountName     = $AwsAccountName
                Region             = $db.Region
                Severity           = 'High'
                Category           = 'Redundant Protection'
                ResourceType       = 'RDS DB Instance'
                ResourceName       = $db.DBInstanceIdentifier
                Finding            = 'Continuous backup enabled alongside frequent scheduled snapshots'
                Evidence           = "$($rule.BackupPlanName) / $($rule.RuleName) in $($db.Region) has continuous backup enabled and also runs $($rule.ExecutionsPerDay)x per day"
                Impact             = 'Can duplicate protection while materially increasing backup storage cost'
                RecommendationKey  = 'SIMPLIFY_STRATEGY'
            })
            $recommendations.Add([pscustomobject]@{
                AwsAccountName   = $AwsAccountName
                Region           = $db.Region
                Priority         = 'High'
                ResourceName     = $db.DBInstanceIdentifier
                Recommendation   = 'Simplify the backup strategy'
                Reason           = 'Avoid combining PITR with aggressive scheduled snapshots unless there is a documented business requirement'
                ExpectedBenefit  = 'Reduced backup redundancy and lower storage cost'
                SuggestedAction  = 'Keep PITR for production, limit scheduled snapshots to daily, and validate retention against recovery requirements'
            })
        }

        if ($db.IsDevelopmentLike -and $rule.EnableContinuousBackup) {
            $problems.Add([pscustomobject]@{
                AwsAccountName     = $AwsAccountName
                Region             = $db.Region
                Severity           = 'Medium'
                Category           = 'Environment Fit'
                ResourceType       = 'RDS DB Instance'
                ResourceName       = $db.DBInstanceIdentifier
                Finding            = 'Development-like database has continuous backup enabled'
                Evidence           = "$($db.DBInstanceIdentifier) in $($db.Region) appears non-production and is covered by $($rule.BackupPlanName) with continuous backup enabled"
                Impact             = 'May exceed business requirements for a non-production workload'
                RecommendationKey  = 'REDUCE_NONPROD_PROTECTION'
            })
            $recommendations.Add([pscustomobject]@{
                AwsAccountName   = $AwsAccountName
                Region           = $db.Region
                Priority         = 'Medium'
                ResourceName     = $db.DBInstanceIdentifier
                Recommendation   = 'Reduce protection level for non-production databases'
                Reason           = 'Development and test systems typically do not require the same backup profile as production'
                ExpectedBenefit  = 'Lower storage cost with acceptable operational risk for non-production'
                SuggestedAction  = 'Consider daily snapshots with short retention and disable PITR if not required'
            })
        }

        if ($null -ne $rule.DeleteAfterDays -and $rule.DeleteAfterDays -gt 14 -and $db.AllocatedStorageGiB -ge 500) {
            $problems.Add([pscustomobject]@{
                AwsAccountName     = $AwsAccountName
                Region             = $db.Region
                Severity           = 'Medium'
                Category           = 'Retention'
                ResourceType       = 'RDS DB Instance'
                ResourceName       = $db.DBInstanceIdentifier
                Finding            = 'Long recovery point retention on large database'
                Evidence           = "$($rule.BackupPlanName) / $($rule.RuleName) in $($db.Region) retains recovery points for $($rule.DeleteAfterDays) days"
                Impact             = 'Long retention increases total billed backup storage'
                RecommendationKey  = 'TUNE_RETENTION'
            })
            $recommendations.Add([pscustomobject]@{
                AwsAccountName   = $AwsAccountName
                Region           = $db.Region
                Priority         = 'Medium'
                ResourceName     = $db.DBInstanceIdentifier
                Recommendation   = 'Tune retention to match recovery requirements'
                Reason           = 'Retention should be driven by compliance and restore needs, not defaults'
                ExpectedBenefit  = 'Gradual reduction of stored recovery points and lower monthly backup charges'
                SuggestedAction  = 'Use approximately 7-14 days for production and 1-3 days for development unless policy requires more'
            })
        }
    }

    if ($stats -and $stats.RecoveryPointCount -ge 10 -and $db.AllocatedStorageGiB -ge 500) {
        $problems.Add([pscustomobject]@{
            AwsAccountName     = $AwsAccountName
            Region             = $db.Region
            Severity           = 'High'
            Category           = 'Accumulation'
            ResourceType       = 'RDS DB Instance'
            ResourceName       = $db.DBInstanceIdentifier
            Finding            = 'Large number of recovery points present for a large database'
            Evidence           = "$($stats.RecoveryPointCount) recovery points found in $($db.Region); approximate cumulative protected size is $($stats.TotalRecoveryPointGiBApprox) GiB"
            Impact             = 'Existing recovery points are already contributing to current ChargedBackupUsage'
            RecommendationKey  = 'CLEANUP_RECOVERY_POINTS'
        })
        $recommendations.Add([pscustomobject]@{
            AwsAccountName   = $AwsAccountName
            Region           = $db.Region
            Priority         = 'High'
            ResourceName     = $db.DBInstanceIdentifier
            Recommendation   = 'Remove unnecessary historical recovery points'
            Reason           = 'Policy changes alone will not reduce current billed storage without cleanup or expiry'
            ExpectedBenefit  = 'Immediate cost reduction once old recovery points are deleted or expire'
            SuggestedAction  = 'Review vault recovery points and remove those outside the approved retention window'
        })
    }
}

$oldManualSnapshots = @($snapshotRows | Where-Object { $_.SnapshotType -eq 'manual' -and $_.SnapshotCreateTime -lt (Get-Date).AddDays(-30) })
foreach ($snap in $oldManualSnapshots) {
    $problems.Add([pscustomobject]@{
        AwsAccountName     = $AwsAccountName
        Region             = $snap.Region
        Severity           = 'Medium'
        Category           = 'Manual Snapshots'
        ResourceType       = 'RDS Snapshot'
        ResourceName       = $snap.DBSnapshotIdentifier
        Finding            = 'Manual snapshot older than 30 days'
        Evidence           = "$($snap.DBInstanceIdentifier) manual snapshot created $($snap.SnapshotCreateTime.ToString('yyyy-MM-dd')) in $($snap.Region)"
        Impact             = 'Manual snapshots do not expire automatically and may contribute to backup charges'
        RecommendationKey  = 'REVIEW_MANUAL_SNAPSHOTS'
    })
    $recommendations.Add([pscustomobject]@{
        AwsAccountName   = $AwsAccountName
        Region           = $snap.Region
        Priority         = 'Medium'
        ResourceName     = $snap.DBSnapshotIdentifier
        Recommendation   = 'Review and delete stale manual snapshots if no longer required'
        Reason           = 'Manual snapshots persist until explicitly removed'
        ExpectedBenefit  = 'Potential one-time reduction in billed backup storage'
        SuggestedAction  = 'Confirm retention owner and delete stale manual snapshots that are not required for rollback or compliance'
    })
}

$regionSummaryRows = foreach ($region in $regions) {
    $regionDbs = @($dbInstanceRows | Where-Object { $_.Region -eq $region })
    $regionRps = @($rdsRecoveryPoints | Where-Object { $_.Region -eq $region })
    $regionPlans = @($planRows | Where-Object { $_.Region -eq $region })
    [pscustomobject]@{
        AwsAccountName            = $AwsAccountName
        Region                    = $region
        RDSInstanceCount          = $regionDbs.Count
        BackupPlanCount           = $regionPlans.Count
        RDSRecoveryPointCount     = $regionRps.Count
        ApproxRecoveryPointGiB    = [math]::Round((($regionRps | Measure-Object -Property BackupSizeGiBApprox -Sum).Sum),2)
        HighSeverityFindingCount  = (@($problems | Where-Object { $_.Region -eq $region -and $_.Severity -eq 'High' })).Count
        MediumSeverityFindingCount= (@($problems | Where-Object { $_.Region -eq $region -and $_.Severity -eq 'Medium' })).Count
    }
}

$summaryRows = @(
    [pscustomobject]@{ AwsAccountName = $AwsAccountName; Metric = 'AWS Account Name'; Value = $AwsAccountName; Notes = 'User-supplied account label for report naming and identification' },
    [pscustomobject]@{ AwsAccountName = $AwsAccountName; Metric = 'Regions Scanned'; Value = $regions.Count; Notes = 'Enabled AWS regions queried across RDS and AWS Backup' },
    [pscustomobject]@{ AwsAccountName = $AwsAccountName; Metric = 'RDS DB Instances'; Value = $dbInstanceRows.Count; Notes = 'Total databases evaluated across all regions' },
    [pscustomobject]@{ AwsAccountName = $AwsAccountName; Metric = 'Backup Plans'; Value = $planRows.Count; Notes = 'AWS Backup plans discovered across all regions' },
    [pscustomobject]@{ AwsAccountName = $AwsAccountName; Metric = 'Backup Rules'; Value = $ruleRows.Count; Notes = 'Rules across all plans and regions' },
    [pscustomobject]@{ AwsAccountName = $AwsAccountName; Metric = 'Backup Vaults'; Value = $vaultRows.Count; Notes = 'Vaults queried for recovery points across all regions' },
    [pscustomobject]@{ AwsAccountName = $AwsAccountName; Metric = 'RDS Recovery Points'; Value = $rdsRecoveryPoints.Count; Notes = 'Recovery points mapped to RDS resources across all regions' },
    [pscustomobject]@{ AwsAccountName = $AwsAccountName; Metric = 'Approx RDS Recovery Point GiB'; Value = [math]::Round((($rdsRecoveryPoints | Measure-Object -Property BackupSizeGiBApprox -Sum).Sum),2); Notes = 'Approximate sum of protected sizes reported by AWS Backup' },
    [pscustomobject]@{ AwsAccountName = $AwsAccountName; Metric = 'High Severity Findings'; Value = (@($problems | Where-Object { $_.Severity -eq 'High' })).Count; Notes = 'Requires near-term action' },
    [pscustomobject]@{ AwsAccountName = $AwsAccountName; Metric = 'Medium Severity Findings'; Value = (@($problems | Where-Object { $_.Severity -eq 'Medium' })).Count; Notes = 'Should be remediated after high-severity items' }
)

$recommendations = $recommendations | Sort-Object Region, Priority, ResourceName, Recommendation -Unique
$problems = $problems | Sort-Object Region, Severity, Category, ResourceName, Finding -Unique

if (Test-Path $workbookPath) { Remove-Item $workbookPath -Force }

$excelParams = @{ Path = $workbookPath; FreezeTopRow = $true; BoldTopRow = $true; AutoSize = $true; AutoFilter = $true; TableStyle = 'Medium2' }

$summaryRows | Export-Excel @excelParams -WorksheetName 'Executive Summary' -TableName 'ExecutiveSummary' -Title "AWS Backup Audit Summary - $AwsAccountName" -TitleBold -TitleSize 16 -ClearSheet
$regionSummaryRows | Sort-Object ApproxRecoveryPointGiB -Descending | Export-Excel @excelParams -WorksheetName 'Regional Summary' -TableName 'RegionalSummary'
$problems | Export-Excel @excelParams -WorksheetName 'Problems' -TableName 'Problems'
$recommendations | Export-Excel @excelParams -WorksheetName 'Recommendations' -TableName 'Recommendations'
$dbInstanceRows | Sort-Object Region, DBInstanceIdentifier | Export-Excel @excelParams -WorksheetName 'RDS Instances' -TableName 'RDSInstances'
$dbRecoveryStats | Sort-Object TotalRecoveryPointGiBApprox -Descending | Export-Excel @excelParams -WorksheetName 'RDS Recovery Stats' -TableName 'RDSRecoveryStats'
$snapshotRows | Sort-Object Region, SnapshotCreateTime | Export-Excel @excelParams -WorksheetName 'RDS Snapshots' -TableName 'RDSSnapshots'
$planRows | Sort-Object Region, BackupPlanName | Export-Excel @excelParams -WorksheetName 'Backup Plans' -TableName 'BackupPlans'
$ruleRows | Sort-Object Region, BackupPlanName, RuleName | Export-Excel @excelParams -WorksheetName 'Backup Rules' -TableName 'BackupRules'
$selectionRows | Sort-Object Region, BackupPlanName, SelectionName | Export-Excel @excelParams -WorksheetName 'Backup Selections' -TableName 'BackupSelections'
$selectionResourceRows | Sort-Object Region, BackupPlanName, SelectionName | Export-Excel @excelParams -WorksheetName 'Selection Resources' -TableName 'SelectionResources'
$vaultRows | Sort-Object Region, BackupVaultName | Export-Excel @excelParams -WorksheetName 'Backup Vaults' -TableName 'BackupVaults'
$rdsRecoveryPoints | Sort-Object Region, CreationDate | Export-Excel @excelParams -WorksheetName 'Recovery Points' -TableName 'RecoveryPoints'
$regionInventoryRows | Export-Excel @excelParams -WorksheetName 'Regions Scanned' -TableName 'RegionsScanned'

$pkg = Open-ExcelPackage -Path $workbookPath
$wsSummary = $pkg.Workbook.Worksheets['Executive Summary']
$wsRegional = $pkg.Workbook.Worksheets['Regional Summary']
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

$wsSummary.Column(3).Style.Numberformat.Format = '#,##0.00'
$wsRegional.Column(5).Style.Numberformat.Format = '#,##0.00'
$wsInstances.Column(7).Style.Numberformat.Format = '#,##0'
$wsRecoveryStats.Column(5).Style.Numberformat.Format = '#,##0'
$wsRecoveryStats.Column(8).Style.Numberformat.Format = '#,##0.00'
$wsRules.Column(9).Style.Numberformat.Format = '#,##0'
$wsRecoveryPoints.Column(8).Style.Numberformat.Format = '#,##0.00'

$problemEndRow = $wsProblems.Dimension.End.Row
if ($problemEndRow -ge 2) {
    Add-ConditionalFormatting -Worksheet $wsProblems -Range "C2:C$problemEndRow" -RuleType ContainsText -ConditionValue 'High' -BackgroundColor '#F4CCCC' -ForeGroundColor '#9C0006'
    Add-ConditionalFormatting -Worksheet $wsProblems -Range "C2:C$problemEndRow" -RuleType ContainsText -ConditionValue 'Medium' -BackgroundColor '#FCE5CD' -ForeGroundColor '#7F6000'
}

$recoEndRow = $wsRecommendations.Dimension.End.Row
if ($recoEndRow -ge 2) {
    Add-ConditionalFormatting -Worksheet $wsRecommendations -Range "C2:C$recoEndRow" -RuleType ContainsText -ConditionValue 'High' -BackgroundColor '#F4CCCC' -ForeGroundColor '#9C0006'
    Add-ConditionalFormatting -Worksheet $wsRecommendations -Range "C2:C$recoEndRow" -RuleType ContainsText -ConditionValue 'Medium' -BackgroundColor '#FCE5CD' -ForeGroundColor '#7F6000'
}

$ruleEndRow = $wsRules.Dimension.End.Row
if ($ruleEndRow -ge 2) {
    Add-ConditionalFormatting -Worksheet $wsRules -Range "I2:I$ruleEndRow" -RuleType GreaterThan -ConditionValue '1' -BackgroundColor '#FCE5CD'
    Add-ConditionalFormatting -Worksheet $wsRules -Range "N2:N$ruleEndRow" -RuleType Equal -ConditionValue 'TRUE' -BackgroundColor '#D9EAD3'
}

$regionalEndRow = $wsRegional.Dimension.End.Row
if ($regionalEndRow -ge 2) {
    Add-ConditionalFormatting -Worksheet $wsRegional -Range "E2:E$regionalEndRow" -RuleType GreaterThan -ConditionValue '0' -BackgroundColor '#D9EAD3'
    Add-ConditionalFormatting -Worksheet $wsRegional -Range "F2:F$regionalEndRow" -RuleType GreaterThan -ConditionValue '0' -BackgroundColor '#F4CCCC'
}

$wsSummary.Cells['F1'].Value = 'Key Callouts'
$wsSummary.Cells['F1'].Style.Font.Bold = $true
$wsSummary.Cells['F2'].Value = 'Problem'
$wsSummary.Cells['G2'].Value = 'Count'
$wsSummary.Cells['F2:G2'].Style.Font.Bold = $true
$wsSummary.Cells['F3'].Value = 'High Severity Findings'
$wsSummary.Cells['G3'].Formula = 'COUNTIF(Problems[Severity],"High")'
$wsSummary.Cells['F4'].Value = 'Medium Severity Findings'
$wsSummary.Cells['G4'].Formula = 'COUNTIF(Problems[Severity],"Medium")'
$wsSummary.Cells['F5'].Value = 'High Priority Recommendations'
$wsSummary.Cells['G5'].Formula = 'COUNTIF(Recommendations[Priority],"High")'
$wsSummary.Cells['F6'].Value = 'Regions Scanned'
$wsSummary.Cells['G6'].Formula = 'ROWS(RegionsScanned[Region])'
$wsSummary.Cells['F7'].Value = 'Approx Recovery Point GiB'
$wsSummary.Cells['G7'].Formula = 'SUM(RecoveryPoints[BackupSizeGiBApprox])'
$wsSummary.Cells['G3:G7'].Style.Numberformat.Format = '#,##0.00'
$wsSummary.Cells['F1:G7'].AutoFitColumns()

$wsSummary.Cells['A1'].AddComment('This workbook consolidates AWS Backup, RDS, plan, rule, and recovery point data across all enabled regions into a single review package. Focus first on Regional Summary, Problems, and Recommendations.', 'ChatGPT') | Out-Null
$wsRegional.Cells['A1'].AddComment('Use this sheet to see which regions actually contain RDS backup inventory and where the largest protected footprint exists.', 'ChatGPT') | Out-Null
$wsProblems.Cells['F1'].AddComment('Finding names are normalized so similar issues can be grouped for director-level review.', 'ChatGPT') | Out-Null
$wsRecommendations.Cells['H1'].AddComment('SuggestedAction provides the concrete remediation step to implement.', 'ChatGPT') | Out-Null

Close-ExcelPackage $pkg

Write-Host ''
Write-Host "Done. Workbook created: $workbookPath"
Write-Host 'Review these tabs first:'
Write-Host '  Regional Summary'
Write-Host '  Problems'
Write-Host '  Recommendations'
