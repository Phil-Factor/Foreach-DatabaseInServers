#The basic sequence
$Sequence="ten","nine","eight","seven","six","five","four","three","two","one"

$StartAt='Ten' #The number we want to start at. Try it out with other values.

$action={param ($x,$Isfirst); #the scriptblock called for every item in the list
if (-not $Isfirst) {"there would be $x green bottles hanging on the wall."}
@"

There were $_ green bottles hanging on the wall, 
$_ green bottles hanging on the wall
and if one green bottle should accidentally fall
"@
}


$Start={ "         $StartAt Green Bottles.`n"} #Scriptblock called at start 
#and the one called after all items are processed
$Finish={ "there would be no green bottles hanging on the wall`n`n    The End`n" } 
#the scriptblock that decides whether the current item should be processed
$Filter={ param ($x, $status); if ($x -eq $startAt) {$status = $true}; $status }

#the actual pipeline. We will save the scriptblock literal in a variable which we can execute
$pipeline={
$Sequence|
  & { BEGIN{$ShouldOutput = $false} PROCESS{$ShouldOutput = $filter.invoke( $_, $ShouldOutput); if ($shouldOutput) {$_}} }  |
    & {BEGIN{$first=$true; $Start.invoke($_) } PROCESS{$action.invoke($_, $first); $first=$false} END{$Finish.invoke($_) } }
}
$pipeline.invoke() #and we just invoke the pipeline

<# Now, we can change the poem to be ‘There were ten in the bed’ without touching the pipeline at all, but just changing the contents of the variables holding three of the four scriptblocks #>

$action={param ($x,$Isfirst); #the scriptblock called for every item in the list
if (-not $Isfirst) { "Single beds were only made for $x"}
"`nThere were $x in the bed and the little one said,"
if ($x -ne 'one') { @" 
'Roll over, roll over!'.
So they all rolled over and one fell out
And he gave a little scream and he gave a little shout
'Please remember to tie a knot in your pajamas'
"@
}
else {for($ii = 1;$ii -le 3; $ii++) {"I've got the whole mattress to myself"}
"I've got the mattress to myself."}
}

$Start={ "         There were $StartAt in the Bed.`n"} #Scriptblock called at start 
#and the one called after all items are processed
$Finish={ "`n`n    The End" }
#and we then just call the pipeline again!
$pipeline.invoke()
