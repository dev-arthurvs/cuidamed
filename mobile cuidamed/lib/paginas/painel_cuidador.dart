import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/botao.dart';
import '../componentes/cabecalho.dart';
import '../componentes/cadastro_paciente.dart';
import '../componentes/cartao.dart';
import '../componentes/data_hora_atual.dart';
import '../estado/app_estado.dart';
import '../modelos/paciente.dart';
import '../servicos/api_cliente.dart';
import '../servicos/paciente_servico.dart';
import '../utilitarios/horarios.dart';
import '../utilitarios/tema.dart';
import '../utilitarios/animacoes.dart';

class PainelCuidador extends StatefulWidget {
  const PainelCuidador({super.key});

  @override
  State<PainelCuidador> createState() => _PainelCuidadorState();
}

class _PainelCuidadorState extends State<PainelCuidador> {
  final PacienteServico _pacienteServico = PacienteServico();
  List<Paciente> _solicitacoes = [];
  bool _carregandoSolicitacoes = false;

  Timer? _atualizarSolicitacoes;

  @override
  void initState() {
    super.initState();
    _carregarSolicitacoes();
    // Pedidos de vínculo feitos no app do paciente aparecem sozinhos (a cada 30 s).
    _atualizarSolicitacoes = Timer.periodic(AppEstado.intervaloAtualizacao, (_) => _carregarSolicitacoes(silencioso: true));
  }

  @override
  void dispose() {
    _atualizarSolicitacoes?.cancel();
    super.dispose();
  }

  /// [silencioso]: atualização automática, sem o indicador de carregando piscar.
  Future<void> _carregarSolicitacoes({bool silencioso = false}) async {
    final estado = context.read<AppEstado>();
    if (!silencioso) setState(() => _carregandoSolicitacoes = true);
    try {
      final lista = await _pacienteServico.listarSolicitacoes(estado.usuario!.id);
      if (mounted) setState(() => _solicitacoes = lista);
    } catch (_) {
      // silencioso: não impede o resto do painel de carregar
    } finally {
      if (mounted && !silencioso) setState(() => _carregandoSolicitacoes = false);
    }
  }

  Future<void> _responderSolicitacao(Paciente paciente, bool aceitar) async {
    final estado = context.read<AppEstado>();
    try {
      if (aceitar) {
        await _pacienteServico.aceitarVinculo(paciente.id, estado.usuario!.id);
      } else {
        await _pacienteServico.recusarVinculo(paciente.id, estado.usuario!.id);
      }
      await _carregarSolicitacoes();
      if (aceitar) await estado.recarregarPaciente(paciente.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(aceitar ? '${paciente.nome} vinculado(a) com sucesso.' : 'Solicitação recusada.')));
      }
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro is ApiExcecao ? erro.mensagem : 'Não foi possível concluir.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();

    return AndaimeApp(
      appBar: const Cabecalho(kicker: 'Painel do cuidador', titulo: 'Acompanhe seus pacientes', mostrarUsuario: true),
      body: RefreshIndicator(
        onRefresh: _carregarSolicitacoes,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // No celular a data não cabe no cabeçalho (o web também a esconde
            // abaixo de 640px), então ela aparece aqui no topo.
            if (MediaQuery.sizeOf(context).width < Cabecalho.larguraComDataHora) ...[
              const FaixaDataHora(),
              const SizedBox(height: 16),
            ],
            _Estatisticas(pacientes: estado.pacientes),
            const SizedBox(height: 20),
            if (_solicitacoes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Cartao(
                  titulo: 'Solicitações pendentes',
                  acao: _carregandoSolicitacoes
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                  child: Column(
                    children: [
                      for (final (indice, paciente) in _solicitacoes.indexed)
                        EntradaSuave(key: ValueKey(paciente.id), indice: indice, child: _linhaSolicitacao(paciente)),
                    ],
                  ),
                ),
              ),
            _cartaoPacientes(context, estado),
          ],
        ),
      ),
    );
  }

  /// Card "Pacientes vinculados": com espaço, o botão fica no cabeçalho do card
  /// (como no web); no celular ele desce pra baixo do título, na largura toda,
  /// pra o texto "+ Cadastrar paciente" caber inteiro.
  Widget _cartaoPacientes(BuildContext context, AppEstado estado) {
    final lista = estado.pacientes.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nenhum paciente vinculado ainda.', style: TextStyle(color: CorApp.textoSuave)),
          )
        : Column(
            children: [
              for (final (indice, dados) in estado.pacientes.indexed)
                EntradaSuave(key: ValueKey(dados.paciente.id), indice: indice, child: _linhaPaciente(context, dados)),
            ],
          );

    return LayoutBuilder(
      builder: (context, restricoes) {
        final botaoNoCabecalho = restricoes.maxWidth >= 560;
        final botao = Botao(
          texto: '+ Cadastrar paciente',
          compacto: true,
          larguraTotal: !botaoNoCabecalho,
          onPressed: () => abrirCadastroPaciente(context),
        );
        return Cartao(
          titulo: 'Pacientes vinculados',
          acao: botaoNoCabecalho ? botao : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!botaoNoCabecalho) ...[botao, const SizedBox(height: 14)],
              lista,
            ],
          ),
        );
      },
    );
  }

  /// Pedido de vínculo: dados do paciente em cima e "Aceitar" / "Recusar" em
  /// texto embaixo, como no web (antes eram só ícones ✓/✗ espremidos na linha).
  Widget _linhaSolicitacao(Paciente paciente) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AvatarUsuario(nome: paciente.nome, descricao: 'Paciente: ${paciente.nome}'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(paciente.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(paciente.email, style: const TextStyle(color: CorApp.textoSuave, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Botao(texto: 'Aceitar', compacto: true, onPressed: () => _responderSolicitacao(paciente, true)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Botao(
                  texto: 'Recusar',
                  variante: VarianteBotao.contorno,
                  compacto: true,
                  onPressed: () => _responderSolicitacao(paciente, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linhaPaciente(BuildContext context, PacienteComDados dados) {
    final adesao = calcularAdesao(dados.historico);
    return InkWell(
      borderRadius: BorderRadius.circular(RaioApp.pequeno),
      onTap: () {
        context.read<AppEstado>().selecionarPaciente(dados.paciente.id);
        context.push('/cuidador/paciente/${dados.paciente.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AvatarUsuario(nome: dados.paciente.nome, descricao: 'Paciente: ${dados.paciente.nome}'),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dados.paciente.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  // Mesmo texto do web: "26 anos · 4 medicamentos" (só os ativos).
                  Text(
                    '${dados.paciente.dataNascimento != null ? '${dados.paciente.calcularIdade()} anos · ' : ''}'
                    '${dados.medicamentosAtivos().length} medicamentos',
                    style: const TextStyle(color: CorApp.textoSuave, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text('$adesao%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: CorApp.azulTexto)),
          ],
        ),
      ),
    );
  }
}

/// Os quatro indicadores do topo — mesmas contas do PainelCuidador.jsx do web.
/// 4 lado a lado com espaço; 2x2 no celular. Cards de cada linha com a mesma altura.
class _Estatisticas extends StatelessWidget {
  final List<PacienteComDados> pacientes;
  const _Estatisticas({required this.pacientes});

  @override
  Widget build(BuildContext context) {
    final emAtencao = pacientes.where((dados) {
      final doses = construirDosesHoje(dados.medicamentosAtivos(), dados.historicoHoje());
      return doses.any((dose) => dose.status == 'atrasado' || dose.status == 'perdido');
    }).length;
    // Só os ativos: medicamentos de ciclos encerrados não estão mais sendo monitorados.
    final totalMedicamentos = pacientes.fold<int>(0, (soma, dados) => soma + dados.medicamentosAtivos().length);
    final adesaoMedia = pacientes.isEmpty
        ? 0
        : (pacientes.fold<int>(0, (soma, dados) => soma + calcularAdesao(dados.historico)) / pacientes.length).round();

    final cartoes = [
      _CartaoEstatistica(valor: '${pacientes.length}', rotulo: 'Pacientes vinculados', cor: CorApp.azulTexto),
      _CartaoEstatistica(
        valor: '$emAtencao',
        rotulo: 'Precisam de atenção',
        cor: CorApp.amarelo,
        corBorda: const Color(0xFFF2E0C2),
      ),
      _CartaoEstatistica(valor: '$adesaoMedia%', rotulo: 'Adesão média (30 dias)', cor: CorApp.verde),
      _CartaoEstatistica(valor: '$totalMedicamentos', rotulo: 'Medicamentos monitorados', cor: CorApp.texto),
    ];

    return LayoutBuilder(
      builder: (context, restricoes) {
        final porLinha = restricoes.maxWidth >= 760 ? 4 : 2;
        const espaco = 12.0;
        return Column(
          children: [
            for (var inicio = 0; inicio < cartoes.length; inicio += porLinha) ...[
              if (inicio > 0) const SizedBox(height: espaco),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = inicio; i < inicio + porLinha; i++) ...[
                      if (i > inicio) const SizedBox(width: espaco),
                      Expanded(child: cartoes[i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CartaoEstatistica extends StatelessWidget {
  final String valor;
  final String rotulo;
  final Color cor;
  final Color corBorda;
  const _CartaoEstatistica({required this.valor, required this.rotulo, required this.cor, this.corBorda = CorApp.borda});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rotulo: $valor',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          color: CorApp.fundoCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: corBorda),
          boxShadow: const [BoxShadow(color: Color(0x0A133A6E), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(valor, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: cor, height: 1.1)),
            const SizedBox(height: 4),
            Text(rotulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CorApp.textoSuave, height: 1.25)),
          ],
        ),
      ),
    );
  }
}
