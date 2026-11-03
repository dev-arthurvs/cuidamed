import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/avisos_alerta.dart';
import '../componentes/avisos_estoque.dart';
import '../componentes/cabecalho.dart';
import '../componentes/carrossel_doses.dart';
import '../componentes/cartao.dart';
import '../componentes/cartao_paciente.dart';
import '../componentes/linha_dupla.dart';
import '../componentes/rotulo_status.dart';
import '../estado/app_estado.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/horarios.dart';
import '../utilitarios/tema.dart';

class PainelIdoso extends StatelessWidget {
  const PainelIdoso({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
    final pacienteFoco = estado.pacienteFoco;

    if (pacienteFoco == null) {
      return const AndaimeApp(
        appBar: Cabecalho(kicker: 'Início', titulo: 'Painel do paciente'),
        body: SizedBox(),
      );
    }

    final doses = construirDosesHoje(pacienteFoco.medicamentosAtivos(), pacienteFoco.historicoHoje())
      ..sort((a, b) => a.horario.compareTo(b.horario));
    final primeiroNome = estado.usuario!.nome.split(' ').first;
    // Largura útil do card de doses (lista com padding 20; lado a lado com o
    // cartão a partir de 680, com 20 entre eles; card com padding 24): com
    // 420 ou mais, "Registrar dose" cabe ao lado da dose.
    final larguraLista = MediaQuery.sizeOf(context).width - 40;
    final larguraCard = larguraLista >= 680 ? (larguraLista - 20) / 2 : larguraLista;
    final botaoAoLado = larguraCard - 48 >= 420;
    final hora = DateTime.now().hour;
    final saudacao = hora < 12 ? 'Bom dia' : (hora < 18 ? 'Boa tarde' : 'Boa noite');

    return AndaimeApp(
      appBar: Cabecalho(kicker: 'Início', titulo: '$saudacao, $primeiroNome!'),
      body: RefreshIndicator(
        onRefresh: () => estado.recarregarPaciente(pacienteFoco.paciente.id),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const FaixaAtivarNotificacoes(),
            // "Doses de hoje" (carrossel) à esquerda e Cartão do paciente à direita em
            // tela larga (como no web); no celular, um embaixo do outro, nessa ordem.
            LinhaDupla(
              espaco: 20,
              direita: CartaoPaciente(
                paciente: pacienteFoco.paciente,
                tomados: doses.where((d) => d.status == 'tomado').length,
                aTomar: doses.where((d) => d.status == 'pendente').length,
                atrasados: doses.where((d) => d.status == 'atrasado' || d.status == 'perdido').length,
              ),
              esquerda: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  // Cor oposta ao fundo da tela, para chamar a atenção.
                  gradient: CorApp.fundoCardDose,
                  borderRadius: BorderRadius.circular(RaioApp.grande),
                ),
                child: CarrosselDoses(
                  doses: doses,
                  botaoAoLado: botaoAoLado,
                  aoRegistrar: (dose) async {
                    final mensageiro = ScaffoldMessenger.of(context);
                    try {
                      await estado.marcarDoseComoTomada(pacienteFoco.paciente.id, dose.medicamentoId, dose.horario, dose.status);
                      return true;
                    } catch (erro) {
                      mensageiro.showSnackBar(
                        SnackBar(content: Text(erro is ApiExcecao ? erro.mensagem : 'Não foi possível registrar a dose.')),
                      );
                      return false;
                    }
                  },
                  aoDesfazer: (dose) async {
                    final mensageiro = ScaffoldMessenger.of(context);
                    try {
                      await estado.desfazerDose(pacienteFoco.paciente.id, dose.medicamentoId, dose.horario);
                      mensageiro.showSnackBar(const SnackBar(content: Text('Registro desfeito.')));
                    } catch (erro) {
                      mensageiro.showSnackBar(
                        SnackBar(content: Text(erro is ApiExcecao ? erro.mensagem : 'Não foi possível desfazer.')),
                      );
                    }
                  },
                ),
              ),
            ),
            AvisosEstoque(dados: pacienteFoco),
            const SizedBox(height: 20),
            Cartao(
              titulo: 'Agenda de hoje',
              child: Column(
                children: doses
                    .map(
                      (dose) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 56,
                              child: Text(dose.horario, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            Expanded(
                              child: Text(dose.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            RotuloStatus(status: dose.status),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
