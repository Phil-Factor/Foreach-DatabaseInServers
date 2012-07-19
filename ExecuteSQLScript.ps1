Import-Module sqlps -DisableNameChecking #load the SQLPS functionality for getting the registered servers
. ".\ForAllDatabaseServers.ps1" # pull in our pipeline function 'Foreach-DatabaseInServers'
#now fetch the list of all our registered servers
$servers= dir 'SQLSERVER:\sqlregistration\Database Engine Server Group' | foreach-object{$_.name}
$Filepath='E:\MyScriptsDirectory' # local directory to save the reports to
$SQLTitle='All_Heaps_In_'
$SQL=@'
--Which of my tables don't have primary keys?
SELECT @@Servername as [Server],DB_NAME() as [Database], --we'll do it via information_Schema
  TheTables.Table_Catalog+'.'+TheTables.Table_Schema+'.'
                        +TheTables.Table_Name AS [tables without primary keys]
FROM
  INFORMATION_SCHEMA.TABLES TheTables
  LEFT OUTER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS TheConstraints
    ON TheTables.table_Schema=TheConstraints.table_schema
       AND TheTables.table_name=TheConstraints.table_name
       AND constraint_type='PRIMARY KEY'
WHERE table_Type='BASE TABLE'
  AND constraint_name IS NULL
ORDER BY [tables without primary keys]
'@

<#So, we can make it call some sql and get back a result. In this case we are only looking at the various AdventureWorks databases in all the servers, just to illustrate the different filters you can specify.#>
Foreach-DatabaseInServers $servers -TheDatabasefilter { param($x); if ($x.name -like ‘Adv*’){$x}}  -jobToDo {
   param($database)

 	$databaseName=$database.name
	$ServerName=$database.Parent.URN.GetAttribute('Name','Server')
   $directory="$($FilePath)\$($ServerName -replace  '[\\\/\:\.]','-' )";#create a directory
   #and a handler for warnings and PRINT messages
	$handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {param($sender, $event) Write-Host $event.Message};
	$database.parent.ConnectionContext.add_InfoMessage($handler);
	$result=$database.ExecuteWithResults("$SQL") #execute the SQL
	$database.parent.ConnectionContext.remove_InfoMessage($handler);
	if (!(Test-Path -path "$directory")) #create the directory if necessary
	      {
			 Try { New-Item "$directory" -type directory | out-null }  
		    Catch [system.exception]{
			      Write-Error "error while creating '$directory'  "
		         return
		          }  
	      }
<#you might want to save these in a central monitoring server, or put them all in one file, of course, but that is all what powershell is about #>
	$result.Tables[0]| convertto-csv -NoTypeInformation >"$directory\$SQLTitle$databasename.csv"
	}
