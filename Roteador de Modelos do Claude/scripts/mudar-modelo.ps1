# Troca modelo e esforco no Claude Desktop via UI Automation + mouse.
# Uso: powershell -File mudar-modelo.ps1 -Modelo Opus -Esforco Alto -Saida arquivo.txt
# Escreve em -Saida: "OK|<estado atual>" ou "ERRO|<motivo>". Detalhes de erro: %TEMP%\roteador-debug.txt
# So aceita valores conhecidos (o "." de M.dio cobre Medio e Medio com acento).
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^(Haiku|Sonnet|Opus)$')][string]$Modelo,
    [Parameter(Mandatory = $true)][ValidatePattern('^(Baixo|M.dio|Alto|Extra|Max)$')][string]$Esforco,
    [Parameter(Mandatory = $true)][string]$Saida
)

# Esperas (ms) entre as acoes na tela. Aumente se o app estiver lento.
$MS_PASSO_MOUSE = 15      # entre passos do movimento do cursor
$MS_ANTES_CLIQUE = 80     # cursor parado antes de clicar
$MS_POLL = 150            # intervalo ao esperar um menu, dialogo ou foco
$MS_APOS_DIALOGO = 400    # depois de confirmar um dialogo
$MS_APOS_TROCA = 300      # depois de clicar numa opcao
$MS_SUBMENU = 700         # hover ate o submenu de esforco abrir
$MS_SETA = 600            # espera apos a seta para a direita
$MS_FECHAR_MENU = 250     # depois de fechar o menu

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Mx {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
    public struct POINT { public int X; public int Y; }
}
"@
[void][Mx]::SetProcessDPIAware()
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, System.Windows.Forms

$orig = New-Object 'Mx+POINT'
[void][Mx]::GetCursorPos([ref]$orig)
$AE = [System.Windows.Automation.AutomationElement]
$CT = [System.Windows.Automation.ControlType]
$DEBUG = Join-Path $env:TEMP 'roteador-debug.txt'   # fora da pasta do projeto

function Norm([string]$s) {
    if (-not $s) { return '' }
    $d = $s.Normalize([Text.NormalizationForm]::FormD)
    return ([regex]::Replace($d, '\p{Mn}', '')).ToLower().Trim()
}

function Fim($status, $detalhe) {
    [void][Mx]::SetCursorPos($orig.X, $orig.Y)
    "$status|$detalhe" | Out-File -Encoding utf8 $Saida
    exit
}

function Achar($tipo) {
    $cond = New-Object System.Windows.Automation.PropertyCondition -ArgumentList ($AE::ControlTypeProperty), $tipo
    return $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
}

function Centro($el) {
    $r = $el.Current.BoundingRectangle
    if ($r.IsEmpty -or $r.Width -le 0) { return $null }
    return @([int]($r.X + $r.Width / 2), [int]($r.Y + $r.Height / 2))
}

function Mover($x, $y) {
    $p = New-Object 'Mx+POINT'
    [void][Mx]::GetCursorPos([ref]$p)
    for ($i = 1; $i -le 8; $i++) {
        [void][Mx]::SetCursorPos([int]($p.X + ($x - $p.X) * $i / 8), [int]($p.Y + ($y - $p.Y) * $i / 8))
        Start-Sleep -Milliseconds $MS_PASSO_MOUSE
    }
}

function Clicar($el) {
    $c = Centro $el
    if (-not $c) { return $false }
    Mover $c[0] $c[1]
    Start-Sleep -Milliseconds $MS_ANTES_CLIQUE
    [Mx]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero)
    [Mx]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
    return $true
}

# guarda o botao de modelo; so varre a janela de novo se ele tiver sido recriado
$script:btnModelo = $null
function BotaoModelo {
    if ($script:btnModelo) {
        try { if ($script:btnModelo.Current.Name -like 'Modelo:*') { return $script:btnModelo } } catch {}
    }
    $script:btnModelo = $null
    foreach ($b in (Achar ($CT::Button))) {
        if ($b.Current.Name -like 'Modelo:*') { $script:btnModelo = $b; return $b }
    }
    return $null
}

function EstadoAtual {
    $b = BotaoModelo
    if (-not $b) { Fim 'ERRO' 'botao de modelo nao encontrado nesta tela' }
    return Estado $b
}

function Estado($b) {
    $n = ($b.Current.Name -replace '^Modelo:\s*', '').Trim()
    $p = $n -split '\s+'
    if ($p.Length -lt 2) { return @{ modelo = $n; esforco = ''; texto = $n } }
    return @{ modelo = ($p[0..($p.Length - 2)] -join ' '); esforco = $p[-1]; texto = $n }
}

function ItemEsforco {
    foreach ($m in (Achar ($CT::MenuItem))) {
        if ((Norm $m.Current.Name) -like 'esforco*') { return $m }
    }
    return $null
}

function AbrirMenu {
    if (ItemEsforco) { return $true }
    $b = BotaoModelo
    if (-not $b) { return $false }
    [void](Clicar $b)
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds $MS_POLL
        if (ItemEsforco) { return $true }
    }
    return $false
}

function AcharOpcaoEsforco($alvo) {
    $re = '^' + [regex]::Escape($alvo) + '(\b|$)'
    if ($alvo -eq 'max') { $re = '^max' }
    foreach ($tipo in @($CT::MenuItem, $CT::RadioButton, $CT::ListItem)) {
        foreach ($e in (Achar $tipo)) {
            $n = Norm $e.Current.Name
            if ($n -notlike 'esforco*' -and $n -match $re) { return $e }
        }
    }
    return $null
}

function Dump {
    # so itens de menu (ListItem ficaria com titulos de conversas)
    $l = foreach ($tipo in @($CT::Menu, $CT::MenuItem, $CT::RadioButton)) {
        foreach ($e in (Achar $tipo)) {
            '{0} | {1} | {2}' -f $e.Current.ControlType.ProgrammaticName, $e.Current.Name, $e.Current.BoundingRectangle
        }
    }
    $l | Out-File -Encoding utf8 $DEBUG
}

function Confirmar {
    # dialogos "Trocar modelo?" / "Alternar modelo?" / "Alterar nivel de esforco?"
    $cb = New-Object System.Windows.Automation.PropertyCondition -ArgumentList ($AE::ControlTypeProperty), ($CT::Button)
    for ($i = 0; $i -lt 6; $i++) {
        Start-Sleep -Milliseconds $MS_POLL
        foreach ($w in (Achar ($CT::Window))) {
            foreach ($b in $w.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cb)) {
                if ($b.Current.Name -like 'Alternar*') {
                    [void](Clicar $b)
                    Start-Sleep -Milliseconds $MS_APOS_DIALOGO
                    return $true
                }
            }
        }
    }
    return $false
}

# ---------- principal ----------
$proc = Get-Process | Where-Object { $_.ProcessName -eq 'claude' -and $_.MainWindowTitle -like '*Claude*' } | Select-Object -First 1
if (-not $proc) { Fim 'ERRO' 'janela do Claude nao encontrada' }
$root = $AE::FromHandle($proc.MainWindowHandle)

$alvoMod = Norm $Modelo
$alvoEf = Norm $Esforco

$est = EstadoAtual
if ((Norm $est.modelo).StartsWith($alvoMod) -and (Norm $est.esforco) -eq $alvoEf) { Fim 'OK' $est.texto }

# 1) modelo
if (-not (Norm $est.modelo).StartsWith($alvoMod)) {
    if (-not (AbrirMenu)) { Fim 'ERRO' 'menu de modelo nao abriu' }
    $achou = $null
    foreach ($r in (Achar ($CT::RadioButton))) {
        if ((Norm $r.Current.Name).StartsWith($alvoMod)) { $achou = $r; break }
    }
    if (-not $achou) { Dump; Fim 'ERRO' "modelo $Modelo nao encontrado no menu" }
    [void](Clicar $achou)
    [void](Confirmar)
    Start-Sleep -Milliseconds $MS_APOS_TROCA
}

# 2) esforco (hover no item abre o submenu)
$est = EstadoAtual
if ((Norm $est.esforco) -ne $alvoEf) {
    if (-not (AbrirMenu)) { Fim 'ERRO' ("modelo aplicado (" + $est.texto + "), mas o menu de esforco nao abriu") }
    $item = ItemEsforco
    $c = $null
    if ($item) { $c = Centro $item }
    if (-not $c) { Fim 'ERRO' ("modelo aplicado (" + $est.texto + "), mas o item de esforco nao apareceu") }
    Mover $c[0] $c[1]
    Start-Sleep -Milliseconds $MS_SUBMENU
    $op = AcharOpcaoEsforco $alvoEf
    if (-not $op) {
        [System.Windows.Forms.SendKeys]::SendWait('{RIGHT}')
        Start-Sleep -Milliseconds $MS_SETA
        $op = AcharOpcaoEsforco $alvoEf
    }
    if (-not $op) {
        Dump
        [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
        Fim 'ERRO' ("modelo aplicado (" + $est.texto + "), mas nao achei a opcao de esforco '" + $Esforco + "'")
    }
    [void](Clicar $op)
    [void](Confirmar)
    Start-Sleep -Milliseconds $MS_APOS_TROCA
}

# fecha o menu se ainda estiver aberto e devolve o foco para a caixa de texto
if (ItemEsforco) {
    [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
    Start-Sleep -Milliseconds $MS_FECHAR_MENU
}
foreach ($e in (Achar ($CT::Edit))) {
    $n = $e.Current.Name
    if ($n -eq 'Prompt' -or $n -like 'Escreva as instru*') {
        try { $e.SetFocus() } catch {}
        break
    }
}
Start-Sleep -Milliseconds $MS_POLL

$est = EstadoAtual
if ((Norm $est.modelo).StartsWith($alvoMod) -and (Norm $est.esforco) -eq $alvoEf) { Fim 'OK' $est.texto }
Fim 'ERRO' ("ficou em: " + $est.texto)
