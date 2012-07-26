Import-Module sqlps -DisableNameChecking #load the SQLPS functionality for getting the registered servers
. ".\ForAllDatabaseServers.ps1" # pull in our pipeline function 'Foreach-DatabaseInServers'
#now fetch the list of all our registered servers
$servers= dir 'SQLSERVER:\sqlregistration\Database Engine Server Group' | foreach-object{$_.name}

<# here we  want to find out the data space used for each row, along with the rowcount. We then can calculate the average size of each row #>
Foreach-DatabaseInServers $servers  -whitelist @('AdventureWorks')  -jobToDo {
   param($database)
	write-verbose "Accessing the database '$($database.name)' on server $($database.parent.name)"
 	$database.tables| select-object (@{Name="Server"; Expression={$database.parent.name}}, @{Name="Database"; Expression={$database.name}}, @{Name="table"; Expression={$_.name}}, @{Name="Data Space Used (Kb)"; e={$_.DataSpaceUsed}}, @{Name="Data Rows"; e={$_.RowCount}}, @{Name="no. columns"; e={$_.columns.count}}, @{Name="Average Row size (Bytes)"; e={"{0:n2}" -f (($_.DataSpaceUsed/$_.RowCount)*1024)}}) 
	} | format-table
