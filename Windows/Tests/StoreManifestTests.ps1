$ErrorActionPreference = 'Stop'
$windowsRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $windowsRoot 'Store/Manifest.ps1')
$fixture = Join-Path ([IO.Path]::GetTempPath()) ("ogma-store-tests-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
try {
    $identityPath = Join-Path $windowsRoot 'Store/identity.json'
    $template = Join-Path $windowsRoot 'Store/AppxManifest.template.xml'
    $output = Join-Path $fixture 'AppxManifest.xml'
    foreach ($architecture in @('x64', 'arm64')) {
        New-OgmaStoreManifest -IdentityPath $identityPath -TemplatePath $template -Destination $output -Architecture $architecture
        [xml]$manifest = Get-Content -LiteralPath $output -Raw
        $identity = $manifest.Package.Identity
        if ($identity.Name -cne 'RaulPop.OgmaTyping' -or $identity.Publisher -cne 'CN=869A679B-6685-49CD-8F98-07F1AF4FEB0A') { throw 'Store identity changed.' }
        if ($identity.ProcessorArchitecture -ne $architecture -or $identity.Version -ne '1.0.0.0') { throw 'Wrong architecture or package version.' }
        if ($manifest.Package.Properties.DisplayName -cne 'Ogma Typing' -or $manifest.Package.Properties.PublisherDisplayName -cne 'Raul Pop') { throw 'Wrong Store display names.' }
        $application = $manifest.Package.Applications.Application
        if ($application.Executable -ne 'Ogma.exe' -or $application.EntryPoint -ne 'Windows.FullTrustApplication') { throw 'Desktop entry point changed.' }
        if ($manifest.Package.Capabilities.Capability.Name -ne 'runFullTrust') { throw 'Missing desktop capability.' }
    }
    foreach ($version in @('0.1.0.0', '1.0.0.1', '1.0.0', '1.65536.0.0', '../1.0.0.0')) {
        $rejected = $false
        try { New-OgmaStoreManifest -IdentityPath $identityPath -TemplatePath $template -Destination $output -Architecture x64 -Version $version }
        catch { $rejected = $true }
        if (-not $rejected) { throw "Invalid Store version accepted: $version" }
    }
    $modified = Get-Content -LiteralPath $identityPath -Raw | ConvertFrom-Json
    $modified.DisplayName = 'Typing & shortcuts'
    $modified.PublisherDisplayName = 'Raul & team'
    $modifiedPath = Join-Path $fixture 'identity.json'
    $modified | ConvertTo-Json | Set-Content -LiteralPath $modifiedPath
    New-OgmaStoreManifest -IdentityPath $modifiedPath -TemplatePath $template -Destination $output -Architecture x64
    [xml]$escaped = Get-Content -LiteralPath $output -Raw
    if ($escaped.Package.Properties.DisplayName -cne $modified.DisplayName -or $escaped.Package.Properties.PublisherDisplayName -cne $modified.PublisherDisplayName) { throw 'XML display name escaping failed.' }
    $modified.Name = '../invalid'
    $modified | ConvertTo-Json | Set-Content -LiteralPath $modifiedPath
    $rejected = $false
    try { New-OgmaStoreManifest -IdentityPath $modifiedPath -TemplatePath $template -Destination $output -Architecture x64 }
    catch { $rejected = $true }
    if (-not $rejected) { throw 'Invalid package identity accepted.' }
    foreach ($script in @('package-store.ps1', 'Store/Manifest.ps1')) {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $windowsRoot $script), [ref]$tokens, [ref]$errors) | Out-Null
        if ($errors.Count -ne 0) { throw ($errors | Out-String) }
    }
    Write-Output 'Store identity, architectures, version rules, XML escaping, capability, and packaging syntax checks passed.'
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
