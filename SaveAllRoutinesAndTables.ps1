$DirectoryToSaveTo='E:\MyScriptsDirectory' # the directory where you want to store them
$TheDatabasefilter = { param($x); if ($x.name -like ‘Phil*’){$x}} # just those starting with 'Phil'.

. ".\ForAllDatabaseServers.ps1" # pull in our pipeline function 'Foreach-DatabaseInServers'
Import-Module sqlps -DisableNameChecking #load the SQLPS functionality for getting the registered servers
#get a list of the servers we want to scan
$servers= dir 'SQLSERVER:\sqlregistration\Database Engine Server Group' | foreach-object{$_.name}

$ServiceBrokerTypes=@( 'MessageType','ServiceBroker','ServiceContract','ServiceQueue','ServiceRoute','RemoteServiceBinding')

$JobToDo= {
   $database=$_ 
	$databaseName=$_.name
	$ServerName=$_.Parent.URN.GetAttribute('Name','Server')
	write-verbose "scripting $databasename in $serverName"
	$ScriptOptions = new-object ("Microsoft.SqlServer.Management.Smo.ScriptingOptions")
	$ScriptOptions.ExtendedProperties= $true # yes, we want these
	$ScriptOptions.DRIAll= $true # and all the constraints
	$ScriptOptions.Indexes= $true # Yup, these would be nice
	$ScriptOptions.ScriptBatchTerminator = $true # this only goes to the file
	$ScriptOptions.IncludeHeaders = $true; # of course
	$ScriptOptions.ToFileOnly = $true # no need of string output as well
	$ScriptOptions.IncludeIfNotExists = $true # not necessary but makes script more versatile
   $scrp=new-object ("$My.Scripter") $Database.parent
	$scrp.options=$ScriptOptions
   $database.EnumObjects([long]0x1FFFFFFF -band [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::all) | `
      Where-Object {('sys','information_schema') -notcontains $_.Schema} | Foreach-Object { 
   $urn=	[Microsoft.SqlServer.Management.Sdk.Sfc.Urn] $_.URN	
	if (('ExtendedStoredProcedure','ServiceBroker') -notcontains $urn.type)
	   {
		$currentPath="$DirectoryToSaveTo\$($ServerName -replace  '[\\\/\:\.]','-' )\$($urn.GetAttribute('Name','Database') -replace  '[\\\/\:\.]','-')"
		if ( $ServiceBrokerTypes -contains $urn.type)
				{$fullPath="$currentPath\ServiceBroker\$($urn.type)"}
	   else
				{$fullPath="$currentPath\$($urn.type)"}
	
	   if (!(Test-Path -path $fullPath ))
	      {
			Try { New-Item $fullPath -type directory | out-null }  
			Catch [system.exception]{
				  Write-Error "error while creating '$fullPath' "
			     return
			    }  
	      }
		 $scrp.options.FileName = "$fullPath\$($urn.GetAttribute('Schema')-replace  '[\\\/\:\.]','-')-$($urn.GetAttribute('Name') -replace  '[\\\/\:\.]','-').sql"
	    $UrnCollection = new-object ('Microsoft.SqlServer.Management.Smo.urnCollection')
	    $URNCollection.add($urn)
		 write-verbose "writing script to $($scrp.options.FileName)"
	    $scrp.Script($URNCollection)
		}
   }
     
}

$params = @{DataSources=$Servers;TheDatabaseFilter=$TheDatabasefilter;JobToDo=$JobToDo;verbose=$true}
Foreach-DatabaseInServers @Params
"done them, Master."






       
