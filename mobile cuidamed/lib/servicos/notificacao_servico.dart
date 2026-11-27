import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../estado/lembretes_agendados.dart';

enum PermissaoNotificacao { naoPerguntada, concedida, negada, indisponivel }

class NotificacaoServico {
  NotificacaoServico._();
  static final NotificacaoServico instancia = NotificacaoServico._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  AudioPlayer? _player;
  bool _inicializado = false;
  int _proximoId = 0;

  static const _canalAndroid = AndroidNotificationDetails(
    'lembretes_cuidamed',
    'Lembretes de medicamento',
    channelDescription: 'Hora do remédio e lembretes enviados pelo cuidador.',
    importance: Importance.max,
    priority: Priority.high,
  );

  Future<void> inicializar() async {
    if (_inicializado) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          web: WebInitializationSettings(),
        ),
      );
      _inicializado = true;
    } catch (erro) {
      debugPrint('Notificações indisponíveis: $erro');
    }
  }

  Future<PermissaoNotificacao> permissao() async {
    await inicializar();
    try {
      if (kIsWeb) {
        final web = _plugin.resolvePlatformSpecificImplementation<WebFlutterLocalNotificationsPlugin>();
        if (web == null || !WebFlutterLocalNotificationsPlugin.isSupported) return PermissaoNotificacao.indisponivel;
        return switch (web.permissionStatus) {
          WebNotificationPermission.granted => PermissaoNotificacao.concedida,
          WebNotificationPermission.denied => PermissaoNotificacao.negada,
          _ => PermissaoNotificacao.naoPerguntada,
        };
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final ativas = await android?.areNotificationsEnabled();
        return ativas == true ? PermissaoNotificacao.concedida : PermissaoNotificacao.naoPerguntada;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final opcoes = await ios?.checkPermissions();
        return opcoes?.isEnabled == true ? PermissaoNotificacao.concedida : PermissaoNotificacao.naoPerguntada;
      }
    } catch (_) {}
    return PermissaoNotificacao.indisponivel;
  }

  Future<PermissaoNotificacao> pedirPermissao() async {
    await inicializar();
    try {
      if (kIsWeb) {
        await _plugin.resolvePlatformSpecificImplementation<WebFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, sound: true);
      }
    } catch (_) {}
    await _prepararSom();
    return permissao();
  }

  Future<void> notificar(String titulo, String corpo) async {
    await inicializar();
    try {
      if (await permissao() != PermissaoNotificacao.concedida) return;
      await _plugin.show(
        id: _proximoId++,
        title: titulo,
        body: corpo,
        notificationDetails: const NotificationDetails(
          android: _canalAndroid,
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
          web: WebNotificationDetails(),
        ),
      );
    } catch (erro) {
      debugPrint('Falha ao notificar: $erro');
    }
  }

  Future<void> agendarLembretes(List<LembreteAgendado> lembretes) async {
    if (kIsWeb) return;
    await inicializar();
    try {
      await _plugin.cancelAllPendingNotifications();
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final exato = await android?.canScheduleExactNotifications() ?? true;
      for (final lembrete in lembretes) {
        await _plugin.zonedSchedule(
          id: lembrete.id,
          title: lembrete.titulo,
          body: lembrete.corpo,
          scheduledDate: tz.TZDateTime.from(lembrete.quando, tz.UTC),
          notificationDetails: const NotificationDetails(
            android: _canalAndroid,
            iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
          ),
          androidScheduleMode: exato ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (erro) {
      debugPrint('Falha ao agendar lembretes: $erro');
    }
  }

  Future<void> cancelarLembretes() async {
    if (kIsWeb) return;
    await inicializar();
    try {
      await _plugin.cancelAllPendingNotifications();
    } catch (_) {}
  }

  Future<void> _prepararSom() async {
    _player ??= AudioPlayer();
    try {
      await _player!.setSource(AssetSource('sons/alerta.wav'));
    } catch (_) {}
  }

  Future<void> tocarAlerta() async {
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.play(AssetSource('sons/alerta.wav'), volume: 1);
    } catch (erro) {
      debugPrint('Falha ao tocar alerta: $erro');
    }
  }
}
