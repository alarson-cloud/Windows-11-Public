#Requires -Version 5.1
#alarson@hbs.net - 2025-06-24
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$exitCode = 0
$log = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\WinREDetect.log"
Start-Transcript -Path $log
$winVer = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "DisplayVersion" | Select-Object DisplayVersion
Try{
if ($winVer.DisplayVersion -eq "24H2") {
    Write-Output "System is already on Windows 24H2, exiting..."
    $exitCode = 0
} else {
    $recoveryinfo = reagentc /info
    if ($recoveryinfo -like '*Enabled*') {     

        #Check if the Recovery environment is placed on the OS Partition, as it's not supported
        $osDriveLetter = ($env:SystemDrive).TrimEnd(":")
        $ospartition = (Get-Partition -DriveLetter $osDriveLetter).PartitionNumber
        $ospartitionnumber = "partition$ospartition"

        #Grab WinRE Partition info
        foreach ($line in $recoveryinfo) {
            if ($line -match "Windows RE location\s*:\s*(.+)") {
                $winRELocation = $matches[1].Trim()
            }
        }

        #Proceed to remediation if the WinRE environment is placed on the OS Disk, as it's not supported
        if ($winRELocation -like "*$ospartitionnumber*") {
            Write-output "WinRE is enabled, but the recovery bits is placed on the OS Disk... proceeding to remediation"
            $exitCode = 1
        }

        $bytes = (Get-Partition | Where-Object { $_.Type -eq "Recovery" } | Sort-Object -Property Size -Descending | Select-Object -First 1 | Select-Object Size)
        $result = $bytes.Size / 1MB
        if ($result -lt 1000) {
            #Write-Output "WinRE partition is smaller than 1000 MB ($($result) MB)... proceeding to remediation"
            #$exitCode = 1
        }
    }

    if ($recoveryinfo -like '*Disabled*') {
    Write-output "Recovery partition is not working :(" ; $exitCode = 1
    }
    $exitCodeZero = $exitCode
    if($exitCodeZero -eq 0 ){ 
        Write-output "Recovery environment is enabled on this device and is set correctly"
    } 
}
} Catch {
        $errMsg = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { "Unknown error occurred." }
        Write-Error "An error occurred: $errMsg`nFull error details: $_"
    } Finally {
        Stop-Transcript
        exit $exitCode
    }
