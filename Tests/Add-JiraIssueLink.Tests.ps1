Describe 'Add-JiraIssueLink' {

    Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'

        $issueKey = "TEST-01"
        $issueLink = [PSCustomObject]@{
            outwardIssue = [PSCustomObject]@{key = "TEST-10"}
            type         = [PSCustomObject]@{name = "Composition"}
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ParameterFilter { $Key -eq $issueKey } {
            $object = [PSCustomObject]@{
                Key = $issueKey
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        Mock Resolve-JiraIssueObject -ModuleName JiraPS {
            Get-JiraIssue -Key $Issue
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/latest/issueLink"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            return $true
        }

        #############
        # Tests
        #############

        Context "Sanity checking" {
            $command = Get-Command -Name Add-JiraIssueLink

            defParam $command 'Issue'
            defParam $command 'IssueLink'
            defParam $command 'Comment'
            defParam $command 'Credential'
        }

        Context "Functionality" {

            It 'Adds a new IssueLink' {
                { Add-JiraIssueLink -Issue $issueKey -IssueLink $issueLink } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It 'Validates the IssueType provided' {
                $issueLink = [PSCustomObject]@{ type = "foo" }
                { Add-JiraIssueLink -Issue $issueKey -IssueLink $issueLink } | Should Throw
            }

            It 'Validates pipeline input object' {
                { "foo" | Add-JiraIssueLink -IssueLink $issueLink } | Should Throw
            }
        }
    }
}
