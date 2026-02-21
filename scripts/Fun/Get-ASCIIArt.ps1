<#
.SYNOPSIS
    Generate ASCII Art
.DESCRIPTION
    This script generates ASCII art text using different fonts and styles.
.EXAMPLE
    .\Get-ASCIIArt.ps1 -Text "Hello World" -Style Banner
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Text = "PowerShell",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Banner","Block","Simple","Random")]
    [string]$Style = "Banner"
)

function Get-BannerArt {
    param($Text)
    
    $banner = @"
 
 ____                        ____  _          _ _ 
|  _ \ _____      _____ _ __/ ___|| |__   ___| | |
| |_) / _ \ \ /\ / / _ \ '__\___ \| '_ \ / _ \ | |
|  __/ (_) \ V  V /  __/ |   ___) | | | |  __/ | |
|_|   \___/ \_/\_/ \___|_|  |____/|_| |_|\___|_|_|
                                                   
"@
    
    Write-Host $banner -ForegroundColor Cyan
}

function Get-BlockArt {
    param($InputText)
    
    $letters = @{
        'A' = @"
 █████╗ 
██╔══██╗
███████║
██╔══██║
██║  ██║
╚═╝  ╚═╝
"@
        'B' = @"
██████╗ 
██╔══██╗
██████╔╝
██╔══██╗
██████╔╝
╚═════╝ 
"@
        'C' = @"
 ██████╗
██╔════╝
██║     
██║     
╚██████╗
 ╚═════╝
"@
        'D' = @"
██████╗ 
██╔══██╗
██║  ██║
██║  ██║
██████╔╝
╚═════╝ 
"@
        'E' = @"
███████╗
██╔════╝
█████╗  
██╔══╝  
███████╗
╚══════╝
"@
        'F' = @"
███████╗
██╔════╝
█████╗  
██╔══╝  
██║     
╚═╝     
"@
        'G' = @"
 ██████╗ 
██╔════╝ 
██║  ███╗
██║   ██║
╚██████╔╝
 ╚═════╝
"@
        'H' = @"
██╗  ██╗
██║  ██║
███████║
██╔══██║
██║  ██║
╚═╝  ╚═╝
"@
        'I' = @"
██╗
██║
██║
██║
██║
╚═╝
"@
        'J' = @"
     ██╗
     ██║
     ██║
██   ██║
╚█████╔╝
 ╚════╝ 
"@
        'K' = @"
██╗  ██╗
██║ ██╔╝
█████╔╝ 
██╔═██╗
██║  ██╗
╚═╝  ╚═╝
"@
        'L' = @"
██╗     
██║     
██║     
██║     
███████╗
╚══════╝
"@
        'M' = @"
███████╗
████████║
██╔██╔██║
██║╚═╝██║
██║   ██║
╚═╝   ╚═╝
"@
        'N' = @"
███╗   ██╗
████╗  ██║
██╔██╗ ██║
██║╚██╗██║
██║ ╚████║
╚═╝  ╚═══╝
"@
        'O' = @"
 ██████╗ 
██╔═══██╗
██║   ██║
██║   ██║
╚██████╔╝
 ╚═════╝ 
"@
        'P' = @"
██████╗ 
██╔══██╗
██████╔╝
██╔═══╝ 
██║     
╚═╝     
"@
        'Q' = @"
 ██████╗ 
██╔═══██╗
██║   ██║
██║▄▄ ██║
╚██████╔╝
 ╚══▀▀═╝ 
"@
        'R' = @"
██████╗ 
██╔══██╗
██████╔╝
██╔══██╗
██║  ██║
╚═╝  ╚═╝
"@
        'S' = @"
███████╗
██╔════╝
███████╗
╚════██║
███████║
╚══════╝
"@
        'T' = @"
████████╗
╚══██╔══╝
   ██║   
   ██║   
   ██║   
   ╚═╝   
"@
        'U' = @"
██╗   ██╗
██║   ██║
██║   ██║
██║   ██║
╚██████╔╝
 ╚═════╝ 
"@
        'V' = @"
██╗   ██╗
██║   ██║
██║   ██║
╚██╗ ██╔╝
 ╚████╔╝
  ╚═══╝  
"@
        'W' = @"
██╗    ██╗
██║    ██║
██║ █╗ ██║
██║███╗██║
╚███╔███╔╝
 ╚══╝╚══╝
"@
        'X' = @"
██╗  ██╗
╚██╗██╔╝
 ╚███╔╝ 
 ██╔██╗ 
██╔╝ ██╗
╚═╝  ╚═╝
"@
        'Y' = @"
██╗   ██╗
╚██╗ ██╔╝
 ╚████╔╝ 
  ╚██╔╝  
   ██║   
   ╚═╝   
"@
        'Z' = @"
███████╗
╚══███╔╝
  ███╔╝ 
 ███╔╝  
███████╗
╚══════╝
"@
        ' ' = @"
      
      
      
      
      
      
"@
    }
    
    $InputText = $InputText.ToUpper()
    $lines = @("", "", "", "", "", "")
    
    foreach ($char in $InputText.ToCharArray()) {
        if ($letters.ContainsKey([string]$char)) {
            $charLines = $letters[[string]$char] -split "`n"
            for ($i = 0; $i -lt 6; $i++) {
                $lines[$i] += $charLines[$i] + "  "
            }
        }
    }
    
    foreach ($line in $lines) {
        Write-Host $line -ForegroundColor Cyan
    }
}

function Get-SimpleArt {
    param($InputText)
    
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║                                           ║" -ForegroundColor Green
    Write-Host "  ║   $($InputText.PadRight(39))║" -ForegroundColor Yellow
    Write-Host "  ║                                           ║" -ForegroundColor Green
    Write-Host "  ╚═══════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
}

function Get-RandomArt {
    $arts = @(
        @"
    _____
   /     \
  | () () |
   \  ^  /
    |||||
    |||||
"@,
        @"
    |\__/,|   (`\
  _.|o o  |_   ) )
-(((---(((--------
"@,
        @"
       .----.
      /  ..  \
     |  (||)  |
      \  ''  /
       '----'
"@,
        @"
    __o
  _`\<,_
 (_)/ (_)
"@,
        @"
  ___
 {o,o}
 |)__)
 -"-"-
"@
    )
    
    Write-Host ($arts | Get-Random) -ForegroundColor Cyan
}

# Main execution
Write-Host ""
Write-Host "ASCII Art Generator" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host ""

switch ($Style) {
    "Banner" { Get-BannerArt -Text $Text }
    "Block" { Get-BlockArt -InputText $Text }
    "Simple" { Get-SimpleArt -InputText $Text }
    "Random" { Get-RandomArt }
}

Write-Host ""
