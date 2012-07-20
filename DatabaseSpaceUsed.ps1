
Import-Module sqlps -DisableNameChecking #load the SQLPS functionality for getting the registered servers
. ".\ForAllDatabaseServers.ps1" # pull in our pipeline function 'Foreach-DatabaseInServers'
#now fetch the list of all our registered servers
$servers= dir 'SQLSERVER:\sqlregistration\Database Engine Server Group' | foreach-object{$_.name}
Foreach-DatabaseInServers $Servers  `
        -TheDatabasefilter { param($x); if ($x.name -like ‘Adv*’){$x}} |
   Select-object @{Name="Server"; Expression={$_.parent.name}}, Name, DataSpaceUsage, SpaceAvailable, IndexSpaceUsage  |ConvertTo-HTML

"Hmm. Did it work, Phil?"

