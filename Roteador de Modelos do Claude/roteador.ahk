#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ============================================================
; ROTEADOR DE MODELO/ESFORÇO — Claude Desktop
; Enter na caixa de prompt -> o Haiku (CLI da assinatura) avalia a tarefa ->
; o modelo/esforço é trocado na tela e um cartão mostra a decisão.
; No cartão: Enter envia (ou envio automático) | Esc cancela | – minimiza | × fecha
; Ctrl+Alt+R liga/desliga | ícone da bandeja: log de uso, sair
; Decisão: sobe na hora; só desce após SEQ_PARA_TROCAR prompts seguidos pedindo menos (por conversa)
; ============================================================

; ---------- CONFIG ----------
global CLAUDE_CLI       := ""              ; vazio = acha o claude no PATH (caminho completo, nunca a pasta atual)
global CLASSIFICADOR    := "haiku"
global APP_EXE          := "claude.exe"    ; processo do Claude Desktop
global MAX_CHARS        := 4000            ; trecho do prompt enviado ao classificador
global MAX_CTX_CHARS    := 2500            ; trecho do contexto da conversa enviado ao classificador
global MAX_PROMPT_CHARS := 20000           ; prompts maiores passam direto, sem análise
global LOG_MAX          := 100             ; linhas guardadas no uso-haiku.csv (as mais antigas saem); 0 = sem log
global AUTO_ESPERA_SEG  := 3               ; segundos mostrando a decisão antes do envio automático
global TEMPO_CLI_SEG    := 30              ; limite para o Haiku responder
global TEMPO_CTX_SEG    := 10              ; limite para ler o contexto da tela
global TEMPO_TROCA_SEG  := 25              ; limite para trocar modelo/esforço na tela
global PS_SCRIPT        := A_ScriptDir "\scripts\mudar-modelo.ps1"
global CTX_SCRIPT       := A_ScriptDir "\scripts\contexto.ps1"
global DIR_DADOS        := A_ScriptDir "\dados"          ; criada sozinha; fora do repositório (.gitignore)
global POS_INI          := DIR_DADOS "\posicao.ini"
global ARQ_LOG          := DIR_DADOS "\uso-haiku.csv"
try DirCreate(DIR_DADOS)
global CAB_LOG          := "data_hora;caracteres;modelo;esforco;segundos;status;atual;aplicado;troca;ctx;leitura;sequencia;conversa"
global MODELOS          := ["Haiku", "Sonnet", "Opus"]
global ESFORCOS         := ["Baixo", "Médio", "Alto", "Extra", "Max"]
global UIA_EDIT         := 50004           ; tipo UIA de campo de texto
global NOME_CAIXA_PROMPT := "i)^(Prompt$|Escreva as instru)"   ; caixa de prompt: "Prompt" no Code, "Escreva as instruções…" no Chat/Cowork
; Em conversa em andamento, trocar modelo/esforço faz o histórico ser relido. Por isso o roteador só desce
; depois de SEQ_PARA_TROCAR prompts seguidos pedindo menos (ou depois de uma pausa, com o cache já vencido).
global SEQ_PARA_TROCAR  := 4
global CACHE_MIN        := 5               ; minutos parado para o histórico sair do cache
global MAX_CONVERSAS    := 12              ; conversas lembradas ao mesmo tempo (as mais antigas saem)
global ESQUECER_MIN     := 120             ; minutos parada até a conversa ser esquecida
global CARD_W := 420, CARD_M := 20         ; largura útil e margem do cartão
global COR_FUNDO := "17181B", COR_DESTAQUE := "8AB4FF", COR_TEXTO := "ECEDEF", COR_SEC := "A3A6AD"
global COR_MUDO := "6E727A", COR_LINHA := "2C2E33", COR_TECLA := "2A2C31", COR_PERIGO := "C73E36"
; ----------------------------

; O CLI chamado pelo roteador não manda telemetria nem relatórios de erro: só a chamada ao modelo
EnvSet("CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC", "1")

global APLICAR_AUTO := (IniRead(POS_INI, "envio", "aplicar", "1") = "1")   ; chaves do cartão; lembram o último estado
global AUTO_ENVIAR  := (IniRead(POS_INI, "envio", "auto", "0") = "1")

global ativo := true, pendente := false, ocupado := false
global guiAviso := "", clicaveis := Map(), ultimo := "", maxPendente := ""
global restante := 0, lblEnvio := "", chModelo := "", chEnvio := ""
global focoAnalise := "", textoAnalisado := "", UIA := ""
global seqs := Map(), chaveAtual := ""   ; só em memória: por conversa, prompts seguidos pedindo menos
global linhasLog := 0, chamadas := 0
global CLAUDE_EXEC := AcharCLI()
global GUIA := "
(
Voce classifica pedidos feitos a um assistente de IA (Claude) e escolhe o MENOR modelo e esforco que ainda resolvem bem.
NAO execute nem responda ao pedido. Apenas classifique.
Responda SOMENTE uma linha neste formato exato:
MODELO|ESFORCO|MOTIVO
MODELO = Haiku, Sonnet ou Opus. ESFORCO = Baixo, Médio, Alto, Extra ou Max. MOTIVO = ate 12 palavras em portugues.
Guia:
- Haiku/Baixo: pergunta factual curta, traducao, reescrita ou formatacao simples, resumo curto, formula simples e conhecida de Excel/Planilhas.
- Sonnet/Médio: maioria das tarefas: e-mails, textos, planilhas, codigo simples a medio, analise de um documento.
- Sonnet/Alto: tarefa longa em varias etapas, codigo que exige cuidado, muitos dados ou arquivos.
- Opus/Alto: raciocinio complexo, arquitetura, depuracao dificil, estrategia, muitos fatores ou ambiguidade.
- Opus/Extra: problema muito dificil, auditoria ou revisao critica em que erro custa caro, pesquisa profunda.
- Opus/Max: reservado a casos excepcionais que exigem o maximo de raciocinio (sistema critico inteiro, decisao irreversivel e de alto custo). Use raramente; na duvida entre Extra e Max, escolha Extra.
Regras sobre codigo:
- Escrever, criar, corrigir, depurar ou analisar codigo (scripts, funcoes, SQL, macros) exige no minimo Sonnet. Nunca Haiku.
- Unica excecao: mudanca trivial e explicita num codigo ja em discussao, como renomear algo ou trocar uma linha por outra que o assistente acabou de indicar. Ai pode ser Haiku.
- Formula simples de planilha que todo mundo conhece (SOMA, SE, PROCV, SOMASE) nao e codigo: pode ser Haiku.
Regras de contexto:
- Use o CONTEXTO DA CONVERSA. Pedido curto ('continua', 'ok faz', 'corrige isso', 'e agora?') herda a complexidade da tarefa em andamento.
- Se a conversa ja envolve codigo, arquivos, comandos ou ferramentas, ou e uma sessao do Claude Code, normalmente Sonnet ou acima.
- Avalie a tarefa inteira, nao o tamanho do texto. Texto longo nao e sinal de complexidade, e texto curto nao e sinal de simplicidade.
)"

PrepararLog()

OnMessage(0x84, ArrastarAviso)
A_TrayMenu.Delete()
A_TrayMenu.Add("Ligar/Desligar (Ctrl+Alt+R)", (*) => Alternar())
A_TrayMenu.Add("Abrir log de uso", (*) => Run(ARQ_LOG))
A_TrayMenu.Add("Sair", (*) => ExitApp())
AtualizarTip()

; ---------- HOTKEYS ----------
^!r:: Alternar()

#HotIf ativo && WinActive("ahk_exe " APP_EXE)
$Enter:: AoApertarEnter()
#HotIf ativo && pendente && WinActive("ahk_exe " APP_EXE)
$Esc:: FecharAviso()
#HotIf

; ---------- FLUXO PRINCIPAL ----------
AoApertarEnter() {
    global pendente, ocupado, focoAnalise, textoAnalisado
    if ocupado
        return
    if pendente {
        mudou := TextoMudou()
        FecharAviso()
        if !mudou {
            Send "{Enter}"
            return
        }                                ; o texto mudou depois da análise: analisa de novo em vez de enviar
    }
    l := {texto: "", metodo: "", foco: ""}
    try l := LerPrompt()
    txt := l.texto
    if (Trim(txt) = "" || StrLen(txt) > MAX_PROMPT_CHARS || SubStr(LTrim(txt), 1, 1) = "/") {
        Send "{Enter}"                   ; botão/diálogo com foco, campo vazio, texto enorme ou comando de barra
        return
    }
    ocupado := true
    focoAnalise := l.foco
    textoAnalisado := l.metodo = "uia" ? txt : ""
    envio := 0
    try {
        envio := ProcessarPrompt(txt, l.metodo)
    } catch as e {
        try MostrarAviso("Erro", "Falha interna", SubStr(e.Message, 1, 160))
    } finally {
        ocupado := false                 ; nunca deixa o Enter preso
    }
    pendente := true
    if (envio > 0)
        IniciarEnvio(envio)              ; sem fechar por tempo: o cartão só some ao enviar, Esc ou ×
}

; Classifica, decide, aplica na tela e mostra o cartão. Retorna os segundos do envio automático (0 = manual).
ProcessarPrompt(txt, leitura) {
    global maxPendente
    maxPendente := ""
    MostrarAviso("Analisando", "Lendo o prompt", "O Haiku está avaliando a complexidade da tarefa.", "", false)
    c := ColetarContexto()
    r := Classificar(txt, RegExReplace(c.texto, "m)^(MODELO ATUAL|TITULO):.*\R?", ""))   ; o Haiku avalia só a tarefa (evita viés)
    reg := {chars: StrLen(txt), r: r, atual: "", aplicado: "", troca: "", ctx: c.status, leitura: leitura, sequencia: "", conversa: ""}
    if !r.ok {
        reg.troca := "classificador: " r.motivo
        MostrarAviso("Erro", "Classificador falhou", r.motivo)
        RegistrarUso(reg)
        return 0
    }
    s := SituacaoConversa(c.texto, r)
    reg.atual := s.atual, reg.sequencia := s.sequencia, reg.conversa := s.conversa
    d := Decidir(r.modelo, r.esforco, s)
    if d.maxSug
        maxPendente := d.modelo
    if !APLICAR_AUTO {
        reg.troca := "desligada"
        MostrarAviso("Sugestão", d.modelo, r.motivo d.nota, d.esforco)
        RegistrarUso(reg)
        return 0
    }
    FecharAviso(false)                   ; libera a tela para os cliques automáticos
    t := AplicarModelo(d.modelo, d.esforco)
    Sleep 100
    Send "^{End}"
    if !t.ok {
        reg.troca := "erro: " t.motivo
        MostrarAviso("Sugestão (manual)", d.modelo, r.motivo "`n" t.motivo, d.esforco)
        RegistrarUso(reg)
        return 0
    }
    NovoEstado(t.estado)
    reg.aplicado := t.estado, reg.troca := "ok"
    RegistrarUso(reg)
    e := SepararEstado(t.estado)
    envio := (AUTO_ENVIAR && !d.maxSug) ? AUTO_ESPERA_SEG : 0      ; com Max sugerido, espera a sua decisão
    MostrarAviso(t.estado = s.atual ? "Mantido" : "Aplicado", e.modelo, r.motivo d.nota, e.esforco, true, envio)
    return envio
}

; ---------- DECISÃO: MANTER OU TROCAR ----------
; Lê da tela o modelo atual e atualiza, por conversa, a sequência de prompts pedindo menos.
; Guarda só o último estado, a contagem e a hora: tudo em memória, nada vai para disco.
SituacaoConversa(ctx, r) {
    global chaveAtual
    atual := RegExMatch(ctx, "m)^MODELO ATUAL: *(.+)$", &ma) ? Trim(ma[1], " `t`r") : ""
    nova := InStr(ctx, "CONVERSA: nova") > 0
    agora := A_TickCount
    chaveAtual := ChaveConversa(ctx)
    if !seqs.Has(chaveAtual)
        seqs[chaveAtual] := {estado: "", conta: 0, ultimo: 0}
    q := seqs[chaveAtual]
    quente := q.ultimo = 0 || (agora - q.ultimo) < CACHE_MIN * 60000   ; conversa vista pela 1ª vez: presume cache quente
    if (nova || atual = "" || atual != q.estado)     ; conversa nova ou troca feita por você: recomeça a contagem
        q.conta := 0
    q.estado := atual, q.ultimo := agora
    q.conta := PedeMenos(r.modelo, r.esforco, atual) ? q.conta + 1 : 0
    EsquecerConversas()
    return {atual: atual, nova: nova, quente: quente, sequencia: q.conta, conversa: Hash8(chaveAtual)}
}

; Identifica a conversa pelo título da sessão, lido da tela (o título da janela é sempre "Claude")
ChaveConversa(ctx) {
    if RegExMatch(ctx, "m)^TITULO: *(.+)$", &mt)
        return Trim(mt[1], " `t`r")
    return "geral"
}

Hash8(txt) {
    h := 5381
    Loop Parse txt
        h := Mod(h * 33 + Ord(A_LoopField), 0xFFFFFF)
    return Format("{:06X}", h)           ; só para conferir no log se duas conversas têm chaves diferentes
}

; Mantém na memória só as conversas recentes: apaga as paradas há muito tempo e, passando do limite, as mais antigas
EsquecerConversas() {
    agora := A_TickCount
    for k, q in seqs.Clone()
        if (agora - q.ultimo > ESQUECER_MIN * 60000)
            seqs.Delete(k)
    while (seqs.Count > MAX_CONVERSAS) {
        velha := "", t0 := 0
        for k, q in seqs
            if (velha = "" || q.ultimo < t0)
                velha := k, t0 := q.ultimo
        seqs.Delete(velha)
    }
}

NovoEstado(estado) {
    if !seqs.Has(chaveAtual)
        return
    q := seqs[chaveAtual]
    if (estado != q.estado)
        q.conta := 0                      ; mudou de patamar: a sequência recomeça
    q.estado := estado, q.ultimo := A_TickCount
}

; Ideal abaixo do atual em algum eixo e acima em nenhum
PedeMenos(modelo, esforco, atual) {
    a := SepararEstado(atual)
    rmI := RankModelo(modelo), rmA := RankModelo(a.modelo), reI := RangoEsforco(esforco), reA := RangoEsforco(a.esforco)
    if (rmA = 0 || reA = 0)
        return false
    return rmI <= rmA && reI <= reA && (rmI < rmA || reI < reA)
}

; Regras (por eixo, modelo e esforço):
; - conversa nova ou estado desconhecido: vai direto ao ideal;
; - o ideal é mais forte que o atual: sobe;
; - o ideal é mais fraco: mantém, e só desce no SEQ_PARA_TROCAR-ésimo prompt seguido pedindo menos
;   ou depois de uma pausa longa (o histórico já saiu do cache e trocar não custa a mais);
; - Max nunca é aplicado sozinho (fica em Extra + botão) e nunca é mantido sem necessidade.
Decidir(modIdeal, efIdeal, s) {
    d := {modelo: modIdeal, esforco: efIdeal, maxSug: false, nota: ""}
    a := SepararEstado(s.atual)
    am := Canonico(a.modelo, MODELOS), ae := Canonico(a.esforco, ESFORCOS)
    if (efIdeal = "Max" && ae != "Max") {
        d.esforco := efIdeal := "Extra", d.maxSug := true
        d.nota := "`nO Haiku sugeriu Max, que gasta cerca de 10x. Ficou em Extra; use o botão se for crítico."
    }
    if (s.nova || am = "" || ae = "")
        return d
    R := s.sequencia
    desce := PedeMenos(modIdeal, efIdeal, s.atual) && (!s.quente || R >= SEQ_PARA_TROCAR || ae = "Max")
    if desce {
        if (s.quente && R >= SEQ_PARA_TROCAR)
            d.nota .= "`n" R "º prompt seguido pedindo menos: reler o histórico compensa."
        else if !s.quente
            d.nota .= "`nHistórico fora do cache (pausa longa): trocar não custa a mais."
        return d
    }
    d.modelo := RankModelo(modIdeal) > RankModelo(am) ? modIdeal : am
    d.esforco := RangoEsforco(efIdeal) > RangoEsforco(ae) ? efIdeal : ae
    if (d.modelo != modIdeal || d.esforco != efIdeal)
        d.nota .= "`nIdeal: " modIdeal " " efIdeal ". Mantido para não reler o histórico"
            . (PedeMenos(modIdeal, efIdeal, s.atual) ? (": troca no " SEQ_PARA_TROCAR "º prompt seguido pedindo menos (este é o " R "º).") : ".")
    return d
}

UsarMax(*) {
    global maxPendente, ocupado
    m := maxPendente
    maxPendente := ""
    if (m = "" || ocupado)
        return
    ocupado := true
    try {
        FecharAviso(false)
        t := AplicarModelo(m, "Max")
        Sleep 100
        Send "^{End}"
        if t.ok {
            NovoEstado(t.estado)
            e := SepararEstado(t.estado)
            MostrarAviso("Aplicado", e.modelo, "Max aplicado por escolha sua.", e.esforco)
        } else
            MostrarAviso("Sugestão (manual)", m, t.motivo, "Max")
    } finally {
        ocupado := false
    }
}

; ---------- LEITURA DA TELA (UI Automation, sem área de transferência) ----------
ObterUIA() {
    global UIA
    if !IsObject(UIA)
        UIA := ComObject("{ff48dba4-60ef-4201-aa87-54103eef594e}", "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}")
    return UIA
}

; Elemento com foco no Windows: tipo, nome, se é botão/item (Enter = ação) e, opcionalmente, o texto
FocoAtual(lerValor := false) {
    static ACAO := Map(50000, 1, 50002, 1, 50003, 1, 50005, 1, 50007, 1, 50011, 1, 50013, 1, 50019, 1, 50024, 1, 50031, 1)
    f := {ok: false, tipo: 0, nome: "", valor: "", acao: false}
    el := 0, tipo := 0
    try {
        ComCall(8, ObterUIA(), "ptr*", &el)              ; IUIAutomation::GetFocusedElement
        if el {
            ComCall(21, el, "int*", &tipo)               ; get_CurrentControlType
            f.tipo := tipo, f.acao := ACAO.Has(tipo)
            f.nome := LerBSTR(23, el)                    ; get_CurrentName
            if lerValor {
                v := Buffer(24, 0)
                ComCall(10, el, "int", 30045, "ptr", v)  ; GetCurrentPropertyValue(Value)
                if (NumGet(v, 0, "ushort") = 8) {         ; VT_BSTR
                    p := NumGet(v, 8, "ptr")
                    f.valor := p ? StrGet(p) : ""
                }
                DllCall("oleaut32\VariantClear", "ptr", v)
            }
            f.ok := true
        }
    }
    if el
        ObjRelease(el)
    return f
}

LerBSTR(indice, el) {
    b := 0
    ComCall(indice, el, "ptr*", &b)
    s := b ? StrGet(b) : ""
    if b
        DllCall("oleaut32\SysFreeString", "ptr", b)
    return s
}

; Texto do campo diferente do que foi analisado (só verificável quando a tela expõe o texto)
TextoMudou() {
    if (textoAnalisado = "")
        return false
    f := FocoAtual(true)
    return f.ok && f.tipo = UIA_EDIT && Trim(f.valor) != "" && f.valor != textoAnalisado
}

; O envio automático só acontece se o foco continua no mesmo campo analisado
MesmoCampo(a, b) {
    if !(IsObject(a) && a.ok)
        return true                       ; sem leitura de tela: mantém o comportamento antigo
    return b.ok && !b.acao && b.tipo = a.tipo && b.nome = a.nome
}

; Lê o prompt pela UI Automation; só usa a área de transferência se a tela não expuser o texto
LerPrompt() {
    f := FocoAtual(true)
    if (f.ok && (f.acao || (f.tipo = UIA_EDIT && !RegExMatch(f.nome, NOME_CAIXA_PROMPT))))
        return {texto: "", metodo: "", foco: f}      ; botão ou outro campo de texto (busca, renomear): o Enter segue normal
    if (f.ok && f.tipo = UIA_EDIT && Trim(f.valor) != "" && f.valor != f.nome)
        return {texto: f.valor, metodo: "uia", foco: f}
    return {texto: LerTexto(), metodo: "clipboard", foco: f}
}

LerTexto() {
    salvo := ClipboardAll()
    A_Clipboard := ""
    Send "^a"
    Sleep 40
    Send "^c"
    txt := ClipWait(1) ? A_Clipboard : ""
    Send "^{End}"          ; tira a seleção para não apagar o texto se você digitar
    Sleep 20
    A_Clipboard := salvo
    return txt
}

ColetarContexto() {
    if !FileExist(CTX_SCRIPT)
        return {texto: "", status: "sem-script"}
    saida := A_Temp "\rc_ctx_" A_TickCount ".txt"
    try {
        if !RodarComLimite(CmdPowerShell(CTX_SCRIPT) ' -Saida "' saida '"', TEMPO_CTX_SEG)
            return {texto: "", status: "tempo"}
        t := Trim(LerArquivo(saida), " `t`r`n")
        return {texto: t, status: t = "" ? "vazio" : "ok"}
    } finally {
        try FileDelete saida              ; não deixa texto da conversa em disco
    }
}

; ---------- PROCESSOS EXTERNOS ----------
AcharCLI() {
    if (CLAUDE_CLI != "")
        return '"' CLAUDE_CLI '"'
    for dir in StrSplit(EnvGet("PATH"), ";") {
        if !RegExMatch(dir, "i)^([a-z]:\\|\\\\)")   ; ignora entradas relativas
            continue
        for nome in ["claude.exe", "claude.cmd"]
            if FileExist(dir "\" nome)
                return '"' dir "\" nome '"'
    }
    return ""
}

CmdPowerShell(script) => 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' script '"'

; Roda oculto com limite de tempo; se estourar, encerra o processo e os filhos. Retorna false no estouro.
RodarComLimite(cmd, seg) {
    Run(cmd, A_Temp, "Hide", &pid)
    if !ProcessWaitClose(pid, seg)
        return true
    try RunWait("taskkill.exe /T /F /PID " pid, , "Hide")
    Sleep 300
    return false
}

GravarArquivo(arq, texto) {
    Loop 5 {
        try {
            FileAppend(texto, arq, "UTF-8-RAW")
            return true
        }
        Sleep 200
    }
    return false
}

LerArquivo(arq) {
    Loop 3 {
        if !FileExist(arq)
            return ""
        try
            return FileRead(arq, "UTF-8")
        Sleep 150
    }
    return ""
}

Classificar(txt, ctx) {
    global chamadas
    ini := A_TickCount
    if (CLAUDE_EXEC = "")
        return {ok: false, motivo: "claude CLI não encontrado no PATH", seg: 0}
    id := A_TickCount "_" Random(1000, 9999)
    entrada := A_Temp "\rc_in_" id ".txt", saida := A_Temp "\rc_out_" id ".txt", erro := A_Temp "\rc_err_" id ".txt"
    conteudo := GUIA "`n`nCONTEXTO DA CONVERSA (lido da tela):`n" (ctx != "" ? SubStr(ctx, 1, MAX_CTX_CHARS) : "nenhum")
        . "`n`nPEDIDO DO USUARIO:`n<<<`n" SubStr(txt, 1, MAX_CHARS) "`n>>>`n"
    out := "", err := ""
    try {
        if !GravarArquivo(entrada, conteudo)
            return {ok: false, motivo: "não consegui gravar o arquivo temporário", seg: 0}
        cmd := CLAUDE_EXEC ' -p --model ' CLASSIFICADOR ' --tools "" --no-session-persistence --strict-mcp-config'
            . ' --setting-sources "" --disable-slash-commands'
            . ' --system-prompt "Voce e um classificador. Responda apenas no formato pedido."'
            . ' < "' entrada '" > "' saida '" 2> "' erro '"'
        if !RodarComLimite(A_ComSpec ' /c "' cmd '"', TEMPO_CLI_SEG)
            err := "o Haiku não respondeu em " TEMPO_CLI_SEG " s"
        chamadas++
        AtualizarTip()
        out := LerArquivo(saida)
        if (err = "")
            err := Trim(LerArquivo(erro))
    } finally {
        for f in [entrada, saida, erro]  ; não deixa o texto do prompt em disco
            try FileDelete f
    }
    seg := Round((A_TickCount - ini) / 1000, 1)
    linha := ""
    Loop Parse out, "`n", "`r" {
        if InStr(A_LoopField, "|") {
            linha := A_LoopField
            break
        }
    }
    p := StrSplit(linha, "|")
    modelo := p.Length >= 3 ? Canonico(p[1], MODELOS) : ""
    esforco := p.Length >= 3 ? Canonico(p[2], ESFORCOS) : ""
    if (modelo = "" || esforco = "") {          ; só aceita valores conhecidos (protege a linha de comando)
        msg := err != "" ? err : (Trim(out) != "" ? ("resposta fora do formato: " Trim(out)) : "sem resposta (CLI instalado e logado?)")
        return {ok: false, motivo: SubStr(RegExReplace(msg, "\s+", " "), 1, 160), seg: seg}
    }
    motivo := SubStr(RegExReplace(Trim(p[3]), "\s+", " "), 1, 160)
    return {ok: true, modelo: modelo, esforco: esforco, motivo: motivo, seg: seg}
}

AplicarModelo(modelo, esforco) {
    if !FileExist(PS_SCRIPT)
        return {ok: false, motivo: "mudar-modelo.ps1 não encontrado"}
    if (Canonico(modelo, MODELOS) = "" || Canonico(esforco, ESFORCOS) = "")
        return {ok: false, motivo: "modelo/esforço inválido: " modelo " " esforco}
    saida := A_Temp "\rc_troca_" A_TickCount ".txt"
    try {
        cmd := CmdPowerShell(PS_SCRIPT) ' -Modelo "' modelo '" -Esforco "' esforco '" -Saida "' saida '"'
        if !RodarComLimite(cmd, TEMPO_TROCA_SEG)
            return {ok: false, motivo: "tempo esgotado ao trocar o modelo"}
        p := StrSplit(Trim(LerArquivo(saida), " `t`r`n"), "|", , 2)
    } finally {
        try FileDelete saida
    }
    if (p.Length >= 2 && p[1] = "OK")
        return {ok: true, estado: Trim(p[2])}
    return {ok: false, motivo: p.Length >= 2 ? p[2] : "sem resposta do script de troca"}
}

; ---------- VALIDAÇÃO E NÍVEIS ----------
; Devolve o nome oficial da lista (ex.: "medio" -> "Médio") ou "" se o valor não for conhecido
Canonico(valor, lista) {
    v := SemAcento(StrLower(Trim(valor, " `t`r`n*.")))
    for nome in lista
        if RegExMatch(v, "^" SemAcento(StrLower(nome)) "(\b|$)")
            return nome
    return ""
}

SemAcento(s) {
    static mapa := Map("á", "a", "à", "a", "â", "a", "ã", "a", "é", "e", "ê", "e", "í", "i", "ó", "o", "ô", "o", "õ", "o", "ú", "u", "ç", "c")
    for de, para in mapa
        s := StrReplace(s, de, para)
    return s
}

RankModelo(m) {
    m := StrLower(Trim(m))
    return InStr(m, "haiku") = 1 ? 1 : InStr(m, "sonnet") = 1 ? 2 : InStr(m, "opus") = 1 ? 3 : 0
}

RangoEsforco(e) {
    e := StrLower(Trim(e))
    if RegExMatch(e, "^(baix|low)")
        return 1
    if RegExMatch(e, "^(m[eé]d)")
        return 2
    if RegExMatch(e, "^(alt|high)")
        return 3
    if RegExMatch(e, "^(extra|xhigh)")
        return 4
    if RegExMatch(e, "^(m[aá]x)")
        return 5
    return 0
}

SepararEstado(estado) {
    p := StrSplit(Trim(estado), " ")
    esf := p.Length > 1 ? p.Pop() : ""
    m := ""
    for v in p
        m .= (m = "" ? "" : " ") v
    return {modelo: m, esforco: esf}
}

; ---------- LOG, CONTADOR E BANDEJA ----------
; Prepara o CSV: mantém se estiver no formato atual (aparando o excesso); senão recomeça do zero
PrepararLog() {
    global linhasLog
    if (LOG_MAX <= 0)
        return
    if FileExist(ARQ_LOG) {
        lido := false
        try {
            cab := Trim(StrSplit(FileRead(ARQ_LOG, "UTF-8"), "`n")[1], " `r" Chr(0xFEFF))
            lido := true
        }
        if !lido
            return                        ; aberto em outro programa: tenta na próxima vez
        if (cab = CAB_LOG) {
            linhasLog := ContarLog()
            if (linhasLog > LOG_MAX)
                AparLog()
            return
        }
        try FileDelete ARQ_LOG            ; formato antigo: não guarda
    }
    Logar(CAB_LOG)
    linhasLog := 0
}

ContarLog() {
    if !FileExist(ARQ_LOG)
        return 0
    try {
        t := Trim(FileRead(ARQ_LOG, "UTF-8"), "`r`n")
        return Max(0, StrSplit(t, "`n").Length - 1)   ; desconta o cabeçalho
    }
    return 0
}

; Deixa só o cabeçalho e as LOG_MAX linhas mais recentes
AparLog() {
    global linhasLog
    try {
        l := StrSplit(Trim(FileRead(ARQ_LOG, "UTF-8"), "`r`n"), "`n", "`r")
        n := l.Length - 1
        if (n > LOG_MAX) {
            t := l[1] "`n"
            Loop LOG_MAX
                t .= l[l.Length - LOG_MAX + A_Index] "`n"
            f := FileOpen(ARQ_LOG, "w", "UTF-8")
            f.Write(t)
            f.Close()
            n := LOG_MAX
        }
        linhasLog := n
    }
}

; Grava no CSV sem derrubar o script se o arquivo estiver aberto em outro programa
Logar(linha) {
    Loop 4 {
        try {
            FileAppend linha "`n", ARQ_LOG, "UTF-8"
            return
        }
        Sleep 150
    }
}

; Uma linha por prompt analisado. Nunca grava o texto do prompt nem da conversa.
RegistrarUso(reg) {
    global linhasLog
    if (LOG_MAX <= 0)
        return
    if !FileExist(ARQ_LOG) {              ; arquivo apagado com o roteador aberto: recria já com o cabeçalho
        Logar(CAB_LOG)
        linhasLog := 0
    }
    r := reg.r
    campos := [FormatTime(, "yyyy-MM-dd HH:mm:ss"), reg.chars, r.ok ? r.modelo : "", r.ok ? r.esforco : "", r.seg, r.ok ? "ok" : "falha", reg.atual, reg.aplicado, reg.troca, reg.ctx, reg.leitura, reg.sequencia, reg.conversa]
    linha := ""
    for v in campos
        linha .= (A_Index = 1 ? "" : ";") RegExReplace(String(v), "[;\r\n]+", " ")
    Logar(linha)
    linhasLog++
    if (linhasLog > LOG_MAX + 20)         ; apara em lotes para não reescrever o arquivo a cada prompt
        AparLog()
}

Alternar() {
    global ativo
    ativo := !ativo
    FecharAviso()
    TrayTip(ativo ? "Roteador LIGADO" : "Roteador DESLIGADO", "Claude Desktop")
    AtualizarTip()
}

AtualizarTip() {
    A_IconTip := "Roteador Claude — " (ativo ? "ligado" : "desligado") " — chamadas ao Haiku nesta sessão: " chamadas
}

; ---------- CARTÃO ----------
MostrarAviso(rotulo, titulo, motivo := "", esforco := "", atalhos := true, envio := 0) {
    global clicaveis, lblEnvio, ultimo
    ultimo := {rotulo: rotulo, titulo: titulo, motivo: motivo, esforco: esforco, atalhos: atalhos}
    FecharAviso(false)
    clicaveis := Map()
    lblEnvio := ""
    g := NovaJanela(CARD_M, 16)
    fim := AddCabecalho(g, rotulo, titulo, esforco)
    fim := AddMotivo(g, fim, motivo)
    if atalhos {
        fim := AddBotaoMax(g, fim)
        AddRodape(g, fim, envio)
    } else
        g.AddText("xm y" (fim + 4) " w1 h1", "")
    ExibirJanela(g)
}

NovaJanela(margemX, margemY) {
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +Border +E0x08000000")   ; não rouba o foco do Claude
    g.BackColor := COR_FUNDO
    g.MarginX := margemX, g.MarginY := margemY
    return g
}

ExibirJanela(g) {
    global guiAviso
    pos := LerPosicao()
    g.Show("NoActivate Hide")
    g.GetPos(, , &gw, &gh)
    if (pos.x = "" || pos.y = "") {        ; primeira vez: centraliza perto da base da janela ativa
        try {
            WinGetPos(&wx, &wy, &ww, &wh, "A")
            pos := {x: wx + (ww - gw) // 2, y: wy + wh - gh - 170}
        } catch {
            pos := {x: (A_ScreenWidth - gw) // 2, y: A_ScreenHeight - gh - 200}
        }
    }
    g.Show("NoActivate x" pos.x " y" pos.y)
    Arredondar(g, gw, gh)
    guiAviso := g
}

Clicavel(ctrl, fn) {
    ctrl.OnEvent("Click", fn)
    clicaveis[ctrl.Hwnd] := true          ; fica fora da área de arrastar
    return ctrl
}

AddCabecalho(g, rotulo, titulo, esforco) {
    direita := CARD_M + CARD_W
    g.SetFont("s9 norm c" COR_MUDO, "Segoe UI")
    g.AddText("xm ym w300 h18 +0x200", rotulo)
    g.SetFont("s13 norm c" COR_MUDO, "Segoe UI")
    Clicavel(g.AddText("x" (direita - 48) " y14 w24 h22 Center +0x200 +0x100", "–"), Minimizar)
    Clicavel(g.AddText("x" (direita - 24) " y14 w24 h22 Center +0x200 +0x100", "×"), (*) => FecharAviso())
    g.SetFont("s18 w600 c" COR_TEXTO, "Segoe UI")
    tt := g.AddText("xm y44 w" (CARD_W - 130) " h36 +0x200", titulo)
    tt.GetPos(, &ty, , &th)
    n := RangoEsforco(esforco)
    if (n > 0) {                          ; medidor de esforço: 5 segmentos
        mx := direita - 108
        Loop 5
            g.AddText("x" (mx + (A_Index - 1) * 22) " y" (ty + 8) " w18 h6 Background" (A_Index <= n ? COR_DESTAQUE : COR_LINHA), "")
        g.SetFont("s9 norm c" COR_SEC, "Segoe UI")
        g.AddText("x" mx " y" (ty + 18) " w108 h16 Right", esforco)
    }
    return ty + th
}

AddMotivo(g, fim, motivo) {
    if (motivo = "")
        return fim
    g.SetFont("s10 norm c" COR_SEC, "Segoe UI")
    mo := g.AddText("xm y" (fim + 6) " w" CARD_W, motivo)
    mo.GetPos(, , , &mh)
    return fim + 6 + mh
}

AddBotaoMax(g, fim) {
    if (maxPendente = "")
        return fim
    g.SetFont("s9 w600 c" COR_FUNDO, "Segoe UI")
    b := Clicavel(g.AddText("xm y" (fim + 12) " w170 h26 Center +0x200 +0x100 Background" COR_DESTAQUE, "Usar Max neste prompt"), UsarMax)
    Pilula(b, 170, 26, 8)
    return fim + 38
}

AddRodape(g, fim, envio) {
    global chModelo, chEnvio, lblEnvio
    ys := fim + 14
    chModelo := MontarChave(g, CARD_M, ys, APLICAR_AUTO, "Trocar modelo", 88, AlternarAplicar)
    chEnvio := MontarChave(g, CARD_M + 176, ys, AUTO_ENVIAR, "Enviar automaticamente", 140, AlternarEnvio)
    yd := ys + 32
    g.AddText("xm y" yd " w" CARD_W " h1 Background" COR_LINHA, "")
    yf := yd + 14
    if (envio > 0) {
        g.SetFont("s9 w600 c" COR_DESTAQUE, "Segoe UI")
        lblEnvio := g.AddText("xm y" yf " w128 h22 +0x200", "Enviando em " envio "s")
        AddTecla(g, "x+8 yp", "Esc", 40, "cancela", 60)
    } else {
        AddTecla(g, "xm y" yf, "Enter", 52, "enviar", 50)
        AddTecla(g, "x+12 yp", "Esc", 40, "cancelar", 62)
    }
    g.SetFont("s9 w600 cFFFFFF", "Segoe UI")
    b := Clicavel(g.AddText("x" (CARD_M + CARD_W - 132) " y" (yf - 2) " w132 h26 Center +0x200 +0x100 Background" COR_PERIGO, "Encerrar roteador"), EncerrarRoteador)
    Pilula(b, 132, 26, 8)
}

AddTecla(g, pos, rotuloTecla, larguraTecla, texto, larguraTexto) {
    g.SetFont("s9 norm c" COR_TEXTO, "Segoe UI")
    g.AddText(pos " w" larguraTecla " h22 Center +0x200 Background" COR_TECLA, rotuloTecla)
    g.SetFont("s9 norm c" COR_MUDO, "Segoe UI")
    g.AddText("x+8 yp w" larguraTexto " h22 +0x200", texto)
}

; Chave liga/desliga: trilho arredondado + bolinha. Devolve [trilho, bolinha].
MontarChave(g, x, y, ligado, texto, larguraTexto, fn) {
    g.SetFont("s9 norm c" COR_MUDO, "Segoe UI")
    g.AddText("x" x " y" y " w" larguraTexto " h18 +0x200", texto)
    tx := x + larguraTexto + 4
    tr := Clicavel(g.AddText("x" tx " y" y " w36 h18 +0x100 Background" (ligado ? COR_DESTAQUE : COR_LINHA), ""), fn)
    kn := Clicavel(g.AddText("x" (tx + (ligado ? 20 : 2)) " y" (y + 2) " w14 h14 +0x100 Background" COR_TEXTO, ""), fn)
    Pilula(tr, 36, 18)
    Pilula(kn, 14, 14)
    return [tr, kn]
}

PintarChave(ch, ligado) {
    try {
        tr := ch[1], kn := ch[2]
        tr.GetPos(&tx)
        tr.Opt("Background" (ligado ? COR_DESTAQUE : COR_LINHA))
        tr.Redraw()
        kn.Move(tx + (ligado ? 20 : 2))
        kn.Redraw()
    }
}

Pilula(c, w, h, r := 0) {
    e := r ? r * 2 : Min(w, h)
    rgn := DllCall("CreateRoundRectRgn", "int", 0, "int", 0, "int", w + 1, "int", h + 1, "int", e, "int", e, "ptr")
    DllCall("SetWindowRgn", "ptr", c.Hwnd, "ptr", rgn, "int", 1)
}

Arredondar(g, gw, gh) {
    hr := DllCall("dwmapi\DwmSetWindowAttribute", "ptr", g.Hwnd, "int", 33, "int*", 2, "int", 4, "int")
    if (hr = 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", g.Hwnd, "int", 34, "int*", 0x332E2C, "int", 4, "int")   ; borda (BGR)
    else {                                  ; Windows 10: recorta com região arredondada
        rgn := DllCall("CreateRoundRectRgn", "int", 0, "int", 0, "int", gw + 1, "int", gh + 1, "int", 20, "int", 20, "ptr")
        DllCall("SetWindowRgn", "ptr", g.Hwnd, "ptr", rgn, "int", 1)
    }
}

Minimizar(*) {
    global clicaveis, lblEnvio
    r := restante
    FecharAviso(false)                    ; guarda a posição; o envio automático em curso é retomado abaixo
    clicaveis := Map(), lblEnvio := ""
    g := NovaJanela(14, 8)
    g.SetFont("s10 w600 c" COR_TEXTO, "Segoe UI")
    g.AddText("xm ym h22 +0x200", ultimo.titulo (ultimo.esforco != "" ? " · " ultimo.esforco : "") "   ")
    g.SetFont("s12 norm c" COR_MUDO, "Segoe UI")
    Clicavel(g.AddText("x+2 yp w22 h22 Center +0x200 +0x100", "▢"), Expandir)
    Clicavel(g.AddText("x+2 yp w22 h22 Center +0x200 +0x100", "×"), (*) => FecharAviso())
    ExibirJanela(g)
    if (r > 0)
        IniciarEnvio(r)
}

Expandir(*) {
    r := restante
    u := ultimo
    MostrarAviso(u.rotulo, u.titulo, u.motivo, u.esforco, u.atalhos, r)
    if (r > 0)
        IniciarEnvio(r)
}

FecharAviso(limpar := true) {
    global guiAviso, pendente, restante
    SetTimer(TickEnvio, 0)
    restante := 0
    if IsObject(guiAviso) {
        try {
            guiAviso.GetPos(&x, &y)
            IniWrite(x, POS_INI, "posicao", "x")
            IniWrite(y, POS_INI, "posicao", "y")
        }
        try guiAviso.Destroy()
        guiAviso := ""
    }
    if limpar
        pendente := false
}

LerPosicao() {
    return {x: IniRead(POS_INI, "posicao", "x", ""), y: IniRead(POS_INI, "posicao", "y", "")}
}

; Qualquer ponto do cartão vira "barra de título" (WM_NCHITTEST -> HTCAPTION), menos os controles clicáveis
ArrastarAviso(wParam, lParam, msg, hwnd) {
    if !IsObject(guiAviso)
        return
    if clicaveis.Has(hwnd)
        return
    h := guiAviso.Hwnd
    if (hwnd = h || DllCall("GetParent", "ptr", hwnd, "ptr") = h)
        return 2
}

; ---------- CHAVES E ENVIO AUTOMÁTICO ----------
AlternarEnvio(*) {
    global AUTO_ENVIAR, restante
    AUTO_ENVIAR := !AUTO_ENVIAR
    IniWrite(AUTO_ENVIAR ? 1 : 0, POS_INI, "envio", "auto")
    PintarChave(chEnvio, AUTO_ENVIAR)
    if (restante > 0 && !AUTO_ENVIAR) {   ; desligou durante a contagem: cancela o envio
        SetTimer(TickEnvio, 0)
        restante := 0
        try lblEnvio.Text := "Envio cancelado"
    }
}

AlternarAplicar(*) {
    global APLICAR_AUTO
    APLICAR_AUTO := !APLICAR_AUTO
    IniWrite(APLICAR_AUTO ? 1 : 0, POS_INI, "envio", "aplicar")
    PintarChave(chModelo, APLICAR_AUTO)
}

IniciarEnvio(seg) {
    global restante
    restante := seg
    SetTimer(TickEnvio, 1000)
}

TickEnvio() {
    global restante
    restante--
    if (restante > 0) {
        try lblEnvio.Text := "Enviando em " restante "s"
        return
    }
    SetTimer(TickEnvio, 0)
    ; só envia se o Claude continua ativo e o foco está no mesmo campo analisado (nunca num botão de diálogo)
    if !(pendente && WinActive("ahk_exe " APP_EXE) && MesmoCampo(focoAnalise, FocoAtual())) {
        try lblEnvio.Text := "Envio cancelado"
        return                            ; o cartão fica aberto: envie com Enter quando quiser
    }
    FecharAviso()
    Send "{Enter}"
}

EncerrarRoteador(*) {
    r := MsgBox("O roteador será encerrado e só volta quando você abrir o roteador.ahk de novo.`n`nEncerrar agora?",
        "Encerrar roteador", "YesNo Icon! Default2 262144")
    if (r = "Yes")
        ExitApp()
}
