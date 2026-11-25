# Procura na tela do Claude Desktop o que identifica a conversa aberta (titulo, item selecionado).
# Grava so nomes curtos (ate 80 caracteres) em %TEMP%\achar-conversa.txt.
# Util para adaptar o roteador a outra versao ou idioma do app.
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
$AE = [System.Windows.Automation.AutomationElement]
$CT = [System.Windows.Automation.ControlType]
$p = Get-Process | Where-Object { $_.ProcessName -eq 'claude' -and $_.MainWindowTitle -like '*Claude*' } | Select-Object -First 1
$saida = Join-Path $env:TEMP 'achar-conversa.txt'
if (-not $p) { 'Janela do Claude nao encontrada.' | Out-File -Encoding utf8 $saida; exit }
$root = $AE::FromHandle($p.MainWindowHandle)
$l = New-Object System.Collections.Generic.List[string]
$l.Add("titulo da janela: '" + $p.MainWindowTitle + "'")
$topo = $root.Current.BoundingRectangle.Top

$todos = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
$l.Add("elementos: " + $todos.Count)

$l.Add('--- itens selecionados (lista, arvore, aba) ---')
$tipos = @($CT::ListItem, $CT::TreeItem, $CT::TabItem, $CT::DataItem, $CT::RadioButton)
foreach ($e in $todos) {
    try {
        $c = $e.Current
        if ($tipos -contains $c.ControlType) {
            $pat = $null
            if ($e.TryGetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern, [ref]$pat) -and $pat.Current.IsSelected) {
                $n = [string]$c.Name; if ($n.Length -gt 80) { $n = $n.Substring(0, 80) }
                $l.Add(("{0} | '{1}' | id='{2}'" -f $c.ControlType.ProgrammaticName, $n, $c.AutomationId))
            }
        }
    } catch {}
}

$l.Add('--- textos e botoes na faixa do topo da janela (ate 120 px) ---')
$tt = @($CT::Text, $CT::Button, $CT::Hyperlink, $CT::Group, $CT::Custom)
foreach ($e in $todos) {
    try {
        $c = $e.Current; $r = $c.BoundingRectangle
        if ($tt -contains $c.ControlType -and -not $r.IsEmpty -and $r.Top -ge $topo -and $r.Top -lt ($topo + 120)) {
            $n = [string]$c.Name
            if ($n.Length -ge 3 -and $n.Length -le 80) { $l.Add(("{0} | '{1}' | y={2}" -f $c.ControlType.ProgrammaticName, $n, [int]($r.Top - $topo))) }
        }
    } catch {}
}
$l | Select-Object -First 80 | Out-File -Encoding utf8 $saida
"Pronto: $saida"
