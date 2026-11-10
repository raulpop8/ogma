function New-OgmaStoreManifest {
    param(
        [string]$IdentityPath,
        [string]$TemplatePath,
        [string]$Destination,
        [ValidateSet('x64', 'arm64')][string]$Architecture,
        [string]$Version = '1.0.0.0'
    )
    $identity = Get-Content -LiteralPath $IdentityPath -Raw | ConvertFrom-Json
    foreach ($key in @('Name', 'Publisher', 'PublisherDisplayName', 'DisplayName')) {
        if ([string]::IsNullOrWhiteSpace($identity.$key)) { throw "Missing Store identity field: $key" }
    }
    if ($identity.Name -notmatch '^[A-Za-z0-9.-]{3,50}$') { throw 'Use the exact Package/Identity/Name from Partner Center.' }
    if ($identity.Publisher -notmatch '(^|,)\s*CN=') { throw 'Use the exact Package/Identity/Publisher (including CN=) from Partner Center.' }
    if ($Version -notmatch '^[1-9]\d{0,4}\.(0|[1-9]\d{0,4})\.(0|[1-9]\d{0,4})\.0$' -or
        @($Version.Split('.') | Where-Object { [int]$_ -gt 65535 }).Count -gt 0) {
        throw 'Store version must be four integers, first greater than zero, last zero, and all at most 65535 (for example 1.0.0.0).'
    }
    [xml]$manifest = Get-Content -LiteralPath $TemplatePath -Raw
    $ns = New-Object System.Xml.XmlNamespaceManager($manifest.NameTable)
    $ns.AddNamespace('p', 'http://schemas.microsoft.com/appx/manifest/foundation/windows10')
    $ns.AddNamespace('uap', 'http://schemas.microsoft.com/appx/manifest/uap/windows10')
    $packageIdentity = $manifest.SelectSingleNode('/p:Package/p:Identity', $ns)
    $packageIdentity.SetAttribute('Name', $identity.Name)
    $packageIdentity.SetAttribute('Publisher', $identity.Publisher)
    $packageIdentity.SetAttribute('Version', $Version)
    $packageIdentity.SetAttribute('ProcessorArchitecture', $Architecture)
    $manifest.SelectSingleNode('/p:Package/p:Properties/p:DisplayName', $ns).InnerText = $identity.DisplayName
    $manifest.SelectSingleNode('/p:Package/p:Properties/p:PublisherDisplayName', $ns).InnerText = $identity.PublisherDisplayName
    $visual = $manifest.SelectSingleNode('/p:Package/p:Applications/p:Application/uap:VisualElements', $ns)
    $visual.SetAttribute('DisplayName', $identity.DisplayName)
    # Keep the tile label short while the full Start menu/Store name is explicit.
    $shortName = $identity.DisplayName.Substring(0, [Math]::Min(40, $identity.DisplayName.Length))
    $visual.SelectSingleNode('uap:DefaultTile', $ns).SetAttribute('ShortName', $shortName)
    $manifest.Save($Destination)
}
