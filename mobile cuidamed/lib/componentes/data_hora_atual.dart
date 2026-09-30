import 'dart:async';

import 'package:flutter/material.dart';

import '../utilitarios/tema.dart';

const _diasSemana = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];
const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

/// "Quinta-feira, 24 de setembro" — mesmo formato do formatarDataPorExtenso do web.
String formatarDataPorExtenso(DateTime data) =>
    '${_diasSemana[data.weekday - 1]}, ${data.day} de ${_meses[data.month - 1]}';

String formatarHora(DateTime data) =>
    '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

/// Reconstrói [construtor] com a hora atual a cada 30 s (igual ao Cabecalho.jsx do web).
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

/// Bloco do cabeçalho em tela larga: data em negrito e "08:24 · Agora" embaixo.
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: CorApp.texto)),
          Text('${formatarHora(agora)} · Agora',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CorApp.textoSuave)),
        ],
      ),
    );
  }
}

/// Faixa com data e hora pro celular, onde o cabeçalho não tem espaço pra ela.
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
            const Icon(Icons.calendar_today_outlined, size: 22, color: CorApp.azulTexto),
            const SizedBox(width: 12),
            // Data e hora empilhadas (como no cabeçalho do web) — lado a lado a
            // data quebrava em duas linhas e espremia a hora.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatarDataPorExtenso(agora),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: CorApp.texto)),
                  Text('${formatarHora(agora)} · Agora',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CorApp.textoSuave)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Círculo com as iniciais (Nunito extra-negrito sobre o gradiente azul do web).
/// Usado para o usuário logado no cabeçalho e para os pacientes nas listas,
/// para que todos os círculos de iniciais do app tenham a mesma fonte.
class AvatarUsuario extends StatelessWidget {
  final String nome;
  final double tamanho;
  /// Texto lido pelo leitor de tela; padrão "Usuário: nome".
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
        decoration: const BoxDecoration(gradient: CorApp.gradienteAzul, shape: BoxShape.circle),
        child: Text(
          _iniciais,
          textScaler: TextScaler.noScaling, // cabe sempre no círculo, mesmo com fonte grande
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: tamanho * 0.36),
        ),
      ),
    );
  }
}
