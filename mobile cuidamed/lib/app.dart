import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'componentes/avisos_alerta.dart';
import 'estado/app_estado.dart';
import 'estado/monitor_alertas.dart';
import 'paginas/acessibilidade.dart';
import 'paginas/agenda_medicamentos.dart';
import 'paginas/cadastro.dart';
import 'paginas/chat.dart';
import 'paginas/ciclos_encerrados.dart';
import 'paginas/definir_senha.dart';
import 'paginas/detalhe_paciente.dart';
import 'paginas/edicao_perfil.dart';
import 'paginas/farmacias.dart';
import 'paginas/historico.dart';
import 'paginas/login.dart';
import 'paginas/painel_cuidador.dart';
import 'paginas/painel_idoso.dart';
import 'paginas/painel_paciente.dart';
import 'componentes/voltar_detalhes_paciente.dart';
import 'servicos/notificacao_servico.dart';
import 'servicos/paciente_servico.dart';
import 'utilitarios/tema.dart';

/// Multiplica a escala de texto do sistema pela preferência do usuário.
Widget aplicarEscalaFonte(BuildContext context, Widget? child) {
  final escala = context.select<AppEstado, double>((e) => e.escalaFonte);
  final midia = MediaQuery.of(context);
  return MediaQuery(
    data: midia.copyWith(textScaler: TextScaler.linear(midia.textScaler.scale(1) * escala)),
    child: child!,
  );
}

GoRouter _construirRouter(AppEstado estado) {
  return GoRouter(
    refreshListenable: estado,
    initialLocation: '/login',
    redirect: (context, state) {
      if (estado.carregandoSessao) return null;
      final indoParaAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/cadastro' ||
          state.matchedLocation == '/definir-senha';
      if (!estado.autenticado && !indoParaAuth) return '/login';
      if (estado.autenticado && indoParaAuth) return '/painel';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const Login()),
      GoRoute(path: '/cadastro', builder: (context, state) => const Cadastro()),
      GoRoute(path: '/definir-senha', builder: (context, state) => const DefinirSenha()),
      GoRoute(
        path: '/painel',
        builder: (context, state) {
          final tipo = estado.usuario?.tipo;
          return tipo == 'cuidador' ? const PainelCuidador() : const PainelIdoso();
        },
      ),
      GoRoute(
        path: rotaDetalhesPaciente, // '/cuidador/paciente/:pacienteId'
        builder: (context, state) => DetalhePaciente(pacienteId: int.parse(state.pathParameters['pacienteId']!)),
        routes: [
          GoRoute(
            path: 'painel',
            redirect: (context, state) => estado.usuario?.tipo == 'cuidador' ? null : '/painel',
            builder: (context, state) => PainelPaciente(pacienteId: int.parse(state.pathParameters['pacienteId']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/agenda',
        builder: (context, state) => const AgendaMedicamentos(),
      ),
      GoRoute(
        path: '/ciclos-encerrados',
        builder: (context, state) => const CiclosEncerrados(),
      ),
      GoRoute(
        path: '/historico',
        builder: (context, state) => const HistoricoPagina(),
      ),
      GoRoute(
        path: '/historico/:pacienteId',
        builder: (context, state) => HistoricoPagina(pacienteId: int.parse(state.pathParameters['pacienteId']!)),
      ),
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const EdicaoPerfil(),
      ),
      GoRoute(
        path: '/farmacias',
        builder: (context, state) => const Farmacias(),
      ),
      GoRoute(path: '/acessibilidade', builder: (context, state) => const Acessibilidade()),
      GoRoute(
        path: '/chat',
        // O assistente responde sobre os remédios do próprio paciente logado.
        redirect: (context, state) => estado.usuario?.tipo == 'cuidador' ? '/painel' : null,
        builder: (context, state) => const Chat(),
      ),
    ],
  );
}

class CuidaMedApp extends StatefulWidget {
  const CuidaMedApp({super.key});

  @override
  State<CuidaMedApp> createState() => _CuidaMedAppState();
}

class _CuidaMedAppState extends State<CuidaMedApp> {
  late final AppEstado _estado;
  late final GoRouter _router;
  late final MonitorAlertas _monitorAlertas;

  @override
  void initState() {
    super.initState();
    _estado = AppEstado();
    _router = _construirRouter(_estado);
    // "Lembrar agora" do cuidador e "Hora do remédio" — liga sozinho quando
    // um paciente entra e desliga ao sair (ver MonitorAlertas).
    final pacientes = PacienteServico();
    _monitorAlertas = MonitorAlertas(
      estado: _estado,
      buscarPaciente: pacientes.buscarPorId,
      confirmarAlertaManual: pacientes.confirmarAlertaManual,
      aoAlertar: dispararAlerta,
    );
    NotificacaoServico.instancia.inicializar();
    _estado.restaurarSessao();
    // Voltou pro app (ou pra aba do navegador): sincroniza na hora.
    _ciclo = AppLifecycleListener(onResume: _estado.sincronizarDados);
  }

  late final AppLifecycleListener _ciclo;

  @override
  void dispose() {
    _ciclo.dispose();
    _monitorAlertas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _estado,
      child: MaterialApp.router(
        title: 'CuidaMed',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: chaveMensageiroGlobal,
        theme: construirTema(),
        routerConfig: _router,
        // Tamanho da fonte escolhido no Perfil/Acessibilidade escala o texto
        // do app inteiro, por cima da preferência de acessibilidade do sistema.
        builder: aplicarEscalaFonte,
      ),
    );
  }
}
