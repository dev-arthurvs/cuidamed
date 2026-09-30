import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/avisos_alerta.dart';
import '../componentes/botao.dart';
import '../componentes/cabecalho.dart';
import '../componentes/cartao.dart';
import '../componentes/rotulo_status.dart';
import '../estado/app_estado.dart';
import '../utilitarios/horarios.dart';
import '../utilitarios/tema.dart';
import '../utilitarios/whatsapp.dart';
import '../utilitarios/animacoes.dart';

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
    final proxima = doses.where((d) => d.status != 'tomado' && d.status != 'perdido').toList();
    final temPerdida = doses.any((d) => d.status == 'perdido');
    final primeiroNome = estado.usuario!.nome.split(' ').first;
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: CorApp.gradienteAzul, borderRadius: BorderRadius.circular(RaioApp.grande)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: transicaoTrocaSuave(),
                layoutBuilder: (atual, anteriores) => Stack(alignment: Alignment.topLeft, children: [...anteriores, ?atual]),
                child: proxima.isEmpty
                    ? Column(
                        key: const ValueKey('nada-pendente'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Próximo medicamento',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Nada pendente',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            temPerdida
                                ? 'Sem doses pendentes no momento — algumas doses de hoje foram perdidas.'
                                : 'Todas as doses de hoje foram tomadas.',
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ],
                      )
                    : Column(
                        key: ValueKey('proxima-${proxima.first.id}'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Próximo medicamento',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            proxima.first.horario,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 34),
                          ),
                          Text(
                            proxima.first.nome,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                          ),
                          // Quantidade por dose (ex.: "1 comp"); sem ela cadastrada, cai na dosagem.
                          Text(
                            formatarQuantidadePorDose(
                              forma: proxima.first.forma,
                              quantidadePorDose: proxima.first.quantidadePorDose,
                              dosagem: proxima.first.dosagem,
                            ),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 18),
                          Botao(
                            texto: 'Registrar dose',
                            larguraTotal: false,
                            variante: VarianteBotao.sobreAzul,
                            onPressed: () => estado.marcarDoseComoTomada(
                              pacienteFoco.paciente.id,
                              proxima.first.medicamentoId,
                              proxima.first.horario,
                              proxima.first.status,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _cartaoContagem('Tomados', doses.where((d) => d.status == 'tomado').length, CorApp.verde)),
                const SizedBox(width: 12),
                Expanded(child: _cartaoContagem('A tomar', doses.where((d) => d.status == 'pendente').length, CorApp.azulTexto)),
                const SizedBox(width: 12),
                Expanded(
                  child: _cartaoContagem(
                    'Atrasados',
                    doses.where((d) => d.status == 'atrasado' || d.status == 'perdido').length,
                    CorApp.amarelo,
                  ),
                ),
              ],
            ),
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
                              child: Text(dose.horario, style: const TextStyle(fontWeight: FontWeight.w800)),
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

  Widget _cartaoContagem(String rotulo, int valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: CorApp.fundoCard,
        borderRadius: BorderRadius.circular(RaioApp.medio),
        border: Border.all(color: CorApp.borda),
      ),
      child: Column(
        children: [
          Text(
            '$valor',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: cor),
          ),
          Text(
            rotulo,
            style: const TextStyle(fontSize: 12, color: CorApp.textoSuave, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
