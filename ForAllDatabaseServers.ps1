Function Foreach-DatabaseInServers {
    <#
    .SYNOPSIS
    Does the whatever scriptblock you wish for the databases in list of SQL server instances
    .DESCRIPTION
    This takes the scriptblock you define  and executes it against every database that you specify, either by using a whitelist or a blacklist, or just does them all.
    .EXAMPLE
	$DataSources='Dave', 'Dee', 'Dozy', 'Beaky', 'Mick', 'Titch'  # server name and instance
	$JobToDo ={param($database)
				 	$databaseName=$database.name
					$ServerName=$database.Parent.Name
					"Do stuff to $databasename on $Servername"}
	$whitelist=''#the only databases I want to do, if they're there(Leave empty otherwise)
	$blacklist='Pubs','NorthWind','AdventureWorks','AdventureWorksDW','ReportServer','ReportServerTempDB' #the databases I don't want to do

	Foreach-DatabaseInServers $Datasources  $jobToDo $whitelist $blacklist
    .PARAMETER DataSources
    The list of servers that you want the files from 
    .PARAMETER JobToDo
    The script of the job you want done
    .PARAMETER Whitelist
    The list of databases you want the action performed on, leaving out all others
    .PARAMETER Blacklist
    The list of databases you don't want the action performed on
    .PARAMETER TheServerFilter
    Any filter you specify for servers
   .PARAMETER TheDatabaseFilter
    Any filter you specify for databases
    .PARAMETER Initialisation
	 any action that needs to be done first before the pipeline
   #>
   param([CmdletBinding()]
        # The list of databases
        [Parameter(Mandatory=$True,
						 Position=0,
                   HelpMessage='the list of one or more SQL Server instances you would like to target')]
        $DataSources,
        # The Job To Do 
        [Parameter(Mandatory=$false,
 						 Position=1,
                   HelpMessage='The actual job you want to do in each database')]
        [scriptblock]$JobToDo ={ param($x); $x},
         # The WhiteList
        [Parameter(Mandatory=$false,
 						 Position=2,
                   HelpMessage='the databases in each instance that you want to select')]
        $Whitelist='',
         # The BlackList
        [Parameter(Mandatory=$false,
 						 Position=3,
                   HelpMessage='the databases in each instance that you dont want to select')]
        $Blacklist='',
        # The custom database filter you want to use 
        [Parameter(Mandatory=$false,
 						 Position=4,
                   HelpMessage='if the whitelist or blacklist is no good for what you want')]
        [scriptblock]$TheServerFilter={ param($x); $x }, # define a filter that does nothing by default
        # The custom server filter you want to use 
        [Parameter(Mandatory=$false,
 						 Position=5,
                   HelpMessage='if you wish to select from a list of servers')]
        [scriptblock]$TheDatabaseFilter={ param($x); $x },# define a filter that does nothing by default
        # The custom server filter you want to use 
        [Parameter(Mandatory=$false,
 						 Position=6,
                   HelpMessage='any initialisation you want (with SMO loaded)')]
        [scriptblock]$Initialisation={}# define an initialisation routine that does nothing by default
  

     )
# set "Option Explicit" to catch subtle errors
set-psdebug -strict
# Load SMO assembly, and if we're running SQL 2008 DLLs load the SMOExtended and SQLWMIManagement libraries
$ms='Microsoft.SqlServer'
$v = [System.Reflection.Assembly]::LoadWithPartialName( "$ms.SMO")
if ((($v.FullName.Split(','))[1].Split('='))[1].Split('.')[0] -ne '9') {
[System.Reflection.Assembly]::LoadWithPartialName("$ms.SMOExtended") | out-null
   }
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoEnum') | out-null

$My="$ms.Management.Smo" #
$DatabaseFilter=$TheDatabaseFilter
if ($blacklist.count -gt 0) {$DatabaseFilter= { param($x); if ($blacklist -notcontains $x.name) {$x} }} 
# followed by the ones you don't want, listed in your blacklist
if ($whitelist.count -gt 0) {$DatabaseFilter= { param($x); if ($whitelist -contains $x.name) {$x} }} 
# and one that just selects the files you specify in your whitelist

$Initialisation.invoke() <# just in case you have a once-off routine you wish to execute (if you are doing SMO, since the function loads SMO.) #>

$DataSources | # our list of servers
  & {PROCESS{$TheServerFilter.invoke($_)}}  | # choose which servers from the list
   Foreach-object {new-object ("$My.Server") $_ } | # create an SMO server object
     Where-Object {$_.ServerType -ne $null} | # did you positively get the server?
      Foreach-object {$_.Databases } | #for every server successfully reached 
         Where-Object {$_.IsSystemObject -ne $true} | #not the system objects
            & {PROCESS{$DatabaseFilter.invoke($_)}}  | # do all,avoid blacklist or do a whitelist etc
              & {PROCESS{$JobToDo.invoke($_)}}  #and do whatever you want for the database
}					






