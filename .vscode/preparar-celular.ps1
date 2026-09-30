# Roda antes do F5 "CuidaMed Mobile (Celular USB)".
# No celular, "localhost" é o próprio celular — não o PC. Pelo cabo USB, o
# "adb reverse" faz o localhost:8080 do celular apontar pro back-end do PC,
# sem precisar de IP, Wi-Fi ou liberar firewall.

# Mesmo passo das outras configurações: tira o "somente leitura" do OneDrive da pasta build.
& (Join-Path $PSScriptRoot 'liberar-build.ps1')

$candidatos = @(
    (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'),
    $(if ($env:ANDROID_HOME) { Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe' }),
    $(if ($env:ANDROID_SDK_ROOT) { Join-Path $env:ANDROID_SDK_ROOT 'platform-tools\adb.exe' })
) | Where-Object { $_ -and (Test-Path $_) }

$adb = $candidatos | Select-Object -First 1
if (-not $adb) {
    $noPath = Get-Command adb -ErrorAction SilentlyContinue
    if ($noPath) { $adb = $noPath.Source }
}

if (-not $adb) {
    Write-Host 'AVISO: adb não encontrado (falta o Android SDK). Instale o Android Studio — veja as instruções no chat.'
    exit 0
}

& $adb reverse tcp:8080 tcp:8080 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host 'Celular: localhost:8080 agora aponta para o back-end do PC (adb reverse).'
} else {
    Write-Host 'AVISO: não consegui fazer o adb reverse. O celular está conectado com a depuração USB autorizada?'
}
exit 0
