import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================================
// CONFIGURAÇÕES GLOBAIS E CHAVES DE SINCRONIZAÇÃO (APP <-> SITE FIREBASE)
// ============================================================================

const String kFirebaseDbUrl =
    'https://barbeariamrjone-f3e8a-default-rtdb.firebaseio.com';

const String kDefaultAdminPass = '1234';
const String kPrefAdminPass = 'mrjone_admin_pass';
const String kPrefLoggedIn = 'mrjone_logged_in';
const String kPrefKnownBookingKeys = 'mrjone_known_booking_keys';
const String kPrefSentExpiryReminders = 'mrjone_sent_expiry_reminders_v1';
const String kPrefExpediente = 'mrjone_expediente_v1';
const String kPrefPauses = 'mrjone_pauses_v1';
const String kPrefSlotStep = 'mrjone_slot_step_v1';

/// Expediente padrão idêntico à tela de configuração (Print 2)
final Map<String, Map<String, dynamic>> kDefaultExpediente = {
  '1': {
    'name': 'Segunda',
    'ativo': true,
    't1Inicio': '09:00',
    't1Fim': '12:00',
    't2Ativo': true,
    't2Inicio': '14:00',
    't2Fim': '18:30',
  },
  '2': {
    'name': 'Terça',
    'ativo': true,
    't1Inicio': '09:00',
    't1Fim': '12:00',
    't2Ativo': true,
    't2Inicio': '14:00',
    't2Fim': '19:30',
  },
  '3': {
    'name': 'Quarta',
    'ativo': true,
    't1Inicio': '09:00',
    't1Fim': '12:00',
    't2Ativo': true,
    't2Inicio': '14:00',
    't2Fim': '19:30',
  },
  '4': {
    'name': 'Quinta',
    'ativo': true,
    't1Inicio': '09:00',
    't1Fim': '12:00',
    't2Ativo': true,
    't2Inicio': '14:00',
    't2Fim': '19:30',
  },
  '5': {
    'name': 'Sexta',
    'ativo': true,
    't1Inicio': '08:00',
    't1Fim': '12:00',
    't2Ativo': true,
    't2Inicio': '14:00',
    't2Fim': '20:00',
  },
  '6': {
    'name': 'Sábado',
    'ativo': true,
    't1Inicio': '08:00',
    't1Fim': '12:00',
    't2Ativo': true,
    't2Inicio': '15:00',
    't2Fim': '20:00',
  },
  '0': {
    'name': 'Domingo',
    'ativo': true,
    't1Inicio': '09:00',
    't1Fim': '14:00',
    't2Ativo': false,
    't2Inicio': '14:00',
    't2Fim': '18:00',
  },
};

final List> kDefaultServices = [
  {
    'id': 'def_srv_1',
    'name': 'Cabelo e Barba (Combo Completo)',
    'category': 'Combos',
    'price': 65.0,
    'duration': 50,
    'isPlan': false,
    'sessionsPerMonth': 1,
    'active': true,
  },
  {
    'id': 'def_srv_2',
    'name': 'Corte Degradê / Disfarçado / Navalhado',
    'category': 'Cortes',
    'price': 40.0,
    'duration': 40,
    'isPlan': false,
    'sessionsPerMonth': 1,
    'active': true,
  },
  {
    'id': 'def_srv_3',
    'name': 'Corte (Um Pente Só)',
    'category': 'Cortes',
    'price': 35.0,
    'duration': 30,
    'isPlan': false,
    'sessionsPerMonth': 1,
    'active': true,
  },
  {
    'id': 'def_srv_4',
    'name': 'Barba Completa',
    'category': 'Barba & Acabamentos',
    'price': 30.0,
    'duration': 20,
    'isPlan': false,
    'sessionsPerMonth': 1,
    'active': true,
  },
  {
    'id': 'def_srv_5',
    'name': 'Sobrancelha',
    'category': 'Barba & Acabamentos',
    'price': 8.0,
    'duration': 10,
    'isPlan': false,
    'sessionsPerMonth': 1,
    'active': true,
  },
  {
    'id': 'def_srv_6',
    'name': 'Só Pezinho (Acabamento)',
    'category': 'Barba & Acabamentos',
    'price': 10.0,
    'duration': 15,
    'isPlan': false,
    'sessionsPerMonth': 1,
    'active': true,
  },
  {
    'id': 'def_srv_7',
    'name': 'Pigmentação',
    'category': 'Barba & Acabamentos',
    'price': 15.0,
    'duration': 15,
    'isPlan': false,
    'sessionsPerMonth': 1,
    'active': true,
  },
  {
    'id': 'def_srv_8',
    'name': 'Platinado ou Luzes + Corte',
    'category': 'Química',
    'price': 100.0,
    'duration': 60,
    'isPlan': false,
    'sessionsPerMonth': 1,
    'active': true,
  },
];

final List> kDefaultPlans = [
  {
    'id': 'def_pln_1',
    'name': 'Plano Mensal: Cabelo e Barba (Toda Semana)',
    'category': 'Planos Mensais',
    'price': 150.0,
    'duration': 50,
    'isPlan': true,
    'sessionsPerMonth': 4,
    'active': true,
  },
  {
    'id': 'def_pln_2',
    'name': 'Plano Mensal: Só Cabelo (Toda Semana)',
    'category': 'Planos Mensais',
    'price': 110.0,
    'duration': 40,
    'isPlan': true,
    'sessionsPerMonth': 4,
    'active': true,
  },
  {
    'id': 'def_pln_3',
    'name': 'Plano Mensal: Só Barba (Toda Semana)',
    'category': 'Planos Mensais',
    'price': 75.0,
    'duration': 20,
    'isPlan': true,
    'sessionsPerMonth': 4,
    'active': true,
  },
];

final List> kDefaultBarbers = [
  {
    'id': 'def_brb_jhonny',
    'name': 'Jhonny',
    'role': 'Proprietário / Barbeiro',
    'commission': 100.0,
    'active': true,
  },
  {
    'id': 'def_brb_marcelo',
    'name': 'Marcelo',
    'role': 'Barbeiro',
    'commission': 50.0,
    'active': true,
  },
];

final FlutterLocalNotificationsPlugin kNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ============================================================================
// FUNÇÕES UTILITÁRIAS DE NORMALIZAÇÃO E ANTI-DUPLICAÇÃO DEFINITIVA
// ============================================================================

String _normalizePhoneShared(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 10 && !digits.startsWith('55')) {
    return '55$digits';
  }
  return digits;
}

String _normalizeNameShared(String raw) {
  return raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String _normalizeTimeShared(String raw) {
  final clean = raw.trim();
  final parts = clean.split(':');
  if (parts.length >= 2) {
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h != null && m != null) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
  }
  return clean.toLowerCase();
}

String _normalizeDateShared(String raw) {
  final clean = raw.trim();
  final slash = clean.split('/');
  if (slash.length == 3) {
    final d = int.tryParse(slash[0].trim());
    final m = int.tryParse(slash[1].trim());
    int? y = int.tryParse(slash[2].trim());
    if (y != null && y < 100) y += 2000;
    if (d != null && m != null && y != null) {
      return '${d.toString().padLeft(2, '0')}/${m.toString().padLeft(2, '0')}/$y';
    }
  }
  final dash = clean.split('-');
  if (dash.length == 3) {
    final y = int.tryParse(dash[0].trim());
    final m = int.tryParse(dash[1].trim());
    final d = int.tryParse(dash[2].trim());
    if (d != null && m != null && y != null) {
      return '${d.toString().padLeft(2, '0')}/${m.toString().padLeft(2, '0')}/$y';
    }
  }
  return clean.toLowerCase();
}

/// Gera uma assinatura determinística por (Data + Horário + Barbeiro + Cliente/Telefone)
/// impedindo que o mesmo cliente apareça duplicado no mesmo horário vindo do site.
String _bookingDedupeKey(Map b, String firebaseKey) {
  final client = _normalizeNameShared((b['clientName'] ?? '').toString());
  final phone = _normalizePhoneShared(
    (b['clientPhone'] ?? b['phone'] ?? '').toString(),
  );
  final date =
      _normalizeDateShared((b['dateLabel'] ?? b['date'] ?? '').toString());
  final time = _normalizeTimeShared((b['time'] ?? '').toString());
  final barber = _normalizeNameShared((b['barberName'] ?? '').toString());

  if (date.isNotEmpty && time.isNotEmpty && (client.isNotEmpty || phone.isNotEmpty)) {
    final identityPart = phone.isNotEmpty ? phone : client;
    return 'slot:$date|$time|$barber|$identityPart';
  }

  final explicitId = (b['bookingId'] ?? b['clientBookingId'] ?? b['uid'] ?? '')
      .toString()
      .trim();
  if (explicitId.isNotEmpty) {
    return 'id:${explicitId.toLowerCase()}';
  }

  return 'fb:$firebaseKey';
}

int _bookingStatusPriority(Map b) {
  final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
  if (st == 'concluído' || st == 'concluido') return 4;
  if (st == 'confirmado') return 3;
  if (st == 'não concluído' || st == 'nao concluido') return 2;
  if (st == 'cancelado') return 1;
  return 0;
}

/// Consolida registros duplicados do Firebase em um único objeto limpo e guarda
/// os IDs redundantes em `_mergedFirebaseKeys` para limpeza automática no banco.
List> _deduplicateBookingsMap(Map decoded) {
  final Map<String, Map<String, dynamic>> byDedupe = {};

  decoded.forEach((key, val) {
    if (val is! Map) return;
    final k = key.toString();
    final item = Map<String, dynamic>.from(val);
    item['firebaseKey'] = k;

    final dKey = _bookingDedupeKey(item, k);
    final existing = byDedupe[dKey];

    if (existing == null) {
      item['_mergedFirebaseKeys'] = <String>[k];
      byDedupe[dKey] = item;
    } else {
      final prevPrio = _bookingStatusPriority(existing);
      final currPrio = _bookingStatusPriority(item);
      final prevUpdated =
          (existing['updatedAt'] ?? existing['createdAt'] ?? '').toString();
      final currUpdated =
          (item['updatedAt'] ?? item['createdAt'] ?? '').toString();

      final bool currentIsBetter = currPrio > prevPrio ||
          (currPrio == prevPrio && currUpdated.compareTo(prevUpdated) >= 0);

      final mergedKeys = <String>{
        ...((existing['_mergedFirebaseKeys'] as List?)
                ?.map((e) => e.toString()) ??
            [(existing['firebaseKey'] ?? '').toString()]),
        k,
      }.where((e) => e.isNotEmpty).toList();

      if (currentIsBetter) {
        item['_mergedFirebaseKeys'] = mergedKeys;
        byDedupe[dKey] = item;
      } else {
        existing['_mergedFirebaseKeys'] = mergedKeys;
      }
    }
  });

  final result = byDedupe.values.toList();
  result.sort((a, b) {
    final da = _normalizeDateShared((a['dateLabel'] ?? a['date'] ?? '').toString());
    final db = _normalizeDateShared((b['dateLabel'] ?? b['date'] ?? '').toString());
    if (da != db) return db.compareTo(da);
    final ta = _normalizeTimeShared((a['time'] ?? '').toString());
    final tb = _normalizeTimeShared((b['time'] ?? '').toString());
    return ta.compareTo(tb);
  });
  return result;
}
// ============================================================================
// NOTIFICAÇÕES LOCAIS & LEMBRETE AUTOMÁTICO DE VENCIMENTO DE PLANOS
// ============================================================================

Future<void> _initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await kNotificationsPlugin.initialize(initSettings);

  final androidImpl = kNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  const AndroidNotificationChannel bgChannel = AndroidNotificationChannel(
    'mrjone_bg_monitor',
    'Monitoramento Mr Jone',
    description: 'Mantém a monitorização ativa mesmo com o app fechado',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  const AndroidNotificationChannel bookingsChannel = AndroidNotificationChannel(
    'mrjone_bookings_channel',
    'Novos Agendamentos e Planos',
    description: 'Avisos de novos agendamentos e vencimentos de planos',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await androidImpl?.createNotificationChannel(bgChannel);
  await androidImpl?.createNotificationChannel(bookingsChannel);
  await androidImpl?.requestNotificationsPermission();
}

Future<void> _showBookingNotification(
  String title,
  String body,
  int id, {
  bool ongoing = false,
}) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    ongoing ? 'mrjone_bg_monitor' : 'mrjone_bookings_channel',
    ongoing ? 'Monitoramento Mr Jone' : 'Novos Agendamentos e Planos',
    channelDescription: ongoing
        ? 'Mantém a monitorização ativa mesmo com o app fechado'
        : 'Avisos de novos agendamentos e vencimentos de planos',
    importance: ongoing ? Importance.low : Importance.max,
    priority: ongoing ? Priority.low : Priority.high,
    playSound: !ongoing,
    enableVibration: !ongoing,
    ongoing: ongoing,
  );

  final NotificationDetails details =
      NotificationDetails(android: androidDetails);

  await kNotificationsPlugin.show(id, title, body, details);
}

DateTime? _parseDateShared(String raw) {
  final clean = raw.trim();
  if (clean.isEmpty) return null;
  final slash = clean.split('/');
  if (slash.length == 3) {
    final d = int.tryParse(slash[0].trim());
    final m = int.tryParse(slash[1].trim());
    int? y = int.tryParse(slash[2].trim());
    if (y != null && y < 100) y += 2000;
    if (d != null && m != null && y != null) {
      return DateTime(y, m, d);
    }
  }
  final dash = clean.split('-');
  if (dash.length == 3) {
    final y = int.tryParse(dash[0].trim());
    final m = int.tryParse(dash[1].trim());
    final d = int.tryParse(dash[2].trim());
    if (d != null && m != null && y != null) {
      return DateTime(y, m, d);
    }
  }
  return null;
}

String _formatDateBRShared(DateTime dt) {
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  return '$dd/$mm/${dt.year}';
}
Future<void> _upsertClientRemote({
  required String name,
  required String phone,
  String? bookingDate,
  String? bookingTime,
  bool incrementCount = false,
}) async {
  final cleanName = name.trim();
  final normPhone = _normalizePhoneShared(phone);
  if (cleanName.isEmpty && normPhone.isEmpty) return;

  try {
    final cliRes = await http.get(Uri.parse('$kFirebaseDbUrl/clients.json'));
    String? existingKey;
    Map existingData = {};

    if (cliRes.statusCode == 200 && cliRes.body != 'null') {
      final d = jsonDecode(cliRes.body);
      if (d is Map) {
        for (final entry in d.entries) {
          if (entry.value is! Map) continue;
          final c = entry.value as Map;
          final cPhone = _normalizePhoneShared((c['phone'] ?? '').toString());
          final cName = _normalizeNameShared((c['name'] ?? '').toString());
          if ((normPhone.isNotEmpty && cPhone == normPhone) ||
              (normPhone.isEmpty &&
                  cleanName.isNotEmpty &&
                  cName == _normalizeNameShared(cleanName))) {
            existingKey = entry.key.toString();
            existingData = Map.from(c);
            break;
          }
        }
      }
    }

    final int prevBookings =
        int.tryParse('${existingData['totalBookings'] ?? 0}') ?? 0;

    final Map<String, dynamic> payload = {
      'name': cleanName.isNotEmpty
          ? cleanName
          : (existingData['name'] ?? 'Cliente').toString(),
      'phone': normPhone.isNotEmpty
          ? normPhone
          : (existingData['phone'] ?? phone).toString(),
      'lastBookingDate': (bookingDate != null && bookingDate.isNotEmpty)
          ? bookingDate
          : (existingData['lastBookingDate'] ?? '').toString(),
      'lastBookingTime': (bookingTime != null && bookingTime.isNotEmpty)
          ? bookingTime
          : (existingData['lastBookingTime'] ?? '').toString(),
      'totalBookings': incrementCount ? prevBookings + 1 : prevBookings,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (existingKey != null && existingKey.isNotEmpty) {
      await http.patch(
        Uri.parse('$kFirebaseDbUrl/clients/$existingKey.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } else {
      payload['createdAt'] = DateTime.now().toIso8601String();
      payload['totalBookings'] = incrementCount ? 1 : 0;
      await http.post(
        Uri.parse('$kFirebaseDbUrl/clients.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    }
  } catch (_) {}
}

/// Atualiza o status de cada membro do plano no Firebase para que o SITE
/// saiba em tempo real quem está ativo (só vê o plano) e quem está vencido (vê avulso).
Future<void> _syncPlanRulesToSiteRemote() async {
  try {
    final memRes =
        await http.get(Uri.parse('$kFirebaseDbUrl/plan_members.json'));
    if (memRes.statusCode != 200 || memRes.body == 'null') return;

    final decoded = jsonDecode(memRes.body);
    if (decoded is! Map) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<String, dynamic> siteIndexByPhone = {};
    final Map<String, dynamic> siteIndexByName = {};

    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      final key = entry.key.toString();
      final m = Map<String, dynamic>.from(entry.value as Map);
      final expDt = _parseDateShared((m['expiresAt'] ?? '').toString());
      final bool isExpired = expDt != null && expDt.isBefore(today);
      final bool isActive = (m['active'] != false) && !isExpired;

      final String allowedMode = isActive ? 'plan_only' : 'avulso_only';
      final bool blockAvulso = isActive;

      await http.patch(
        Uri.parse('$kFirebaseDbUrl/plan_members/$key.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'isExpired': isExpired,
          'isValidNow': isActive,
          'blockAvulsoOnSite': blockAvulso,
          'allowedModeOnSite': allowedMode,
          'lastCheckedAt': DateTime.now().toIso8601String(),
        }),
      );

      final normPhone = _normalizePhoneShared((m['phone'] ?? '').toString());
      final normName = _normalizeNameShared((m['clientName'] ?? '').toString());
      final ruleObj = {
        'memberId': key,
        'clientName': (m['clientName'] ?? '').toString(),
        'phone': normPhone,
        'planId': (m['planId'] ?? '').toString(),
        'planName': (m['planName'] ?? '').toString(),
        'planPrice': m['planPrice'] ?? 0,
        'expiresAt': (m['expiresAt'] ?? '').toString(),
        'isValidNow': isActive,
        'blockAvulso': blockAvulso,
        'allowedMode': allowedMode,
      };
      if (normPhone.isNotEmpty) siteIndexByPhone[normPhone] = ruleObj;
      if (normName.isNotEmpty) siteIndexByName[normName] = ruleObj;
    }

    await http.put(
      Uri.parse('$kFirebaseDbUrl/site_plan_rules.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'byPhone': siteIndexByPhone,
        'byName': siteIndexByName,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
  } catch (_) {}
}
 bool _bgChecking = false;

Future<void> _checkPlanExpiryRemindersBg(SharedPreferences prefs) async {
  try {
    final memRes =
        await http.get(Uri.parse('$kFirebaseDbUrl/plan_members.json'));
    if (memRes.statusCode != 200 || memRes.body == 'null') return;

    final decoded = jsonDecode(memRes.body);
    if (decoded is! Map) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = _formatDateBRShared(today);

    final sentList = prefs.getStringList(kPrefSentExpiryReminders) ?? [];
    final sentSet = sentList.toSet();
    int notifId = 900;

    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      final key = entry.key.toString();
      final m = Map<String, dynamic>.from(entry.value as Map);
      if (m['active'] == false) continue;

      final expDt = _parseDateShared((m['expiresAt'] ?? '').toString());
      if (expDt == null) continue;
      final expiry = DateTime(expDt.year, expDt.month, expDt.day);
      final int daysLeft = expiry.difference(today).inDays;

      // Dispara lembrete automático quando faltar 3 dias, 1 dia ou vencer hoje
      if (daysLeft == 3 || daysLeft == 1 || daysLeft == 0) {
        final dedupeReminderKey = '$key|$todayStr|d$daysLeft';
        if (sentSet.contains(dedupeReminderKey)) continue;

        final clientName = (m['clientName'] ?? 'Cliente').toString();
        final planName = (m['planName'] ?? 'Plano Mensal').toString();
        final expStr = _formatDateBRShared(expiry);
        final phone = _normalizePhoneShared((m['phone'] ?? '').toString());

        final String msgText = daysLeft == 0
            ? 'Olá $clientName! Seu *$planName* na *Barbearia Mr Jone* vence *HOJE ($expStr)*. Renove agora para continuar com seu benefício ativo!'
            : 'Olá $clientName! Lembrete automático da *Barbearia Mr Jone*: seu *$planName* vence em *$daysLeft dia(s)* ($expStr).';

        final encodedMsg = Uri.encodeComponent(msgText);
        final String waLink = phone.length >= 12
            ? 'https://api.whatsapp.com/send?phone=$phone&text=$encodedMsg'
            : 'https://api.whatsapp.com/send?text=$encodedMsg';

        // Grava fila automática no Firebase para disparo integrado / registro
        await http.post(
          Uri.parse('$kFirebaseDbUrl/auto_reminders_queue.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'memberId': key,
            'clientName': clientName,
            'phone': phone,
            'planName': planName,
            'expiresAt': expStr,
            'daysLeft': daysLeft,
            'message': msgText,
            'whatsappUrl': waLink,
            'status': 'disparado_automatico',
            'createdAt': DateTime.now().toIso8601String(),
          }),
        );

        await http.patch(
          Uri.parse('$kFirebaseDbUrl/plan_members/$key.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'lastReminderSentAt': DateTime.now().toIso8601String(),
            'lastReminderDaysLeft': daysLeft,
          }),
        );

        await _showBookingNotification(
          'Vencimento de Plano • $clientName',
          daysLeft == 0
              ? '$planName vence HOJE ($expStr)! Lembrete automático enviado.'
              : '$planName vence em $daysLeft dia(s) ($expStr).',
          notifId++,
        );

        sentSet.add(dedupeReminderKey);
      }
    }

    await prefs.setStringList(kPrefSentExpiryReminders, sentSet.toList());
  } catch (_) {}
}

@pragma('vm:entry-point')
void _onStartBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await _initNotifications();

  Future<void> checkNewBookingsBg() async {
    if (_bgChecking) return;
    _bgChecking = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(kPrefKnownBookingKeys) ?? [];
      final knownSet = savedList.toSet();

      final uri = Uri.parse(
        '$kFirebaseDbUrl/bookings.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200 && res.body != 'null') {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) {
          final deduped = _deduplicateBookingsMap(decoded);
          final List<String> currentSignatures = [];
          final List> brandNew = [];

          for (final item in deduped) {
            final fKey = (item['firebaseKey'] ?? '').toString();
            final sig = _bookingDedupeKey(item, fKey);
            currentSignatures.add(sig);
            currentSignatures.add('fb:$fKey');

            final alreadyKnown =
                knownSet.contains(sig) || knownSet.contains('fb:$fKey');
            if (savedList.isNotEmpty && !alreadyKnown) {
              brandNew.add(item);
            }
          }

          int notifId = 500;
          for (final novo in brandNew) {
            final client = (novo['clientName'] ?? 'Cliente').toString();
            final phone =
                (novo['clientPhone'] ?? novo['phone'] ?? '').toString();
            final dateLbl =
                (novo['dateLabel'] ?? novo['date'] ?? '').toString();
            final timeLbl = (novo['time'] ?? '').toString();
            final barber =
                (novo['barberName'] ?? 'Barbearia Mr Jone').toString();

            await _upsertClientRemote(
              name: client,
              phone: phone,
              bookingDate: dateLbl,
              bookingTime: timeLbl,
              incrementCount: true,
            );

            await _showBookingNotification(
              'Novo agendamento • $client',
              '$dateLbl às $timeLbl ($barber)',
              notifId++,
            );
          }

          await prefs.setStringList(
            kPrefKnownBookingKeys,
            currentSignatures.toSet().toList(),
          );
        }
      }

      await _syncPlanRulesToSiteRemote();
      await _checkPlanExpiryRemindersBg(prefs);
    } catch (_) {
    } finally {
      _bgChecking = false;
    }
  }

  await checkNewBookingsBg();

  Timer.periodic(const Duration(seconds: 30), (_) async {
    await checkNewBookingsBg();
  });
}

Future<void> _initBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStartBackground,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'mrjone_bg_monitor',
      initialNotificationTitle: 'Barbearia Mr Jone • Gestão Ativa',
      initialNotificationContent:
          'Sincronizando agenda, planos e lembretes automáticos',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: _onStartBackground,
    ),
  );
  await service.startService();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initNotifications();
  await _initBackgroundService();
  runApp(const MrJoneGestaoApp());
}
 class MrJoneGestaoApp extends StatelessWidget {
  const MrJoneGestaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barbearia Mr Jone • Gestão Completa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0B0C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFF3D97E),
          surface: Color(0xFF141417),
        ),
      ),
      home: const GestaoHomePage(),
    );
  }
}

class GestaoHomePage extends StatefulWidget {
  const GestaoHomePage({super.key});

  @override
  State<GestaoHomePage> createState() => _GestaoHomePageState();
}

class _GestaoHomePageState extends State<GestaoHomePage> {
  bool _unlocked = false;
  bool _loading = false;
  bool _fetchingBookings = false;
  int _tabIndex = 0;

  bool _onlyCompletedInAccounting = true;
  String _accountingPeriodFilter = 'diario';
  String _barberReportPeriod = 'mensal';

  DateTime _gridSelectedDate = DateTime.now();
  String _gridSelectedBarberFilter = 'TODOS';
  String _clientSearchQuery = '';

  String _statusMsg = 'A aguardar ligação ao Firebase';
  String _adminPass = kDefaultAdminPass;
  int _slotStepMinutes = 15;

  final TextEditingController _passController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final Map<String, TextEditingController> _expControllers = {};

  Map<String, Map<String, dynamic>> _expediente = {};
  List> _pauses = [];
  List> _bookings = [];
  List> _newAlerts = [];
  List> _services = [];
  List> _plans = [];
  List> _barbers = [];
  List> _clients = [];
  List> _planMembers = [];

  final Set<String> _knownSignatures = {};
  bool _firstLoadDone = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _services =
        kDefaultServices.map((e) => Map<String, dynamic>.from(e)).toList();
    _plans = kDefaultPlans.map((e) => Map<String, dynamic>.from(e)).toList();
    _barbers =
        kDefaultBarbers.map((e) => Map<String, dynamic>.from(e)).toList();
    _expediente = _cloneDefaultExpediente();
    _rebuildExpedienteControllers();
    _loadSavedSessionAndPass();
  }

  Map<String, Map<String, dynamic>> _cloneDefaultExpediente() {
    final Map<String, Map<String, dynamic>> copy = {};
    kDefaultExpediente.forEach((k, v) {
      copy[k] = Map<String, dynamic>.from(v);
    });
    return copy;
  }

  void _rebuildExpedienteControllers() {
    for (final c in _expControllers.values) {
      c.dispose();
    }
    _expControllers.clear();

    for (final d in ['1', '2', '3', '4', '5', '6', '0']) {
      final info = _expediente[d] ?? {};
      _expControllers['${d}_t1Ini'] =
          TextEditingController(text: (info['t1Inicio'] ?? '09:00').toString());
      _expControllers['${d}_t1Fim'] =
          TextEditingController(text: (info['t1Fim'] ?? '12:00').toString());
      _expControllers['${d}_t2Ini'] =
          TextEditingController(text: (info['t2Inicio'] ?? '14:00').toString());
      _expControllers['${d}_t2Fim'] =
          TextEditingController(text: (info['t2Fim'] ?? '19:30').toString());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _passController.dispose();
    _newPassController.dispose();
    for (final c in _expControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _startActiveSession() {
    _syncAll();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _fetchBookings(silent: true),
    );
  }
      Future<void> _loadSavedSessionAndPass() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPass = prefs.getString(kPrefAdminPass);
    final wasLoggedIn = prefs.getBool(kPrefLoggedIn) ?? false;
    final savedStep = prefs.getInt(kPrefSlotStep) ?? 15;
    final savedExpRaw = prefs.getString(kPrefExpediente);
    final savedPausesRaw = prefs.getString(kPrefPauses);

    Map<String, Map<String, dynamic>> loadedExp = _cloneDefaultExpediente();
    if (savedExpRaw != null && savedExpRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedExpRaw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (v is Map && loadedExp.containsKey(k.toString())) {
              loadedExp[k.toString()] = {
                ...loadedExp[k.toString()]!,
                ...Map<String, dynamic>.from(v),
              };
            }
          });
        }
      } catch (_) {}
    }

    List> loadedPauses = [];
    if (savedPausesRaw != null && savedPausesRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedPausesRaw);
        if (decoded is List) {
          loadedPauses = decoded
              .whereType()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      if (savedPass != null && savedPass.trim().isNotEmpty) {
        _adminPass = savedPass.trim();
      }
      _newPassController.text = _adminPass;
      _slotStepMinutes = savedStep;
      _expediente = loadedExp;
      _pauses = loadedPauses;
      _unlocked = wasLoggedIn;
    });
    _rebuildExpedienteControllers();

    if (wasLoggedIn) {
      _startActiveSession();
    }
  }

  /// Publica todas as configurações do App no nó `/site_config` e nós individuais
  /// do Firebase para que o site reflita imediatamente cada alteração feita aqui.
  Future<void> _publishAllConfigToSite() async {
    try {
      await Future.wait([
        http.put(
          Uri.parse('$kFirebaseDbUrl/expediente.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_expediente),
        ),
        http.put(
          Uri.parse('$kFirebaseDbUrl/slotStepMinutes.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_slotStepMinutes),
        ),
        http.put(
          Uri.parse('$kFirebaseDbUrl/pauses.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_pauses),
        ),
        http.put(
          Uri.parse('$kFirebaseDbUrl/site_config.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'expediente': _expediente,
            'pauses': _pauses,
            'slotStepMinutes': _slotStepMinutes,
            'services': _services.where((s) => s['active'] != false).toList(),
            'plans': _plans.where((p) => p['active'] != false).toList(),
            'barbers': _barbers.where((b) => b['active'] != false).toList(),
            'enforcePlanRules': true,
            'updatedAt': DateTime.now().toIso8601String(),
          }),
        ),
      ]);
      await _syncPlanRulesToSiteRemote();
    } catch (_) {}
  }

  Future<void> _saveExpedienteAndSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefExpediente, jsonEncode(_expediente));
    await prefs.setInt(kPrefSlotStep, _slotStepMinutes);
    await _publishAllConfigToSite();
  }

  Future<void> _savePausesAndSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefPauses, jsonEncode(_pauses));
    await _publishAllConfigToSite();
  }

  Future<void> _fetchRemoteSettings() async {
    try {
      final expRes =
          await http.get(Uri.parse('$kFirebaseDbUrl/expediente.json'));
      if (expRes.statusCode == 200 && expRes.body != 'null') {
        final decoded = jsonDecode(expRes.body);
        if (decoded is Map) {
          final merged = _cloneDefaultExpediente();
          decoded.forEach((k, v) {
            if (v is Map && merged.containsKey(k.toString())) {
              merged[k.toString()] = {
                ...merged[k.toString()]!,
                ...Map<String, dynamic>.from(v),
              };
            }
          });
          if (mounted) {
            setState(() => _expediente = merged);
            _rebuildExpedienteControllers();
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(kPrefExpediente, jsonEncode(merged));
        }
      }

      final pausesRes =
          await http.get(Uri.parse('$kFirebaseDbUrl/pauses.json'));
      if (pausesRes.statusCode == 200 && pausesRes.body != 'null') {
        final decoded = jsonDecode(pausesRes.body);
        if (decoded is List) {
          final listP = decoded
              .whereType()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (mounted) setState(() => _pauses = listP);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(kPrefPauses, jsonEncode(listP));
        }
      }

      final stepRes =
          await http.get(Uri.parse('$kFirebaseDbUrl/slotStepMinutes.json'));
      if (stepRes.statusCode == 200 && stepRes.body != 'null') {
        final parsedStep = int.tryParse(stepRes.body.replaceAll('"', ''));
        if (parsedStep != null && parsedStep > 0 && mounted) {
          setState(() => _slotStepMinutes = parsedStep);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(kPrefSlotStep, parsedStep);
        }
      }
    } catch (_) {}
  }
      Future<void> _saveNewAdminPass(String newPass) async {
    final clean = newPass.trim();
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduza uma palavra-passe válida.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefAdminPass, clean);
    if (!mounted) return;
    setState(() {
      _adminPass = clean;
      _newPassController.text = clean;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nova palavra-passe guardada com sucesso!')),
    );
  }

  Future<void> _checkPass() async {
    if (_passController.text.trim() == _adminPass) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kPrefLoggedIn, true);
      if (!mounted) return;
      setState(() => _unlocked = true);
      _startActiveSession();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Palavra-passe incorreta.')),
      );
    }
  }

  Future<void> _logoutAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefLoggedIn, false);
    _pollTimer?.cancel();
    _passController.clear();
    if (!mounted) return;
    setState(() {
      _unlocked = false;
      _tabIndex = 0;
    });
  }

  String _normalizePhone(String raw) => _normalizePhoneShared(raw);

  Future<void> _upsertClientFromBooking({
    required String name,
    required String phone,
    String? bookingDate,
    String? bookingTime,
    bool incrementCount = false,
  }) async {
    await _upsertClientRemote(
      name: name,
      phone: phone,
      bookingDate: bookingDate,
      bookingTime: bookingTime,
      incrementCount: incrementCount,
    );
    await _fetchClientsAndPlanMembers();
  }

  Future<void> _fetchClientsAndPlanMembers() async {
    try {
      final cliRes = await http.get(Uri.parse('$kFirebaseDbUrl/clients.json'));
      final memRes =
          await http.get(Uri.parse('$kFirebaseDbUrl/plan_members.json'));

      final Map<String, Map<String, dynamic>> uniqueClients = {};
      final List> memList = [];

      if (cliRes.statusCode == 200 && cliRes.body != 'null') {
        final d = jsonDecode(cliRes.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = Map<String, dynamic>.from(v);
              item['id'] = k.toString();
              final pNorm = _normalizePhone((item['phone'] ?? '').toString());
              final nNorm = _normalizeNameShared((item['name'] ?? '').toString());
              final cKey = pNorm.isNotEmpty ? 'ph:$pNorm' : 'nm:$nNorm';
              if (!uniqueClients.containsKey(cKey)) {
                uniqueClients[cKey] = item;
              } else {
                final prevCount = int.tryParse(
                        '${uniqueClients[cKey]!['totalBookings'] ?? 0}') ??
                    0;
                final currCount =
                    int.tryParse('${item['totalBookings'] ?? 0}') ?? 0;
                if (currCount > prevCount) {
                  uniqueClients[cKey] = {
                    ...uniqueClients[cKey]!,
                    ...item,
                    'totalBookings': currCount,
                  };
                }
              }
            }
          });
        }
      }

      if (memRes.statusCode == 200 && memRes.body != 'null') {
        final d = jsonDecode(memRes.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = Map<String, dynamic>.from(v);
              item['id'] = k.toString();
              memList.add(item);
            }
          });
        }
      }

      final cliList = uniqueClients.values.toList();
      cliList.sort((a, b) => (a['name'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['name'] ?? '').toString().toLowerCase()));

      memList.sort((a, b) => (a['clientName'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['clientName'] ?? '').toString().toLowerCase()));

      if (!mounted) return;
      setState(() {
        _clients = cliList;
        _planMembers = memList;
      });
    } catch (_) {}
  }

  Future<void> _syncAll() async {
    setState(() {
      _loading = true;
      _statusMsg = 'A sincronizar dados com o Firebase...';
    });
    await Future.wait([
      _fetchBookings(silent: true),
      _fetchCatalog(),
      _fetchBarbers(),
      _fetchClientsAndPlanMembers(),
      _fetchRemoteSettings(),
    ]);
    await _publishAllConfigToSite();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _statusMsg =
          'Sincronizado • ${_bookings.length} marcação(ões) • ${_clients.length} cliente(s) • ${_planMembers.length} no plano';
    });
  }

  Future<void> _fetchBookings({bool silent = false}) async {
    if (_fetchingBookings) return;
    _fetchingBookings = true;

    if (!silent) {
      setState(() {
        _loading = true;
        _statusMsg = 'A sincronizar marcações...';
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKeys = prefs.getStringList(kPrefKnownBookingKeys) ?? [];
      _knownSignatures.addAll(savedKeys);

      final uri = Uri.parse(
        '$kFirebaseDbUrl/bookings.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List> loaded = [];
        final List> brandNew = [];
        final Set<String> allSignatures = {};

        if (res.body != 'null') {
          final decoded = jsonDecode(res.body);
          if (decoded is Map) {
            final deduped = _deduplicateBookingsMap(decoded);

            for (final item in deduped) {
              // Se o site gerou duplicatas no Firebase, limpa os nós redundantes
              final mergedKeys = (item['_mergedFirebaseKeys'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];
              if (mergedKeys.length > 1) {
                for (final extraKey in mergedKeys.skip(1)) {
                  unawaited(http.delete(
                      Uri.parse('$kFirebaseDbUrl/bookings/$extraKey.json')));
                }
                item['_mergedFirebaseKeys'] = [mergedKeys.first];
              }

              final fKey = (item['firebaseKey'] ?? '').toString();
              final sig = _bookingDedupeKey(item, fKey);
              allSignatures.add(sig);
              allSignatures.add('fb:$fKey');

              final alreadyKnown = _knownSignatures.contains(sig) ||
                  _knownSignatures.contains('fb:$fKey');

              if (_firstLoadDone && !alreadyKnown) {
                brandNew.add(item);
              }

              _knownSignatures.add(sig);
              _knownSignatures.add('fb:$fKey');
              loaded.add(item);
            }
          }
        }

        await prefs.setStringList(
          kPrefKnownBookingKeys,
          allSignatures.toList(),
        );
        _firstLoadDone = true;

        int notifId = 100;
        for (final novo in brandNew) {
          final client = (novo['clientName'] ?? 'Cliente').toString();
          final phone =
              (novo['clientPhone'] ?? novo['phone'] ?? '').toString();
          final dateLbl =
              (novo['dateLabel'] ?? novo['date'] ?? '').toString();
          final timeLbl = (novo['time'] ?? '').toString();
          final barber =
              (novo['barberName'] ?? 'Barbearia Mr Jone').toString();

          await _upsertClientFromBooking(
            name: client,
            phone: phone,
            bookingDate: dateLbl,
            bookingTime: timeLbl,
            incrementCount: true,
          );

          await _showBookingNotification(
            'Nova marcação • $client',
            '$dateLbl às $timeLbl ($barber)',
            notifId++,
          );
        }

        if (!mounted) return;
        setState(() {
          _bookings = loaded;
          if (brandNew.isNotEmpty) {
            _newAlerts = [...brandNew, ..._newAlerts];
          }
          _statusMsg = 'Online • ${loaded.length} registo(s) único(s)';
        });
      } else {
        if (!mounted) return;
        setState(() => _statusMsg = 'Erro HTTP ${res.statusCode}');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusMsg = 'Falha de rede ao ler Firebase');
    } finally {
      _fetchingBookings = false;
      if (mounted && !silent) {
        setState(() => _loading = false);
      }
    }
  }
      Future<void> _fetchCatalog() async {
    try {
      final srvRes = await http.get(Uri.parse('$kFirebaseDbUrl/services.json'));
      final plnRes = await http.get(Uri.parse('$kFirebaseDbUrl/plans.json'));

      final List> srvList = [];
      final List> plnList = [];

      if (srvRes.statusCode == 200 && srvRes.body != 'null') {
        final d = jsonDecode(srvRes.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = Map<String, dynamic>.from(v);
              item['id'] = k.toString();
              srvList.add(item);
            }
          });
        } else if (d is List) {
          for (var i = 0; i < d.length; i++) {
            if (d[i] is Map) {
              final item = Map<String, dynamic>.from(d[i] as Map);
              item['id'] = i.toString();
              srvList.add(item);
            }
          }
        }
      }

      if (plnRes.statusCode == 200 && plnRes.body != 'null') {
        final d = jsonDecode(plnRes.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = Map<String, dynamic>.from(v);
              item['id'] = k.toString();
              plnList.add(item);
            }
          });
        } else if (d is List) {
          for (var i = 0; i < d.length; i++) {
            if (d[i] is Map) {
              final item = Map<String, dynamic>.from(d[i] as Map);
              item['id'] = i.toString();
              plnList.add(item);
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _services = srvList.isNotEmpty
            ? srvList
            : kDefaultServices
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
        _plans = plnList.isNotEmpty
            ? plnList
            : kDefaultPlans.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (_) {}
  }

  Future<void> _fetchBarbers() async {
    try {
      final res = await http.get(Uri.parse('$kFirebaseDbUrl/barbers.json'));
      final List> list = [];
      if (res.statusCode == 200 && res.body != 'null') {
        final d = jsonDecode(res.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = Map<String, dynamic>.from(v);
              item['id'] = k.toString();
              final nm = _normalizeNameShared((item['name'] ?? '').toString());
              if (nm == 'jhonny' || nm == 'mr. jone' || nm == 'mr jone') {
                item['commission'] = 100.0;
              } else if (nm == 'marcelo') {
                item['commission'] =
                    double.tryParse('${item['commission'] ?? 50.0}') ?? 50.0;
              }
              list.add(item);
            }
          });
        } else if (d is List) {
          for (var i = 0; i < d.length; i++) {
            if (d[i] is Map) {
              final item = Map<String, dynamic>.from(d[i] as Map);
              item['id'] = i.toString();
              list.add(item);
            }
          }
        }
      }

      final hasJhonny = list.any((b) =>
          _normalizeNameShared((b['name'] ?? '').toString()) == 'jhonny');
      final hasMarcelo = list.any((b) =>
          _normalizeNameShared((b['name'] ?? '').toString()) == 'marcelo');

      if (!hasJhonny) {
        list.insert(0, Map<String, dynamic>.from(kDefaultBarbers[0]));
      }
      if (!hasMarcelo) {
        list.add(Map<String, dynamic>.from(kDefaultBarbers[1]));
      }

      if (!mounted) return;
      setState(() => _barbers = list);
    } catch (_) {}
  }

  DateTime? _parseDateString(String raw) => _parseDateShared(raw);

  String _formatDateBR(DateTime dt) => _formatDateBRShared(dt);

  String _weekdayFullName(DateTime dt) {
    final key = _expedienteKeyForDate(dt);
    final name = (_expediente[key]?['name'] ?? '').toString();
    if (name.isNotEmpty) return name;
    const names = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    return names[(dt.weekday - 1).clamp(0, 6)];
  }

  Map<String, dynamic>? _findPlanMember({
    String? clientName,
    String? clientPhone,
  }) {
    final normPhone = _normalizePhone(clientPhone ?? '');
    final cleanName = _normalizeNameShared(clientName ?? '');

    for (final m in _planMembers) {
      final mPhone = _normalizePhone((m['phone'] ?? '').toString());
      final mName = _normalizeNameShared((m['clientName'] ?? '').toString());

      if (normPhone.isNotEmpty && mPhone.isNotEmpty && normPhone == mPhone) {
        return m;
      }
      if (cleanName.isNotEmpty && mName.isNotEmpty && cleanName == mName) {
        return m;
      }
    }
    return null;
  }

  bool _isPlanMemberValid(Map member) {
    if (member['active'] == false) return false;
    final expDt = _parseDateString((member['expiresAt'] ?? '').toString());
    if (expDt == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expDt.year, expDt.month, expDt.day);
    return !expiry.isBefore(today);
  }

  /// Se o cliente tem plano VÁLIDO -> retorna SOMENTE o plano (bloqueia avulso).
  /// Se o plano VENCEU -> retorna SOMENTE os preços avulsos (libera avulso e bloqueia plano).
  List> _allowedCatalogOptions({
    String? clientName,
    String? clientPhone,
  }) {
    final member = _findPlanMember(
      clientName: clientName,
      clientPhone: clientPhone,
    );

    if (member != null) {
      if (_isPlanMemberValid(member)) {
        final assignedPlanName =
            _normalizeNameShared((member['planName'] ?? '').toString());
        final List> planOnly = [];

        for (final p in _plans) {
          if (p['active'] == false) continue;
          final pName = (p['name'] ?? '').toString();
          final pNorm = _normalizeNameShared(pName);
          if (assignedPlanName.isEmpty ||
              pNorm == assignedPlanName ||
              pNorm.contains(assignedPlanName) ||
              assignedPlanName.contains(pNorm)) {
            planOnly.add({
              'id': (p['id'] ?? '').toString(),
              'name': pName,
              'price': double.tryParse('${p['price'] ?? 0}') ?? 0.0,
              'duration': int.tryParse('${p['duration'] ?? 40}') ?? 40,
              'isPlan': true,
              'sessionsPerMonth':
                  int.tryParse('${p['sessionsPerMonth'] ?? 4}') ?? 4,
              'mode': 'plan_only',
            });
          }
        }

        if (planOnly.isNotEmpty) return planOnly;

        return [
          {
            'id': (member['planId'] ?? '').toString(),
            'name': (member['planName'] ?? 'Plano Mensal').toString(),
            'price': double.tryParse('${member['planPrice'] ?? 0}') ?? 0.0,
            'duration': int.tryParse('${member['duration'] ?? 40}') ?? 40,
            'isPlan': true,
            'sessionsPerMonth':
                int.tryParse('${member['sessionsPerMonth'] ?? 4}') ?? 4,
            'mode': 'plan_only',
          }
        ];
      } else {
        final List> avulsosOnly = [];
        for (final s in _services) {
          if (s['active'] == false) continue;
          avulsosOnly.add({
            'id': (s['id'] ?? '').toString(),
            'name': (s['name'] ?? '').toString(),
            'price': double.tryParse('${s['price'] ?? 0}') ?? 0.0,
            'duration': int.tryParse('${s['duration'] ?? 30}') ?? 30,
            'isPlan': false,
            'sessionsPerMonth': 1,
            'mode': 'expired_avulso_only',
          });
        }
        return avulsosOnly;
      }
    }

    final List> all = [];
    for (final s in _services) {
      if (s['active'] == false) continue;
      all.add({
        'id': (s['id'] ?? '').toString(),
        'name': (s['name'] ?? '').toString(),
        'price': double.tryParse('${s['price'] ?? 0}') ?? 0.0,
        'duration': int.tryParse('${s['duration'] ?? 30}') ?? 30,
        'isPlan': false,
        'sessionsPerMonth': 1,
        'mode': 'normal',
      });
    }
    for (final p in _plans) {
      if (p['active'] == false) continue;
      all.add({
        'id': (p['id'] ?? '').toString(),
        'name': (p['name'] ?? '').toString(),
        'price': double.tryParse('${p['price'] ?? 0}') ?? 0.0,
        'duration': int.tryParse('${p['duration'] ?? 40}') ?? 40,
        'isPlan': true,
        'sessionsPerMonth': int.tryParse('${p['sessionsPerMonth'] ?? 4}') ?? 4,
        'mode': 'normal',
      });
    }
    return all;
  }
      int? _timeToMinutes(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;
    final parts = clean.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  String _minutesToTime(int mins) {
    final clamped = mins.clamp(0, 23 * 60 + 59);
    final h = (clamped ~/ 60).toString().padLeft(2, '0');
    final m = (clamped % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _expedienteKeyForDate(DateTime dt) {
    if (dt.weekday == DateTime.sunday) return '0';
    return dt.weekday.toString();
  }

  int _bookingDurationMinutes(Map b) {
    if (b['items'] is List && (b['items'] as List).isNotEmpty) {
      int total = 0;
      for (final it in (b['items'] as List).whereType()) {
        total += int.tryParse('${it['duration'] ?? 30}') ?? 30;
      }
      if (total > 0) return total;
    }
    return int.tryParse('${b['duration'] ?? 30}') ?? 30;
  }

  bool _sameBarberName(String? a, String? b) {
    final x = _normalizeNameShared(a ?? '');
    final y = _normalizeNameShared(b ?? '');
    if (x.isEmpty || y.isEmpty) return true;
    return x == y;
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Retorna todos os agendamentos que ocupam o intervalo [slotMin, slotMin+step).
  /// Marca `isStart == true` apenas no horário inicial para nunca renderizar 4x repetido!
  List> _findBookingsAtSlot(
    DateTime day,
    int slotMin, {
    String barberFilter = 'TODOS',
  }) {
    final int step = _slotStepMinutes <= 0 ? 15 : _slotStepMinutes;
    final int slotEnd = slotMin + step;
    final List> hits = [];

    for (final b in _bookings) {
      final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
      if (st == 'cancelado') continue;

      final bDt = _parseBookingDate(b);
      if (!_isSameDay(bDt, day)) continue;

      if (barberFilter != 'TODOS' &&
          !_sameBarberName(b['barberName']?.toString(), barberFilter)) {
        continue;
      }

      final startMin = _timeToMinutes((b['time'] ?? '').toString());
      if (startMin == null) continue;
      final dur = _bookingDurationMinutes(b);
      final endMin = startMin + dur;

      if (slotMin < endMin && slotEnd > startMin) {
        hits.add({
          'booking': b,
          'startMin': startMin,
          'endMin': endMin,
          'startStr': _minutesToTime(startMin),
          'endStr': _minutesToTime(endMin),
          'isStart': slotMin >= startMin && slotMin < startMin + step,
        });
      }
    }
    return hits;
  }

  Map<String, dynamic>? _findPauseAtSlot(DateTime day, int slotMin) {
    final int step = _slotStepMinutes <= 0 ? 15 : _slotStepMinutes;
    final int slotEnd = slotMin + step;

    for (final p in _pauses) {
      final pDt = _parseDateString((p['date'] ?? '').toString());
      if (pDt != null && !_isSameDay(pDt, day)) continue;

      final ps = _timeToMinutes((p['start'] ?? '').toString());
      final pe = _timeToMinutes((p['end'] ?? '').toString());
      if (ps != null && pe != null && pe > ps) {
        if (slotMin < pe && slotEnd > ps) {
          return {
            'reason': (p['reason'] ?? 'Pausa / Bloqueio').toString(),
            'startStr': _minutesToTime(ps),
            'endStr': _minutesToTime(pe),
          };
        }
      }
    }
    return null;
  }

  bool _isCompletedStatus(Map b) {
    final st = (b['status'] ?? '').toString().trim().toLowerCase();
    return st == 'concluído' || st == 'concluido';
  }

  DateTime? _parseBookingDate(Map b) {
    final rawDate = (b['dateLabel'] ?? b['date'] ?? '').toString().trim();
    if (rawDate.isNotEmpty) {
      final parsed = _parseDateString(rawDate);
      if (parsed != null) return parsed;
    }

    final created = (b['createdAt'] ?? '').toString().trim();
    if (created.isNotEmpty) {
      final parsed = DateTime.tryParse(created);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }

  bool _matchesPeriod(Map b, String period) {
    final dt = _parseBookingDate(b);
    if (dt == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (period == 'diario') {
      return dt.year == today.year &&
          dt.month == today.month &&
          dt.day == today.day;
    }

    if (period == 'mensal') {
      return dt.year == today.year && dt.month == today.month;
    }

    final weekStart = today.subtract(const Duration(days: 6));
    final weekEnd = today.add(const Duration(days: 1));
    return !dt.isBefore(weekStart) && dt.isBefore(weekEnd);
  }

  double _getBarberCommissionPct(String? barberName) {
    final target = _normalizeNameShared(barberName ?? '');
    if (target == 'jhonny' || target == 'mr. jone' || target == 'mr jone') {
      return 100.0;
    }
    if (target == 'marcelo') {
      return 50.0;
    }
    if (target.isNotEmpty) {
      for (final b in _barbers) {
        final bName = _normalizeNameShared((b['name'] ?? '').toString());
        if (bName == target) {
          return double.tryParse('${b['commission'] ?? 50.0}') ?? 50.0;
        }
      }
    }
    return 50.0;
  }

  double _calcReceitaItem(Map item) {
    final double price = double.tryParse('${item['price'] ?? 0}') ?? 0;
    final bool isPlan = item['isPlan'] == true;
    final int sessions = int.tryParse('${item['sessionsPerMonth'] ?? 4}') ?? 4;
    return isPlan ? (price / (sessions <= 0 ? 4 : sessions)) : price;
  }

  double _calcBookingValue(Map b) {
    double sum = 0;
    final items = b['items'];
    if (items is List) {
      for (final it in items.whereType()) {
        sum += _calcReceitaItem(it);
      }
    }
    if (sum == 0) {
      final fallbackPrice =
          double.tryParse('${b['price'] ?? b['total'] ?? 0}') ?? 0;
      if (fallbackPrice > 0) sum = fallbackPrice;
    }
    return sum;
  }

  double _calcBookingCommission(Map b) {
    final pct = _getBarberCommissionPct(b['barberName']?.toString());
    return _calcBookingValue(b) * (pct / 100.0);
  }

  bool _shouldCountBooking(Map b, {bool onlyCompleted = true}) {
    final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
    if (st == 'cancelado' || st == 'não concluído' || st == 'nao concluido') {
      return false;
    }
    if (onlyCompleted) {
      return st == 'concluído' || st == 'concluido';
    }
    return true;
  }

  Map<String, dynamic> _periodFinancialSummary(
    String period, {
    bool onlyCompleted = true,
  }) {
    double receita = 0;
    double comissao = 0;
    int count = 0;
    for (final b in _bookings) {
      if (!_shouldCountBooking(b, onlyCompleted: onlyCompleted)) continue;
      if (!_matchesPeriod(b, period)) continue;
      final r = _calcBookingValue(b);
      final c = _calcBookingCommission(b);
      receita += r;
      comissao += c;
      count++;
    }
    return {
      'receita': receita,
      'comissao': comissao,
      'liquido': receita - comissao,
      'count': count,
    };
  }
      List<String> _allKeysForBooking(Map b) {
    final list = <String>[];
    final mainKey = (b['firebaseKey'] ?? '').toString();
    if (mainKey.isNotEmpty) list.add(mainKey);
    if (b['_mergedFirebaseKeys'] is List) {
      for (final mk in (b['_mergedFirebaseKeys'] as List)) {
        if (mk.toString().isNotEmpty) list.add(mk.toString());
      }
    }
    return list.toSet().toList();
  }

  Future<void> _patchBookingKeys(
    List<String> keys,
    Map<String, dynamic> patch,
  ) async {
    final cleanKeys = keys.where((k) => k.isNotEmpty).toSet().toList();
    if (cleanKeys.isEmpty) return;

    final primaryKey = cleanKeys.first;
    await http.patch(
      Uri.parse('$kFirebaseDbUrl/bookings/$primaryKey.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patch),
    );

    if (cleanKeys.length > 1) {
      for (final extraKey in cleanKeys.skip(1)) {
        await http.delete(Uri.parse('$kFirebaseDbUrl/bookings/$extraKey.json'));
      }
    }
  }

  String _buildServiceSummary(Map b) {
    final List<String> srvNames = [];
    if (b['items'] is List) {
      for (final it in (b['items'] as List).whereType()) {
        if (it['name'] != null) {
          srvNames.add(it['name'].toString());
        }
      }
    }
    if (srvNames.isNotEmpty) return srvNames.join(' + ');
    final fallback = (b['serviceName'] ?? b['service'] ?? '').toString().trim();
    return fallback.isEmpty ? 'Atendimento agendado' : fallback;
  }

  Future<void> _openWhatsApp(Map b, {bool rescheduled = false}) async {
    final client = (b['clientName'] ?? 'Cliente').toString().trim();
    final dateLbl = (b['dateLabel'] ?? b['date'] ?? '').toString().trim();
    final timeLbl = (b['time'] ?? '').toString().trim();
    final barber = (b['barberName'] ?? 'Barbearia Mr Jone').toString().trim();
    final srvSummary = _buildServiceSummary(b);

    final rawPhone = (b['clientPhone'] ?? b['phone'] ?? '')
        .toString()
        .replaceAll(RegExp(r'\D'), '');

    String normalizedPhone = rawPhone;
    if (normalizedPhone.length >= 10 && !normalizedPhone.startsWith('55')) {
      normalizedPhone = '55$normalizedPhone';
    }

    final reminderText = rescheduled
        ? 'Olá $client! Seu horário na *Barbearia Mr Jone* foi atualizado para *$dateLbl* às *$timeLbl* ($srvSummary com *$barber*). Estamos à disposição!'
        : 'Olá $client! Lembrete da *Barbearia Mr Jone*: seu horário está marcado para *$dateLbl* às *$timeLbl* ($srvSummary com *$barber*). Estamos à sua espera!';

    final encodedMsg = Uri.encodeComponent(reminderText);
    final Uri waUri = normalizedPhone.length >= 12
        ? Uri.parse(
            'https://api.whatsapp.com/send?phone=$normalizedPhone&text=$encodedMsg')
        : Uri.parse('https://api.whatsapp.com/send?text=$encodedMsg');

    try {
      final launched = await launchUrl(
        waUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o WhatsApp neste dispositivo.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao tentar abrir o WhatsApp.')),
      );
    }
  }
      @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF141417),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x55D4AF37)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.content_cut,
                    size: 48,
                    color: Color(0xFFD4AF37),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BARBEARIA MR JONE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF3D97E),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Painel Administrativo & Sincronização Site',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _checkPass(),
                    decoration: InputDecoration(
                      labelText: 'Palavra-passe Admin',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: Color(0xFFD4AF37)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _checkPass,
                      child: const Text(
                        'ENTRAR NA GESTÃO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final List<Widget> tabs = [
      _buildAgendaAndAccountingTab(),
      _buildCatalogTab(),
      _buildExpedienteTab(),
      _buildClientsAndPlansTab(),
      _buildBarbersTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF141417),
        title: const Text(
          'MR JONE • GESTÃO COMPLETA',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF3D97E),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Novas notificações',
                icon: const Icon(Icons.notifications, color: Color(0xFFD4AF37)),
                onPressed: () {
                  setState(() => _newAlerts.clear());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alertas visualizados.')),
                  );
                },
              ),
              if (_newAlerts.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_newAlerts.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Sincronizar App e Site agora',
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFD4AF37),
                    ),
                  )
                : const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
            onPressed: _syncAll,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (idx) => setState(() => _tabIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF141417),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white60,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_day),
            label: 'Agenda/Caixa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Preços',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Horários',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership),
            label: 'Planos/Cli',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Barbeiros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1915),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x44D4AF37)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync, size: 16, color: Color(0xFFD4AF37)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMsg,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
          const Text(
            'APP = SITE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }
      Widget _buildAgendaAndAccountingTab() {
    final diario = _periodFinancialSummary(
      'diario',
      onlyCompleted: _onlyCompletedInAccounting,
    );
    final semanal = _periodFinancialSummary(
      'semanal',
      onlyCompleted: _onlyCompletedInAccounting,
    );
    final mensal = _periodFinancialSummary(
      'mensal',
      onlyCompleted: _onlyCompletedInAccounting,
    );

    final List> accountingFilteredBookings =
        _bookings.where((b) {
      if (!_shouldCountBooking(b, onlyCompleted: _onlyCompletedInAccounting)) {
        return false;
      }
      return _matchesPeriod(b, _accountingPeriodFilter);
    }).toList();

    return RefreshIndicator(
      onRefresh: _syncAll,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeaderBanner(),

          // 1. GRADE ÚNICA DO DIA (OCUPADOS + HORÁRIOS VAGOS)
          _buildScheduleGridSection(),

          // 2. GRADE DE CONTABILIDADE DIÁRIA, SEMANAL E MENSAL
          Card(
            color: const Color(0xFF141417),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0x44D4AF37)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CONTABILIDADE (DIÁRIA • SEMANAL • MENSAL)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF3D97E),
                        ),
                      ),
                      Row(
                        children: [
                          const Text('Só concluídos',
                              style: TextStyle(fontSize: 10)),
                          Switch(
                            value: _onlyCompletedInAccounting,
                            activeColor: const Color(0xFFD4AF37),
                            onChanged: (v) =>
                                setState(() => _onlyCompletedInAccounting = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Grade comparativa lado a lado
                  Table(
                    border: TableBorder.all(
                      color: const Color(0x33D4AF37),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(1.2),
                      1: FlexColumnWidth(1.2),
                      2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(1.2),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFF231D09)),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text('Período',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF3D97E))),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text('Bruto',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text('Comissão',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text('Líquido',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.greenAccent)),
                          ),
                        ],
                      ),
                      _buildAccountingTableRow('Diária (Hoje)', diario),
                      _buildAccountingTableRow('Semanal (7d)', semanal),
                      _buildAccountingTableRow('Mensal (Mês)', mensal),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Seletor para ver a grade resumida de clientes daquele período
                  Row(
                    children: [
                      _periodChip('diario', 'Diária'),
                      const SizedBox(width: 6),
                      _periodChip('semanal', 'Semanal'),
                      const SizedBox(width: 6),
                      _periodChip('mensal', 'Mensal'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (accountingFilteredBookings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum atendimento contabilizado neste período.',
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    )
                  else
                    Table(
                      border: TableBorder.all(color: Colors.white12),
                      columnWidths: const {
                        0: FlexColumnWidth(2.0),
                        1: FlexColumnWidth(1.8),
                        2: FlexColumnWidth(1.1),
                        3: FlexColumnWidth(1.1),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFF1D1D22)),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(6),
                              child: Text('Cliente',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF3D97E))),
                            ),
                            Padding(
                              padding: EdgeInsets.all(6),
                              child: Text('Serviço',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(6),
                              child: Text('Barbeiro',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(6),
                              child: Text('Valor',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent)),
                            ),
                          ],
                        ),
                        ...accountingFilteredBookings.map((b) {
                          final val = _calcBookingValue(b);
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  '${b['clientName'] ?? 'Cliente'} (${b['time'] ?? ''})',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  _buildServiceSummary(b),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.white70),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  '${b['barberName'] ?? 'Jhonny'}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  'R\$ ${val.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildAccountingTableRow(String label, Map<String, dynamic> data) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            '$label\n(${data['count']} atend.)',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            'R\$ ${(data['receita'] as double).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            'R\$ ${(data['comissao'] as double).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 11, color: Colors.orangeAccent),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            'R\$ ${(data['liquido'] as double).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _periodChip(String key, String label) {
    final selected = _accountingPeriodFilter == key;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      selectedColor: const Color(0xFFD4AF37),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => setState(() => _accountingPeriodFilter = key),
    );
  }
      Widget _buildScheduleGridSection() {
    final String expKey = _expedienteKeyForDate(_gridSelectedDate);
    final Map<String, dynamic> dayExp = _expediente[expKey] ?? {};
    final bool isOpen = dayExp['ativo'] == true;
    final String dateBR = _formatDateBR(_gridSelectedDate);
    final String weekdayName = _weekdayFullName(_gridSelectedDate);

    final List turnos = [];
    final t1s = _timeToMinutes((dayExp['t1Inicio'] ?? '09:00').toString());
    final t1e = _timeToMinutes((dayExp['t1Fim'] ?? '12:00').toString());
    if (t1s != null && t1e != null && t1e > t1s) {
      turnos.add({'start': t1s, 'end': t1e});
    }
    if (dayExp['t2Ativo'] == true) {
      final t2s = _timeToMinutes((dayExp['t2Inicio'] ?? '14:00').toString());
      final t2e = _timeToMinutes((dayExp['t2Fim'] ?? '19:30').toString());
      if (t2s != null && t2e != null && t2e > t2s) {
        turnos.add({'start': t2s, 'end': t2e});
      }
    }

    final int step = _slotStepMinutes <= 0 ? 15 : _slotStepMinutes;
    final List<int> slotMinutes = [];
    for (final t in turnos) {
      for (int m = t['start']!; m < t['end']!; m += step) {
        if (!slotMinutes.contains(m)) slotMinutes.add(m);
      }
    }

    // Também garante que agendamentos fora da grade padrão apareçam sem sumir
    for (final b in _bookings) {
      final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
      if (st == 'cancelado') continue;
      final bDt = _parseBookingDate(b);
      if (!_isSameDay(bDt, _gridSelectedDate)) continue;
      if (_gridSelectedBarberFilter != 'TODOS' &&
          !_sameBarberName(
              b['barberName']?.toString(), _gridSelectedBarberFilter)) {
        continue;
      }
      final sm = _timeToMinutes((b['time'] ?? '').toString());
      if (sm != null && !slotMinutes.contains(sm)) {
        slotMinutes.add(sm);
      }
    }
    slotMinutes.sort();

    final Set<String> renderedBookingKeys = {};
    final List<Widget> gridRows = [];

    for (final m in slotMinutes) {
      final String slotStartStr = _minutesToTime(m);
      final String slotEndStr = _minutesToTime(m + step);
      final pauseHit = _findPauseAtSlot(_gridSelectedDate, m);
      final bookingHits = _findBookingsAtSlot(
        _gridSelectedDate,
        m,
        barberFilter: _gridSelectedBarberFilter,
      );

      if (bookingHits.isNotEmpty) {
        for (final hit in bookingHits) {
          final bk = hit['booking'] as Map<String, dynamic>;
          final uniqueId =
              _bookingDedupeKey(bk, (bk['firebaseKey'] ?? '').toString());
          // Se este agendamento já foi exibido no horário inicial (ex: 09:00 às 10:00),
          // não repete nos blocos intermediários (09:15, 09:30, 09:45)!
          if (renderedBookingKeys.contains(uniqueId)) continue;
          renderedBookingKeys.add(uniqueId);

          final bool isDone = _isCompletedStatus(bk);
          final String startStr = (hit['startStr'] ?? slotStartStr).toString();
          final String endStr = (hit['endStr'] ?? slotEndStr).toString();
          final String cName = (bk['clientName'] ?? 'Cliente').toString();
          final String bName = (bk['barberName'] ?? 'Jhonny').toString();
          final String srvSummary = _buildServiceSummary(bk);
          final double val = _calcBookingValue(bk);
          final String stLabel = (bk['status'] ?? 'confirmado').toString();

          gridRows.add(
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF132619)
                    : const Color(0xFF261F0A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDone
                      ? Colors.greenAccent.withValues(alpha: 0.7)
                      : const Color(0xFFD4AF37),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDone
                              ? Colors.greenAccent
                              : const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$startStr\naté\n$endStr',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$cName • $startStr às $endStr',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFF3D97E),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$srvSummary • $bName ($stLabel)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Valor: R\$ ${val.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Trocar Serviço / Editar Horário',
                        icon: const Icon(Icons.edit_note,
                            color: Color(0xFFF3D97E), size: 26),
                        onPressed: () => _openEditBookingDialog(bk),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _miniActionBtn(
                        label: 'Trocar Serviço',
                        icon: Icons.swap_horiz,
                        color: const Color(0xFFF3D97E),
                        onTap: () => _openEditBookingDialog(bk),
                      ),
                      _miniActionBtn(
                        label: isDone ? 'Concluído ✓' : 'Concluir',
                        icon: Icons.check_circle_outline,
                        color: Colors.greenAccent,
                        onTap: () async {
                          await _patchBookingKeys(_allKeysForBooking(bk), {
                            'status': 'concluído',
                            'attended': true,
                            'completedAt': DateTime.now().toIso8601String(),
                          });
                          await _fetchBookings(silent: true);
                        },
                      ),
                      _miniActionBtn(
                        label: 'WhatsApp',
                        icon: Icons.chat,
                        color: Colors.lightGreenAccent,
                        onTap: () => _openWhatsApp(bk),
                      ),
                      _miniActionBtn(
                        label: 'Excluir',
                        icon: Icons.delete_outline,
                        color: Colors.redAccent,
                        onTap: () async {
                          for (final k in _allKeysForBooking(bk)) {
                            await http.delete(
                                Uri.parse('$kFirebaseDbUrl/bookings/$k.json'));
                          }
                          await _fetchBookings(silent: true);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        continue;
      }

      if (pauseHit != null) {
        gridRows.add(
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF221517),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Text(
                  '$slotStartStr–$slotEndStr',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PAUSA • ${pauseHit['reason']}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Horário vago na grade
      gridRows.add(
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF19191E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Text(
                '$slotStartStr–$slotEndStr',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'HORÁRIO VAGO',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 30),
                ),
                onPressed: () => _openManualEntryDialog(
                  presetDateStr: dateBR,
                  presetTimeStr: slotStartStr,
                ),
                icon: const Icon(Icons.add, size: 15, color: Color(0xFFD4AF37)),
                label: const Text(
                  'Agendar',
                  style: TextStyle(fontSize: 11, color: Color(0xFFF3D97E)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: const Color(0xFF141417),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x44D4AF37), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra de dias rápidos + Calendário
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...List.generate(7, (idx) {
                    final d = DateTime.now().add(Duration(days: idx));
                    final selected = _isSameDay(d, _gridSelectedDate);
                    final lbl =
                        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} • ${_weekdayFullName(d).substring(0, 3)}';
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(lbl, style: const TextStyle(fontSize: 11)),
                        selected: selected,
                        selectedColor: const Color(0xFFD4AF37),
                        labelStyle: TextStyle(
                          color: selected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) =>
                            setState(() => _gridSelectedDate = d),
                      ),
                    );
                  }),
                  IconButton(
                    tooltip: 'Escolher outra data',
                    icon: const Icon(Icons.calendar_month,
                        color: Color(0xFFD4AF37)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _gridSelectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && mounted) {
                        setState(() => _gridSelectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Filtro por barbeiro
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos os Barbeiros',
                        style: TextStyle(fontSize: 11)),
                    selected: _gridSelectedBarberFilter == 'TODOS',
                    selectedColor: const Color(0xFFD4AF37),
                    labelStyle: TextStyle(
                      color: _gridSelectedBarberFilter == 'TODOS'
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) =>
                        setState(() => _gridSelectedBarberFilter = 'TODOS'),
                  ),
                  const SizedBox(width: 6),
                  ..._barbers.map((br) {
                    final bName = (br['name'] ?? '').toString();
                    final selected = _sameBarberName(
                            bName, _gridSelectedBarberFilter) &&
                        _gridSelectedBarberFilter != 'TODOS';
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label:
                            Text(bName, style: const TextStyle(fontSize: 11)),
                        selected: selected,
                        selectedColor: const Color(0xFFD4AF37),
                        labelStyle: TextStyle(
                          color: selected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) =>
                            setState(() => _gridSelectedBarberFilter = bName),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GRADE DO DIA • $weekdayName ($dateBR)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                    fontSize: 12,
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _openManualEntryDialog(presetDateStr: dateBR),
                  icon: const Icon(Icons.add_circle_outline,
                      size: 16, color: Color(0xFFD4AF37)),
                  label: const Text(
                    '+ Encaixe',
                    style: TextStyle(fontSize: 11, color: Color(0xFFF3D97E)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (!isOpen && gridRows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Expediente fechado neste dia. Ative na aba Horários.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              )
            else
              ...gridRows,
          ],
        ),
      ),
    );
  }

  Widget _miniActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
      Future<void> _openEditBookingDialog(Map<String, dynamic> b) async {
    final nameCtrl =
        TextEditingController(text: (b['clientName'] ?? '').toString());
    final phoneCtrl = TextEditingController(
        text: (b['clientPhone'] ?? b['phone'] ?? '').toString());
    final dateCtrl = TextEditingController(
        text: (b['dateLabel'] ?? b['date'] ?? _formatDateBR(DateTime.now()))
            .toString());
    final timeCtrl =
        TextEditingController(text: (b['time'] ?? '09:00').toString());

    String selectedBarber = (b['barberName'] ??
            (_barbers.isNotEmpty ? _barbers.first['name'] : 'Jhonny'))
        .toString();

    final options = _allowedCatalogOptions(
      clientName: nameCtrl.text,
      clientPhone: phoneCtrl.text,
    );

    String currentSrvName = _buildServiceSummary(b);
    Map<String, dynamic> selectedService = options.firstWhere(
      (opt) =>
          _normalizeNameShared(opt['name'].toString()) ==
          _normalizeNameShared(currentSrvName),
      orElse: () => options.first,
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final dynamicOptions = _allowedCatalogOptions(
              clientName: nameCtrl.text,
              clientPhone: phoneCtrl.text,
            );
            if (!dynamicOptions.any((o) => o['name'] == selectedService['name'])) {
              selectedService = dynamicOptions.first;
            }
            final member = _findPlanMember(
              clientName: nameCtrl.text,
              clientPhone: phoneCtrl.text,
            );
            final bool hasValidPlan =
                member != null && _isPlanMemberValid(member);
            final bool hasExpiredPlan =
                member != null && !_isPlanMemberValid(member);

            return AlertDialog(
              backgroundColor: const Color(0xFF141417),
              title: const Text(
                'Editar Horário / Trocar Serviço',
                style: TextStyle(color: Color(0xFFF3D97E), fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasValidPlan)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: Text(
                          'PLANO ATIVO (vence em ${member['expiresAt']}): Avulso bloqueado; direcionado somente ao plano.',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.greenAccent),
                        ),
                      ),
                    if (hasExpiredPlan)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orangeAccent),
                        ),
                        child: Text(
                          'PLANO VENCIDO (${member['expiresAt']}): Liberado para escolher preços avulsos.',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.orangeAccent),
                        ),
                      ),
                    TextField(
                      controller: nameCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration:
                          const InputDecoration(labelText: 'Nome do Cliente'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      onChanged: (_) => setModalState(() {}),
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: 'WhatsApp / Telefone'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dateCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Data (DD/MM/AAAA)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: timeCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Hora (HH:MM)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Trocar Serviço / Plano Disponível:',
                      style: TextStyle(fontSize: 12, color: Color(0xFFF3D97E)),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedService['name'].toString(),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1D1D22),
                      items: dynamicOptions.map((opt) {
                        final p = (opt['price'] as double).toStringAsFixed(2);
                        final dur = opt['duration'];
                        return DropdownMenuItem<String>(
                          value: opt['name'].toString(),
                          child: Text(
                            '${opt['name']} • R\$ $p (${dur}m)',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setModalState(() {
                          selectedService = dynamicOptions
                              .firstWhere((o) => o['name'].toString() == val);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Barbeiro:',
                      style: TextStyle(fontSize: 12, color: Color(0xFFF3D97E)),
                    ),
                    DropdownButtonFormField<String>(
                      value: _barbers.any((br) =>
                              _sameBarberName(br['name']?.toString(), selectedBarber))
                          ? _barbers
                              .firstWhere((br) => _sameBarberName(
                                  br['name']?.toString(), selectedBarber))['name']
                              .toString()
                          : _barbers.first['name'].toString(),
                      dropdownColor: const Color(0xFF1D1D22),
                      items: _barbers.map((br) {
                        final bn = br['name'].toString();
                        return DropdownMenuItem<String>(
                          value: bn,
                          child: Text(bn, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedBarber = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final updatedPatch = {
                      'clientName': nameCtrl.text.trim(),
                      'clientPhone': _normalizePhone(phoneCtrl.text),
                      'phone': _normalizePhone(phoneCtrl.text),
                      'dateLabel': _normalizeDateShared(dateCtrl.text),
                      'date': _normalizeDateShared(dateCtrl.text),
                      'time': _normalizeTimeShared(timeCtrl.text),
                      'barberName': selectedBarber,
                      'serviceName': selectedService['name'],
                      'price': selectedService['price'],
                      'total': selectedService['price'],
                      'duration': selectedService['duration'],
                      'items': [
                        {
                          'id': selectedService['id'] ?? '',
                          'name': selectedService['name'],
                          'price': selectedService['price'],
                          'duration': selectedService['duration'],
                          'isPlan': selectedService['isPlan'] == true,
                          'sessionsPerMonth':
                              selectedService['sessionsPerMonth'] ?? 1,
                        }
                      ],
                      'updatedAt': DateTime.now().toIso8601String(),
                    };

                    await _patchBookingKeys(
                        _allKeysForBooking(b), updatedPatch);
                    await _fetchBookings(silent: true);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Salvar Alterações'),
                ),
              ],
            );
          },
        );
      },
    );
  }
     Future<void> _openManualEntryDialog({
    String? presetDateStr,
    String? presetTimeStr,
  }) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
        text: presetDateStr ?? _formatDateBR(_gridSelectedDate));
    final timeCtrl = TextEditingController(text: presetTimeStr ?? '09:00');

    String selectedBarber =
        _barbers.isNotEmpty ? _barbers.first['name'].toString() : 'Jhonny';
    bool markAsCompletedNow = false;

    final initialOptions = _allowedCatalogOptions();
    Map<String, dynamic> selectedService = initialOptions.first;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final dynamicOptions = _allowedCatalogOptions(
              clientName: nameCtrl.text,
              clientPhone: phoneCtrl.text,
            );
            if (!dynamicOptions.any((o) => o['name'] == selectedService['name'])) {
              selectedService = dynamicOptions.first;
            }
            final member = _findPlanMember(
              clientName: nameCtrl.text,
              clientPhone: phoneCtrl.text,
            );
            final bool hasValidPlan =
                member != null && _isPlanMemberValid(member);
            final bool hasExpiredPlan =
                member != null && !_isPlanMemberValid(member);

            return AlertDialog(
              backgroundColor: const Color(0xFF141417),
              title: const Text(
                'Agendar / Encaixar Cliente',
                style: TextStyle(color: Color(0xFFF3D97E), fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasValidPlan)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: Text(
                          'Cliente do Plano (válido até ${member['expiresAt']}): direcionado exclusivamente ao plano.',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.greenAccent),
                        ),
                      ),
                    if (hasExpiredPlan)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orangeAccent),
                        ),
                        child: Text(
                          'Plano vencido em ${member['expiresAt']}: opções avulsas liberadas.',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.orangeAccent),
                        ),
                      ),
                    TextField(
                      controller: nameCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration:
                          const InputDecoration(labelText: 'Nome do Cliente'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      onChanged: (_) => setModalState(() {}),
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: 'WhatsApp (DDD + Número)'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dateCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Data (DD/MM/AAAA)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: timeCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Hora (HH:MM)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Serviço / Plano:',
                      style: TextStyle(fontSize: 12, color: Color(0xFFF3D97E)),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedService['name'].toString(),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1D1D22),
                      items: dynamicOptions.map((opt) {
                        final p = (opt['price'] as double).toStringAsFixed(2);
                        return DropdownMenuItem<String>(
                          value: opt['name'].toString(),
                          child: Text(
                            '${opt['name']} • R\$ $p',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setModalState(() {
                          selectedService = dynamicOptions
                              .firstWhere((o) => o['name'].toString() == val);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Barbeiro:',
                      style: TextStyle(fontSize: 12, color: Color(0xFFF3D97E)),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedBarber,
                      dropdownColor: const Color(0xFF1D1D22),
                      items: _barbers.map((br) {
                        final bn = br['name'].toString();
                        return DropdownMenuItem<String>(
                          value: bn,
                          child: Text(bn, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedBarber = val);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Já contabilizar como CONCLUÍDO agora',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: markAsCompletedNow,
                      activeColor: const Color(0xFFD4AF37),
                      onChanged: (v) =>
                          setModalState(() => markAsCompletedNow = v ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final clientName = nameCtrl.text.trim().isEmpty
                        ? 'Cliente Avulso'
                        : nameCtrl.text.trim();
                    final normPhone = _normalizePhone(phoneCtrl.text);
                    final normDate = _normalizeDateShared(dateCtrl.text);
                    final normTime = _normalizeTimeShared(timeCtrl.text);

                    // Chave determinística no Firebase evita duplicata se clicar 2x
                    final deterministicId =
                        'bk_${normDate.replaceAll('/', '')}_${normTime.replaceAll(':', '')}_${_normalizeNameShared(selectedBarber).replaceAll(' ', '_')}_${normPhone.isNotEmpty ? normPhone : _normalizeNameShared(clientName).replaceAll(' ', '_')}';

                    final payload = {
                      'bookingId': deterministicId,
                      'clientName': clientName,
                      'clientPhone': normPhone,
                      'phone': normPhone,
                      'dateLabel': normDate,
                      'date': normDate,
                      'time': normTime,
                      'barberName': selectedBarber,
                      'serviceName': selectedService['name'],
                      'price': selectedService['price'],
                      'total': selectedService['price'],
                      'duration': selectedService['duration'],
                      'status':
                          markAsCompletedNow ? 'concluído' : 'confirmado',
                      'attended': markAsCompletedNow,
                      'source': 'app_gestao',
                      'items': [
                        {
                          'id': selectedService['id'] ?? '',
                          'name': selectedService['name'],
                          'price': selectedService['price'],
                          'duration': selectedService['duration'],
                          'isPlan': selectedService['isPlan'] == true,
                          'sessionsPerMonth':
                              selectedService['sessionsPerMonth'] ?? 1,
                        }
                      ],
                      'createdAt': DateTime.now().toIso8601String(),
                      'updatedAt': DateTime.now().toIso8601String(),
                    };

                    await http.put(
                      Uri.parse('$kFirebaseDbUrl/bookings/$deterministicId.json'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(payload),
                    );

                    await _upsertClientFromBooking(
                      name: clientName,
                      phone: normPhone,
                      bookingDate: normDate,
                      bookingTime: normTime,
                      incrementCount: true,
                    );

                    await _fetchBookings(silent: true);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Confirmar na Grade'),
                ),
              ],
            );
          },
        );
      },
    );
     }
        Widget _buildCatalogTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildHeaderBanner(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SERVIÇOS AVULSOS (REFLETE NO SITE)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFF3D97E),
                fontSize: 13,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              onPressed: () => _openCatalogItemDialog(isPlan: false),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Novo Serviço'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._services.map((s) => _buildCatalogItemCard(s, isPlan: false)),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PLANOS MENSAIS (REFLETE NO SITE)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFF3D97E),
                fontSize: 13,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              onPressed: () => _openCatalogItemDialog(isPlan: true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Novo Plano'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._plans.map((p) => _buildCatalogItemCard(p, isPlan: true)),
      ],
    );
  }

  Widget _buildCatalogItemCard(Map<String, dynamic> item,
      {required bool isPlan}) {
    final price = double.tryParse('${item['price'] ?? 0}') ?? 0.0;
    final dur = item['duration'] ?? 30;
    final active = item['active'] != false;

    return Card(
      color: const Color(0xFF141417),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          (item['name'] ?? '').toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: active ? const Color(0xFFF3D97E) : Colors.white38,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          'R\$ ${price.toStringAsFixed(2)} • Duração: ${dur} min${isPlan ? ' • ${item['sessionsPerMonth'] ?? 4}x/mês' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFD4AF37), size: 20),
              onPressed: () =>
                  _openCatalogItemDialog(existing: item, isPlan: isPlan),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: () async {
                final node = isPlan ? 'plans' : 'services';
                final id = (item['id'] ?? '').toString();
                if (id.isNotEmpty) {
                  await http
                      .delete(Uri.parse('$kFirebaseDbUrl/$node/$id.json'));
                }
                await _fetchCatalog();
                await _publishAllConfigToSite();
              },
            ),
          ],
        ),
      ),
    );
  }
      Future<void> _openCatalogItemDialog({
    Map<String, dynamic>? existing,
    required bool isPlan,
  }) async {
    final nameCtrl =
        TextEditingController(text: (existing?['name'] ?? '').toString());
    final catCtrl = TextEditingController(
        text: (existing?['category'] ?? (isPlan ? 'Planos Mensais' : 'Cortes'))
            .toString());
    final priceCtrl = TextEditingController(
        text: (existing?['price'] ?? (isPlan ? '110.0' : '40.0')).toString());
    final durCtrl = TextEditingController(
        text: (existing?['duration'] ?? '40').toString());
    final sessCtrl = TextEditingController(
        text: (existing?['sessionsPerMonth'] ?? (isPlan ? '4' : '1'))
            .toString());
    bool isActive = existing?['active'] != false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF141417),
              title: Text(
                existing == null
                    ? (isPlan ? 'Novo Plano Mensal' : 'Novo Serviço')
                    : 'Editar ${isPlan ? 'Plano' : 'Serviço'}',
                style: const TextStyle(color: Color(0xFFF3D97E), fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: catCtrl,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Preço (R\$)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: durCtrl,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Duração (min)'),
                          ),
                        ),
                      ],
                    ),
                    if (isPlan) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: sessCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Atendimentos por mês'),
                      ),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Visível no App e no Site',
                          style: TextStyle(fontSize: 13)),
                      value: isActive,
                      activeColor: const Color(0xFFD4AF37),
                      onChanged: (v) => setModalState(() => isActive = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final node = isPlan ? 'plans' : 'services';
                    final id = (existing?['id'] ??
                            '${isPlan ? 'pln' : 'srv'}_${DateTime.now().millisecondsSinceEpoch}')
                        .toString();

                    final payload = {
                      'id': id,
                      'name': nameCtrl.text.trim(),
                      'category': catCtrl.text.trim(),
                      'price': double.tryParse(
                              priceCtrl.text.replaceAll(',', '.')) ??
                          0.0,
                      'duration': int.tryParse(durCtrl.text.trim()) ?? 30,
                      'isPlan': isPlan,
                      'sessionsPerMonth':
                          isPlan ? (int.tryParse(sessCtrl.text.trim()) ?? 4) : 1,
                      'active': isActive,
                      'updatedAt': DateTime.now().toIso8601String(),
                    };

                    await http.put(
                      Uri.parse('$kFirebaseDbUrl/$node/$id.json'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(payload),
                    );

                    await _fetchCatalog();
                    await _publishAllConfigToSite();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Guardar e Sincronizar Site'),
                ),
              ],
            );
          },
        );
      },
    );
      }
         Widget _buildExpedienteTab() {
    const orderedKeys = ['1', '2', '3', '4', '5', '6', '0'];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildHeaderBanner(),
        Card(
          color: const Color(0xFF141417),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INTERVALO DA GRADE DE HORÁRIOS (APP & SITE)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [15, 20, 30, 40, 60].map((mins) {
                    final sel = _slotStepMinutes == mins;
                    return ChoiceChip(
                      label: Text('$mins min'),
                      selected: sel,
                      selectedColor: const Color(0xFFD4AF37),
                      labelStyle: TextStyle(
                        color: sel ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) async {
                        setState(() => _slotStepMinutes = mins);
                        await _saveExpedienteAndSync();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...orderedKeys.map((dayKey) {
          final info = _expediente[dayKey] ?? {};
          final bool ativo = info['ativo'] == true;
          final bool t2Ativo = info['t2Ativo'] == true;

          return Card(
            color: const Color(0xFF141417),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: ativo,
                        activeColor: const Color(0xFFD4AF37),
                        onChanged: (v) {
                          setState(() {
                            _expediente[dayKey]!['ativo'] = v ?? false;
                          });
                        },
                      ),
                      Text(
                        (info['name'] ?? '').toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFFF3D97E),
                        ),
                      ),
                      const Spacer(),
                      if (ativo)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _expediente[dayKey]!['t2Ativo'] = !t2Ativo;
                            });
                          },
                          child: Text(
                            t2Ativo ? 'Remover Turno 2' : '+ Adicionar Turno 2',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.orangeAccent),
                          ),
                        ),
                    ],
                  ),
                  if (ativo) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _expControllers['${dayKey}_t1Ini'],
                            decoration:
                                const InputDecoration(labelText: 'Início 1'),
                            onChanged: (v) =>
                                _expediente[dayKey]!['t1Inicio'] = v.trim(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _expControllers['${dayKey}_t1Fim'],
                            decoration:
                                const InputDecoration(labelText: 'Fim 1'),
                            onChanged: (v) =>
                                _expediente[dayKey]!['t1Fim'] = v.trim(),
                          ),
                        ),
                        if (t2Ativo) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _expControllers['${dayKey}_t2Ini'],
                              decoration:
                                  const InputDecoration(labelText: 'Início 2'),
                              onChanged: (v) =>
                                  _expediente[dayKey]!['t2Inicio'] = v.trim(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _expControllers['${dayKey}_t2Fim'],
                              decoration:
                                  const InputDecoration(labelText: 'Fim 2'),
                              onChanged: (v) =>
                                  _expediente[dayKey]!['t2Fim'] = v.trim(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(46),
          ),
          onPressed: () async {
            await _saveExpedienteAndSync();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Expediente salvo e atualizado no site em tempo real!'),
              ),
            );
          },
          icon: const Icon(Icons.save),
          label: const Text(
            'SALVAR EXPEDIENTE E REFLETIR NO SITE',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PAUSAS / BLOQUEIOS DE HORÁRIO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFF3D97E),
                fontSize: 12,
              ),
            ),
            TextButton.icon(
              onPressed: _openAddPauseDialog,
              icon: const Icon(Icons.block, size: 16, color: Colors.redAccent),
              label: const Text('Nova Pausa'),
            ),
          ],
        ),
        ..._pauses.asMap().entries.map((entry) {
          final idx = entry.key;
          final p = entry.value;
          return Card(
            color: const Color(0xFF141417),
            child: ListTile(
              dense: true,
              title: Text(
                '${(p['date'] ?? '').toString().isEmpty ? 'Todos os dias' : p['date']} • ${p['start']} às ${p['end']}',
                style: const TextStyle(color: Colors.redAccent),
              ),
              subtitle: Text('${p['reason'] ?? 'Pausa'}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white60),
                onPressed: () async {
                  setState(() => _pauses.removeAt(idx));
                  await _savePausesAndSync();
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _openAddPauseDialog() async {
    final dateCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '12:00');
    final endCtrl = TextEditingController(text: '14:00');
    final reasonCtrl = TextEditingController(text: 'Almoço / Intervalo');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: const Text('Adicionar Pausa / Bloqueio',
            style: TextStyle(color: Color(0xFFF3D97E), fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Data (DD/MM/AAAA ou vazio para diário)',
              ),
            ),
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(labelText: 'Início (HH:MM)'),
            ),
            TextField(
              controller: endCtrl,
              decoration: const InputDecoration(labelText: 'Fim (HH:MM)'),
            ),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Motivo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              setState(() {
                _pauses.add({
                  'date': dateCtrl.text.trim(),
                  'start': _normalizeTimeShared(startCtrl.text),
                  'end': _normalizeTimeShared(endCtrl.text),
                  'reason': reasonCtrl.text.trim(),
                });
              });
              await _savePausesAndSync();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar Pausa'),
          ),
        ],
      ),
    );
  }
      Widget _buildClientsAndPlansTab() {
    final filteredClients = _clients.where((c) {
      if (_clientSearchQuery.trim().isEmpty) return true;
      final q = _normalizeNameShared(_clientSearchQuery);
      final nm = _normalizeNameShared((c['name'] ?? '').toString());
      final ph = (c['phone'] ?? '').toString();
      return nm.contains(q) || ph.contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildHeaderBanner(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'ASSINANTES DE PLANO (COM VENCIMENTO)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF3D97E),
                  fontSize: 13,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              onPressed: () => _openPlanMemberDialog(),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Acrescentar no Plano'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '• Plano Válido: bloqueia preço avulso e direciona o cliente só para o plano.\n• Plano Vencido: libera automaticamente o preço avulso.',
          style: TextStyle(fontSize: 11, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        if (_planMembers.isEmpty)
          const Card(
            color: Color(0xFF141417),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('Nenhum cliente cadastrado nos planos mensais.'),
            ),
          )
        else
          ..._planMembers.map((m) {
            final bool valid = _isPlanMemberValid(m);
            final String expStr = (m['expiresAt'] ?? 'Sem data').toString();
            final String cName = (m['clientName'] ?? 'Cliente').toString();
            final String phone = (m['phone'] ?? '').toString();
            final String planName = (m['planName'] ?? 'Plano').toString();

            return Card(
              color: const Color(0xFF141417),
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: valid
                      ? Colors.greenAccent.withValues(alpha: 0.5)
                      : Colors.redAccent.withValues(alpha: 0.6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFF3D97E),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: valid
                                ? Colors.green.withValues(alpha: 0.25)
                                : Colors.red.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            valid
                                ? 'ATIVO • SÓ PLANO'
                                : 'VENCIDO • AVULSO LIBERADO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: valid
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$planName • Vencimento: $expStr',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        'WhatsApp: $phone',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white60),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _miniActionBtn(
                          label: 'Editar / Renovar Data',
                          icon: Icons.edit_calendar,
                          color: const Color(0xFFF3D97E),
                          onTap: () => _openPlanMemberDialog(existing: m),
                        ),
                        _miniActionBtn(
                          label: 'Enviar Lembrete WhatsApp',
                          icon: Icons.notifications_active,
                          color: Colors.greenAccent,
                          onTap: () => _sendManualPlanExpiryWhatsApp(m),
                        ),
                        _miniActionBtn(
                          label: 'Remover',
                          icon: Icons.delete_outline,
                          color: Colors.redAccent,
                          onTap: () async {
                            final id = (m['id'] ?? '').toString();
                            if (id.isNotEmpty) {
                              await http.delete(Uri.parse(
                                  '$kFirebaseDbUrl/plan_members/$id.json'));
                            }
                            await _fetchClientsAndPlanMembers();
                            await _syncPlanRulesToSiteRemote();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        const Divider(height: 28, color: Colors.white24),
        const Text(
          'BASE DE CLIENTES CADASTRADOS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF3D97E),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (v) => setState(() => _clientSearchQuery = v),
          decoration: InputDecoration(
            hintText: 'Pesquisar cliente por nome ou telefone...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        ...filteredClients.map((c) {
          return Card(
            color: const Color(0xFF141417),
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              title: Text(
                (c['name'] ?? 'Cliente').toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Tel: ${c['phone'] ?? 'Não informado'} • Visitas: ${c['totalBookings'] ?? 0}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: TextButton(
                onPressed: () => _openPlanMemberDialog(
                  presetName: (c['name'] ?? '').toString(),
                  presetPhone: (c['phone'] ?? '').toString(),
                ),
                child: const Text(
                  '+ Plano',
                  style: TextStyle(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
          );
        }),
      ],
    );
      }
         Future<void> _sendManualPlanExpiryWhatsApp(Map<String, dynamic> m) async {
    final cName = (m['clientName'] ?? 'Cliente').toString();
    final planName = (m['planName'] ?? 'Plano Mensal').toString();
    final expStr = (m['expiresAt'] ?? '').toString();
    final phone = _normalizePhone((m['phone'] ?? '').toString());

    final msg =
        'Olá $cName! Lembrete da *Barbearia Mr Jone*: a data de vencimento do seu *$planName* está chegando ($expStr). Avise-nos para renovar e manter seu acesso exclusivo ao plano!';
    final encoded = Uri.encodeComponent(msg);
    final uri = phone.length >= 12
        ? Uri.parse('https://api.whatsapp.com/send?phone=$phone&text=$encoded')
        : Uri.parse('https://api.whatsapp.com/send?text=$encoded');

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openPlanMemberDialog({
    Map<String, dynamic>? existing,
    String? presetName,
    String? presetPhone,
  }) async {
    final nameCtrl = TextEditingController(
        text: (existing?['clientName'] ?? presetName ?? '').toString());
    final phoneCtrl = TextEditingController(
        text: (existing?['phone'] ?? presetPhone ?? '').toString());
    final defaultExpiry = _formatDateBR(DateTime.now().add(const Duration(days: 30)));
    final expiryCtrl = TextEditingController(
        text: (existing?['expiresAt'] ?? defaultExpiry).toString());

    Map<String, dynamic> selectedPlan = _plans.firstWhere(
      (p) =>
          _normalizeNameShared(p['name'].toString()) ==
          _normalizeNameShared((existing?['planName'] ?? '').toString()),
      orElse: () => _plans.first,
    );
    bool autoReminderEnabled = existing?['autoReminder'] != false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF141417),
              title: Text(
                existing == null
                    ? 'Acrescentar Cliente no Plano'
                    : 'Editar Assinante do Plano',
                style: const TextStyle(color: Color(0xFFF3D97E), fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Nome do Cliente'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: 'WhatsApp (DDD + Número)'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: expiryCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Data de Vencimento (DD/MM/AAAA)'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today,
                              color: Color(0xFFD4AF37)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: _parseDateString(expiryCtrl.text) ??
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2032),
                            );
                            if (picked != null) {
                              setModalState(() {
                                expiryCtrl.text = _formatDateBR(picked);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPlan['name'].toString(),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1D1D22),
                      items: _plans.map((p) {
                        final pr =
                            (double.tryParse('${p['price'] ?? 0}') ?? 0.0)
                                .toStringAsFixed(2);
                        return DropdownMenuItem<String>(
                          value: p['name'].toString(),
                          child: Text(
                            '${p['name']} • R\$ $pr',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setModalState(() {
                          selectedPlan = _plans
                              .firstWhere((p) => p['name'].toString() == val);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Lembrete automático antes do vencimento',
                        style: TextStyle(fontSize: 12),
                      ),
                      subtitle: const Text(
                        'Avisa automaticamente 3 dias antes, 1 dia antes e no dia.',
                        style: TextStyle(fontSize: 10, color: Colors.white60),
                      ),
                      value: autoReminderEnabled,
                      activeColor: const Color(0xFFD4AF37),
                      onChanged: (v) =>
                          setModalState(() => autoReminderEnabled = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final normPhone = _normalizePhone(phoneCtrl.text);
                    final id = (existing?['id'] ??
                            'mem_${normPhone.isNotEmpty ? normPhone : DateTime.now().millisecondsSinceEpoch}')
                        .toString();

                    final payload = {
                      'id': id,
                      'clientName': nameCtrl.text.trim(),
                      'phone': normPhone,
                      'planId': (selectedPlan['id'] ?? '').toString(),
                      'planName': selectedPlan['name'],
                      'planPrice': selectedPlan['price'],
                      'duration': selectedPlan['duration'] ?? 40,
                      'sessionsPerMonth': selectedPlan['sessionsPerMonth'] ?? 4,
                      'expiresAt': _normalizeDateShared(expiryCtrl.text),
                      'active': true,
                      'autoReminder': autoReminderEnabled,
                      'updatedAt': DateTime.now().toIso8601String(),
                    };

                    await http.put(
                      Uri.parse('$kFirebaseDbUrl/plan_members/$id.json'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(payload),
                    );

                    await _fetchClientsAndPlanMembers();
                    await _syncPlanRulesToSiteRemote();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Salvar e Sincronizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
      Widget _buildBarbersTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildHeaderBanner(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'EQUIPE DE BARBEIROS (APP & SITE)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFF3D97E),
                fontSize: 13,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              onPressed: () => _openBarberDialog(),
              icon: const Icon(Icons.person_add_alt_1, size: 16),
              label: const Text('Novo Barbeiro'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Diário'),
              selected: _barberReportPeriod == 'diario',
              selectedColor: const Color(0xFFD4AF37),
              onSelected: (_) =>
                  setState(() => _barberReportPeriod = 'diario'),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Semanal'),
              selected: _barberReportPeriod == 'semanal',
              selectedColor: const Color(0xFFD4AF37),
              onSelected: (_) =>
                  setState(() => _barberReportPeriod = 'semanal'),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Mensal'),
              selected: _barberReportPeriod == 'mensal',
              selectedColor: const Color(0xFFD4AF37),
              onSelected: (_) =>
                  setState(() => _barberReportPeriod = 'mensal'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._barbers.map((br) {
          final bName = (br['name'] ?? '').toString();
          final commPct = _getBarberCommissionPct(bName);

          double gerado = 0;
          int atendimentos = 0;
          for (final bk in _bookings) {
            if (!_shouldCountBooking(bk,
                onlyCompleted: _onlyCompletedInAccounting)) {
              continue;
            }
            if (!_matchesPeriod(bk, _barberReportPeriod)) continue;
            if (!_sameBarberName(bk['barberName']?.toString(), bName)) continue;
            gerado += _calcBookingValue(bk);
            atendimentos++;
          }
          final comissao = gerado * (commPct / 100.0);

          return Card(
            color: const Color(0xFF141417),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                '$bName (${commPct.toStringAsFixed(0)}%)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF3D97E),
                ),
              ),
              subtitle: Text(
                'Atendimentos: $atendimentos • Produzido: R\$ ${gerado.toStringAsFixed(2)} • Comissão: R\$ ${comissao.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFFD4AF37)),
                onPressed: () => _openBarberDialog(existing: br),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _openBarberDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl =
        TextEditingController(text: (existing?['name'] ?? '').toString());
    final roleCtrl = TextEditingController(
        text: (existing?['role'] ?? 'Barbeiro').toString());
    final commCtrl = TextEditingController(
        text: (existing?['commission'] ?? '50').toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: Text(
          existing == null ? 'Adicionar Barbeiro' : 'Editar Barbeiro',
          style: const TextStyle(color: Color(0xFFF3D97E), fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(labelText: 'Função'),
            ),
            TextField(
              controller: commCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Comissão (%)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final id = (existing?['id'] ??
                      'brb_${DateTime.now().millisecondsSinceEpoch}')
                  .toString();
              await http.put(
                Uri.parse('$kFirebaseDbUrl/barbers/$id.json'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'id': id,
                  'name': nameCtrl.text.trim(),
                  'role': roleCtrl.text.trim(),
                  'commission':
                      double.tryParse(commCtrl.text.replaceAll(',', '.')) ??
                          50.0,
                  'active': true,
                }),
              );
              await _fetchBarbers();
              await _publishAllConfigToSite();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
      Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildHeaderBanner(),
        Card(
          color: const Color(0xFF141417),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SINCRONIZAÇÃO TOTAL APP -> SITE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Envia imediatamente expediente, pausas, intervalo da grade, preços, planos, barbeiros e bloqueios de vencimento para o site.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    await _syncAll();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Tudo sincronizado entre o App e o Site com sucesso!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('FORÇAR SINCRONIZAÇÃO COM O SITE'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF141417),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SEGURANÇA DO PAINEL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPassController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nova Palavra-passe Admin',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _saveNewAdminPass(_newPassController.text),
                  child: const Text('Alterar Palavra-passe'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _logoutAccount,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Bloquear / Sair do Painel',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

    
 
