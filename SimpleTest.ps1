. ".\ForAllDatabaseServers.ps1" # pull in our pipeline function 'Foreach-DatabaseInServers'
$DataSources=@('Dave','Dee','Dosy','Beaky','Mitch','Titch') # server name and instance
Foreach-DatabaseInServers $Datasources  -TheDatabasefilter { param($x); if ($x.name -like ‘Adv*’){$x}} #test that you can cannect to your datasources


