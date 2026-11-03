import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/botao.dart';
import '../componentes/cabecalho.dart';
import '../componentes/confirmacao.dart';
import '../componentes/voltar_detalhes_paciente.dart';
import '../componentes/escolha_paciente.dart';
import '../componentes/lista_tratamentos_encerrados.dart';
import '../estado/app_estado.dart';
import '../modelos/historico.dart';
import '../modelos/medicamento.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/horarios.dart';
import '../utilitarios/tema.dart';
import '../utilitarios/animacoes.dart';
import 'formulario_medicamento.dart';

/// "1 medicamento em uso" / "3 medicamentos em uso".
String _contar(int quantidade, String singular, String plural) => '$quantidade ${quantidade == 1 ? singular : plural}';

/// Agenda com duas abas, como no web: "Em uso" (remédios ativos) e
/// "Encerrados" (tratamentos que já terminaram). Abre em "Encerrados" com
/// ?aba=encerrados (é para onde vai o endereço antigo /ciclos-encerrados).
class AgendaMedicamentos extends StatefulWidget {
  const AgendaMedicamentos({super.key});

  @override
  State<AgendaMedicamentos> createState() => _AgendaMedicamentosState();
}

class _AgendaMedicamentosState extends State<AgendaMedicamentos> {
  bool? _encerrados; // null = ainda não leu a URL

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _encerrados ??= GoRouterState.of(context).uri.queryParameters['aba'] == 'encerrados';
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
    final encerrados = _encerrados ?? false;
    if (deveEscolherPaciente(context)) {
      return const EscolhaPaciente(kicker: 'Agenda de medicamentos', rotaDestino: '/agenda');
    }
    final dados = estado.pacienteFoco;

    if (dados == null) {
      return const AndaimeApp(
        appBar: Cabecalho(kicker: 'Agenda de medicamentos', titulo: 'Nenhum paciente selecionado'),
        body: Padding(padding: EdgeInsets.all(20), child: Text('Selecione um paciente para ver a agenda.')),
      );
    }

    final medicamentosAtivos = dados.medicamentosAtivos();
    final medicamentosEncerrados = dados.medicamentos.where((m) => !medicamentosAtivos.contains(m)).toList();
    // Paciente sem cuidador cuida da própria agenda; com cuidador, só se ele liberou.
    final podeEditar =
        estado.usuario!.tipo == 'cuidador' || dados.paciente.cuidadorId == null || dados.paciente.permiteAlteracoes;

    final kicker = estado.usuario!.tipo == 'cuidador'
        ? 'Agenda de ${dados.paciente.nome.split(' ').first}'
        : 'Agenda de medicamentos';

    return AndaimeApp(
      appBar: Cabecalho(
        kicker: kicker,
        titulo: encerrados
            ? _contar(medicamentosEncerrados.length, 'tratamento encerrado', 'tratamentos encerrados')
            : _contar(medicamentosAtivos.length, 'medicamento em uso', 'medicamentos em uso'),
      ),
      body: RefreshIndicator(
        onRefresh: () => estado.recarregarPaciente(dados.paciente.id),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            VoltarDetalhesPaciente(pacienteId: dados.paciente.id),
            _TopoAgenda(
              podeEditar: podeEditar,
              encerrados: encerrados,
              totalEmUso: medicamentosAtivos.length,
              totalEncerrados: medicamentosEncerrados.length,
              aoTrocarAba: (valor) => setState(() => _encerrados = valor),
            ),
            const SizedBox(height: 20),
            if (encerrados) ListaTratamentosEncerrados(medicamentos: medicamentosEncerrados),
            if (!encerrados && medicamentosAtivos.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Nenhum medicamento em uso no momento.', style: TextStyle(color: CorApp.textoSuave)),
              ),
            if (!encerrados)
              for (final (indice, medicamento) in medicamentosAtivos.indexed)
              EntradaSuave(
                key: ValueKey(medicamento.id),
                indice: indice,
                child: _CartaoMedicamento(
                  medicamento: medicamento,
                  podeEditar: podeEditar,
                  pacienteId: dados.paciente.id,
                  historico: dados.historico,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartaoMedicamento extends StatelessWidget {
  final Medicamento medicamento;
  final bool podeEditar;
  final int pacienteId;
  final List<Historico> historico;

  const _CartaoMedicamento({
    required this.medicamento,
    required this.podeEditar,
    required this.pacienteId,
    this.historico = const [],
  });

  @override
  Widget build(BuildContext context) {
    final estoque = calcularEstoque(medicamento, historico: historico);
    final iniciado = medicamentoIniciado(medicamento);
    final proximaDose = iniciado && !temDoseNoDia(medicamento) ? proximoDiaDeDose(medicamento) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: CorApp.fundoCard, borderRadius: BorderRadius.circular(RaioApp.medio), border: Border.all(color: CorApp.borda)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(gradient: CorApp.gradienteAzul, borderRadius: BorderRadius.circular(RaioApp.pequeno)),
                child: const Icon(Icons.medication_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(medicamento.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    Text(
                      [medicamento.dosagem, rotuloForma[medicamento.forma] ?? medicamento.forma].where((t) => t.isNotEmpty).join(' · '),
                      style: TextStyle(color: CorApp.textoSuave),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final horario in medicamento.horarios) _pilula(horario, CorApp.azulFundo, CorApp.azulTexto),
              _pilula(rotuloFrequencia[medicamento.frequencia] ?? medicamento.frequencia, CorApp.fundoDestaque, CorApp.textoSuave),
              if (!iniciado) _pilula('Começa em ${_dataCurta(medicamento.dataInicio)}', CorApp.amareloFundo, CorApp.amareloTexto),
              if (proximaDose != null)
                _pilula('Próxima dose: ${_dataCurta(DateTime.parse(proximaDose))}', CorApp.amareloFundo, CorApp.amareloTexto),
            ],
          ),
          if (estoque != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: estoque.esgotado
                    ? CorApp.vermelhoFundo
                    : estoque.duraAteOFim
                        ? CorApp.verdeFundo
                        : (estoque.baixo ? CorApp.amareloFundo : CorApp.fundoDestaque),
                borderRadius: BorderRadius.circular(RaioApp.pequeno),
              ),
              child: Text(
                estoque.esgotado
                    ? '⚠️ Estoque esgotado — Reponha o quanto antes.'
                    : estoque.duraAteOFim
                        ? '✅ Estoque suficiente — (até ${_dataCurta(medicamento.dataFim!)}).'
                    : estoque.baixo
                        ? '⚠️ Estoque baixo: ${estoque.quantidade} ${estoque.unidade} restantes — '
                            '(${_duracao(estoque.diasRestantes)}).'
                        : 'Estoque: ${estoque.quantidade} ${estoque.unidade} — (${_duracao(estoque.diasRestantes)}).',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: estoque.esgotado
                      ? CorApp.vermelhoTexto
                      : estoque.duraAteOFim
                          ? CorApp.verdeTexto
                          : (estoque.baixo ? CorApp.amareloTexto : CorApp.textoSuave),
                ),
              ),
            ),
          ],
          if (podeEditar) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Botao(
                    texto: 'Editar',
                    variante: VarianteBotao.secundario,
                    compacto: true,
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => FormularioMedicamento(medicamentoExistente: medicamento)));
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Botao(
                    texto: 'Excluir',
                    variante: VarianteBotao.perigo,
                    compacto: true,
                    onPressed: () => _confirmarExclusao(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// "dura 3 dias" / "dura 1 dia" / "não dá para o dia todo" (antes: "dura ~0 dias").
  String _duracao(int dias) => dias <= 0 ? 'não dá para o dia todo' : 'dura $dias dia${dias == 1 ? '' : 's'}';

  String _dataCurta(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

  Widget _pilula(String texto, Color fundo, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(RaioApp.pilula)),
        child: Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 12)),
      );

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Excluir medicamento?',
      mensagem: 'Tem certeza que deseja excluir "${medicamento.nome}" da agenda? Essa ação não pode ser desfeita.',
      textoConfirmar: 'Sim, excluir',
    );
    if (!confirmou || !context.mounted) return;
    try {
      await context.read<AppEstado>().excluirMedicamento(pacienteId, medicamento.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicamento excluído.')));
      }
    } catch (erro) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(erro is ApiExcecao ? erro.mensagem : 'Não foi possível excluir o medicamento.')));
      }
    }
  }
}

/// Topo da agenda igual ao web: abas "Em uso" / "Encerrados" à esquerda e
/// "+ Inserir medicamento" à direita (só em "Em uso"). No celular empilha, com o
/// botão na largura toda.
class _TopoAgenda extends StatelessWidget {
  final bool podeEditar;
  final bool encerrados;
  final int totalEmUso;
  final int totalEncerrados;
  final ValueChanged<bool> aoTrocarAba;

  const _TopoAgenda({
    required this.podeEditar,
    required this.encerrados,
    required this.totalEmUso,
    required this.totalEncerrados,
    required this.aoTrocarAba,
  });

  @override
  Widget build(BuildContext context) {
    final abas = _Abas(
      encerrados: encerrados,
      totalEmUso: totalEmUso,
      totalEncerrados: totalEncerrados,
      aoTrocar: aoTrocarAba,
    );
    // Só o aviso de "sem permissão" aparece (e só em "Em uso"); o texto
    // explicando a finalidade da tela foi removido (a ajuda "?" cobre isso).
    final aviso = !encerrados && !podeEditar
        ? Text(
            'Seu cuidador ainda não liberou alterações nessa agenda. Fale com ele(a) se precisar ajustar algo.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CorApp.textoSuave, height: 1.4),
          )
        : null;
    final mostrarInserir = !encerrados && podeEditar;

    return LayoutBuilder(
      builder: (context, restricoes) {
        final largo = restricoes.maxWidth >= 640;
        final botaoInserir = Botao(
          texto: '+ Inserir medicamento',
          larguraTotal: !largo,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FormularioMedicamento())),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (largo)
              Row(children: [abas, const Spacer(), if (mostrarInserir) botaoInserir])
            else ...[
              abas,
              if (mostrarInserir) ...[const SizedBox(height: 12), botaoInserir],
            ],
            if (aviso != null) ...[const SizedBox(height: 12), aviso],
          ],
        );
      },
    );
  }
}

/// Controle segmentado com a contagem em cada aba.
class _Abas extends StatelessWidget {
  final bool encerrados;
  final int totalEmUso;
  final int totalEncerrados;
  final ValueChanged<bool> aoTrocar;

  const _Abas({required this.encerrados, required this.totalEmUso, required this.totalEncerrados, required this.aoTrocar});

  @override
  Widget build(BuildContext context) {
    Widget aba(String rotulo, int total, bool ativa, bool valor) {
      return Expanded(
        child: Semantics(
          selected: ativa,
          button: true,
          child: Material(
            color: ativa ? CorApp.fundoCard : Colors.transparent,
            elevation: ativa ? 1 : 0,
            shadowColor: const Color(0x1F0B2F63),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => aoTrocar(valor),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          rotulo,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: ativa ? CorApp.azulTexto : CorApp.textoSuave,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(color: CorApp.azulFundo, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          '$total',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: ativa ? CorApp.azulTexto : CorApp.textoSuave,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: CorApp.fundoDestaque,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CorApp.borda, width: 1.5),
        ),
        child: Row(
          children: [
            aba('Em uso', totalEmUso, !encerrados, false),
            const SizedBox(width: 4),
            aba('Encerrados', totalEncerrados, encerrados, true),
          ],
        ),
      ),
    );
  }
}
