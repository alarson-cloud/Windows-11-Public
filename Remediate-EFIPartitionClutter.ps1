#Requires -Version 5.1
#alarson@hbs.net - 2025-06-24
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$exitCode = 0
$log = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\EFIRemediate.log"
Start-Transcript -Path $log
Try{
$driveletter = 'Y:'
$hpstaging = 'C:\HPStuff'

#Mount to ESP
mountvol $driveletter /s

# Check if the drive exists
if(-not (Test-Path $driveletter\)){
	Write-Error "Drive $driveletter\ not found."
	$exitCode = 1
}

# Get drive info using .NET
$driveInfo = New-Object -TypeName System.IO.DriveInfo -ArgumentList $driveLetter
$freeSpaceold = $driveInfo.AvailableFreeSpace

Write-output "Free space before beginning: $freespaceold"

#Move HP Files if they exist
if(Test-Path $driveletter\EFI\HP\DEVFW){
	if(!(Test-Path $hpstaging)){New-Item $hpstaging -ItemType Directory}
	Write-output "DevFW folder located on EFI Partition.. moving this to $hpstaging"
	Move-Item $driveletter\EFI\HP\DEVFW -Destination $hpstaging -Force
}

if(Test-Path $driveletter\EFI\HP\Previous){
	if(!(Test-Path $hpstaging)){New-Item $hpstaging -ItemType Directory}
	Write-output "Old HP Firmware files located on EFI Partition.. proceeding to remediation.."
	Move-Item $driveletter\EFI\HP\Previous -Destination $hpstaging -Force
}

#Cleanup font files
gci $driveletter\EFI\Microsoft\Boot\Fonts -Filter *.ttf | Remove-Item -Force

#New status
$freeSpace = $driveInfo.AvailableFreeSpace
Write-output "Free space before: $freespaceold --- Free space after cleanup: $freespace"

#Delete the mount point
mountvol $driveletter /d
}Catch{
	$errMsg = if($_.Exception -and $_.Exception.Message){ $_.Exception.Message }else{ "Unknown error occurred." }
	Write-Error "An error occurred: $errMsg`nFull error details: $_"
}Finally{
	Stop-Transcript
	exit $exitCode
}
