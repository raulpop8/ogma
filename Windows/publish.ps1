param(
    [ValidateSet('win-x64', 'win-arm64')]
    [string]$Runtime = 'win-x64',
    [string]$Version = '1.0.1',
    [string]$CertificateThumbprint,
    [ValidateSet('CurrentUser', 'LocalMachine')]
    [string]$CertificateStore = 'CurrentUser',
    [string]$SignToolPath = 'signtool.exe',
    [uri]$TimestampUrl = 'http://timestamp.digicert.com',
    [switch]$AllowUnsigned
)
$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Version must have the form X.Y.Z.' }
$CertificateThumbprint = ([string]$CertificateThumbprint -replace '\s', '').ToUpperInvariant()
$signed = -not [string]::IsNullOrEmpty($CertificateThumbprint)
if (-not $signed -and -not $AllowUnsigned) {
    throw 'A trusted Windows code-signing certificate is required. Supply -CertificateThumbprint, or explicitly use -AllowUnsigned for a development preview. Smart App Control can block unsigned builds without an override.'
}
if ($signed -and $AllowUnsigned) { throw 'Choose a signing certificate or -AllowUnsigned, not both.' }

if ($signed) {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Signing requires Windows, the Windows SDK SignTool, and access to your signing certificate.' }
    if ($CertificateThumbprint -notmatch '^[A-F0-9]{40}$') { throw 'CertificateThumbprint must be the 40 hexadecimal digits shown in the Windows certificate store.' }
    if (-not $TimestampUrl.IsAbsoluteUri -or $TimestampUrl.Scheme -notin @('http', 'https')) { throw 'TimestampUrl must be an absolute HTTP or HTTPS URL.' }
    $signTool = (Get-Command $SignToolPath -CommandType Application -ErrorAction Stop).Source
    $certificate = Get-Item "Cert:\$CertificateStore\My\$CertificateThumbprint" -ErrorAction Stop
    if (-not $certificate.HasPrivateKey -or $certificate.NotBefore -gt (Get-Date) -or $certificate.NotAfter -le (Get-Date)) {
        throw 'The signing certificate must be currently valid and have an accessible private key.'
    }
    $codeSigningOid = '1.3.6.1.5.5.7.3.3'
    if ($codeSigningOid -notin @($certificate.EnhancedKeyUsageList | ForEach-Object { $_.ObjectId })) {
        throw 'The certificate must be issued for code signing.'
    }
} else {
    Write-Warning 'UNSIGNED DEVELOPMENT PREVIEW: Smart App Control can block this build. It has no per-app allow exception. This ZIP is not a signed release.'
}

$artifactRoot = Join-Path $PSScriptRoot 'artifacts'
$suffix = if ($signed) { 'signed' } else { 'unsigned-preview' }
$archive = Join-Path $artifactRoot "Ogma-$Version-$Runtime-$suffix.zip"
$temporaryId = [Guid]::NewGuid().ToString('N')
$staging = Join-Path $artifactRoot ".staging-$temporaryId"
$temporaryArchive = Join-Path $artifactRoot ".staging-$temporaryId.zip"
New-Item -ItemType Directory -Path $staging -Force | Out-Null
try {
    # Signed releases keep assemblies as separate files so each Ogma binary
    # can be signed and verified. Never alter shared SDK/NuGet cache files.
    $singleFile = -not $signed
    $publishArguments = @(
        'publish', (Join-Path $PSScriptRoot 'Ogma.Windows/Ogma.Windows.csproj'),
        '--configuration', 'Release', '--runtime', $Runtime, '--self-contained', 'true',
        "-p:PublishSingleFile=$singleFile", "-p:IncludeNativeLibrariesForSelfExtract=$singleFile",
        "-p:Version=$Version", '-p:DebugType=None', '--output', $staging
    )
    & dotnet @publishArguments
    if ($LASTEXITCODE -ne 0) { throw 'Windows publish failed.' }

    if ($signed) {
        $storeArguments = @('/s', 'My', '/sha1', $CertificateThumbprint)
        if ($CertificateStore -eq 'LocalMachine') { $storeArguments += '/sm' }
        foreach ($name in @('Ogma.exe', 'Ogma.dll', 'Ogma.Core.dll')) {
            $file = Join-Path $staging $name
            if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing application binary: $name" }
            & $signTool sign @storeArguments /fd SHA256 /tr $TimestampUrl.AbsoluteUri /td SHA256 $file
            if ($LASTEXITCODE -ne 0) { throw "Signing failed: $name" }
            $signature = Get-AuthenticodeSignature -LiteralPath $file
            if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Thumbprint -ne $CertificateThumbprint -or $null -eq $signature.TimeStamperCertificate) {
                throw "Signature or timestamp verification failed: $name"
            }
        }
        # Includes Microsoft runtime libraries and any future dependencies.
        # An unsigned or invalid dependency must prevent release packaging.
        foreach ($binary in Get-ChildItem -LiteralPath $staging -Recurse -File | Where-Object { $_.Extension -in @('.exe', '.dll') }) {
            & $signTool verify /pa /all $binary.FullName
            if ($LASTEXITCODE -ne 0) { throw "Authenticode verification failed: $($binary.Name)" }
        }
        $readme = 'SIGNED-README.txt'
    } else {
        $readme = 'PORTABLE-README.txt'
    }
    Copy-Item (Join-Path $PSScriptRoot $readme) (Join-Path $staging 'README.txt')
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $temporaryArchive
    Move-Item -LiteralPath $temporaryArchive -Destination $archive -Force
    Write-Output "Created $archive"
} finally {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
    if (Test-Path -LiteralPath $temporaryArchive) { Remove-Item -LiteralPath $temporaryArchive -Force }
}
