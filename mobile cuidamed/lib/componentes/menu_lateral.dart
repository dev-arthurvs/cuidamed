import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/app_estado.dart';
import '../utilitarios/tema.dart';
import 'cabecalho.dart';
import 'escolha_paciente.dart';

class _ItemMenu {
  final String rota;
  final IconData icone;
  final String rotulo;
  const _ItemMenu(this.rota, this.icone, this.rotulo);
}

const List<_ItemMenu> _itensComuns = [
  _ItemMenu('/painel', Icons.home_outlined, 'Início'),
  _ItemMenu('/agenda', Icons.calendar_month_outlined, 'Agenda de medicamentos'),
  _ItemMenu('/ciclos-encerrados', Icons.inventory_2_outlined, 'Ciclos encerrados'),
  _ItemMenu('/historico', Icons.history, 'Histórico'),
  _ItemMenu('/farmacias', Icons.local_pharmacy_outlined, 'Farmácias'),
  _ItemMenu('/perfil', Icons.person_outline, 'Perfil'),
  _ItemMenu('/acessibilidade', Icons.accessibility_new, 'Ajuda e acessibilidade'),
];

/// Menu hambúrguer (drawer): acesso completo a todas as telas, incluindo as
/// que não cabem na barra inferior — equivalente a BarraNavegacao.jsx do web.
class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
    final usuario = estado.usuario;
    final ehPaciente = usuario?.tipo == 'paciente';

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(20, 24, 20, 12), child: LogoCuidaMed(tamanho: 38, tamanhoTexto: 22)),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final item in _itensComuns)
                    if (item.rota != '/chat' || ehPaciente)
                      ListTile(
                        leading: Icon(item.icone, color: CorApp.textoSuave),
                        title: Text(item.rotulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(rotaDoMenu(item.rota, usuario?.tipo));
                        },
                      ),
                  if (ehPaciente)
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline, color: CorApp.textoSuave),
                      title: const Text('Chat com o assistente', style: TextStyle(fontWeight: FontWeight.w700)),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/chat');
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: CorApp.vermelho),
              title: const Text('Sair da conta', style: TextStyle(fontWeight: FontWeight.w700, color: CorApp.vermelho)),
              onTap: () async {
                Navigator.of(context).pop();
                await estado.sair();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
