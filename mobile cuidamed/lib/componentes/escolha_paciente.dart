import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/app_estado.dart';
import '../utilitarios/animacoes.dart';
import '../utilitarios/tema.dart';
import 'andaime_app.dart';
import 'botao.dart';
import 'cabecalho.dart';
import 'cartao.dart';
import 'data_hora_atual.dart';

/// Telas que mostram dados de um paciente só. Pelo menu ou pela barra inferior,
/// o cuidador primeiro escolhe o paciente numa lista — antes elas abriam direto
/// no último paciente acessado. Pelos detalhes do paciente, abrem direto.
const _rotasPorPaciente = {'/agenda', '/ciclos-encerrados', '/historico'};

/// Rota usada pelo menu lateral e pela barra inferior: para o cuidador, as
/// telas por paciente abrem com "?escolher=1" (lista de pacientes primeiro).
String rotaDoMenu(String rota, String? tipoUsuario) =>
    tipoUsuario == 'cuidador' && _rotasPorPaciente.contains(rota) ? '$rota?escolher=1' : rota;

/// A tela deve mostrar a lista de pacientes em vez dos dados?
bool deveEscolherPaciente(BuildContext context) =>
    context.read<AppEstado>().usuario?.tipo == 'cuidador' &&
    GoRouterState.of(context).uri.queryParameters['escolher'] == '1';

/// Lista de pacientes vinculados para o cuidador escolher de quem ver a tela.
/// Ao tocar, o paciente vira o "em foco" e a tela abre por cima da lista — o
/// botão voltar retorna para cá.
class EscolhaPaciente extends StatelessWidget {
  final String kicker;
  final String rotaDestino;
  const EscolhaPaciente({super.key, required this.kicker, required this.rotaDestino});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
    final pacientes = estado.pacientes;

    return AndaimeApp(
      appBar: Cabecalho(kicker: kicker, titulo: 'Escolha o paciente'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Cartao(
            titulo: 'Pacientes vinculados',
            child: pacientes.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Nenhum paciente vinculado ainda.', style: TextStyle(color: CorApp.textoSuave)),
                      ),
                      Botao(texto: 'Ir para o início', variante: VarianteBotao.contorno, onPressed: () => context.go('/painel')),
                    ],
                  )
                : Column(
                    children: [
                      for (final (indice, dados) in pacientes.indexed)
                        EntradaSuave(key: ValueKey(dados.paciente.id), indice: indice, child: _linha(context, dados)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _linha(BuildContext context, PacienteComDados dados) {
    final paciente = dados.paciente;
    return InkWell(
      borderRadius: BorderRadius.circular(RaioApp.pequeno),
      onTap: () {
        context.read<AppEstado>().selecionarPaciente(paciente.id);
        context.push(rotaDestino);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AvatarUsuario(nome: paciente.nome, descricao: 'Paciente: ${paciente.nome}'),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paciente.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(
                    '${paciente.dataNascimento != null ? '${paciente.calcularIdade()} anos · ' : ''}'
                    '${dados.medicamentosAtivos().length} medicamentos',
                    style: const TextStyle(color: CorApp.textoSuave, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: CorApp.textoSuave),
          ],
        ),
      ),
    );
  }
}
