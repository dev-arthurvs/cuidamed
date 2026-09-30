import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/botao.dart';
import '../componentes/cabecalho.dart';
import '../componentes/confirmacao.dart';
import '../componentes/voltar_detalhes_paciente.dart';
import '../componentes/escolha_paciente.dart';
import '../estado/app_estado.dart';
import '../modelos/historico.dart';
import '../modelos/medicamento.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/horarios.dart';
import '../utilitarios/tema.dart';
import '../utilitarios/animacoes.dart';
import 'formulario_medicamento.dart';

class AgendaMedicamentos extends StatelessWidget {
  const AgendaMedicamentos({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
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
    final totalEncerrados = dados.medicamentos.length - medicamentosAtivos.length;
    final podeEditar = estado.usuario!.tipo == 'cuidador' || dados.paciente.permiteAlteracoes;

    final kicker = estado.usuario!.tipo == 'cuidador'
        ? 'Agenda de ${dados.paciente.nome.split(' ').first}'
        : 'Agenda de medicamentos';

    return AndaimeApp(
      appBar: Cabecalho(kicker: kicker, titulo: '${medicamentosAtivos.length} medicamentos cadastrados'),
      body: RefreshIndicator(
        onRefresh: () => estado.recarregarPaciente(dados.paciente.id),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            VoltarDetalhesPaciente(pacienteId: dados.paciente.id),
            _TopoAgenda(podeEditar: podeEditar, totalEncerrados: totalEncerrados),
            const SizedBox(height: 20),
            if (medicamentosAtivos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Nenhum medicamento ativo cadastrado no momento.', style: TextStyle(color: CorApp.textoSuave)),
              ),
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
                    Text(medicamento.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    Text('${medicamento.dosagem} · ${rotuloForma[medicamento.forma] ?? medicamento.forma}', style: const TextStyle(color: CorApp.textoSuave)),
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

/// Topo da agenda igual ao web: descrição à esquerda; "Ciclos encerrados" e
/// "+ Inserir medicamento" à direita. No celular empilha, com o botão na
/// largura toda (no lugar do antigo botão flutuante).
class _TopoAgenda extends StatelessWidget {
  final bool podeEditar;
  final int totalEncerrados;
  const _TopoAgenda({required this.podeEditar, required this.totalEncerrados});

  @override
  Widget build(BuildContext context) {
    // Só o aviso de "sem permissão" aparece; o texto explicando a finalidade da
    // tela foi removido (a ajuda "?" cobre isso).
    final descricao = const Text(
      'Seu cuidador ainda não liberou alterações nessa agenda. Fale com ele(a) se precisar ajustar algo.',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CorApp.textoSuave, height: 1.4),
    );
    final linkEncerrados = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/ciclos-encerrados'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          'Ciclos encerrados${totalEncerrados > 0 ? ' ($totalEncerrados)' : ''}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CorApp.azul),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, restricoes) {
        final largo = restricoes.maxWidth >= 640;
        final botaoInserir = Botao(
          texto: '+ Inserir medicamento',
          larguraTotal: !largo,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FormularioMedicamento())),
        );
        if (largo) {
          return Row(
            children: [
              Expanded(child: podeEditar ? const SizedBox.shrink() : descricao),
              const SizedBox(width: 20),
              linkEncerrados,
              if (podeEditar) ...[const SizedBox(width: 18), botaoInserir],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!podeEditar) ...[descricao, const SizedBox(height: 10)],
            Align(alignment: Alignment.centerLeft, child: linkEncerrados),
            if (podeEditar) ...[const SizedBox(height: 12), botaoInserir],
          ],
        );
      },
    );
  }
}
