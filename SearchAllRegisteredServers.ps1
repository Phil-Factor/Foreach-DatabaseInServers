Import-Module sqlps -DisableNameChecking #load the SQLPS functionality for getting the registered servers
. ".\ForAllDatabaseServers.ps1" # pull in our pipeline function 'Foreach-DatabaseInServers'
#now fetch the list of all our registered servers
$servers= dir 'SQLSERVER:\sqlregistration\Database Engine Server Group' | foreach-object{$_.name}
#and a list of the databases we don't want to be scripted
$blacklist='Pubs','NorthWind','AdventureWorks','AdventureWorksDW','ReportServer','ReportServerTempDB' #the databases I don't want to do
#where we want to store the scripts (each server/instance  a separate directory
$Filepath='E:\MyScriptsDirectory' # local directory to save build-scripts to
#and do it
Foreach-DatabaseInServers -verbose $servers -blacklist $blacklist -jobToDo {param($database)
   $directory="$($FilePath)\$( $database.Parent.URN.GetAttribute('Name','Server')  -replace  '[\\\/\:\.]','-' )";
	$transfer = new-object ("$My.Transfer") $database
	$CreationScriptOptions = new-object ("$My.ScriptingOptions") 
	$CreationScriptOptions.ExtendedProperties= $true # yes, we want these
	$CreationScriptOptions.DRIAll= $true # and all the constraints 
	$CreationScriptOptions.Indexes= $true # Yup, these would be nice
	$CreationScriptOptions.Triggers= $true # This should be included when scripting a database
	$CreationScriptOptions.ScriptBatchTerminator = $true # this only goes to the file
	$CreationScriptOptions.IncludeHeaders = $true; # of course
	$CreationScriptOptions.ToFileOnly = $true #no need of string output as well
	$CreationScriptOptions.IncludeIfNotExists = $true # not necessary but it means the script can be more versatile
	$CreationScriptOptions.Filename = "$directory\$($Database.name)_Build.sql"; 
	$transfer.options=$CreationScriptOptions # tell the transfer object of our preferences
   write-verbose "scripting '$($database.name)' in server '$($database.parent.name)' to $($CreationScriptOptions.Filename)"
   if (!(Test-Path -path "$directory"))
      {
		 Try { New-Item "$directory" -type directory | out-null }  
	    Catch [system.exception]{
		      Write-Error "error while creating '$directory'  "
	         return
	          }  
      }
   Try {$transfer.ScriptTransfer()}
	    Catch [system.exception]{
		      Write-Error "couldn't script to '$directory\$($Database.name)_Build.sql' because of error (possibly an encrypted stored procedure"
	          }  
   }
'did that go well?'

