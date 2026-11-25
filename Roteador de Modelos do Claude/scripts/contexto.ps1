# Le da tela do Claude Desktop um resumo curto da conversa atual (para o classificador).
# Uso: powershell -File contexto.ps1 -Saida arquivo.txt
param([Parameter(Mandatory = $true)][string]$Saida)

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
$AE = [System.Windows.Automation.AutomationElement]
$CT = [System.Windows.Automation.ControlType]
$TS = [System.Windows.Automation.TreeScope]

function Cond($prop, $valor) { return New-Object System.Windows.Automation.PropertyCondition -ArgumentList $prop, $valor }
function Tipo($el, $tipo, $escopo) { return $el.FindAll($escopo, (Cond ($AE::ControlTypeProperty) $tipo)) }

$proc = Get-Process | Where-Object { $_.ProcessName -eq 'claude' -and $_.MainWindowTitle -like '*Claude*' } | Select-Object -First 1
if (-not $proc) { '' | Out-File -Encoding utf8 $Saida; exit }
$root = $AE::FromHandle($proc.MainWindowHandle)

$l = New-Object System.Collections.Generic.List[string]

# modo: a caixa de prompt do Claude Code se chama 'Prompt' (a busca para no primeiro achado)
$condPrompt = [System.Windows.Automation.AndCondition]::new([System.Windows.Automation.Condition[]]@(
    (Cond ($AE::ControlTypeProperty) ($CT::Edit)), (Cond ($AE::NameProperty) 'Prompt')))
$modo = 'Chat/Cowork'
if ($root.FindFirst(($TS::Descendants), $condPrompt)) { $modo = 'Claude Code (sessao de programacao)' }
$l.Add("MODO: $modo")

# uma unica varredura de botoes serve para o modelo atual e para as ferramentas ja usadas
$modelo = $null
$titulo = $null
$ferr = New-Object System.Collections.Generic.List[string]
foreach ($b in (Tipo $root ($CT::Button) ($TS::Descendants))) {
    $n = $b.Current.Name
    # titulo da sessao: o botao do topo se chama "<titulo>, renomear sessao"
    if (-not $titulo -and $n -match '^(.+), (renomear sess|rename sess)') { $titulo = $Matches[1] }
    if (-not $modelo -and $n -like 'Modelo:*') { $modelo = ($n -replace '^Modelo:\s*', '') }
    elseif ($n -match '^(Executou|Editou|Criou|Leu|Usou|Pesquisou|Compactou|Buscou)' -and -not $ferr.Contains($n)) { $ferr.Add($n) }
}
if ($modelo) { $l.Add("MODELO ATUAL: $modelo") }
if ($titulo) { $l.Add("TITULO: " + $titulo.Substring(0, [Math]::Min(100, $titulo.Length))) }

# conversa
$conv = $root.FindFirst(($TS::Descendants), (Cond ($AE::NameProperty) 'Mensagens da conversa'))
if (-not $conv) {
    $l.Add('CONVERSA: nova (sem historico)')
} else {
    $msgs = @(Tipo $conv ($CT::Group) ($TS::Children) | Where-Object { $_.Current.Name -like 'Mensagem*' })
    $l.Add("CONVERSA: em andamento (" + $msgs.Count + " mensagens visiveis)")

    if ($ferr.Count -gt 0) { $l.Add("FERRAMENTAS JA USADAS: " + (($ferr | Select-Object -Last 6) -join '; ')) }

    $l.Add('ULTIMAS MENSAGENS:')
    foreach ($m in ($msgs | Select-Object -Last 3)) {
        $t = (Tipo $m ($CT::Text) ($TS::Descendants) | ForEach-Object { $_.Current.Name }) -join ' '
        $t = ($t -replace '\s+', ' ').Trim()
        if ($t.Length -gt 600) { $t = $t.Substring(0, 600) + '...' }
        $l.Add("- $t")
    }
}

$l -join "`n" | Out-File -Encoding utf8 $Saida
