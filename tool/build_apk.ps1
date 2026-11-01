param([switch]$Cloud)
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$temporary = Join-Path $project '.dart_tool/jtmp'
New-Item -ItemType Directory -Force -Path $temporary | Out-Null
$previousOptions = $env:JAVA_TOOL_OPTIONS
try {
    # Chỉ áp dụng cho tiến trình build; không sửa Java hoặc thiết lập Windows.
    $env:JAVA_TOOL_OPTIONS = "-Djdk.net.unixdomain.tmpdir=`"$temporary`" -Djava.io.tmpdir=`"$temporary`""
    Push-Location $project
    try {
        $arguments = @('build', 'apk', '--debug', '--no-pub')
        if ($Cloud) { $arguments += '--dart-define=USE_FIREBASE_AUTH=true' }
        & flutter @arguments
        if ($LASTEXITCODE -ne 0) { throw 'Build APK thất bại.' }
        if ($Cloud) {
            Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-debug.apk' -Destination 'build/app/outputs/flutter-apk/app-cloud-debug.apk'
        }
    } finally { Pop-Location }
} finally { $env:JAVA_TOOL_OPTIONS = $previousOptions }
