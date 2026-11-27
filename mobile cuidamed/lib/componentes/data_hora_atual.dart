import 'dart:async';

import 'package:flutter/material.dart';

import '../utilitarios/tema.dart';

const _diasSemana = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];
const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

String formatarDataPorExtenso(DateTime data) =>
    '${_diasSemana[data.weekday - 1]}, ${data.day} de ${_meses[data.month - 1]}';

String formatarHora(DateTime data) =>
    '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

class RelogioAtual extends StatefulWidget {
  final Widget Function(BuildContext context, DateTime agora) construtor;
  const RelogioAtual({super.key, required this.construtor});

  @override
  State<RelogioAtual> createState() => _RelogioAtualState();
}

class _RelogioAtualState extends State<RelogioAtual> {
  DateTime _agora = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() => _agora = DateTime.now()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.construtor(context, _agora);
}

class DataHoraCabecalho extends StatelessWidget {
  const DataHoraCabecalho({super.key});

  @override
  Widget build(BuildContext context) {
    return RelogioAtual(
      construtor: (context, agora) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatarDataPorExtenso(agora),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CorApp.texto)),
          Text('${formatarHora(agora)} · Agora',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CorApp.textoSuave)),
        ],
      ),
    );
  }
}

class FaixaDataHora extends StatelessWidget {
  const FaixaDataHora({super.key});

  @override
  Widget build(BuildContext context) {
    return RelogioAtual(
      construtor: (context, agora) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CorApp.fundoCard,
          borderRadius: BorderRadius.circular(RaioApp.medio),
          border: Border.all(color: CorApp.borda),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 22, color: CorApp.azulTexto),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatarDataPorExtenso(agora),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CorApp.texto)),
                  Text('${formatarHora(agora)} · Agora',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CorApp.textoSuave)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AvatarUsuario extends StatelessWidget {
  final String nome;
  final double tamanho;
  final String? descricao;
  const AvatarUsuario({super.key, required this.nome, this.tamanho = 40, this.descricao});

  String get _iniciais {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '';
    return (partes.first[0] + (partes.length > 1 ? partes.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: descricao ?? 'Usuário: $nome',
      child: Container(
        width: tamanho,
        height: tamanho,
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: CorApp.gradienteAzul, shape: BoxShape.circle),
        child: Text(
          _iniciais,
          textScaler: TextScaler.noScaling,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: tamanho * 0.36),
        ),
      ),
    );
  }
}
