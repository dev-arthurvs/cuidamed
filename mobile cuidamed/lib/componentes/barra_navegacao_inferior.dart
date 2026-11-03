import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'escolha_paciente.dart';

/// Bottom nav fixa com os acessos mais usados no dia a dia — ícones grandes
/// + legenda em texto (não só ícone), pensando no público idoso. Configurações
/// e Ajuda ficam na engrenagem e no "?" da faixa de cima.
class BarraNavegacaoInferior extends StatelessWidget {
  final String tipoUsuario; // 'paciente' | 'cuidador'
  final String rotaAtual;

  const BarraNavegacaoInferior({
    super.key,
    required this.tipoUsuario,
    required this.rotaAtual,
  });

  List<_ItemNav> _itens() {
    if (tipoUsuario == 'paciente') {
      return const [
        _ItemNav('/painel', Icons.home_outlined, 'Início'),
        _ItemNav('/agenda', Icons.calendar_month_outlined, 'Agenda'),
        _ItemNav('/historico', Icons.history, 'Histórico'),
        _ItemNav('/chat', Icons.chat_bubble_outline, 'Chat'),
      ];
    }
    return const [
      _ItemNav('/painel', Icons.home_outlined, 'Início'),
      _ItemNav('/agenda', Icons.calendar_month_outlined, 'Agenda'),
      _ItemNav('/historico', Icons.history, 'Histórico'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final itens = _itens();
    final indiceAtual = itens.indexWhere((item) => rotaAtual.startsWith(item.rota));

    return BottomNavigationBar(
      currentIndex: indiceAtual < 0 ? 0 : indiceAtual,
      items: [
        ...itens.map((item) => BottomNavigationBarItem(icon: Icon(item.icone), label: item.rotulo)),
      ],
      onTap: (indice) {
        context.go(rotaDoMenu(itens[indice].rota, tipoUsuario));
      },
    );
  }
}

class _ItemNav {
  final String rota;
  final IconData icone;
  final String rotulo;
  const _ItemNav(this.rota, this.icone, this.rotulo);
}
