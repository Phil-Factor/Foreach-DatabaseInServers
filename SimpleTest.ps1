Import-Module sqlps -DisableNameChecking #load the SQLPS functionality for getting the registered servers
. ".\ForAllDatabaseServers.ps1" # pull in our pipeline function 'Foreach-DatabaseInServers'
#now fetch the list of all our registered servers
$DataSources= dir 'SQLSERVER:\sqlregistration\Database Engine Server Group' | foreach-object{$_.name}
#$DataSources=@('Dave','Dee','Dosy','Beaky','Mitch','Titch') # server name and instance
Foreach-DatabaseInServers $Datasources | foreach-object{"Found database '$($_.name)' on Server $($_.parent.name) "} #test that you can cannect to your datasources


