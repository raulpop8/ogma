$ErrorActionPreference = 'Stop'
$previousExitCode = [int]$global:LASTEXITCODE
$fixture = Join-Path ([IO.Path]::GetTempPath()) ("ogma-packaging-tests-" + [Guid]::NewGuid().ToString('N'))
$global:ogmaPackagingCalls = 0
$global:ogmaPackagingExit = 0
$global:ogmaPackagingArguments = @()

# Mock only dotnet publish: these tests validate release packaging and failure
# handling, not executable compilation, signing, or acceptance by Windows.
function global:dotnet {
    $global:ogmaPackagingCalls++
    $global:ogmaPackagingArguments = @($args)
    $outputIndex = [Array]::IndexOf($args, '--output')
    if ($outputIndex -lt 0) { throw 'Missing publish output argument.' }
    $output = $args[$outputIndex + 1]
    New-Item -ItemType Directory -Path $output -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $output 'Ogma.exe'), 'fake executable for packaging checks')
    [IO.File]::WriteAllText((Join-Path $output 'UNICODE_LICENSE.txt'), 'license fixture')
    $global:LASTEXITCODE = $global:ogmaPackagingExit
}

function Assert-Rejected([scriptblock]$Action, [string]$Expected) {
    $failure = $null
    try { & $Action | Out-Null } catch { $failure = $_.Exception.Message }
    if ($null -eq $failure -or $failure -notmatch $Expected) { throw "Expected rejection matching '$Expected'; got '$failure'." }
}

try {
    New-Item -ItemType Directory -Path $fixture | Out-Null
    $windowsRoot = Split-Path $PSScriptRoot -Parent
    foreach ($name in @('publish.ps1', 'PORTABLE-README.txt', 'SIGNED-README.txt')) {
        Copy-Item (Join-Path $windowsRoot $name) $fixture
    }
    $script = Join-Path $fixture 'publish.ps1'
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -ne 0) { throw ($errors | Out-String) }

    Assert-Rejected { & $script } 'trusted Windows code-signing certificate'
    Assert-Rejected { & $script -Version '../invalid' -AllowUnsigned } 'Version must'
    Assert-Rejected { & $script -CertificateThumbprint ('A' * 40) -AllowUnsigned } 'not both'
    if ($global:ogmaPackagingCalls -ne 0) { throw 'Rejected invocations must not publish anything.' }

    & $script -Runtime win-x64 -Version '1.2.3' -AllowUnsigned
    $archive = Join-Path $fixture 'artifacts/Ogma-1.2.3-win-x64-unsigned-preview.zip'
    if (-not (Test-Path -LiteralPath $archive)) { throw 'Missing explicitly labeled unsigned preview ZIP.' }
    if ('-p:PublishSingleFile=True' -notin $global:ogmaPackagingArguments -or '--self-contained' -notin $global:ogmaPackagingArguments) {
        throw 'Unsigned previews must remain self-contained single-file builds.'
    }
    $extracted = Join-Path $fixture 'extracted'
    Expand-Archive -LiteralPath $archive -DestinationPath $extracted
    $readme = Get-Content (Join-Path $extracted 'README.txt') -Raw
    if ($readme -notmatch 'Smart App Control can block it completely') { throw 'The preview README must explain the hard block.' }
    $beforeFailure = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash

    $global:ogmaPackagingExit = 1
    Assert-Rejected { & $script -Runtime win-x64 -Version '1.2.3' -AllowUnsigned } 'Windows publish failed'
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $beforeFailure) { throw 'A failed publish replaced the earlier archive.' }
    if (@(Get-ChildItem (Join-Path $fixture 'artifacts') -Force | Where-Object { $_.Name -like '.staging-*' }).Count -ne 0) {
        throw 'Temporary publish files were left behind.'
    }
    Write-Output 'Packaging syntax, unsigned-release guard, archive labeling, README, cleanup, and failure-preservation checks passed. Live signing was not tested.'
} finally {
    # The negative-path test mocks a native failure. Restore the caller's exit
    # state so GitHub's PowerShell wrapper does not mistake it for a real one.
    $global:LASTEXITCODE = $previousExitCode
    Remove-Item Function:\dotnet -ErrorAction SilentlyContinue
    Remove-Variable ogmaPackagingCalls, ogmaPackagingExit, ogmaPackagingArguments -Scope Global -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
