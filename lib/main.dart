import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const String kFirebaseDbUrl =
    'https://barbeariamrjone-f3e8a-default-rtdb.firebaseio.com';
const String kDefaultAdminPass = '1234';
const String kPrefAdminPass = 'mrjone_admin_pass';
const String kPrefLoggedIn = 'mrjone_logged_in';
const String kPrefKnownBookingKeys = 'mrjone_known_booking_keys';
const String kPrefExpediente = 'mrjone_expediente_v1';
const String kPrefPauses = 'mrjone_pauses_v1';
const String kPrefSlotStep = 'mrjone_slot_step_v1';
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
  },
  {
    'id': 'def_srv_2',
    'name': 'Corte Degradê / Disfarçado / Navalhado',
    'category': 'Cortes',
    'price': 40.0,
    'duration': 40,
    'isPlan': false,
    'sessionsPerMonth': 1,
  },
  {
    'id': 'def_srv_3',
    'name': 'Corte (Um Pente Só)',
    'category': 'Cortes',
    'price': 35.0,
    'duration': 30,
    'isPlan': false,
    'sessionsPerMonth': 1,
  },
  {
    'id': 'def_srv_4',
    'name': 'Barba Completa',
    'category': 'Barba & Acabamentos',
    'price': 30.0,
    'duration': 20,
    'isPlan': false,
    'sessionsPerMonth': 1,
  },
  {
    'id': 'def_srv_5',
    'name': 'Sobrancelha',
    'category': 'Barba & Acabamentos',
    'price': 8.0,
    'duration': 10,
    'isPlan': false,
    'sessionsPerMonth': 1,
  },
  {
    'id': 'def_srv_6',
    'name': 'Só Pezinho (Acabamento)',
    'category': 'Barba & Acabamentos',
    'price': 10.0,
    'duration': 15,
    'isPlan': false,
    'sessionsPerMonth': 1,
  },
  {
    'id': 'def_srv_7',
    'name': 'Pigmentação',
    'category': 'Barba & Acabamentos',
    'price': 15.0,
    'duration': 15,
    'isPlan': false,
    'sessionsPerMonth': 1,
  },
  {
    'id': 'def_srv_8',
    'name': 'Platinado ou Luzes + Corte',
    'category': 'Química',
    'price': 100.0,
    'duration': 60,
    'isPlan': false,
    'sessionsPerMonth': 1,
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
  },
  {
    'id': 'def_pln_2',
    'name': 'Plano Mensal: Só Cabelo (Toda Semana)',
    'category': 'Planos Mensais',
    'price': 110.0,
    'duration': 40,
    'isPlan': true,
    'sessionsPerMonth': 4,
  },
  {
    'id': 'def_pln_3',
    'name': 'Plano Mensal: Só Barba (Toda Semana)',
    'category': 'Planos Mensais',
    'price': 75.0,
    'duration': 20,
    'isPlan': true,
    'sessionsPerMonth': 4,
  },
];

final List> kDefaultBarbers = [
  {
    'id': 'def_brb_jhonny',
    'name': 'Jhonny',
    'role': 'Proprietário / Barbeiro',
    'commission': 100.0,
  },
  {
    'id': 'def_brb_marcelo',
    'name': 'Marcelo',
    'role': 'Barbeiro',
    'commission': 50.0,
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
  return clean.toLowerCase();
}
String _bookingDedupeKey(Map b, String firebaseKey) {
  final explicitId = (b['bookingId'] ?? b['clientBookingId'] ?? b['uid'] ?? '')
      .toString()
      .trim();
  if (explicitId.isNotEmpty) {
    return 'id:${explicitId.toLowerCase()}';
  }

  final client = _normalizeNameShared((b['clientName'] ?? '').toString());
  final phone = _normalizePhoneShared(
    (b['clientPhone'] ?? b['phone'] ?? '').toString(),
  );
  final date = _normalizeDateShared((b['dateLabel'] ?? b['date'] ?? '').toString());
  final time = _normalizeTimeShared((b['time'] ?? '').toString());
  final barber = _normalizeNameShared((b['barberName'] ?? '').toString());

  String itemsSig = '';
  if (b['items'] is List && (b['items'] as List).isNotEmpty) {
    itemsSig = (b['items'] as List)
        .whereType()
        .map((it) => _normalizeNameShared((it['name'] ?? '').toString()))
        .where((s) => s.isNotEmpty)
        .join('|');
  }
  if (itemsSig.isEmpty) {
    itemsSig = _normalizeNameShared(
      (b['serviceName'] ?? b['service'] ?? '').toString(),
    );
  }

  if (client.isEmpty && phone.isEmpty && date.isEmpty && time.isEmpty) {
    return 'fb:$firebaseKey';
  }

  final identityPart = phone.isNotEmpty ? phone : client;
  return 'slot:$identityPart|$client|$date|$time|$barber|$itemsSig';
}
int _bookingStatusPriority(Map b) {
  final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
  if (st == 'concluído' || st == 'concluido') return 4;
  if (st == 'confirmado') return 3;
  if (st == 'não concluído' || st == 'nao concluido') return 2;
  if (st == 'cancelado') return 1;
  return 0;
}

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
  result.sort((a, b) => (b['createdAt'] ?? '')
      .toString()
      .compareTo((a['createdAt'] ?? '').toString()));
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
    'Novos Agendamentos',
    description: 'Avisos quando um cliente faz um novo agendamento',
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
    ongoing ? 'Monitoramento Mr Jone' : 'Novos Agendamentos',
    channelDescription: ongoing
        ? 'Mantém a monitorização ativa mesmo com o app fechado'
        : 'Avisos quando um cliente faz um novo agendamento',
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
bool _bgChecking = false;

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
          'A monitorizar agendamentos mesmo com o app fechado',
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
  String _barberReportPeriod = 'mensal';

  DateTime _gridSelectedDate = DateTime.now();
  String _gridSelectedBarberFilter = 'TODOS';

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
    _services = kDefaultServices.map((e) => Map<String, dynamic>.from(e)).toList();
    _plans = kDefaultPlans.map((e) => Map<String, dynamic>.from(e)).toList();
    _barbers = kDefaultBarbers.map((e) => Map<String, dynamic>.from(e)).toList();
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
      const Duration(seconds: 25),
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

  Future<void> _saveExpedienteAndSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefExpediente, jsonEncode(_expediente));
    await prefs.setInt(kPrefSlotStep, _slotStepMinutes);

    try {
      await http.put(
        Uri.parse('$kFirebaseDbUrl/expediente.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_expediente),
      );
      await http.put(
        Uri.parse('$kFirebaseDbUrl/slotStepMinutes.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_slotStepMinutes),
      );
    } catch (_) {}
  }

  Future<void> _savePausesAndSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefPauses, jsonEncode(_pauses));

    try {
      await http.put(
        Uri.parse('$kFirebaseDbUrl/pauses.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_pauses),
      );
    } catch (_) {}
  }
      Future<void> _fetchRemoteSettings() async {
    try {
      final expRes = await http.get(Uri.parse('$kFirebaseDbUrl/expediente.json'));
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

      final pausesRes = await http.get(Uri.parse('$kFirebaseDbUrl/pauses.json'));
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
                final prevCount =
                    int.tryParse('${uniqueClients[cKey]!['totalBookings'] ?? 0}') ??
                        0;
                final currCount = int.tryParse('${item['totalBookings'] ?? 0}') ?? 0;
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
          _statusMsg = 'Online • ${loaded.length} registo(s)';
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
            : kDefaultServices.map((e) => Map<String, dynamic>.from(e)).toList();
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
     DateTime? _parseDateString(String raw) {
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

  String _formatDateBR(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd/$mm/${dt.year}';
  }

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

  Map<String, dynamic>? _findPlanMember({String? clientName, String? clientPhone}) {
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
          final pName = (p['name'] ?? '').toString();
          final pNorm = _normalizeNameShared(pName);
          if (assignedPlanName.isEmpty ||
              pNorm == assignedPlanName ||
              pNorm.contains(assignedPlanName) ||
              assignedPlanName.contains(pNorm)) {
            planOnly.add({
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
          avulsosOnly.add({
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
      all.add({
        'name': (s['name'] ?? '').toString(),
        'price': double.tryParse('${s['price'] ?? 0}') ?? 0.0,
        'duration': int.tryParse('${s['duration'] ?? 30}') ?? 30,
        'isPlan': false,
        'sessionsPerMonth': 1,
        'mode': 'normal',
      });
    }
    for (final p in _plans) {
      all.add({
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

  Map<String, dynamic>? _findBookingAtSlot(
    DateTime day,
    int slotMin, {
    String barberFilter = 'TODOS',
  }) {
    final int step = _slotStepMinutes <= 0 ? 15 : _slotStepMinutes;
    final int slotEnd = slotMin + step;

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
        return {
          'booking': b,
          'startMin': startMin,
          'endMin': endMin,
          'startStr': _minutesToTime(startMin),
          'endStr': _minutesToTime(endMin),
          'isStart': slotMin == startMin,
        };
      }
    }
    return null;
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

  bool _isNotCompletedStatus(Map b) {
    final st = (b['status'] ?? '').toString().trim().toLowerCase();
    return st == 'não concluído' || st == 'nao concluido';
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

  double _calcComissaoItem(Map item, double commPct) {
    return _calcReceitaItem(item) * (commPct / 100.0);
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

  Map<String, double> _periodFinancialSummary(
    String period, {
    bool onlyCompleted = true,
  }) {
    double receita = 0;
    double comissao = 0;
    for (final b in _bookings) {
      if (!_shouldCountBooking(b, onlyCompleted: onlyCompleted)) continue;
      if (!_matchesPeriod(b, period)) continue;
      final r = _calcBookingValue(b);
      final c = _calcBookingCommission(b);
      receita += r;
      comissao += c;
    }
    return {
      'receita': receita,
      'comissao': comissao,
      'liquido': receita - comissao,
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
        ? 'Olá $client! Seu horário na *Barbearia Mr Jone* foi reagendado para *$dateLbl* às *$timeLbl* ($srvSummary com *$barber*). Qualquer dúvida estamos à disposição!'
        : 'Olá $client! Lembrete da Barbearia Mr Jone: marcou o horário das *$timeLbl* em *$dateLbl* para o serviço *$srvSummary* com *$barber*. Estamos à sua espera!';

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
        const SnackBar(
          content: Text('Erro ao tentar abrir o WhatsApp.'),
        ),
      );
    }
  }
      Widget _buildAccountingTab() {
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

    final List> visibleBookings = _bookings.where((b) {
      if (!_onlyCompletedInAccounting) return true;
      final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
      return st != 'cancelado';
    }).toList();

    Widget periodCard(String title, Map<String, double> data) {
      return Card(
        color: const Color(0xFF141417),
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF3D97E),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Receita: R\$ ${(data['receita'] ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  Text(
                    'Comissões: R\$ ${(data['comissao'] ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.orangeAccent),
                  ),
                  Text(
                    'Líquido: R\$ ${(data['liquido'] ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _syncAll,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildHeaderBanner(),
          periodCard('CONTABILIDADE DIÁRIA (HOJE)', diario),
          periodCard('CONTABILIDADE SEMANAL (ÚLTIMOS 7 DIAS)', semanal),
          periodCard('CONTABILIDADE MENSAL (MÊS ATUAL)', mensal),
          const SizedBox(height: 6),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () => _openManualEntryDialog(),
            icon: const Icon(Icons.add_card),
            label: const Text('Encaixar / Registar Atendimento Manual'),
          ),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF141417),
            child: SwitchListTile(
              title: const Text(
                'Somar apenas clientes CONCLUÍDOS no total',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Ativo por padrão: Concluir soma; Não concluído fica na agenda até excluir.',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
              value: _onlyCompletedInAccounting,
              activeColor: const Color(0xFFD4AF37),
              onChanged: (v) => setState(() => _onlyCompletedInAccounting = v),
            ),
          ),
          const SizedBox(height: 12),
          _buildScheduleGridSection(),
          const Text(
            'AGENDA & ATENDIMENTOS (SEM DUPLICATAS)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF3D97E),
            ),
          ),
          const SizedBox(height: 6),
          if (_loading && _bookings.isEmpty)
            const Center(child: CircularProgressIndicator()),
          ...visibleBookings.map((b) {
            final String key = (b['firebaseKey'] ?? '').toString();
            final String status = (b['status'] ?? 'confirmado').toString();
            final bool isDone = _isCompletedStatus(b);
            final bool isNotDone = _isNotCompletedStatus(b);
            final double val = _calcBookingValue(b);
            final double comm = _calcBookingCommission(b);
            final String srvNames = _buildServiceSummary(b);
            final String cName = (b['clientName'] ?? 'Cliente').toString();

            return Card(
              color: const Color(0xFF141417),
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$cName • ${b['dateLabel'] ?? b['date'] ?? ''} ${b['time'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF3D97E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Barbeiro: ${b['barberName'] ?? 'Jhonny'} • Receita: R\$ ${val.toStringAsFixed(2)} • Comissão: R\$ ${comm.toStringAsFixed(2)} • $status',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      srvNames,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => _openEditBookingDialog(b),
                          child: const Text(
                            'Reagendar / Editar',
                            style: TextStyle(color: Color(0xFFF3D97E)),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openWhatsApp(b),
                          child: const Text(
                            'WhatsApp',
                            style: TextStyle(color: Colors.greenAccent),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _patchBookingKeys(_allKeysForBooking(b), {
                              'status': 'concluído',
                              'attended': true,
                              'completedAt': DateTime.now().toIso8601String(),
                            });
                            await _fetchBookings(silent: true);
                          },
                          child: Text(
                            isDone ? 'Concluído ✓' : 'Concluir',
                            style: TextStyle(
                              color: isDone
                                  ? Colors.greenAccent
                                  : const Color(0xFFF3D97E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _patchBookingKeys(_allKeysForBooking(b), {
                              'status': 'não concluído',
                              'attended': false,
                              'completedAt': null,
                            });
                            await _fetchBookings(silent: true);
                          },
                          child: Text(
                            isNotDone ? 'Não concluído ✓' : 'Não concluído',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: isNotDone
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _patchBookingKeys(_allKeysForBooking(b), {
                              'status': 'cancelado',
                            });
                            await _fetchBookings(silent: true);
                          },
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () async {
                            for (final k in _allKeysForBooking(b)) {
                              await http.delete(
                                  Uri.parse('$kFirebaseDbUrl/bookings/$k.json'));
                            }
                            await _fetchBookings(silent: true);
                          },
                          child: const Text(
                            'Excluir',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
      }
      Widget _buildScheduleGridSection() {
    final String expKey = _expedienteKeyForDate(_gridSelectedDate);
    final Map<String, dynamic> dayExp = _expediente[expKey] ?? {};
    final bool isOpen = dayExp['ativo'] == true;
    final String dateBR = _formatDateBR(_gridSelectedDate);
    final String weekdayName = _weekdayFullName(_gridSelectedDate);

    final List> turnos = [];
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

    return Card(
      color: const Color(0xFF141417),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x33D4AF37), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GRADE DIÁRIA • $weekdayName ($dateBR)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                    fontSize: 13,
                  ),
                ),
                TextButton.icon(
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
                  icon: const Icon(Icons.calendar_month,
                      size: 16, color: Color(0xFFD4AF37)),
                  label: const Text('Data'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!isOpen || slotMinutes.isEmpty)
              const Text(
                'Expediente fechado neste dia. Ative na aba Horários.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              )
            else
              ...slotMinutes.map((m) {
                final String slotStartStr = _minutesToTime(m);
                final String slotEndStr = _minutesToTime(m + step);
                final pauseHit = _findPauseAtSlot(_gridSelectedDate, m);
                final bookingHit = _findBookingAtSlot(
                  _gridSelectedDate,
                  m,
                  barberFilter: _gridSelectedBarberFilter,
                );

                if (pauseHit != null) {
                  return ListTile(
                    dense: true,
                    title: Text('$slotStartStr–$slotEndStr • PAUSA'),
                    subtitle: Text('${pauseHit['reason']}'),
                  );
                }

                if (bookingHit != null) {
                  final bk = bookingHit['booking'] as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    tileColor: const Color(0xFF231D09),
                    title: Text(
                      '$slotStartStr–$slotEndStr • ${bk['clientName'] ?? 'Cliente'}',
                      style: const TextStyle(color: Color(0xFFF3D97E)),
                    ),
                    subtitle: Text(
                      'Barbeiro: ${bk['barberName'] ?? 'Jhonny'} • ${_buildServiceSummary(bk)}',
                    ),
                    trailing: TextButton(
                      onPressed: () => _openManualEntryDialog(
                        presetDateStr: dateBR,
                        presetTimeStr: slotStartStr,
                      ),
                      child: const Text('Encaixar'),
                    ),
                  );
                }

                return ListTile(
                  dense: true,
                  title: Text('$slotStartStr–$slotEndStr • LIVRE'),
                  trailing: TextButton(
                    onPressed: () => _openManualEntryDialog(
                      presetDateStr: dateBR,
                      presetTimeStr: slotStartStr,
                    ),
                    child: const Text('+ Marcar / Encaixar'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
