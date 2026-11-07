import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'componentes/avisos_alerta.dart';
import 'estado/app_estado.dart';
import 'estado/lembretes_agendados.dart';
import 'estado/monitor_alertas.dart';
import 'paginas/acessibilidade.dart';
import 'paginas/agenda_medicamentos.dart';
import 'paginas/cadastro.dart';
import 'paginas/chat.dart';
import 'paginas/definir_senha.dart';
import 'paginas/detalhe_paciente.dart';
import 'paginas/edicao_perfil.dart';
import 'paginas/historico.dart';
import 'paginas/login.dart';
import 'paginas/painel_cuidador.dart';
import 'paginas/painel_idoso.dart';
import 'componentes/voltar_detalhes_paciente.dart';
import 'servicos/notificacao_servico.dart';
import 'servicos/paciente_servico.dart';
import 'utilitarios/tema.dart';

/// Multiplica a escala de texto do sistema pela preferência do usuário.
Widget aplicarEscalaFonte(BuildContext context, Widget? child) {
  // O tamanho escolhido vale só dentro do sistema: deslogado (login, cadastro
  // e ativação), as telas ficam sempre no tamanho padrão.
  final escala = context.select<AppEstado, double>((e) => e.autenticado ? e.escalaFonte : 1.0);
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
          // O antigo "Painel do paciente" agora faz parte dos detalhes do paciente.
          GoRoute(
            path: 'painel',
            redirect: (context, state) => '/cuidador/paciente/${state.pathParameters['pacienteId']}',
          ),
        ],
      ),
      GoRoute(
        path: '/agenda',
        builder: (context, state) => const AgendaMedicamentos(),
      ),
      // Tratamentos encerrados viraram a aba "Encerrados" da Agenda.
      GoRoute(
        path: '/ciclos-encerrados',
        redirect: (context, state) => '/agenda?aba=encerrados',
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
        path: '/configuracoes',
        builder: (context, state) => const EdicaoPerfil(),
      ),
      GoRoute(path: '/perfil', redirect: (context, state) => '/configuracoes'),
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
  late final LembretesAgendados _lembretes;

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
    // Lembretes de "Hora do remédio" agendados no celular: tocam com o app fechado.
    _lembretes = LembretesAgendados(
      estado: _estado,
      agendar: NotificacaoServico.instancia.agendarLembretes,
      cancelar: NotificacaoServico.instancia.cancelarLembretes,
    );
    _estado.addListener(_aplicarTema);
    _estado.restaurarSessao();
    // Voltou pro app (ou pra aba do navegador): vê se passou dos 7 dias sem uso
    // e, se continua logado, sincroniza na hora.
    _ciclo = AppLifecycleListener(
      onHide: () => _estado.emSegundoPlano = true,
      onShow: () => _estado.emSegundoPlano = false,
      onResume: () async {
        await _estado.verificarInatividade();
        if (_estado.autenticado) await _estado.sincronizarDados();
      },
    );
    // Com o app aberto o tempo todo, confere também de tempos em tempos.
    _relogioInatividade = Timer.periodic(const Duration(minutes: 10), (_) => _estado.verificarInatividade());
  }

  late final AppLifecycleListener _ciclo;
  late final Timer _relogioInatividade;

  /// Modo claro/escuro: troca a paleta do CorApp quando o tema efetivo muda
  /// (chave do menu, Configurações, login ou saída) e redesenha todas as telas
  /// já abertas — as cores são lidas no build, então basta reconstruir, sem
  /// perder o que está aberto (pilha de telas, formulários, rolagem).
  void _aplicarTema() {
    final escuro = _estado.usarModoEscuro;
    if (escuro == CorApp.escuro) return;
    CorApp.usarModoEscuro(escuro);
    if (!mounted) return;
    setState(() {}); // tema do MaterialApp (construirTema) com a paleta nova
    void marcar(Element elemento) {
      elemento.markNeedsBuild();
      elemento.visitChildren(marcar);
    }

    (context as Element).visitChildren(marcar);
  }

  @override
  void dispose() {
    _estado.removeListener(_aplicarTema);
    _relogioInatividade.cancel();
    _ciclo.dispose();
    _monitorAlertas.dispose();
    _lembretes.dispose();
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
        // Português do Brasil: calendários em dia/mês/ano e botões do sistema
        // ("Cancelar", "OK"...) em português.
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Tamanho da fonte escolhido no Perfil/Acessibilidade escala o texto
        // do app inteiro, por cima da preferência de acessibilidade do sistema.
        // Qualquer toque na tela conta como uso (saída após 7 dias sem uso).
        builder: (context, child) => Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _estado.registrarAtividade(),
          child: aplicarEscalaFonte(context, child),
        ),
      ),
    );
  }
}
