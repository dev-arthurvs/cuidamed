import 'dart:async';

import 'package:flutter/material.dart';

import '../modelos/dose.dart';
import '../utilitarios/whatsapp.dart';

const _corTomada = Color(0xFF7EF0B4);
const _corPerdida = Color(0xFFFFB0B0);
const _corAtrasada = Color(0xFFFFD98A);
const _fundoLinha = Color(0x17FFFFFF); // branco 9%

const _rotuloStatus = {'tomado': 'Tomada', 'perdido': 'Perdida', 'atrasado': 'Atrasada', 'pendente': 'Pendente'};

String _quantidade(Dose dose) =>
    formatarQuantidadePorDose(forma: dose.forma, quantidadePorDose: dose.quantidadePorDose, dosagem: dose.dosagem);

/// Card "Doses de hoje" do Início do paciente — equivalente a
/// CarrosselDoses.jsx do web: carrossel vertical com a dose anterior (pequena,
/// em cima), a dose em foco (grande, com "Registrar dose" quando é a dose da
/// vez) e a próxima (pequena, embaixo). Só as duas setas trocam de dose:
/// arrastar ou rolar sobre o card move a tela.
class CarrosselDoses extends StatefulWidget {
  /// Doses de hoje, já em ordem de horário.
  final List<Dose> doses;

  /// Registra a dose; devolve true se deu certo.
  final Future<bool> Function(Dose dose) aoRegistrar;

  /// "Desfazer" uma dose registrada hoje por engano.
  final void Function(Dose dose) aoDesfazer;

  /// "Registrar dose" ao lado da dose (card largo) ou embaixo, ocupando a
  /// largura (celular). Vem de fora porque o card fica numa LinhaDupla, que mede
  /// a altura intrínseca — e LayoutBuilder não suporta isso.
  final bool botaoAoLado;

  const CarrosselDoses({super.key, required this.doses, required this.aoRegistrar, required this.aoDesfazer, this.botaoAoLado = false});

  @override
  State<CarrosselDoses> createState() => _CarrosselDosesState();
}

class _CarrosselDosesState extends State<CarrosselDoses> {
  late int _foco;
  int _direcao = 1;
  late String _chaveDaVez;

  // Logo depois de registrar, oferece "Desfazer" por alguns segundos.
  static const _tempoDesfazer = Duration(seconds: 12);
  Dose? _registrada;
  Timer? _temporizadorDesfazer;
  final _popupDesfazer = OverlayPortalController();

  Future<void> _registrar(Dose dose) async {
    if (!await widget.aoRegistrar(dose) || !mounted) return;
    _temporizadorDesfazer?.cancel();
    _popupDesfazer.show();
    setState(() => _registrada = dose);
    _temporizadorDesfazer = Timer(_tempoDesfazer, _fecharPopup);
  }

  void _fecharPopup() {
    if (!mounted) return;
    _popupDesfazer.hide();
    setState(() => _registrada = null);
  }

  void _desfazer(Dose dose) {
    _temporizadorDesfazer?.cancel();
    _fecharPopup();
    widget.aoDesfazer(dose);
  }

  Widget _botaoDesfazer(Dose dose) => OutlinedButton(
        onPressed: () => _desfazer(dose),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xB3FFFFFF), width: 1.5),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        child: const Text('Desfazer'),
      );

  @override
  void dispose() {
    _temporizadorDesfazer?.cancel();
    super.dispose();
  }

  int get _indiceDaVez => widget.doses.indexWhere((d) => d.status == 'pendente' || d.status == 'atrasado');

  /// Sem dose da vez, entra um item final "Nada pendente" depois da última dose.
  int get _total => _indiceDaVez == -1 ? widget.doses.length + 1 : widget.doses.length;

  int get _indiceInicial => _indiceDaVez == -1 ? _total - 1 : _indiceDaVez;

  String _calcularChave() => _indiceDaVez == -1 ? 'fim-${widget.doses.length}' : widget.doses[_indiceDaVez].id;

  /// null = item final "Nada pendente".
  Dose? _item(int indice) => indice < widget.doses.length ? widget.doses[indice] : null;

  @override
  void initState() {
    super.initState();
    _foco = _indiceInicial;
    _chaveDaVez = _calcularChave();
  }

  @override
  void didUpdateWidget(CarrosselDoses antigo) {
    super.didUpdateWidget(antigo);
    // Quando a dose da vez muda (ex.: acabou de registrar), o foco volta pra ela.
    final chave = _calcularChave();
    if (chave != _chaveDaVez) {
      _chaveDaVez = chave;
      _direcao = 1;
      _foco = _indiceInicial;
    }
    _foco = _foco.clamp(0, _total - 1);
  }

  bool _podeIr(int indice) => indice >= 0 && indice < _total && indice != _foco;

  void _irPara(int indice) {
    if (!_podeIr(indice)) return;
    setState(() {
      _direcao = indice > _foco ? 1 : -1;
      _foco = indice;
    });
  }

  @override
  Widget build(BuildContext context) {
    final atual = _item(_foco);
    final anterior = _foco > 0 ? _LinhaDose(dose: _item(_foco - 1)) : null;
    final proxima = _foco < _total - 1 ? _LinhaDose(dose: _item(_foco + 1)) : null;

    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Doses de hoje',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            if (widget.doses.isNotEmpty)
              _Seta(icone: Icons.keyboard_arrow_up, rotulo: 'Dose anterior', aoTocar: _foco > 0 ? () => _irPara(_foco - 1) : null),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (filho, animacao) {
                final entrando = filho.key == ValueKey(atual?.id ?? 'fim');
                final deslocamento = Tween<Offset>(
                  begin: Offset(0, (entrando ? _direcao : -_direcao) * 0.12),
                  end: Offset.zero,
                ).animate(animacao);
                return FadeTransition(opacity: animacao, child: SlideTransition(position: deslocamento, child: filho));
              },
              layoutBuilder: (atualFilho, anteriores) =>
                  Stack(alignment: Alignment.topCenter, children: [...anteriores, ?atualFilho]),
              child: Column(
                key: ValueKey(atual?.id ?? 'fim'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  anterior ?? const SizedBox(height: 44),
                  const SizedBox(height: 14),
                  atual == null ? _nadaPendente() : _doseEmFoco(atual),
                  const SizedBox(height: 14),
                  // Abre espaço para a seta do canto inferior, que fica fora da animação.
                  Padding(
                    padding: const EdgeInsets.only(right: 54),
                    child: proxima ?? const SizedBox(height: 44),
                  ),
                ],
              ),
            ),
            if (widget.doses.isNotEmpty)
              Positioned(
                right: 0,
                bottom: 0,
                child: _Seta(
                  icone: Icons.keyboard_arrow_down,
                  rotulo: 'Próxima dose',
                  aoTocar: _foco < _total - 1 ? () => _irPara(_foco + 1) : null,
                ),
              ),
          ],
        ),
      ],
    );
    return OverlayPortal(controller: _popupDesfazer, overlayChildBuilder: _construirPopup, child: conteudo);
  }

  /// Pop-up logo depois de registrar, acima da barra inferior, com o "Desfazer"
  /// e a barrinha do tempo que resta.
  Widget _construirPopup(BuildContext context) {
    final dose = _registrada;
    if (dose == null) return const SizedBox.shrink();
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.viewPaddingOf(context).bottom + kBottomNavigationBarHeight + 12,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Semantics(
            liveRegion: true,
            child: Material(
              color: const Color(0xFF0F2C50),
              elevation: 8,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0x2EFFFFFF)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dose das ${dose.horario} registrada.',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _botaoDesfazer(dose),
                      ],
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    key: ValueKey(dose.id),
                    tween: Tween(begin: 1, end: 0),
                    duration: _tempoDesfazer,
                    builder: (context, restante, _) => LinearProgressIndicator(
                      value: restante,
                      minHeight: 6,
                      color: Colors.white,
                      backgroundColor: const Color(0x2EFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nadaPendente() {
    final temPerdida = widget.doses.any((d) => d.status == 'perdido');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nada pendente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24)),
        const SizedBox(height: 6),
        Text(
          widget.doses.isEmpty
              ? 'Nenhuma dose para hoje.'
              : (temPerdida ? 'Algumas doses de hoje foram perdidas.' : 'Todas as doses de hoje foram tomadas.'),
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ],
    );
  }

  Widget _doseEmFoco(Dose dose) {
    final ehDaVez = _foco == _indiceDaVez;
    final perdida = dose.status == 'perdido';
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(dose.horario, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 34)),
            if (dose.status != 'pendente') _SeloStatus(status: dose.status),
          ],
        ),
        Text(
          dose.nome,
          style: TextStyle(
            color: Colors.white.withValues(alpha: perdida ? 0.85 : 1),
            fontWeight: FontWeight.w700,
            fontSize: 22,
            decoration: perdida ? TextDecoration.lineThrough : null,
            decorationColor: Colors.white,
            decorationThickness: 2,
          ),
        ),
        // Quantidade por dose (ex.: "1 comp"); pomada não tem.
        if (_quantidade(dose).isNotEmpty) Text(_quantidade(dose), style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
    if (dose.status == 'tomado') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [info, const SizedBox(height: 12), _botaoDesfazer(dose)],
      );
    }
    if (!ehDaVez) return info;

    final botao = FilledButton(
      onPressed: () => _registrar(dose),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0B3A78),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      child: const Text('Registrar dose'),
    );
    return widget.botaoAoLado
        ? Row(children: [Expanded(child: info), const SizedBox(width: 16), botao])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [info, const SizedBox(height: 16), botao]);
  }
}

/// Linha pequena (dose anterior em cima, próxima embaixo): tomada em verde com
/// ✓; perdida em vermelho, riscada e com ✕; pendente/atrasada em branco.
class _LinhaDose extends StatelessWidget {
  final Dose? dose; // null = fim das doses de hoje

  const _LinhaDose({required this.dose});

  @override
  Widget build(BuildContext context) {
    final d = dose;
    final cor = switch (d?.status) {
      'tomado' => _corTomada,
      'perdido' => _corPerdida,
      _ => Colors.white.withValues(alpha: 0.85),
    };
    final perdida = d?.status == 'perdido';
    final estilo = TextStyle(
      color: cor,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      decoration: perdida ? TextDecoration.lineThrough : null,
      decorationColor: cor,
      decorationThickness: 2,
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: _fundoLinha, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: d == null
                ? Text('Fim das doses de hoje', style: estilo)
                : Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${d.horario}  ', style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: [d.nome, _quantidade(d)].where((t) => t.isNotEmpty).join(' · ')),
                    ]),
                    style: estilo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (d != null) ...[const SizedBox(width: 8), _IconeStatus(status: d.status, cor: cor)],
        ],
      ),
    );
  }
}

class _IconeStatus extends StatelessWidget {
  final String status;
  final Color cor;
  const _IconeStatus({required this.status, required this.cor});

  @override
  Widget build(BuildContext context) {
    if (status == 'tomado') return Icon(Icons.check, size: 18, color: cor);
    if (status == 'perdido') return Icon(Icons.close, size: 18, color: cor);
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: cor, shape: BoxShape.circle));
  }
}

class _SeloStatus extends StatelessWidget {
  final String status;
  const _SeloStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final cor = switch (status) {
      'tomado' => _corTomada,
      'perdido' => _corPerdida,
      _ => _corAtrasada,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _fundoLinha, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconeStatus(status: status, cor: cor),
          const SizedBox(width: 6),
          Text(_rotuloStatus[status] ?? status, style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Seta extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final VoidCallback? aoTocar;
  const _Seta({required this.icone, required this.rotulo, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: aoTocar == null ? 0.35 : 1,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: const CircleBorder(side: BorderSide(color: Color(0x4DFFFFFF))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: aoTocar,
          child: Tooltip(
            message: rotulo,
            child: SizedBox(width: 44, height: 44, child: Icon(icone, color: Colors.white, size: 24)),
          ),
        ),
      ),
    );
  }
}
