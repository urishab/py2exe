param(
    [string]$ExecutablePath = (Join-Path $PSScriptRoot "dist\service_test.exe")
)

if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
    Write-Host "Executable not found: $ExecutablePath"
    exit 1
}

function Invoke-ServiceStep {
    param(
        [string]$StepName,
        [string]$Action
    )

    Write-Host "service_test: running '$StepName'"
    & $ExecutablePath $Action
    $stepExitCode = $LASTEXITCODE
    Write-Host "service_test: '$StepName' exited with $stepExitCode"

    if ($stepExitCode -ne 0) {
        exit $stepExitCode
    }
}

Invoke-ServiceStep -StepName "install" -Action "install"
Invoke-ServiceStep -StepName "start" -Action "start"

# Give SCM a moment before issuing stop.
Start-Sleep -Seconds 2

Invoke-ServiceStep -StepName "stop" -Action "stop"
Invoke-ServiceStep -StepName "remove" -Action "remove"

exit 0
