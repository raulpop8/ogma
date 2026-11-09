param(
    [ValidateSet('win-x64', 'win-arm64')][string]$Runtime = 'win-x64',
    [string]$PackageVersion = '1.0.0.0',
    [string]$IdentityPath = (Join-Path $PSScriptRoot 'Store/identity.json'),
    [string]$MakeAppxPath = 'makeappx.exe'
)
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Creating MSIX packages requires Windows with the .NET 10 SDK and Windows SDK MakeAppx.' }
. (Join-Path $PSScriptRoot 'Store/Manifest.ps1')
$makeAppx = Get-Command $MakeAppxPath -CommandType Application -ErrorAction SilentlyContinue
if ($null -eq $makeAppx -and $MakeAppxPath -eq 'makeappx.exe') {
    $sdkBin = Join-Path ([Environment]::GetEnvironmentVariable('ProgramFiles(x86)')) 'Windows Kits/10/bin'
    if (Test-Path -LiteralPath $sdkBin) {
        $makeAppx = Get-ChildItem -LiteralPath $sdkBin -Directory |
            Where-Object { $_.Name -match '^10\.0\.\d+\.0$' } |
            Sort-Object { [version]$_.Name } -Descending |
            ForEach-Object { Join-Path $_.FullName 'x64/makeappx.exe' } |
            Where-Object { Test-Path -LiteralPath $_ } |
            Select-Object -First 1 | ForEach-Object { Get-Command $_ -CommandType Application }
    }
}
if ($null -eq $makeAppx) { throw 'Install the Windows SDK (MSIX Packaging Tools), or supply -MakeAppxPath with the path to makeappx.exe.' }
$artifactRoot = Join-Path $PSScriptRoot 'artifacts/store'
$temporaryId = [Guid]::NewGuid().ToString('N')
$staging = Join-Path $artifactRoot ".staging-$temporaryId"
$temporaryPackage = Join-Path $artifactRoot ".staging-$temporaryId.msix"
New-Item -ItemType Directory -Path $staging -Force | Out-Null
try {
    $architecture = $Runtime.Substring(4)
    New-OgmaStoreManifest -IdentityPath $IdentityPath -TemplatePath (Join-Path $PSScriptRoot 'Store/AppxManifest.template.xml') `
        -Destination (Join-Path $staging 'AppxManifest.xml') -Architecture $architecture -Version $PackageVersion
    $assemblyVersion = $PackageVersion.Substring(0, $PackageVersion.LastIndexOf('.'))
    & dotnet publish (Join-Path $PSScriptRoot 'Ogma.Windows/Ogma.Windows.csproj') --configuration Release `
        --runtime $Runtime --self-contained true -p:PublishSingleFile=false -p:DebugType=None `
        "-p:Version=$assemblyVersion" --output $staging
    if ($LASTEXITCODE -ne 0) { throw 'Store app publish failed.' }
    foreach ($required in @('Ogma.exe', 'Ogma.dll', 'Ogma.Core.dll', 'UNICODE_LICENSE.txt')) {
        if (-not (Test-Path -LiteralPath (Join-Path $staging $required) -PathType Leaf)) { throw "Missing package file: $required" }
    }
    Copy-Item (Join-Path $PSScriptRoot 'Store/Assets') (Join-Path $staging 'Assets') -Recurse
    # SDK schema/semantic validation stays enabled; do not use /nv.
    & $makeAppx.Source pack /d $staging /p $temporaryPackage /h SHA256
    if ($LASTEXITCODE -ne 0) { throw 'MakeAppx validation or packaging failed.' }
    $identity = Get-Content -LiteralPath $IdentityPath -Raw | ConvertFrom-Json
    $package = Join-Path $artifactRoot "$($identity.Name)_$($PackageVersion)_$architecture.msix"
    Move-Item -LiteralPath $temporaryPackage -Destination $package -Force
    Write-Output "Created Store submission package: $package"
    Write-Warning 'This unsigned MSIX is for Partner Center submission, not direct installation. Microsoft signs the Store-distributed package after certification.'
} finally {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
    if (Test-Path -LiteralPath $temporaryPackage) { Remove-Item -LiteralPath $temporaryPackage -Force }
}
