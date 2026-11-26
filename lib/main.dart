import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

typedef JsonMap = Map<String, dynamic>;
typedef IntMap = Map<String, int>;

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
const String kPrefBarbersSeeded = 'mrjone_barbers_seeded_v1';
final Map<String, JsonMap> kDefaultExpediente = {
  '1': {
    'name': 'Segunda',
    'ativo': true,
    't1Inicio': '09:00',
    't1Fim': '12:00',
    't2Ativo': true,
    't2Inicio': '14:00',
    't2Fim': '19:00',
  },
  '2': {
    'name': 'Terça',
    'ativo': true,
    't1Inicio': '09:00',
    't1Fim': '12:00',
    't2Ativo': true,
    't2Inicio': '14:00',
    't2Fim': '19:00',
  },
  '3': {
    'name': 'Quarta',
    'ativo': true,
    't1Inicio': '09:00',
    't1Fim': '12:00',
    't2Ativo': true,
    't2Inicio': '14:00',
    't2Fim': '19:00',
  },
  '4': {
    'name': 'Quinta',
    'ativo': true,
    't1Inicio': '09:00',
    't1Fim': '12:00',
    't2Ativo': true,
    't2Inicio': '14:00',
    't2Fim': '19:00',
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
    't2Inicio': '14:00',
    't2Fim': '20:00',
  },
  '0': {
    'name': 'Domingo',
    'ativo': true,
    't1Inicio': '08:00',
    't1Fim': '14:00',
    't2Ativo': false,
    't2Inicio': '14:00',
    't2Fim': '18:00',
  },
};
final List<JsonMap> kDefaultServices = [
  {
    'id': 'def_srv_1',
    'name': 'Cabelo e Barba',
    'category': 'Combos',
    'price': 65.0,
    'duration': 50,
    'isPlan': false,
    'sessionsPerMonth': 1,
    'active': true,
  },
  {
    'id': 'def_srv_2',
    'name': 'Cabelo Disfarçado / Degradê',
    'category': 'Cortes',
    'price': 40.0,
    'duration': 40,
    'isPlan': false,
    'sessionsPerMonth': 1,
    'active': true,
  },
  {
    'id': 'def_srv_3',
    'name': 'Máquina (Pente Só)',
    'category': 'Cortes',
    'price': 35.0,
    'duration': 30,
    'isPlan': false,
    'sessionsPerMonth': 1,
    'active': true,
  },
  {
    'id': 'def_srv_4',
    'name': 'Barba',
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
    'name': 'Pé de Cabelo',
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

final List<JsonMap> kDefaultPlans = [
  {
    'id': 'def_pln_1',
    'name': 'Plano Mensal: Cabelo e Barba',
    'category': 'Planos Mensais',
    'price': 150.0,
    'duration': 50,
    'isPlan': true,
    'sessionsPerMonth': 4,
    'active': true,
  },
  {
    'id': 'def_pln_2',
    'name': 'Plano Mensal: Cabelo',
    'category': 'Planos Mensais',
    'price': 110.0,
    'duration': 40,
    'isPlan': true,
    'sessionsPerMonth': 4,
    'active': true,
  },
  {
    'id': 'def_pln_3',
    'name': 'Plano Mensal: Barba',
    'category': 'Planos Mensais',
    'price': 75.0,
    'duration': 20,
    'isPlan': true,
    'sessionsPerMonth': 4,
    'active': true,
  },
];

final List<JsonMap> kDefaultBarbers = [
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

String _canonicalBarberKeyShared(String raw) {
  final n = _normalizeNameShared(raw).replaceAll('.', '').trim();
  if (n.isEmpty ||
      n == 'jone' ||
      n == 'mr jone' ||
      n == 'mrjone' ||
      n == 'jhonny' ||
      n == 'barbearia mr jone') {
    return 'jhonny';
  }
  return n;
}

String _extractBookingDateRaw(Map b) {
  for (final k in ['dateLabel', 'date', 'data', 'dia', 'bookingDate']) {
    final v = (b[k] ?? '').toString().trim();
    if (v.isNotEmpty) return v;
  }
  final created = (b['createdAt'] ?? '').toString().trim();
  if (created.isNotEmpty) {
    final dt = DateTime.tryParse(created);
    if (dt != null) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
  }
  return '';
}

String _extractBookingTimeRaw(Map b) {
  for (final k in ['time', 'hora', 'horario', 'slot', 'startTime']) {
    final v = (b[k] ?? '').toString().trim();
    if (v.isNotEmpty) {
      final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(v);
      return match != null ? match.group(1)! : v;
    }
  }
  return '';
}

String _extractBookingClientName(Map b) {
  for (final k in ['clientName', 'name', 'cliente', 'nome']) {
    final v = (b[k] ?? '').toString().trim();
    if (v.isNotEmpty) return v;
  }
  return 'Cliente';
}

String _extractBookingClientPhone(Map b) {
  for (final k in ['clientPhone', 'phone', 'telefone', 'whatsapp', 'fone']) {
    final v = (b[k] ?? '').toString().trim();
    if (v.isNotEmpty) return v;
  }
  return '';
}

String _extractBookingBarberRaw(Map b) {
  for (final k in ['barberName', 'barber', 'barbeiro', 'profissional']) {
    final v = (b[k] ?? '').toString().trim();
    if (v.isNotEmpty) return v;
  }
  return 'Jhonny';
}

String _normalizeTimeShared(String raw) {
  final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(raw.trim());
  final clean = match != null ? match.group(1)! : raw.trim();
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

String _bookingDedupeKey(Map b, String firebaseKey) {
  final client = _normalizeNameShared(_extractBookingClientName(b));
  final phone = _normalizePhoneShared(_extractBookingClientPhone(b));
  final date = _normalizeDateShared(_extractBookingDateRaw(b));
  final time = _normalizeTimeShared(_extractBookingTimeRaw(b));
  final barber = _canonicalBarberKeyShared(_extractBookingBarberRaw(b));

  if (date.isNotEmpty &&
      time.isNotEmpty &&
      (client.isNotEmpty || phone.isNotEmpty)) {
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

List<JsonMap> _deduplicateBookingsMap(Map decoded) {
  final Map<String, JsonMap> byDedupe = {};

  decoded.forEach((key, val) {
    if (val is! Map) return;
    final k = key.toString();
    final item = JsonMap.from(val);
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
    final da = _normalizeDateShared(_extractBookingDateRaw(a));
    final db = _normalizeDateShared(_extractBookingDateRaw(b));
    if (da != db) return db.compareTo(da);
    final ta = _normalizeTimeShared(_extractBookingTimeRaw(a));
    final tb = _normalizeTimeShared(_extractBookingTimeRaw(b));
    return ta.compareTo(tb);
  });
  return result;
}
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
              (cleanName.isNotEmpty &&
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

    final finalName = cleanName.isNotEmpty
        ? cleanName
        : (existingData['name'] ?? 'Cliente').toString();
    final finalPhone = normPhone.isNotEmpty
        ? normPhone
        : (existingData['phone'] ?? phone).toString();

    final JsonMap payload = {
      'name': finalName,
      'phone': finalPhone,
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

    if (finalPhone.isNotEmpty) {
      await http.put(
        Uri.parse('$kFirebaseDbUrl/site_clients_lookup/byPhone/$finalPhone.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': finalName,
          'phone': finalPhone,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );
    }
    final nameKey = _normalizeNameShared(finalName).replaceAll(' ', '_');
    if (nameKey.isNotEmpty && finalPhone.isNotEmpty) {
      await http.put(
        Uri.parse('$kFirebaseDbUrl/site_clients_lookup/byName/$nameKey.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': finalName,
          'phone': finalPhone,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );
    }
  } catch (_) {}
}

Future<void> _syncPlanRulesToSiteRemote() async {
  try {
    final memRes =
        await http.get(Uri.parse('$kFirebaseDbUrl/plan_members.json'));
    if (memRes.statusCode != 200 || memRes.body == 'null') return;

    final decoded = jsonDecode(memRes.body);
    if (decoded is! Map) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final JsonMap siteIndexByPhone = {};
    final JsonMap siteIndexByName = {};

    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      final key = entry.key.toString();
      final m = JsonMap.from(entry.value as Map);
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
Future<void> _publishOccupiedSlotsFromBookings(List<JsonMap> bookings) async {
  try {
    // Reconstrói /occupied_slots e /site_bookings exclusivamente com marcações ativas.
    // Se um cliente for excluído ou cancelado no app, o horário deixa de constar aqui e fica livre no site.
    final Map<String, List<JsonMap>> byDate = {};
    final Map<String, JsonMap> activeSiteBookings = {};

    for (final b in bookings) {
      final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
      if (st == 'cancelado' || st == 'cancelada') continue;

      final rawDate = _extractBookingDateRaw(b);
      final normDate = _normalizeDateShared(rawDate);
      final dateKey = normDate.replaceAll('/', '-');
      final startTime = _normalizeTimeShared(_extractBookingTimeRaw(b));
      if (dateKey.isEmpty || startTime.isEmpty) continue;

      int dur = int.tryParse('${b['duration'] ?? 30}') ?? 30;
      if (b['items'] is List && (b['items'] as List).isNotEmpty) {
        int sumDur = 0;
        for (final it in (b['items'] as List).whereType()) {
          sumDur += int.tryParse('${it['duration'] ?? 30}') ?? 30;
        }
        if (sumDur > 0) dur = sumDur;
      }

      final parts = startTime.split(':');
      int startMin = 0;
      if (parts.length >= 2) {
        startMin = (int.tryParse(parts[0]) ?? 0) * 60 +
            (int.tryParse(parts[1]) ?? 0);
      }
      final endMin = startMin + dur;
      final endH = (endMin ~/ 60).toString().padLeft(2, '0');
      final endM = (endMin % 60).toString().padLeft(2, '0');
      final endTimeStr = '$endH:$endM';

      final barberRaw = _extractBookingBarberRaw(b);
      final barberCanonical = _canonicalBarberKeyShared(barberRaw);
      final clientName = _extractBookingClientName(b);
      final fKey = (b['firebaseKey'] ?? '').toString();

      final slotObj = {
        'id': fKey,
        'date': normDate,
        'startTime': startTime,
        'endTime': endTimeStr,
        'startMin': startMin,
        'endMin': endMin,
        'duration': dur,
        'barberName': barberRaw,
        'barberCanonical': barberCanonical,
        'clientName': clientName,
        'status': st,
        'active': true,
        'available': false,
      };

      byDate.putIfAbsent(dateKey, () => []).add(slotObj);

      if (fKey.isNotEmpty) {
        activeSiteBookings[fKey] = {
          'id': fKey,
          'date': normDate,
          'dateLabel': normDate,
          'time': startTime,
          'endTime': endTimeStr,
          'duration': dur,
          'barberName': barberRaw,
          'barberCanonical': barberCanonical,
          'clientName': clientName,
          'status': st,
          'active': true,
        };
      }
    }

    await Future.wait([
      http.put(
        Uri.parse('$kFirebaseDbUrl/occupied_slots.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'byDate': byDate,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      ),
      http.put(
        Uri.parse('$kFirebaseDbUrl/site_bookings.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(activeSiteBookings),
      ),
    ]);
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
      final m = JsonMap.from(entry.value as Map);
      if (m['active'] == false) continue;

      final expDt = _parseDateShared((m['expiresAt'] ?? '').toString());
      if (expDt == null) continue;
      final expiry = DateTime(expDt.year, expDt.month, expDt.day);
      final int daysLeft = expiry.difference(today).inDays;

      if (daysLeft == 3 || daysLeft == 1 || daysLeft == 0) {
        final dedupeReminderKey = '$key|$todayStr|d$daysLeft';
        if (sentSet.contains(dedupeReminderKey)) continue;

        final clientName = (m['clientName'] ?? 'Cliente').toString();
        final planName = (m['planName'] ?? 'Plano Mensal').toString();
        final expStr = _formatDateBRShared(expiry);
        final phone = _normalizePhoneShared((m['phone'] ?? '').toString());

        final String msgText = daysLeft == 0
            ? 'Olá $clientName! Seu *$planName* na *Barbearia Mr Jone* vence *HOJE ($expStr)*. Renove agora!'
            : 'Olá $clientName! Lembrete automático da *Barbearia Mr Jone*: seu *$planName* vence em *$daysLeft dia(s)* ($expStr).';

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
            'status': 'disparado_automatico',
            'createdAt': DateTime.now().toIso8601String(),
          }),
        );

        await _showBookingNotification(
          'Vencimento de Plano • $clientName',
          daysLeft == 0
              ? '$planName vence HOJE ($expStr)!'
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
          await _publishOccupiedSlotsFromBookings(deduped);

          final List<String> currentSignatures = [];
          final List<JsonMap> brandNew = [];

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
            final client = _extractBookingClientName(novo);
            final phone = _extractBookingClientPhone(novo);
            final dateLbl = _extractBookingDateRaw(novo);
            final timeLbl = _extractBookingTimeRaw(novo);
            final barber = _extractBookingBarberRaw(novo);

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

  Timer.periodic(const Duration(seconds: 12), (_) async {
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
          'Bloqueando horários marcados e sincronizando clientes',
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
  bool _publishingConfig = false;
  int _tabIndex = 0;
  int _selectedBarberTabIdx = 0;

  bool _onlyCompletedInAccounting = true;
  String _accountingPeriodFilter = 'diario';
  String _barberReportPeriod = 'mensal';

  DateTime _gridSelectedDate = DateTime.now();
  String _clientSearchQuery = '';

  String _statusMsg = 'A aguardar ligação ao Firebase';
  String _adminPass = kDefaultAdminPass;
  int _slotStepMinutes = 15;

  final TextEditingController _passController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final Map<String, TextEditingController> _expControllers = {};

  Map<String, JsonMap> _expediente = {};
  List<JsonMap> _pauses = [];
  List<JsonMap> _bookings = [];
  List<JsonMap> _newAlerts = [];
  List<JsonMap> _services = [];
  List<JsonMap> _plans = [];
  List<JsonMap> _barbers = [];
  List<JsonMap> _clients = [];
  List<JsonMap> _planMembers = [];

  final Set<String> _knownSignatures = {};
  bool _firstLoadDone = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _services = kDefaultServices.map((e) => JsonMap.from(e)).toList();
    _plans = kDefaultPlans.map((e) => JsonMap.from(e)).toList();
    _barbers = kDefaultBarbers.map((e) => JsonMap.from(e)).toList();
    _expediente = _cloneDefaultExpediente();
    _rebuildExpedienteControllers();
    _loadSavedSessionAndPass();
  }

  Map<String, JsonMap> _cloneDefaultExpediente() {
    final Map<String, JsonMap> copy = {};
    kDefaultExpediente.forEach((k, v) {
      copy[k] = JsonMap.from(v);
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
          TextEditingController(text: (info['t2Fim'] ?? '19:00').toString());
    }
  }

  void _syncExpedienteFromControllers() {
    for (final d in ['1', '2', '3', '4', '5', '6', '0']) {
      if (_expediente[d] == null) continue;
      final t1Ini = _expControllers['${d}_t1Ini']?.text.trim();
      final t1Fim = _expControllers['${d}_t1Fim']?.text.trim();
      final t2Ini = _expControllers['${d}_t2Ini']?.text.trim();
      final t2Fim = _expControllers['${d}_t2Fim']?.text.trim();
      if (t1Ini != null && t1Ini.isNotEmpty) {
        _expediente[d]!['t1Inicio'] = _normalizeTimeShared(t1Ini);
      }
      if (t1Fim != null && t1Fim.isNotEmpty) {
        _expediente[d]!['t1Fim'] = _normalizeTimeShared(t1Fim);
      }
      if (t2Ini != null && t2Ini.isNotEmpty) {
        _expediente[d]!['t2Inicio'] = _normalizeTimeShared(t2Ini);
      }
      if (t2Fim != null && t2Fim.isNotEmpty) {
        _expediente[d]!['t2Fim'] = _normalizeTimeShared(t2Fim);
      }
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
      const Duration(seconds: 6),
      (_) async {
        await _fetchBookings(silent: true);
        await _fetchBarbers();
        await _fetchCatalog();
        await _fetchClientsAndPlanMembers();
        await _fetchRemoteSettings(silent: true);
      },
    );
  }

  Future<void> _loadSavedSessionAndPass() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPass = prefs.getString(kPrefAdminPass);
    final wasLoggedIn = prefs.getBool(kPrefLoggedIn) ?? false;
    final savedStep = prefs.getInt(kPrefSlotStep) ?? 15;
    final savedExpRaw = prefs.getString(kPrefExpediente);
    final savedPausesRaw = prefs.getString(kPrefPauses);

    Map<String, JsonMap> loadedExp = _cloneDefaultExpediente();
    if (savedExpRaw != null && savedExpRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedExpRaw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (v is Map && loadedExp.containsKey(k.toString())) {
              loadedExp[k.toString()] = {
                ...loadedExp[k.toString()]!,
                ...JsonMap.from(v),
              };
            }
          });
        }
      } catch (_) {}
    }

    List<JsonMap> loadedPauses = [];
    if (savedPausesRaw != null && savedPausesRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedPausesRaw);
        if (decoded is List) {
          loadedPauses = decoded
              .whereType()
              .map((e) => JsonMap.from(e))
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

  Map<String, JsonMap> _listToIdMap(List<JsonMap> items) {
    final Map<String, JsonMap> out = {};
    for (final item in items) {
      final id = (item['id'] ?? '').toString().trim();
      if (id.isNotEmpty) {
        out[id] = item;
      }
    }
    return out;
  }

  Future<void> _publishAllConfigToSite({bool showFeedback = false}) async {
    if (_publishingConfig) return;
    _publishingConfig = true;
    _syncExpedienteFromControllers();

    try {
      final activeServices =
          _services.where((s) => s['active'] != false).toList();
      final activePlans = _plans.where((p) => p['active'] != false).toList();
      final activeBarbers =
          _barbers.where((b) => b['active'] != false).toList();

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
          Uri.parse('$kFirebaseDbUrl/services.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_listToIdMap(_services)),
        ),
        http.put(
          Uri.parse('$kFirebaseDbUrl/plans.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_listToIdMap(_plans)),
        ),
        http.put(
          Uri.parse('$kFirebaseDbUrl/barbers.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_listToIdMap(_barbers)),
        ),
        http.put(
          Uri.parse('$kFirebaseDbUrl/site_config.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'expediente': _expediente,
            'pauses': _pauses,
            'slotStepMinutes': _slotStepMinutes,
            'services': activeServices,
            'plans': activePlans,
            'barbers': activeBarbers,
            'enforcePlanRules': true,
            'blockOccupiedSlots': true,
            'releaseDeletedSlotsImmediately': true,
            'updatedAt': DateTime.now().toIso8601String(),
          }),
        ),
      ]);

      await _publishOccupiedSlotsFromBookings(_bookings);
      await _syncPlanRulesToSiteRemote();

      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _statusMsg =
              'Sincronizado App ↔ Site • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        });
        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tudo salvo e refletido no Site!'),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted && showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao sincronizar com o Site.'),
          ),
        );
      }
    } finally {
      _publishingConfig = false;
    }
  }
      Future<void> _saveExpedienteAndSync() async {
    _syncExpedienteFromControllers();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefExpediente, jsonEncode(_expediente));
    await prefs.setInt(kPrefSlotStep, _slotStepMinutes);
    await _publishAllConfigToSite(showFeedback: true);
  }

  Future<void> _savePausesAndSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefPauses, jsonEncode(_pauses));
    await _publishAllConfigToSite(showFeedback: true);
  }

  Future<void> _fetchRemoteSettings({bool silent = false}) async {
    if (_publishingConfig) return;
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
                ...JsonMap.from(v),
              };
            }
          });
          if (mounted) {
            setState(() => _expediente = merged);
            if (!silent) {
              _rebuildExpedienteControllers();
            }
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
              .map((e) => JsonMap.from(e))
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
      Future<void> _deleteBookingAndFreeSiteSlot(Map b) async {
    final keys = _allKeysForBooking(b);
    for (final String k in keys) {
      if (k.isNotEmpty) {
        await http.delete(Uri.parse('$kFirebaseDbUrl/bookings/$k.json'));
        await http.delete(Uri.parse('$kFirebaseDbUrl/site_bookings/$k.json'));
      }
    }

    final remaining = _bookings.where((item) {
      final itemKeys = _allKeysForBooking(item);
      return !itemKeys.any((k) => keys.contains(k));
    }).toList();

    if (mounted) {
      setState(() {
        _bookings = remaining;
      });
    }

    await _publishOccupiedSlotsFromBookings(remaining);
    await _publishAllConfigToSite(showFeedback: true);
    await _fetchBookings(silent: true);
  }

  Future<void> _fetchClientsAndPlanMembers() async {
    try {
      final cliRes = await http.get(Uri.parse('$kFirebaseDbUrl/clients.json'));
      final memRes =
          await http.get(Uri.parse('$kFirebaseDbUrl/plan_members.json'));

      final Map<String, JsonMap> uniqueClients = {};
      final List<JsonMap> memList = [];

      if (cliRes.statusCode == 200 && cliRes.body != 'null') {
        final d = jsonDecode(cliRes.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = JsonMap.from(v);
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
              final item = JsonMap.from(v);
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
      _statusMsg = 'A sincronizar dados App ↔ Site...';
    });
    await Future.wait([
      _fetchBookings(silent: true),
      _fetchCatalog(),
      _fetchBarbers(),
      _fetchClientsAndPlanMembers(),
      _fetchRemoteSettings(silent: false),
    ]);
    await _publishAllConfigToSite();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _statusMsg =
          'Sincronizado • ${_bookings.length} marcação(ões) • ${_clients.length} cliente(s) salvos';
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
        final List<JsonMap> loaded = [];
        final List<JsonMap> brandNew = [];
        final Set<String> allSignatures = {};

        if (res.body != 'null') {
          final decoded = jsonDecode(res.body);
          if (decoded is Map) {
            final deduped = _deduplicateBookingsMap(decoded);

            for (final item in deduped) {
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

        await _publishOccupiedSlotsFromBookings(loaded);

        for (final item in loaded) {
          final cName = _extractBookingClientName(item);
          final cPhone = _extractBookingClientPhone(item);
          if (cName.isNotEmpty || cPhone.isNotEmpty) {
            final alreadySaved = _clients.any((c) {
              final p1 = _normalizePhone((c['phone'] ?? '').toString());
              final p2 = _normalizePhone(cPhone);
              final n1 = _normalizeNameShared((c['name'] ?? '').toString());
              final n2 = _normalizeNameShared(cName);
              return (p2.isNotEmpty && p1 == p2) ||
                  (n2.isNotEmpty && n1 == n2);
            });
            if (!alreadySaved) {
              unawaited(_upsertClientFromBooking(
                name: cName,
                phone: cPhone,
                bookingDate: _extractBookingDateRaw(item),
                bookingTime: _extractBookingTimeRaw(item),
                incrementCount: false,
              ));
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
          final client = _extractBookingClientName(novo);
          final phone = _extractBookingClientPhone(novo);
          final dateLbl = _extractBookingDateRaw(novo);
          final timeLbl = _extractBookingTimeRaw(novo);
          final barber = _extractBookingBarberRaw(novo);

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
          _statusMsg = 'Online • ${loaded.length} marcação(ões)';
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
    if (_publishingConfig) return;
    try {
      final srvRes = await http.get(Uri.parse('$kFirebaseDbUrl/services.json'));
      final plnRes = await http.get(Uri.parse('$kFirebaseDbUrl/plans.json'));

      final List<JsonMap> srvList = [];
      final List<JsonMap> plnList = [];

      if (srvRes.statusCode == 200 && srvRes.body != 'null') {
        final d = jsonDecode(srvRes.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = JsonMap.from(v);
              item['id'] = k.toString();
              srvList.add(item);
            }
          });
        }
      }

      if (plnRes.statusCode == 200 && plnRes.body != 'null') {
        final d = jsonDecode(plnRes.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = JsonMap.from(v);
              item['id'] = k.toString();
              plnList.add(item);
            }
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _services = srvList.isNotEmpty
            ? srvList
            : kDefaultServices.map((e) => JsonMap.from(e)).toList();
        _plans = plnList.isNotEmpty
            ? plnList
            : kDefaultPlans.map((e) => JsonMap.from(e)).toList();
      });
    } catch (_) {}
  }

  Future<void> _fetchBarbers() async {
    if (_publishingConfig) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool alreadySeeded = prefs.getBool(kPrefBarbersSeeded) ?? false;

      final res = await http.get(Uri.parse('$kFirebaseDbUrl/barbers.json'));
      final List<JsonMap> list = [];
      bool remoteHasData = false;

      if (res.statusCode == 200 && res.body != 'null') {
        final d = jsonDecode(res.body);
        if (d is Map && d.isNotEmpty) {
          remoteHasData = true;
          d.forEach((k, v) {
            if (v is Map) {
              final item = JsonMap.from(v);
              item['id'] = k.toString();
              if (item['active'] == false) return;
              final parsedComm =
                  double.tryParse('${item['commission'] ?? 50.0}') ?? 50.0;
              item['commission'] = parsedComm.clamp(0.0, 100.0);
              list.add(item);
            }
          });
        } else if (d is List && d.isNotEmpty) {
          remoteHasData = true;
          for (var i = 0; i < d.length; i++) {
            if (d[i] is Map) {
              final item = JsonMap.from(d[i] as Map);
              item['id'] = i.toString();
              if (item['active'] == false) continue;
              final parsedComm =
                  double.tryParse('${item['commission'] ?? 50.0}') ?? 50.0;
              item['commission'] = parsedComm.clamp(0.0, 100.0);
              list.add(item);
            }
          }
        }
      }

      if (!remoteHasData && !alreadySeeded) {
        list.addAll(kDefaultBarbers.map((e) => JsonMap.from(e)));
        await prefs.setBool(kPrefBarbersSeeded, true);
      } else if (remoteHasData && !alreadySeeded) {
        await prefs.setBool(kPrefBarbersSeeded, true);
      }

      if (!mounted) return;
      setState(() {
        _barbers = list;
        if (_selectedBarberTabIdx >= _barbers.length) {
          _selectedBarberTabIdx = 0;
        }
      });
    } catch (_) {}
  }

  Future<void> _saveBarber({
    JsonMap? existing,
    required String name,
    required String role,
    required double commission,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    final cleanRole = role.trim().isEmpty ? 'Barbeiro' : role.trim();
    final cleanComm = commission.clamp(0.0, 100.0);

    final id = (existing?['id'] ??
            'brb_${_normalizeNameShared(cleanName).replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}')
        .toString();

    final payload = {
      'id': id,
      'name': cleanName,
      'role': cleanRole,
      'commission': cleanComm,
      'active': true,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await http.put(
      Uri.parse('$kFirebaseDbUrl/barbers/$id.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (!mounted) return;
    setState(() {
      final idx = _barbers.indexWhere((e) =>
          (e['id'] ?? '').toString() == id ||
          _normalizeNameShared((e['name'] ?? '').toString()) ==
              _normalizeNameShared(cleanName));
      if (idx >= 0) {
        _barbers[idx] = payload;
      } else {
        _barbers.add(payload);
      }
    });

    await _publishAllConfigToSite(showFeedback: true);
  }

  Future<void> _deleteBarber(JsonMap barber) async {
    final id = (barber['id'] ?? '').toString().trim();
    final bName = (barber['name'] ?? 'Barbeiro').toString();

    if (id.isNotEmpty) {
      await http.delete(Uri.parse('$kFirebaseDbUrl/barbers/$id.json'));
    }

    if (!mounted) return;
    setState(() {
      _barbers.removeWhere((item) {
        final sameId =
            id.isNotEmpty && (item['id'] ?? '').toString().trim() == id;
        final sameName = _normalizeNameShared((item['name'] ?? '').toString()) ==
            _normalizeNameShared(bName);
        return sameId || sameName;
      });
      if (_selectedBarberTabIdx >= _barbers.length) {
        _selectedBarberTabIdx = 0;
      }
    });

    await _publishAllConfigToSite(showFeedback: true);
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

  JsonMap? _findPlanMember({
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

  List<JsonMap> _allowedCatalogOptions({
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
        final List<JsonMap> planOnly = [];

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
        final List<JsonMap> avulsosOnly = [];
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

    final List<JsonMap> all = [];
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
    final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(raw.trim());
    final clean = match != null ? match.group(1)! : raw.trim();
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
    final x = _canonicalBarberKeyShared(a ?? '');
    final y = _canonicalBarberKeyShared(b ?? '');
    if (x.isEmpty || y.isEmpty) return true;
    return x == y;
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
      List<JsonMap> _findBookingsAtSlot(
    DateTime day,
    int slotMin, {
    required String barberFilter,
  }) {
    final int step = _slotStepMinutes <= 0 ? 15 : _slotStepMinutes;
    final int slotEnd = slotMin + step;
    final List<JsonMap> hits = [];

    for (final b in _bookings) {
      final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
      if (st == 'cancelado' || st == 'cancelada') continue;

      final bDt = _parseBookingDate(b);
      if (bDt != null && !_isSameDay(bDt, day)) continue;

      if (!_sameBarberName(_extractBookingBarberRaw(b), barberFilter)) {
        continue;
      }

      final startMin = _timeToMinutes(_extractBookingTimeRaw(b));
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

  bool _hasBookingConflict({
    required DateTime day,
    required int startMin,
    required int durationMin,
    required String barberName,
    String? ignoreBookingKey,
  }) {
    final int endMin = startMin + durationMin;

    for (final b in _bookings) {
      final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
      if (st == 'cancelado' || st == 'cancelada') continue;

      if (ignoreBookingKey != null &&
          ignoreBookingKey.isNotEmpty &&
          _allKeysForBooking(b).contains(ignoreBookingKey)) {
        continue;
      }

      final bDt = _parseBookingDate(b);
      if (bDt != null && !_isSameDay(bDt, day)) continue;

      if (!_sameBarberName(_extractBookingBarberRaw(b), barberName)) {
        continue;
      }

      final bStart = _timeToMinutes(_extractBookingTimeRaw(b));
      if (bStart == null) continue;
      final bEnd = bStart + _bookingDurationMinutes(b);

      if (startMin < bEnd && endMin > bStart) {
        return true;
      }
    }
    return false;
  }

  bool _isWindowFreeForDuration(
    DateTime day,
    int startMin,
    int durationMin, {
    required String barberFilter,
  }) {
    final int endMin = startMin + durationMin;

    final String expKey = _expedienteKeyForDate(day);
    final JsonMap dayExp = _expediente[expKey] ?? {};
    if (dayExp['ativo'] != true) return false;

    final List<IntMap> turnos = [];
    final int? t1s = _timeToMinutes((dayExp['t1Inicio'] ?? '09:00').toString());
    final int? t1e = _timeToMinutes((dayExp['t1Fim'] ?? '12:00').toString());
    if (t1s != null && t1e != null && t1e > t1s) {
      turnos.add({'start': t1s, 'end': t1e});
    }
    if (dayExp['t2Ativo'] == true) {
      final int? t2s =
          _timeToMinutes((dayExp['t2Inicio'] ?? '14:00').toString());
      final int? t2e = _timeToMinutes((dayExp['t2Fim'] ?? '19:00').toString());
      if (t2s != null && t2e != null && t2e > t2s) {
        turnos.add({'start': t2s, 'end': t2e});
      }
    }

    final bool insideTurn = turnos.any(
      (t) => startMin >= (t['start'] ?? 0) && endMin <= (t['end'] ?? 0),
    );
    if (!insideTurn) return false;

    for (final p in _pauses) {
      final pDt = _parseDateString((p['date'] ?? '').toString());
      if (pDt != null && !_isSameDay(pDt, day)) continue;
      final ps = _timeToMinutes((p['start'] ?? '').toString());
      final pe = _timeToMinutes((p['end'] ?? '').toString());
      if (ps != null && pe != null && pe > ps) {
        if (startMin < pe && endMin > ps) return false;
      }
    }

    if (_hasBookingConflict(
      day: day,
      startMin: startMin,
      durationMin: durationMin,
      barberName: barberFilter,
    )) {
      return false;
    }

    return true;
  }

  JsonMap? _findPauseAtSlot(DateTime day, int slotMin) {
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
    final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
    return st == 'concluído' || st == 'concluido';
  }

  DateTime? _parseBookingDate(Map b) {
    final rawDate = _extractBookingDateRaw(b);
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
    final target = _canonicalBarberKeyShared(barberName ?? '');
    if (target.isNotEmpty) {
      for (final b in _barbers) {
        final bName = _canonicalBarberKeyShared((b['name'] ?? '').toString());
        if (bName == target) {
          final val = double.tryParse('${b['commission'] ?? 50.0}') ?? 50.0;
          return val.clamp(0.0, 100.0);
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
    final pct = _getBarberCommissionPct(_extractBookingBarberRaw(b));
    return _calcBookingValue(b) * (pct / 100.0);
  }

  bool _shouldCountBooking(Map b, {bool onlyCompleted = true}) {
    final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
    if (st == 'cancelado' ||
        st == 'cancelada' ||
        st == 'não concluído' ||
        st == 'nao concluido') {
      return false;
    }
    if (onlyCompleted) {
      return st == 'concluído' || st == 'concluido';
    }
    return true;
  }

  JsonMap _periodFinancialSummary(
    String period, {
    bool onlyCompleted = true,
  }) {
    double faturamento = 0;
    double comissao = 0;
    int count = 0;
    for (final b in _bookings) {
      if (!_shouldCountBooking(b, onlyCompleted: onlyCompleted)) continue;
      if (!_matchesPeriod(b, period)) continue;
      final r = _calcBookingValue(b);
      final c = _calcBookingCommission(b);
      faturamento += r;
      comissao += c;
      count++;
    }
    return {
      'faturamento': faturamento,
      'comissao': comissao,
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
    JsonMap patch,
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
    await _publishAllConfigToSite();
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
    final client = _extractBookingClientName(b);
    final dateLbl = _extractBookingDateRaw(b);
    final timeLbl = _extractBookingTimeRaw(b);
    final barber = _extractBookingBarberRaw(b);
    final srvSummary = _buildServiceSummary(b);

    final rawPhone =
        _extractBookingClientPhone(b).replaceAll(RegExp(r'\D'), '');

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
            'APP ↔ SITE',
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

    final List<JsonMap> accountingFilteredBookings = _bookings.where((b) {
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
          _buildScheduleGridSection(),
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
                      const Expanded(
                        child: Text(
                          'FATURAMENTO & COMISSÃO BARBEIROS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF3D97E),
                          ),
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
                  Table(
                    border: TableBorder.all(
                      color: const Color(0x33D4AF37),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(1.4),
                      1: FlexColumnWidth(1.3),
                      2: FlexColumnWidth(1.3),
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
                            child: Text('Faturamento',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.greenAccent)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6),
                            child: Text('Comissão Barbeiros',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent)),
                          ),
                        ],
                      ),
                      _buildAccountingTableRow('Diário (Hoje)', diario),
                      _buildAccountingTableRow('Semanal (7d)', semanal),
                      _buildAccountingTableRow('Mensal (Mês)', mensal),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _periodChip('diario', 'Diário'),
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
                                  '${_extractBookingClientName(b)} (${_extractBookingTimeRaw(b)})',
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
                                  _extractBookingBarberRaw(b),
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
      TableRow _buildAccountingTableRow(String label, JsonMap data) {
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
            'R\$ ${(data['faturamento'] as double).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            'R\$ ${(data['comissao'] as double).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
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

  Widget _buildBookedClientCard(JsonMap bk, String barberName) {
    final bool isDone = _isCompletedStatus(bk);
    final int startM = _timeToMinutes(_extractBookingTimeRaw(bk)) ?? 0;
    final int durM = _bookingDurationMinutes(bk);
    final String startStr = _minutesToTime(startM);
    final String endStr = _minutesToTime(startM + durM);
    final String cName = _extractBookingClientName(bk);
    final String cPhone = _extractBookingClientPhone(bk);
    final String srvSummary = _buildServiceSummary(bk);
    final double val = _calcBookingValue(bk);
    final String stLabel = (bk['status'] ?? 'confirmado').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFF132619) : const Color(0xFF261F0A),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDone ? Colors.greenAccent : const Color(0xFFD4AF37),
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
                      '$cName • $startStr até $endStr',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFFF3D97E),
                      ),
                    ),
                    if (cPhone.isNotEmpty)
                      Text(
                        'Tel: $cPhone',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '$srvSummary • $barberName ($stLabel)',
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
                onTap: () => _deleteBookingAndFreeSiteSlot(bk),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGridRowsForSingleBarber(
    DateTime day,
    String barberName,
    List<int> slotMinutes,
    bool isOpen,
  ) {
    final int step = _slotStepMinutes <= 0 ? 15 : _slotStepMinutes;
    final String dateBR = _formatDateBR(day);
    final Set<String> renderedBookingKeys = {};
    final List<Widget> rows = [];

    // Garante que qualquer cliente marcado no dia e barbeiro apareça sempre na grade
    final dayBookings = _bookings.where((b) {
      final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
      if (st == 'cancelado' || st == 'cancelada') return false;
      final bDt = _parseBookingDate(b);
      if (bDt != null && !_isSameDay(bDt, day)) return false;
      return _sameBarberName(_extractBookingBarberRaw(b), barberName);
    }).toList();

    for (final int m in slotMinutes) {
      final String slotStartStr = _minutesToTime(m);
      final String slotEndStr = _minutesToTime(m + step);
      final JsonMap? pauseHit = _findPauseAtSlot(day, m);
      final List<JsonMap> bookingHits = _findBookingsAtSlot(
        day,
        m,
        barberFilter: barberName,
      );

      if (bookingHits.isNotEmpty) {
        for (final JsonMap hit in bookingHits) {
          final JsonMap bk = hit['booking'] as JsonMap;
          final String uniqueId =
              _bookingDedupeKey(bk, (bk['firebaseKey'] ?? '').toString());
          if (renderedBookingKeys.contains(uniqueId)) continue;
          renderedBookingKeys.add(uniqueId);
          rows.add(_buildBookedClientCard(bk, barberName));
        }
        continue;
      }

      if (pauseHit != null) {
        rows.add(
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
                  '$slotStartStr até $slotEndStr',
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

      final bool canFit40Min = _isWindowFreeForDuration(
        day,
        m,
        40,
        barberFilter: barberName,
      );

      rows.add(
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
                '$slotStartStr até $slotEndStr',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  canFit40Min
                      ? 'HORÁRIO VAGO'
                      : 'VAGO CURTO (INDISPONÍVEL P/ 40M+)',
                  style: TextStyle(
                    fontSize: 11,
                    color: canFit40Min ? Colors.white54 : Colors.amberAccent,
                  ),
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
                  presetBarberName: barberName,
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

    // Caso algum agendamento tenha horário fora dos slots gerados, renderiza-o no topo
    final List<Widget> extraBookedCards = [];
    for (final bk in dayBookings) {
      final String uniqueId =
          _bookingDedupeKey(bk, (bk['firebaseKey'] ?? '').toString());
      if (!renderedBookingKeys.contains(uniqueId)) {
        renderedBookingKeys.add(uniqueId);
        extraBookedCards.add(_buildBookedClientCard(bk, barberName));
      }
    }

    if (!isOpen && rows.isEmpty && extraBookedCards.isEmpty) {
      rows.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Expediente fechado neste dia. Ative na aba Horários.',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
      );
    }

    return [...extraBookedCards, ...rows];
  }
      Widget _buildScheduleGridSection() {
    final String expKey = _expedienteKeyForDate(_gridSelectedDate);
    final JsonMap dayExp = _expediente[expKey] ?? {};
    final bool isOpen = dayExp['ativo'] == true;
    final String dateBR = _formatDateBR(_gridSelectedDate);
    final String weekdayName = _weekdayFullName(_gridSelectedDate);

    final List<String> barberNames = _barbers
        .map((br) => (br['name'] ?? '').toString().trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (barberNames.isEmpty) {
      barberNames.add('Jhonny');
    }

    final int safeBarberIdx =
        _selectedBarberTabIdx.clamp(0, barberNames.length - 1);
    final String activeBarberName = barberNames[safeBarberIdx];

    final List<IntMap> turnos = [];
    final int? t1s = _timeToMinutes((dayExp['t1Inicio'] ?? '09:00').toString());
    final int? t1e = _timeToMinutes((dayExp['t1Fim'] ?? '12:00').toString());
    if (t1s != null && t1e != null && t1e > t1s) {
      turnos.add({'start': t1s, 'end': t1e});
    }
    if (dayExp['t2Ativo'] == true) {
      final int? t2s =
          _timeToMinutes((dayExp['t2Inicio'] ?? '14:00').toString());
      final int? t2e = _timeToMinutes((dayExp['t2Fim'] ?? '19:00').toString());
      if (t2s != null && t2e != null && t2e > t2s) {
        turnos.add({'start': t2s, 'end': t2e});
      }
    }

    final int step = _slotStepMinutes <= 0 ? 15 : _slotStepMinutes;
    final List<int> slotMinutes = [];
    for (final IntMap t in turnos) {
      final int startM = t['start'] ?? 0;
      final int endM = t['end'] ?? 0;
      for (int m = startM; m < endM; m += step) {
        if (!slotMinutes.contains(m)) {
          slotMinutes.add(m);
        }
      }
    }

    for (final JsonMap b in _bookings) {
      final String st =
          (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
      if (st == 'cancelado' || st == 'cancelada') continue;
      final DateTime? bDt = _parseBookingDate(b);
      if (bDt != null && !_isSameDay(bDt, _gridSelectedDate)) continue;
      if (!_sameBarberName(_extractBookingBarberRaw(b), activeBarberName)) {
        continue;
      }
      final int? sm = _timeToMinutes(_extractBookingTimeRaw(b));
      if (sm != null && !slotMinutes.contains(sm)) {
        slotMinutes.add(sm);
      }
    }
    slotMinutes.sort();

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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...List<Widget>.generate(7, (int idx) {
                    final DateTime d = DateTime.now().add(Duration(days: idx));
                    final bool selected = _isSameDay(d, _gridSelectedDate);
                    final String lbl =
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
                      final DateTime? picked = await showDatePicker(
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
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E11),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x44D4AF37)),
              ),
              padding: const EdgeInsets.all(4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(barberNames.length, (idx) {
                    final bName = barberNames[idx];
                    final isTabActive = idx == safeBarberIdx;
                    final countForBarber = _bookings.where((bk) {
                      final st = (bk['status'] ?? 'confirmado')
                          .toString()
                          .trim()
                          .toLowerCase();
                      if (st == 'cancelado' || st == 'cancelada') return false;
                      final dt = _parseBookingDate(bk);
                      return (dt == null || _isSameDay(dt, _gridSelectedDate)) &&
                          _sameBarberName(
                              _extractBookingBarberRaw(bk), bName);
                    }).length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedBarberTabIdx = idx),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isTabActive
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFF1A1A20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.content_cut,
                                size: 14,
                                color: isTabActive
                                    ? Colors.black
                                    : const Color(0xFFD4AF37),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$bName ($countForBarber)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isTabActive
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'AGENDA DE $activeBarberName • $weekdayName ($dateBR)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF3D97E),
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openManualEntryDialog(
                    presetDateStr: dateBR,
                    presetBarberName: activeBarberName,
                  ),
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
            ..._buildGridRowsForSingleBarber(
              _gridSelectedDate,
              activeBarberName,
              slotMinutes,
              isOpen,
            ),
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
      Future<void> _openEditBookingDialog(JsonMap b) async {
    final nameCtrl =
        TextEditingController(text: _extractBookingClientName(b));
    final phoneCtrl =
        TextEditingController(text: _extractBookingClientPhone(b));
    final dateCtrl = TextEditingController(
        text: _extractBookingDateRaw(b).isNotEmpty
            ? _extractBookingDateRaw(b)
            : _formatDateBR(DateTime.now()));
    final timeCtrl = TextEditingController(
        text: _extractBookingTimeRaw(b).isNotEmpty
            ? _extractBookingTimeRaw(b)
            : '09:00');

    String selectedBarber = _extractBookingBarberRaw(b);

    final options = _allowedCatalogOptions(
      clientName: nameCtrl.text,
      clientPhone: phoneCtrl.text,
    );

    String currentSrvName = _buildServiceSummary(b);
    JsonMap selectedService = options.firstWhere(
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
            if (!dynamicOptions
                .any((o) => o['name'] == selectedService['name'])) {
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
                      decoration: const InputDecoration(
                          labelText: 'WhatsApp / Telefone'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dateCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Data (DD/MM/AAAA)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: timeCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Hora Início (HH:MM)'),
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
                      value: _barbers.any((br) => _sameBarberName(
                              br['name']?.toString(), selectedBarber))
                          ? _barbers
                              .firstWhere((br) => _sameBarberName(
                                  br['name']?.toString(),
                                  selectedBarber))['name']
                              .toString()
                          : (_barbers.isNotEmpty
                              ? _barbers.first['name'].toString()
                              : 'Jhonny'),
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
                    final normDate = _normalizeDateShared(dateCtrl.text);
                    final normTime = _normalizeTimeShared(timeCtrl.text);
                    final parsedDt = _parseDateString(normDate);
                    final startM = _timeToMinutes(normTime) ?? 0;
                    final durM =
                        int.tryParse('${selectedService['duration'] ?? 30}') ??
                            30;

                    if (parsedDt != null &&
                        _hasBookingConflict(
                          day: parsedDt,
                          startMin: startM,
                          durationMin: durM,
                          barberName: selectedBarber,
                          ignoreBookingKey: (b['firebaseKey'] ?? '').toString(),
                        )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            'Horário $normTime já está ocupado para $selectedBarber!',
                          ),
                        ),
                      );
                      return;
                    }

                    final endTimeStr = _minutesToTime(startM + durM);

                    final updatedPatch = {
                      'clientName': nameCtrl.text.trim(),
                      'clientPhone': _normalizePhone(phoneCtrl.text),
                      'phone': _normalizePhone(phoneCtrl.text),
                      'dateLabel': normDate,
                      'date': normDate,
                      'time': normTime,
                      'endTime': endTimeStr,
                      'barberName': selectedBarber,
                      'serviceName': selectedService['name'],
                      'price': selectedService['price'],
                      'total': selectedService['price'],
                      'duration': durM,
                      'items': [
                        {
                          'id': selectedService['id'] ?? '',
                          'name': selectedService['name'],
                          'price': selectedService['price'],
                          'duration': durM,
                          'isPlan': selectedService['isPlan'] == true,
                          'sessionsPerMonth':
                              selectedService['sessionsPerMonth'] ?? 1,
                        }
                      ],
                      'updatedAt': DateTime.now().toIso8601String(),
                    };

                    await _patchBookingKeys(
                        _allKeysForBooking(b), updatedPatch);
                    await _upsertClientFromBooking(
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text,
                      bookingDate: normDate,
                      bookingTime: normTime,
                      incrementCount: false,
                    );
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
    String? presetBarberName,
  }) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
        text: presetDateStr ?? _formatDateBR(_gridSelectedDate));
    final timeCtrl = TextEditingController(text: presetTimeStr ?? '09:00');

    String selectedBarber = presetBarberName ??
        (_barbers.isNotEmpty ? _barbers.first['name'].toString() : 'Jhonny');
    bool markAsCompletedNow = false;

    final initialOptions = _allowedCatalogOptions();
    JsonMap selectedService = initialOptions.first;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final qName = _normalizeNameShared(nameCtrl.text);
            final qPhone = _normalizePhone(phoneCtrl.text);
            final List<JsonMap> matchingClients = (qName.length >= 2 ||
                    qPhone.length >= 4)
                ? _clients.where((c) {
                    final cn =
                        _normalizeNameShared((c['name'] ?? '').toString());
                    final cp = _normalizePhone((c['phone'] ?? '').toString());
                    return (qName.length >= 2 && cn.contains(qName)) ||
                        (qPhone.length >= 4 && cp.contains(qPhone));
                  }).take(4).toList()
                : [];

            final dynamicOptions = _allowedCatalogOptions(
              clientName: nameCtrl.text,
              clientPhone: phoneCtrl.text,
            );
            if (!dynamicOptions
                .any((o) => o['name'] == selectedService['name'])) {
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

            final int startM =
                _timeToMinutes(_normalizeTimeShared(timeCtrl.text)) ?? 540;
            final int durM =
                int.tryParse('${selectedService['duration'] ?? 30}') ?? 30;
            final String previewEndStr = _minutesToTime(startM + durM);

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
                      decoration: const InputDecoration(
                        labelText: 'Nome do Cliente (busca automática)',
                      ),
                    ),
                    if (matchingClients.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C22),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x55D4AF37)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Clientes salvos (toque para preencher):',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xFFF3D97E)),
                            ),
                            ...matchingClients.map((mc) {
                              final mcName = (mc['name'] ?? '').toString();
                              final mcPhone = (mc['phone'] ?? '').toString();
                              return InkWell(
                                onTap: () {
                                  setModalState(() {
                                    nameCtrl.text = mcName;
                                    phoneCtrl.text = mcPhone;
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '• $mcName ($mcPhone)',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.greenAccent),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      onChanged: (_) => setModalState(() {}),
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'WhatsApp (DDD + Número)'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dateCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Data (DD/MM/AAAA)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: timeCtrl,
                            onChanged: (_) => setModalState(() {}),
                            decoration: const InputDecoration(
                                labelText: 'Hora Início (HH:MM)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Faixa do atendimento: ${_normalizeTimeShared(timeCtrl.text)} até $previewEndStr ($durM min)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFF3D97E),
                      ),
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
                        final d = opt['duration'] ?? 30;
                        return DropdownMenuItem<String>(
                          value: opt['name'].toString(),
                          child: Text(
                            '${opt['name']} • R\$ $p (${d}m)',
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
                      value: _barbers.any((b) => _sameBarberName(
                              b['name']?.toString(), selectedBarber))
                          ? _barbers
                              .firstWhere((b) => _sameBarberName(
                                  b['name']?.toString(),
                                  selectedBarber))['name']
                              .toString()
                          : (_barbers.isNotEmpty
                              ? _barbers.first['name'].toString()
                              : 'Jhonny'),
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
                    final parsedDt = _parseDateString(normDate);

                    if (parsedDt != null &&
                        _hasBookingConflict(
                          day: parsedDt,
                          startMin: startM,
                          durationMin: durM,
                          barberName: selectedBarber,
                        )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            'Horário $normTime já está ocupado para $selectedBarber! Escolha outro horário.',
                          ),
                        ),
                      );
                      return;
                    }

                    final deterministicId =
                        'bk_${normDate.replaceAll('/', '')}_${normTime.replaceAll(':', '')}_${_canonicalBarberKeyShared(selectedBarber)}_${normPhone.isNotEmpty ? normPhone : _normalizeNameShared(clientName).replaceAll(' ', '_')}';

                    final JsonMap payload = {
                      'firebaseKey': deterministicId,
                      'bookingId': deterministicId,
                      'clientName': clientName,
                      'clientPhone': normPhone,
                      'phone': normPhone,
                      'dateLabel': normDate,
                      'date': normDate,
                      'time': normTime,
                      'endTime': previewEndStr,
                      'barberName': selectedBarber,
                      'serviceName': selectedService['name'],
                      'price': selectedService['price'],
                      'total': selectedService['price'],
                      'duration': durM,
                      'status':
                          markAsCompletedNow ? 'concluído' : 'confirmado',
                      'attended': markAsCompletedNow,
                      'source': 'app_gestao',
                      'items': [
                        {
                          'id': selectedService['id'] ?? '',
                          'name': selectedService['name'],
                          'price': selectedService['price'],
                          'duration': durM,
                          'isPlan': selectedService['isPlan'] == true,
                          'sessionsPerMonth':
                              selectedService['sessionsPerMonth'] ?? 1,
                        }
                      ],
                      'createdAt': DateTime.now().toIso8601String(),
                      'updatedAt': DateTime.now().toIso8601String(),
                    };

                    if (mounted) {
                      setState(() {
                        if (parsedDt != null) {
                          _gridSelectedDate = parsedDt;
                        }
                        final bIdx = _barbers.indexWhere((br) =>
                            _sameBarberName(br['name']?.toString(), selectedBarber));
                        if (bIdx >= 0) {
                          _selectedBarberTabIdx = bIdx;
                        }
                        _bookings.removeWhere((item) =>
                            _bookingDedupeKey(
                                item, (item['firebaseKey'] ?? '').toString()) ==
                            _bookingDedupeKey(payload, deterministicId));
                        _bookings.add(payload);
                      });
                    }

                    await http.put(
                      Uri.parse(
                          '$kFirebaseDbUrl/bookings/$deterministicId.json'),
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

                    await _publishAllConfigToSite();
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

  Widget _buildCatalogItemCard(JsonMap item, {required bool isPlan}) {
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
                if (mounted) {
                  setState(() {
                    if (isPlan) {
                      _plans.removeWhere((e) => e['id'] == id);
                    } else {
                      _services.removeWhere((e) => e['id'] == id);
                    }
                  });
                }
                await _publishAllConfigToSite(showFeedback: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCatalogItemDialog({
    JsonMap? existing,
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
                            decoration: const InputDecoration(
                                labelText: 'Duração (min)'),
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
                      'sessionsPerMonth': isPlan
                          ? (int.tryParse(sessCtrl.text.trim()) ?? 4)
                          : 1,
                      'active': isActive,
                      'updatedAt': DateTime.now().toIso8601String(),
                    };

                    await http.put(
                      Uri.parse('$kFirebaseDbUrl/$node/$id.json'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(payload),
                    );

                    if (mounted) {
                      setState(() {
                        final targetList = isPlan ? _plans : _services;
                        final idx =
                            targetList.indexWhere((e) => e['id'] == id);
                        if (idx >= 0) {
                          targetList[idx] = payload;
                        } else {
                          targetList.add(payload);
                        }
                      });
                    }

                    await _publishAllConfigToSite(showFeedback: true);
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
                            onChanged: (v) => _expediente[dayKey]!['t1Inicio'] =
                                _normalizeTimeShared(v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _expControllers['${dayKey}_t1Fim'],
                            decoration:
                                const InputDecoration(labelText: 'Fim 1'),
                            onChanged: (v) => _expediente[dayKey]!['t1Fim'] =
                                _normalizeTimeShared(v),
                          ),
                        ),
                        if (t2Ativo) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _expControllers['${dayKey}_t2Ini'],
                              decoration:
                                  const InputDecoration(labelText: 'Início 2'),
                              onChanged: (v) => _expediente[dayKey]!['t2Inicio'] =
                                  _normalizeTimeShared(v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _expControllers['${dayKey}_t2Fim'],
                              decoration:
                                  const InputDecoration(labelText: 'Fim 2'),
                              onChanged: (v) => _expediente[dayKey]!['t2Fim'] =
                                  _normalizeTimeShared(v),
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
          onPressed: _saveExpedienteAndSync,
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
          'BANCO DE DADOS DE CLIENTES (NOME & CONTATO SALVOS)',
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

  Future<void> _sendManualPlanExpiryWhatsApp(JsonMap m) async {
    final cName = (m['clientName'] ?? 'Cliente').toString();
    final planName = (m['planName'] ?? 'Plano Mensal').toString();
    final expStr = (m['expiresAt'] ?? '').toString();
    final phone = _normalizePhone((m['phone'] ?? '').toString());

    final msg =
        'Olá $cName! Lembrete da *Barbearia Mr Jone*: a data de vencimento do seu *$planName* está chegando ($expStr). Avise-nos para renovar!';
    final encoded = Uri.encodeComponent(msg);
    final uri = phone.length >= 12
        ? Uri.parse('https://api.whatsapp.com/send?phone=$phone&text=$encoded')
        : Uri.parse('https://api.whatsapp.com/send?text=$encoded');

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openPlanMemberDialog({
    JsonMap? existing,
    String? presetName,
    String? presetPhone,
  }) async {
    final nameCtrl = TextEditingController(
        text: (existing?['clientName'] ?? presetName ?? '').toString());
    final phoneCtrl = TextEditingController(
        text: (existing?['phone'] ?? presetPhone ?? '').toString());
    final defaultExpiry =
        _formatDateBR(DateTime.now().add(const Duration(days: 30)));
    final expiryCtrl = TextEditingController(
        text: (existing?['expiresAt'] ?? defaultExpiry).toString());

    JsonMap selectedPlan = _plans.firstWhere(
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
                      decoration: const InputDecoration(
                          labelText: 'WhatsApp (DDD + Número)'),
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

                    await _upsertClientFromBooking(
                      name: nameCtrl.text.trim(),
                      phone: normPhone,
                      incrementCount: false,
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
        if (_barbers.isEmpty)
          const Card(
            color: Color(0xFF141417),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Nenhum barbeiro cadastrado. Clique em "Novo Barbeiro" para adicionar.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          )
        else
          ..._barbers.map((br) {
            final bName = (br['name'] ?? '').toString().trim();
            final displayName = bName.isEmpty ? 'Sem Nome' : bName;
            final roleStr = (br['role'] ?? 'Barbeiro').toString();
            final commPct = _getBarberCommissionPct(bName);

            double gerado = 0;
            int atendimentos = 0;
            for (final bk in _bookings) {
              if (!_shouldCountBooking(bk,
                  onlyCompleted: _onlyCompletedInAccounting)) {
                continue;
              }
              if (!_matchesPeriod(bk, _barberReportPeriod)) continue;
              if (!_sameBarberName(_extractBookingBarberRaw(bk), bName)) {
                continue;
              }
              gerado += _calcBookingValue(bk);
              atendimentos++;
            }
            final comissao = gerado * (commPct / 100.0);

            return Card(
              color: const Color(0xFF141417),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  '$displayName • Comissão: ${commPct.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                  ),
                ),
                subtitle: Text(
                  '$roleStr\nAtendimentos: $atendimentos • Faturamento: R\$ ${gerado.toStringAsFixed(2)} • Comissão: R\$ ${comissao.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar Barbeiro / Comissão',
                      icon: const Icon(Icons.edit, color: Color(0xFFD4AF37)),
                      onPressed: () => _openBarberDialog(existing: br),
                    ),
                    IconButton(
                      tooltip: 'Excluir Barbeiro',
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () => _confirmDeleteBarber(br),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _confirmDeleteBarber(JsonMap br) async {
    final bName = (br['name'] ?? 'Barbeiro').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: const Text(
          'Excluir Barbeiro',
          style: TextStyle(color: Color(0xFFF3D97E), fontSize: 16),
        ),
        content: Text(
          'Deseja excluir "$bName" do App e do Site?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBarber(br);
    }
  }

  Future<void> _openBarberDialog({JsonMap? existing}) async {
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
          existing == null ? 'Adicionar Barbeiro' : 'Editar Barbeiro & Comissão',
          style: const TextStyle(color: Color(0xFFF3D97E), fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome do Barbeiro'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(labelText: 'Função / Cargo'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Comissão (%) ex: 50 ou 100'),
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
              final cleanName = nameCtrl.text.trim();
              if (cleanName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Informe o nome do barbeiro.')),
                );
                return;
              }
              final parsedComm =
                  double.tryParse(commCtrl.text.replaceAll(',', '.')) ?? 50.0;

              await _saveBarber(
                existing: existing,
                name: cleanName,
                role: roleCtrl.text,
                commission: parsedComm,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar e Sincronizar'),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0x44D4AF37)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SINCRONIZAÇÃO EM TEMPO REAL (APP ↔ SITE)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tudo o que você alterar no app (agendamentos, exclusões que liberam horários no site, preços, expediente, barbeiros e comissões) reflete no site imediatamente.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _publishAllConfigToSite(showFeedback: true),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text(
                    'SINCRONIZAR APP E SITE AGORA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          color: const Color(0xFF141417),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0x44D4AF37)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SEGURANÇA DO PAINEL ADMIN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPassController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nova palavra-passe admin',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _saveNewAdminPass(_newPassController.text),
                  icon: const Icon(Icons.key),
                  label: const Text(
                    'SALVAR PALAVRA-PASSE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: _logoutAccount,
                  icon: const Icon(Icons.logout),
                  label: const Text('SAIR DO PAINEL'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
