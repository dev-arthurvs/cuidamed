import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../modelos/paciente.dart';
import '../utilitarios/tema.dart';
import 'cabecalho.dart';

/// "Cartão do paciente" da tela inicial, no formato de cartão de plano de
/// saúde — equivalente ao CartaoPaciente.jsx do web: identifica o paciente
/// (nome, nascimento, sexo, nº) e resume o dia (doses tomadas, a tomar e
/// atrasadas), com o atalho para a agenda.
class CartaoPaciente extends StatelessWidget {
  final Paciente paciente;
  final int tomados;
  final int aTomar;
  final int atrasados;

  const CartaoPaciente({
    super.key,
    required this.paciente,
    required this.tomados,
    required this.aTomar,
    required this.atrasados,
  });

  static const _sexoParaTexto = {'FEMININO': 'Feminino', 'MASCULINO': 'Masculino', 'OUTRO': 'Outro'};

  /// Código do vínculo como número de cartão: 12 → "0000 0012".
  static String numeroDoCartao(int id) {
    final digitos = id.toString().padLeft(8, '0');
    return '${digitos.substring(0, 4)} ${digitos.substring(4)}';
  }

  static String _data(DateTime? data) => data == null
      ? '—'
      : '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cartão do paciente',
      child: Container(
        constraints: const BoxConstraints(minHeight: 280),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: CorApp.fundoCartaoPaciente,
          boxShadow: const [BoxShadow(color: Color(0x590B2F63), blurRadius: 40, offset: Offset(0, 18))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Círculos de brilho, como nos cartões de verdade.
            const Positioned(right: -60, top: -80, child: _Circulo(tamanho: 220, cor: Color(0x29FFFFFF))),
            const Positioned(right: -40, bottom: -110, child: _Circulo(tamanho: 240, cor: Color(0x474AA8F0))),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const LogoCuidaMed(tamanho: 34, tamanhoTexto: 20, claro: true),
                      const SizedBox(width: 12),
                      // Flexível: em tela estreita (ou fonte grande) quebra em vez de estourar.
                      Expanded(
                        child: Text(
                          'CARTÃO DO PACIENTE',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _Chip(),
                  const SizedBox(height: 12),
                  Text(
                    paciente.nome.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 26,
                    runSpacing: 10,
                    children: [
                      _Dado(rotulo: 'NASCIMENTO', valor: _data(paciente.dataNascimento)),
                      _Dado(rotulo: 'SEXO', valor: _sexoParaTexto[paciente.sexo] ?? '—'),
                      // Nº do cartão = código do vínculo com o cuidador: só com cuidador vinculado.
                      if (paciente.codigoVinculo != null)
                        _Dado(rotulo: 'Nº DO CARTÃO', valor: numeroDoCartao(paciente.codigoVinculo!), espacado: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
                  const SizedBox(height: 14),
                  // Wrap: se não couberem lado a lado, descem para a linha de baixo.
                  Wrap(
                    spacing: 22,
                    runSpacing: 10,
                    children: [
                      _Contador(valor: tomados, rotulo: 'Tomados', cor: const Color(0xFF5FD39B)),
                      _Contador(valor: aTomar, rotulo: 'A tomar', cor: const Color(0xFF7CC2FF)),
                      _Contador(valor: atrasados, rotulo: 'Atrasados', cor: const Color(0xFFF2C25B)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => context.go('/agenda'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                      shape: const StadiumBorder(),
                      textStyle: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Ver agenda completa ›'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  final double tamanho;
  final Color cor;
  const _Circulo({required this.tamanho, required this.cor});

  @override
  Widget build(BuildContext context) => Container(
    width: tamanho,
    height: tamanho,
    decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
  );
}

/// Chip dourado do cartão.
class _Chip extends StatelessWidget {
  const _Chip();

  @override
  Widget build(BuildContext context) {
    const linha = Color(0x59785614);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 44,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          gradient: const LinearGradient(colors: [Color(0xFFF6DD96), Color(0xFFD8A945), Color(0xFFB98A2A)]),
        ),
        child: Stack(
          children: [
            Center(child: Container(width: 3, color: linha)),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(height: 2, color: linha),
                Container(height: 2, color: linha),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dado extends StatelessWidget {
  final String rotulo;
  final String valor;
  final bool espacado;
  const _Dado({required this.rotulo, required this.valor, this.espacado = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: espacado ? 2 : 0,
          ),
        ),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  final int valor;
  final String rotulo;
  final Color cor;
  const _Contador({required this.valor, required this.rotulo, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$valor',
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, height: 1.1),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              rotulo,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
