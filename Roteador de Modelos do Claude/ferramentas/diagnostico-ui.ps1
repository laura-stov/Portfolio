# Lista os controles da janela do Claude Desktop (para mapear o seletor de modelo e esforco).
# A saida contem texto da tela: vai para a pasta temporaria do Windows. Apague o arquivo depois de usar.
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes

$janela = Get-Process | Where-Object { $_.ProcessName -eq 'claude' -and $_.MainWindowTitle -like '*Claude*' } | Select-Object -First 1
$saida = Join-Path $env:TEMP 'diagnostico-ui.txt'

if (-not $janela) {
    'Janela do Claude nao encontrada.'
    exit
}

$raiz = [System.Windows.Automation.AutomationElement]::FromHandle($janela.MainWindowHandle)
$todos = $raiz.FindAll([System.Windows.Automation.TreeScope]::Descendants,
                       [System.Windows.Automation.Condition]::TrueCondition)

$linhas = foreach ($e in $todos) {
    $c = $e.Current
    if ($c.Name -or $c.AutomationId) {
        "{0} | nome='{1}' | id='{2}' | pos={3}" -f $c.ControlType.ProgrammaticName, $c.Name, $c.AutomationId, $c.BoundingRectangle
    }
}
$linhas | Out-File -Encoding utf8 $saida
"Pronto: $saida ($($linhas.Count) controles). Apague o arquivo depois de usar."
