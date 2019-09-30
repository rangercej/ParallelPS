#Requires -Version 4
###############################################################################
#
# Parallel jobs library
#
###############################################################################

Function Start-Parallel {
	Param(
		[Parameter(Mandatory = $false)]
		[int]$limit = 4,

		[Parameter(Mandatory = $false)]
		[string]$prefix = "JOBS",

		[Parameter(Mandatory = $false)]
		[string]$jobRef = "",

		[Parameter(Mandatory = $true)]
		[scriptblock]$cmd
	)

	if ($jobid -eq "") {
		$uid = "$prefix $(new-guid)"
	} else {
		$uid = "$prefix $jobid"
	}
	$jobs = get-job -state Running | where-object { $_.name -match "^$prefix" }
	while ($jobs.Count -ge $limit) {
		start-sleep 1
		$jobs = get-job -state Running | where-object { $_.name -match "^$prefix" }
	}

	start-job -name $uid $cmd | out-null
}

#------------------------------------------------------------------------------
Function Complete-Parallel {
	Param (
		[Parameter(Mandatory = $false)]
		[string]$prefix = "JOBS"
	)

	$jobs = get-job -state Running | where-object { $_.name -match "^$prefix" }
	while ($jobs.Count -gt 0) {
		start-sleep 1
		$jobs = get-job -state Running | where-object { $_.name -match "^$prefix" }
	}

	get-job -state Completed | where-object { $_.name -match "^$prefix" } | foreach-object {
		$out = receive-job $_ | out-string
		[PSCustomObject]@{
			"Job" = $_.name
			"Out" = $out
		}
		remove-job $_ | out-null
	}
}

#------------------------------------------------------------------------------
Export-ModuleMember -Function Start-Parallel
Export-ModuleMember -Function Complete-Parallel

#"Starting"
#1..10 | %{ "$_ = $(get-date)"; start-parallel -limit 2 -cmd { (get-date).tostring("yyyy-MM-ddTHH:mm:ss") ; start-sleep 2 } #}
#"Collecting"
#Collect-Parallel | format-table