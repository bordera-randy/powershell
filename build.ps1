param(
  [ValidateSet("Docs","Test","Lint","All")]
  [string]$Task = "All"
)

$ModuleName = "SysAdminTools"
$ModulePath = "./modules/$ModuleName/$ModuleName.psd1"
$HelpPath   = "./docs/help/$ModuleName"
$HelpXmlOut = "./docs/help/$ModuleName/en-US"

function Build-Docs {
  Install-Module PlatyPS -Scope CurrentUser -Force -ErrorAction Stop

  Import-Module $ModulePath -Force

  New-Item -ItemType Directory -Force -Path $HelpPath | Out-Null
  New-Item -ItemType Directory -Force -Path $HelpXmlOut | Out-Null

  if (-not (Test-Path $HelpPath) -or -not (Get-ChildItem $HelpPath -Filter *.md -ErrorAction SilentlyContinue)) {
    New-MarkdownHelp -Module $ModuleName -OutputFolder $HelpPath -Force
  } else {
    Update-MarkdownHelp -Path $HelpPath -Force
  }

  New-ExternalHelp -Path $HelpPath -OutputPath $HelpXmlOut -Force
  Write-Host "Docs generated at $HelpPath and compiled to $HelpXmlOut"
}

switch ($Task) {
  "Docs" { Build-Docs }
  "All"  { Build-Docs }
  default { Build-Docs }
}