import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/botao.dart';
import '../componentes/cabecalho.dart';
import '../estado/app_estado.dart';
import '../servicos/api_cliente.dart';
import '../servicos/chat_servico.dart';
import '../utilitarios/tema.dart';

const _mensagemBoasVindas = 'Olá! Eu sou o assistente do CuidaMed. Pode me perguntar sobre seus remédios e horários.';
const _mensagemErroConexao = 'Não consegui me conectar ao servidor agora. Tente novamente em instantes.';
const _perguntasSugeridas = [
  'Quais remédios eu preciso tomar?',
  'Que horas eu tomo cada remédio?',
  'Tem alguma observação sobre como tomar meus remédios?',
  'Eu tomei todos os remédios nos últimos dias?',
];

class _Mensagem {
  final bool doUsuario;
  String texto;
  bool digitando;
  _Mensagem({required this.doUsuario, required this.texto, this.digitando = false});
}

/// Equivalente a paginas/Chat.jsx: conversa com o assistente (só paciente),
/// perguntas sugeridas e indicador de "digitando" enquanto a API responde.
class Chat extends StatefulWidget {
  /// Injetável pra teste; por padrão usa a API real.
  final Future<String> Function(int pacienteId, String mensagem)? perguntar;
  const Chat({super.key, this.perguntar});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final _entradaController = TextEditingController();
  final _rolagem = ScrollController();
  final List<_Mensagem> _mensagens = [_Mensagem(doUsuario: false, texto: _mensagemBoasVindas)];
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _entradaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entradaController.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  void _rolarParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_rolagem.hasClients) return;
      _rolagem.animateTo(
        _rolagem.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviar(String valor) async {
    final texto = valor.trim();
    if (texto.isEmpty || _enviando) return;
    final pacienteId = context.read<AppEstado>().usuario!.id;
    final resposta = _Mensagem(doUsuario: false, texto: '', digitando: true);

    setState(() {
      _mensagens.add(_Mensagem(doUsuario: true, texto: texto));
      _mensagens.add(resposta);
      _enviando = true;
    });
    _entradaController.clear();
    _rolarParaOFim();

    try {
      final perguntar = widget.perguntar ?? ChatServico().perguntar;
      resposta.texto = await perguntar(pacienteId, texto);
    } catch (erro) {
      // Erro do servidor (ex.: limite de perguntas atingido) já vem com a mensagem certa.
      resposta.texto = erro is ApiExcecao ? erro.mensagem : _mensagemErroConexao;
    } finally {
      resposta.digitando = false;
      if (mounted) {
        setState(() => _enviando = false);
        _rolarParaOFim();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final podeEnviar = !_enviando && _entradaController.text.trim().isNotEmpty;

    return AndaimeApp(
      appBar: const Cabecalho(kicker: 'Assistente', titulo: 'Chat'),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _rolagem,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _mensagens.length,
              itemBuilder: (context, indice) => _Bolha(mensagem: _mensagens[indice]),
            ),
          ),
          // Perguntas prontas quebrando em linhas (flex-wrap do web), todas
          // visíveis sem rolagem lateral. Limitadas a ~1/3 da tela (rolam se passar) pra não
          // espremer a conversa, e escondidas enquanto o teclado está aberto.
          if (MediaQuery.viewInsetsOf(context).bottom == 0)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.32),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: SizedBox(
                  width: double.infinity, // alinhadas à esquerda, como no web
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final pergunta in _perguntasSugeridas)
                        _PerguntaSugerida(
                          texto: pergunta,
                          onPressed: _enviando ? null : () => _enviar(pergunta),
                          compacta: MediaQuery.sizeOf(context).width < 360,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: CorApp.fundoCard,
              border: Border(top: BorderSide(color: CorApp.borda)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _entradaController,
                    enabled: !_enviando,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _enviar,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 17),
                    decoration: const InputDecoration(hintText: 'Digite sua pergunta...', hintMaxLines: 1),
                  ),
                ),
                const SizedBox(width: 10),
                Botao(
                  texto: 'Enviar',
                  larguraTotal: false,
                  onPressed: podeEnviar ? () => _enviar(_entradaController.text) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Pílula" de pergunta pronta — igual ao .chat__sugestao do web. Se o texto
/// não couber numa linha, quebra dentro da pílula em vez de ser cortado.
class _PerguntaSugerida extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;

  /// Telas bem estreitas: um pouco menor, pra as 4 perguntas caberem sem rolar.
  final bool compacta;
  const _PerguntaSugerida({required this.texto, required this.onPressed, this.compacta = false});

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: CorApp.bordaDestaque, width: 1.5),
    );
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: Material(
        color: CorApp.azulFundo,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compacta ? 12 : 16, vertical: compacta ? 7 : 10),
            child: Text(
              texto,
              style: TextStyle(fontSize: compacta ? 13 : 14, fontWeight: FontWeight.w700, color: CorApp.azulTexto),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bolha extends StatelessWidget {
  final _Mensagem mensagem;
  const _Bolha({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final doUsuario = mensagem.doUsuario;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child),
      ),
      child: Align(
        alignment: doUsuario ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: doUsuario ? CorApp.gradienteAzul : null,
            color: doUsuario ? null : CorApp.fundoCard,
            border: doUsuario ? null : Border.all(color: CorApp.borda),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(RaioApp.medio),
              topRight: const Radius.circular(RaioApp.medio),
              bottomLeft: Radius.circular(doUsuario ? RaioApp.medio : 4),
              bottomRight: Radius.circular(doUsuario ? 4 : RaioApp.medio),
            ),
          ),
          child: mensagem.digitando
              ? const _Digitando()
              : Text(
                  mensagem.texto,
                  style: TextStyle(fontSize: 16, height: 1.4, color: doUsuario ? Colors.white : CorApp.texto),
                ),
        ),
      ),
    );
  }
}

/// Três pontinhos pulsando enquanto o assistente responde.
class _Digitando extends StatefulWidget {
  const _Digitando();

  @override
  State<_Digitando> createState() => _DigitandoState();
}

class _DigitandoState extends State<_Digitando> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('chat-digitando'),
      label: 'Assistente digitando',
      child: AnimatedBuilder(
        animation: _controlador,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CorApp.textoSuave.withValues(
                    alpha: 0.3 + 0.7 * (((_controlador.value * 3 - i) % 3) < 1 ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
