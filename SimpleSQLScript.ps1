Import-Module sqlps -DisableNameChecking #load the SQLPS functionality for getting the registered servers
. ".\ForAllDatabaseServers.ps1" # pull in our pipeline function 'Foreach-DatabaseInServers'
#now fetch the list of all our registered servers
$servers= dir 'SQLSERVER:\sqlregistration\Database Engine Server Group' | foreach-object{$_.name}
$SQL=@'
--Which of my tables don't have any indexes at all?
SELECT @@Servername as [Server],DB_NAME() as [Database], 
DB_NAME()+'.'+Object_Schema_name(t.object_ID)+'.'+t.name AS [Tables without any index]
FROM sys.tables t WHERE OBJECTPROPERTY(object_id, 'TableHasIndex')=0
order by [Tables without any index]  
'@

<#So, we can make it call some sql and get back a result. In this case we are only looking at the various AdventureWorks databases in all the servers, just to illustrate the different filters you can specify.#>
Foreach-DatabaseInServers $servers -TheDatabasefilter { param($x); if ($x.name -like ‘Adv*’){$x}}  -jobToDo {
   param($database)
 	$result=$database.ExecuteWithResults("$SQL") #execute the SQL
	$result.Tables[0]
	} | select-object ('Server','Database' ,'Tables without any index') | convertTo-html
