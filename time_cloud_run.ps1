param([string]$jobID = 'junk')

$start_time = Get-Date -UFormat %s
 
mdc job status $jobID -w

$end_time = Get-Date -UFormat %s
Write-Host "Execution time was $([int]$end_time - [int]$start_time) seconds."
Get-Date