#Requires -Version 5.1
#alarson@hbs.net - 2025-06-24
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$exitCode = 0
$log = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\EFIDetect.log"
Start-Transcript -Path $log
Try{
#Set threshold in bytes (e.g., 50 MB)
$thresholdBytes = 50MB

#Mount the EFI Partition
$driveLetter = "Y:"
mountvol $driveLetter /s

#Check if the drive exists
if(-not (Test-Path $driveLetter)){
	Write-Error "Drive $driveLetter not found."
}

#Get drive info using .NET
$driveInfo = New-Object -TypeName System.IO.DriveInfo -ArgumentList $driveLetter
$freeSpace = $driveInfo.AvailableFreeSpace

#Report results
if($freeSpace -lt $thresholdBytes){
	Write-Output "Low disk space on $driveLetter. Free: $([math]::Round($freeSpace / 1MB, 2)) MB"
	mountvol $driveLetter /d
	$exitCode = 1
}else{
	Write-Output "$driveLetter has sufficient free space: $([math]::Round($freeSpace / 1MB, 2)) MB"
	mountvol $driveLetter /d
	exit
}

}Catch{
		$errMsg = if($_.Exception -and $_.Exception.Message) { $_.Exception.Message }else{ "Unknown error occurred." }
		Write-Error "An error occurred: $errMsg`nFull error details: $_"
}Finally{
	Stop-Transcript
	exit $exitCode
}
