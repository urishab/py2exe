param(
    [string]$ExecutablePath = (Join-Path $PSScriptRoot "dist\service_test.exe"),
    [string]$PythonExecutable = "python"
)

function Invoke-CheckedCommand {
    param(
        [string]$StepName,
        [scriptblock]$Command
    )

    Write-Host "service_test: running '$StepName'"
    & $Command
    $stepExitCode = $LASTEXITCODE
    Write-Host "service_test: '$StepName' exited with $stepExitCode"

    if ($stepExitCode -ne 0) {
        exit $stepExitCode
    }
}

$requirementsPath = Join-Path $PSScriptRoot "requirements.txt"
$freezeScriptPath = Join-Path $PSScriptRoot "freeze.py"

Push-Location $PSScriptRoot
try {
    if (Test-Path -LiteralPath $requirementsPath -PathType Leaf) {
        Invoke-CheckedCommand -StepName "install dependencies" -Command {
            & $PythonExecutable -m pip install -r $requirementsPath
        }
    }

    Invoke-CheckedCommand -StepName "freeze service executable" -Command {
        & $PythonExecutable $freezeScriptPath
    }
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
    Write-Host "service_test: executable not found after freeze: $ExecutablePath"
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

$logPath = Join-Path (Split-Path -Parent $ExecutablePath) "minimal_service.log"
if (-not (Test-Path -LiteralPath $logPath -PathType Leaf)) {
    Write-Host "service_test: log file not found: $logPath"
    exit 1
}

$logLines = Get-Content -LiteralPath $logPath | ForEach-Object { $_.Trim() }
if ((-not ($logLines -contains "hello")) -or (-not ($logLines -contains "goodbye"))) {
    Write-Host "service_test: log validation failed in $logPath"
    exit 1
}

Write-Host "service_test: log validation passed"

exit 0
