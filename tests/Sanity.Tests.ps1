BeforeAll {
    Import-Module "$PSScriptRoot/../modules/SysAdminTools/SysAdminTools.psd1" -Force
}

Describe 'SysAdminTools module' {
    It 'Imports successfully' {
        Get-Module -Name SysAdminTools | Should -Not -BeNullOrEmpty
    }

    It 'Exports Get-Example' {
        Get-Command -Module SysAdminTools -Name Get-Example | Should -Not -BeNullOrEmpty
    }

    It 'Get-Example returns an object' {
        $result = Get-Example
        $result.Name | Should -Be 'Example'
        $result.Status | Should -Be 'OK'
    }
}
