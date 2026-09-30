import 'package:flutter/material.dart';
import '../utilitarios/tema.dart';

class _EstiloStatus {
  final String rotulo;
  final Color fundo;
  final Color texto;
  const _EstiloStatus(this.rotulo, this.fundo, this.texto);
}

const Map<String, _EstiloStatus> _estilos = {
  'tomado': _EstiloStatus('Tomado', CorApp.verdeFundo, CorApp.verdeTexto),
  'pendente': _EstiloStatus('A tomar', CorApp.azulFundo, CorApp.azulTexto),
  'atrasado': _EstiloStatus('Atrasado', CorApp.amareloFundo, CorApp.amareloTexto),
  'perdido': _EstiloStatus('Perdido', CorApp.vermelhoFundo, CorApp.vermelhoTexto),
};

/// Badge de status de dose — mesma paleta/rótulos de componentes/Rotulo.jsx.
class RotuloStatus extends StatelessWidget {
  final String status;
  const RotuloStatus({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final estilo = _estilos[status] ?? _estilos['pendente']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: estilo.fundo, borderRadius: BorderRadius.circular(RaioApp.pilula)),
      child: Text(estilo.rotulo, style: TextStyle(color: estilo.texto, fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }
}
