
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
 This script aims to query event ID 37 that gets logged after installing KB5008380. From these events, gathers what DC constructed the ticket and what object the ticket was issued to. Displays all that information in a GridView. 
 
 .EXAMPLE
Get-Events37.ps1 
Query all Domain Controllers in the domain for event id 37.

.EXAMPLE
Get-Events37.ps1 -MaxEvents 500
Query for event id 37 with a maximum of 500 events queried per DC.

.EXAMPLE
Get-Events37.ps1 -DomainControllerList ((Get-ADDomainController -Filter {name -like 'dc*'}).name)
Query Domain Controllers that start with the 'dc' and only query those for event id 37.
#> 
Param(

[int]$MaxEvents=300, # by default only 300 events are retrieved from DCs.
[System.Array]$DomainControllerList = ((Get-ADDomainController -Filter *).name) #By default queries all domain controllers
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
$result= @()
foreach($cmp in $DomainControllerList){

    try {   $events= Get-WinEvent -FilterXml $xmlFilter -ComputerName $cmp -MaxEvents $MaxEvents -ea SilentlyContinue}
    catch [System.Diagnostics.Eventing.Reader.EventLogException]  { Write-Error "Error accessing $cmp via RPC. Check network connectivity."; $events= $null }
    
    if ($events) 
        {
            $result += $events |  select `
                @{Label='EventsGatheredFrom';Expression={$cmp}},
                @{ Label='TicketConstructedBy'; Expression={$_.Message -match "(Ticket PAC constructed by: )(?<TicketConstructerDCName>.+)" | Out-Null;$Matches.TicketConstructerDCName}}, 
                @{Label='Client';Expression={$_.Message -match "(Client: .+\\\\)(?<ClientName>.+)" |Out-Null;$Matches.ClientName}},
                @{Label="Ticket";Expression={$_.Message -match "(Ticket for: )(?<Ticket>.+)" |Out-Null;$Matches.Ticket}}
               
         } 
    
    }

$result | Sort-Object EventsGatheredFrom | Out-GridView

#endregion