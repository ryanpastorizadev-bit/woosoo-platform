#Requires -Version 5.1
<#
.SYNOPSIS
    Returns the Windows host LAN IPv4 address used for Woosoo PUBLIC_HOST on WSL dev.

.DESCRIPTION
    Picks the first RFC1918 address (192.168.* or 10.*) on the network adapter
    that owns the default route, sorted by interface metric (lower = preferred).
    Called from WSL via host-network.sh — not for direct operator use.
    Operators should run: woosoo network

.OUTPUTS
    Single IPv4 string to stdout, or exit 1 on failure.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-Rfc1918Ipv4 {
    param([string]$Ip)
    if ($Ip -notmatch '^\d+\.\d+\.\d+\.\d+$') { return $false }
    $octets = $Ip.Split('.')
    if ($octets[0] -eq '10') { return $true }
    if ($octets[0] -eq '192' -and $octets[1] -eq '168') { return $true }
    return $false
}

# Default route → interface index
$defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Where-Object { $_.NextHop -ne '0.0.0.0' } |
    Sort-Object RouteMetric, InterfaceMetric |
    Select-Object -First 1

$preferredIfIndex = $null
if ($defaultRoute) {
    $preferredIfIndex = $defaultRoute.InterfaceIndex
}

$candidates = @()

Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
        $_.IPAddress -ne '127.0.0.1' -and
        (Test-Rfc1918Ipv4 $_.IPAddress)
    } |
    ForEach-Object {
        $ifAlias = (Get-NetIPInterface -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue)
        $metric = if ($ifAlias) { $ifAlias.InterfaceMetric } else { 9999 }
        $isDefault = ($_.InterfaceIndex -eq $preferredIfIndex)
        [PSCustomObject]@{
            Ip           = $_.IPAddress
            Metric       = $metric
            IsDefaultNic = $isDefault
        }
    } |
    Sort-Object @{ Expression = 'IsDefaultNic'; Descending = $true }, Metric |
    ForEach-Object { $candidates += $_ }

if ($candidates.Count -eq 0) {
    Write-Error 'No RFC1918 IPv4 address found on Windows host.'
    exit 1
}

Write-Output $candidates[0].Ip
