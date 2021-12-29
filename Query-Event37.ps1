
<#PSScriptInfo

.VERSION 1.0

.GUID 63fa4e5d-8e93-4ea4-9700-418a99d3a653

.AUTHOR Can Dagdelen

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

#Requires -Module ActiveDirectory

<# 

.DESCRIPTION 
 This script aims to query event ID 37 that gets logged after installing KB5008380. From these events, gathers what DC constructed the ticket and what object the ticket was issued to. 

#> 
Param(

[int]$MaxEvents=300,
[string[]]$CmpName = Get-ADDomainController -Filter *| select name
    )

#region Event filter
$xmlFilter = @'
    <QueryList>
    <Query Id="0">
    <Select Path="System">
    *[System[Provider[@EventSourceName='KDC'] and (EventID=37)]]
    </Select>
    </Query>
    </QueryList>
'@
#endregion

#region get events from DCs & display
$result=""
$x= foreach($cmp in $CmpName){ 
    $events= Get-WinEvent -FilterXml $xmlFilter -ComputerName $cmp.name
    $events |  select `
    @{ Label='TicketConstructerDCName'; Expression={$_.Message -match "(Ticket PAC constructed by: )(?<TicketConstructerDCName>.+)" | Out-Null;$Matches.TicketConstructerDCName}}, 
    @{Label='ClientName';Expression={$_.Message -match "(Client: .+\\\\)(?<ClientName>.+)" |Out-Null;$Matches.ClientName}},
    @{Label="Ticket";Expression={$_.Message -match "(Ticket for: )(?<Ticket>.+)" |Out-Null;$Matches.Ticket}}, 
    @{Label="EventsonDC";Expression={$cmp.name}} 
    }

$x | Sort-Object DCName,EventsonDC | Out-GridView

#endregion