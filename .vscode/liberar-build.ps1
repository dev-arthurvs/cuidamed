# Roda antes de cada F5 do app mobile (preLaunchTask "mobile: liberar pasta build").
#
# 1) O OneDrive marca pastas como "somente leitura" e o Flutter copia esse
#    atributo para build\ (ex.: assets\fonts) e .dart_tool\. Na execução seguinte
#    ele não consegue apagar a cópia e a depuração fecha sozinha. Aqui o atributo
#    é removido de build\, assets\ e .dart_tool\.
# 2) Se uma depuração anterior no navegador não fechou direito, o "flutter run"
#    antigo continua segurando a porta 5050 e o F5 novo falha ao abrir o
#    servidor web. Aqui esse processo antigo (só se for do Flutter) é encerrado.
$projeto = Join-Path $PSScriptRoot '..\mobile cuidamed'
$somenteLeitura = [IO.FileAttributes]::ReadOnly

foreach ($pasta in @('build', 'assets', '.dart_tool')) {
    $caminho = Join-Path $projeto $pasta
    if (-not (Test-Path $caminho)) { continue }

    $itens = @(Get-Item $caminho -Force) + @(Get-ChildItem $caminho -Recurse -Force -ErrorAction SilentlyContinue)
    foreach ($item in $itens) {
        if ($item.Attributes -band $somenteLeitura) {
            try { $item.Attributes = $item.Attributes -band (-bnot $somenteLeitura) } catch { }
        }
    }
}
Write-Host 'Pastas build, assets e .dart_tool liberadas.'

$porta = 5050
$conexoes = Get-NetTCPConnection -LocalPort $porta -State Listen -ErrorAction SilentlyContinue
foreach ($idProcesso in @($conexoes.OwningProcess | Sort-Object -Unique)) {
    $processo = Get-CimInstance Win32_Process -Filter "ProcessId = $idProcesso" -ErrorAction SilentlyContinue
    if (-not $processo -or $processo.Name -notmatch '^dart') {
        Write-Host "Porta $porta ocupada por outro programa ($($processo.Name)); não foi encerrado."
        continue
    }
    # Encerra o "flutter run" antigo (o pai do dartvm que segura a porta) e os filhos.
    $alvo = $processo
    $pai = Get-CimInstance Win32_Process -Filter "ProcessId = $($processo.ParentProcessId)" -ErrorAction SilentlyContinue
    if ($pai -and $pai.Name -match '^dart' -and $pai.CommandLine -match 'flutter_tools') { $alvo = $pai }
    & taskkill.exe /PID $alvo.ProcessId /T /F | Out-Null
    Write-Host "Depuração antiga presa na porta $porta encerrada (PID $($alvo.ProcessId))."
}
