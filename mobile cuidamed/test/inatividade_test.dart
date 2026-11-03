import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/paginas/login.dart';

import 'apoio.dart';

int _diasAtras(int dias) => DateTime.now().subtract(Duration(days: dias)).millisecondsSinceEpoch;

/// Sai da conta sozinho depois de 7 dias sem uso (qualquer tipo de usuário).
void main() {
  test('Ao abrir: sessão salva parada há mais de 7 dias não volta (sem aviso)', () async {
    SharedPreferences.setMockInitialValues({
      'usuarioId': 1,
      'usuarioTipo': 'paciente',
      'tokenSessao': 'token-antigo',
      'ultimaAtividade': _diasAtras(8),
    });
    final estado = AppEstado();
    await estado.restaurarSessao();
    expect(estado.autenticado, isFalse);
    expect(estado.consumirAvisoSessao(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tokenSessao'), isNull);
    expect(prefs.getInt('ultimaAtividade'), isNull);
  });

  test('Com o app aberto: passou de 7 dias sem uso, sai da conta', () async {
    SharedPreferences.setMockInitialValues({'ultimaAtividade': _diasAtras(8)});
    final estado = estadoPaciente();
    await estado.verificarInatividade();
    expect(estado.autenticado, isFalse);
    expect(estado.consumirAvisoSessao(), isNull);
  });

  test('Usado há menos de 7 dias: continua logado', () async {
    SharedPreferences.setMockInitialValues({'ultimaAtividade': _diasAtras(6)});
    final estado = estadoCuidador();
    await estado.verificarInatividade();
    expect(estado.autenticado, isTrue);
    expect(estado.consumirAvisoSessao(), isNull);
  });

  test('"Lembrar de mim": não sai por inatividade, nem com o app aberto', () async {
    SharedPreferences.setMockInitialValues({'ultimaAtividade': _diasAtras(30), 'lembrarMim': true});
    final estado = estadoPaciente();
    await estado.verificarInatividade();
    expect(estado.autenticado, isTrue);
  });

  test('"Lembrar de mim": ao sair, o login continua lembrado para o próximo login', () async {
    SharedPreferences.setMockInitialValues({'lembrarMim': true, 'loginLembrado': 'maria@email.com'});
    final estado = estadoPaciente();
    await estado.sair();
    expect(await estado.loginLembrado(), 'maria@email.com');
    expect((await SharedPreferences.getInstance()).getBool('lembrarMim'), isNull);
  });

  testWidgets('Login: caixa "Lembrar de mim" ao lado de "Esqueci minha senha"', (tester) async {
    await montarPagina(tester, AppEstado()..carregandoSessao = false, '/login', (_) => const Login());
    expect(find.text('Lembrar de mim'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
  });
}
