# Tim cong COM cua ESP32-C3 (USB-Serial-JTAG, VID 303A). In ra ten cong, vi du COM5.
$devs = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object { $_.InstanceId -match 'VID_303A' -and $_.FriendlyName -match '\((COM\d+)\)' }
if (-not $devs) {
    Write-Output 'Khong tim thay ESP32-C3 (VID 303A). Giu nut BOOT, cam lai cap roi thu lai.'
    exit 1
}
foreach ($d in $devs) {
    if ($d.FriendlyName -match '\((COM\d+)\)') { Write-Output $Matches[1] }
}
