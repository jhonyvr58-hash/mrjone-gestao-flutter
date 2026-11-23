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

final Map<String, Map> kDefaultExpediente = {
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
final List kDefaultServices = [
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

final List kDefaultPlans = [
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
final FlutterLocalNotificationsPlugin kNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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
@pragma('vm:entry-point')
void _onStartBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await _initNotifications();

  Future<void> checkNewBookingsBg() async {
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
          final List<String> currentKeys = [];
          final List brandNew = [];

          decoded.forEach((key, val) {
            if (val is Map) {
              final k = key.toString();
              currentKeys.add(k);
              if (savedList.isNotEmpty && !knownSet.contains(k)) {
                final item = Map.from(val);
                item['firebaseKey'] = k;
                brandNew.add(item);
              }
            }
          });

          int notifId = 500;
          for (final novo in brandNew) {
            final client = (novo['clientName'] ?? 'Cliente').toString();
            final dateLbl = (novo['dateLabel'] ?? '').toString();
            final timeLbl = (novo['time'] ?? '').toString();
            final barber =
                (novo['barberName'] ?? 'Barbearia Mr Jone').toString();
            await _showBookingNotification(
              'Novo agendamento • $client',
              '$dateLbl às $timeLbl ($barber)',
              notifId++,
            );
          }

          await prefs.setStringList(kPrefKnownBookingKeys, currentKeys);
        }
      }
    } catch (_) {}
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
  int _tabIndex = 0;

  bool _onlyCompletedInAccounting = true;
  String _barberReportPeriod = 'mensal'; // 'semanal' ou 'mensal'

  String _statusMsg = 'A aguardar ligação ao Firebase';
  String _adminPass = kDefaultAdminPass;
  int _slotStepMinutes = 15;

  final TextEditingController _passController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();

  Map<String, Map> _expediente = {};
  List _pauses = [];
  List _bookings = [];
  List _newAlerts = [];
  List _services = [];
  List _plans = [];
  List _barbers = [];
  List _clients = [];
  List _planMembers = [];

  final Set<String> _knownKeys = {};
  bool _firstLoadDone = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _services = List.from(kDefaultServices);
    _plans = List.from(kDefaultPlans);
    _expediente = _cloneDefaultExpediente();
    _loadSavedSessionAndPass();
  }

  Map<String, Map> _cloneDefaultExpediente() {
    final Map<String, Map> copy = {};
    kDefaultExpediente.forEach((k, v) {
      copy[k] = Map.from(v);
    });
    return copy;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _passController.dispose();
    _newPassController.dispose();
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

    Map<String, Map> loadedExp = _cloneDefaultExpediente();
    if (savedExpRaw != null && savedExpRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedExpRaw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (v is Map && loadedExp.containsKey(k.toString())) {
              loadedExp[k.toString()] = {
                ...loadedExp[k.toString()]!,
                ...Map.from(v),
              };
            }
          });
        }
      } catch (_) {}
    }

    List loadedPauses = [];
    if (savedPausesRaw != null && savedPausesRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedPausesRaw);
        if (decoded is List) loadedPauses = decoded;
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
                ...Map.from(v),
              };
            }
          });
          if (mounted) {
            setState(() => _expediente = merged);
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(kPrefExpediente, jsonEncode(merged));
        }
      }

      final pausesRes = await http.get(Uri.parse('$kFirebaseDbUrl/pauses.json'));
      if (pausesRes.statusCode == 200 && pausesRes.body != 'null') {
        final decoded = jsonDecode(pausesRes.body);
        if (decoded is List && mounted) {
          setState(() => _pauses = decoded);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(kPrefPauses, jsonEncode(decoded));
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

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10 && !digits.startsWith('55')) {
      return '55$digits';
    }
    return digits;
  }

  Future<void> _upsertClientFromBooking({
    required String name,
    required String phone,
    String? bookingDate,
    String? bookingTime,
  }) async {
    final cleanName = name.trim();
    final normPhone = _normalizePhone(phone);
    if (cleanName.isEmpty && normPhone.isEmpty) return;

    try {
      String? existingKey;
      Map existingData = {};

      for (final c in _clients) {
        if (c is! Map) continue;
        final cPhone = _normalizePhone((c['phone'] ?? '').toString());
        final cName = (c['name'] ?? '').toString().trim().toLowerCase();
        if ((normPhone.isNotEmpty && cPhone == normPhone) ||
            (normPhone.isEmpty &&
                cleanName.isNotEmpty &&
                cName == cleanName.toLowerCase())) {
          existingKey = (c['id'] ?? '').toString();
          existingData = Map.from(c);
          break;
        }
      }

      final int prevBookings =
          int.tryParse('${existingData['totalBookings'] ?? 0}') ?? 0;

      final payload = {
        'name': cleanName.isNotEmpty
            ? cleanName
            : (existingData['name'] ?? 'Cliente').toString(),
        'phone': normPhone.isNotEmpty
            ? normPhone
            : (existingData['phone'] ?? phone).toString(),
        'lastBookingDate': bookingDate ??
            (existingData['lastBookingDate'] ?? '').toString(),
        'lastBookingTime': bookingTime ??
            (existingData['lastBookingTime'] ?? '').toString(),
        'totalBookings': prevBookings + 1,
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
        await http.post(
          Uri.parse('$kFirebaseDbUrl/clients.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }
      await _fetchClientsAndPlanMembers();
    } catch (_) {}
  }

  Future<void> _fetchClientsAndPlanMembers() async {
    try {
      final cliRes = await http.get(Uri.parse('$kFirebaseDbUrl/clients.json'));
      final memRes =
          await http.get(Uri.parse('$kFirebaseDbUrl/plan_members.json'));

      final List cliList = [];
      final List memList = [];

      if (cliRes.statusCode == 200 && cliRes.body != 'null') {
        final d = jsonDecode(cliRes.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = Map.from(v);
              item['id'] = k.toString();
              cliList.add(item);
            }
          });
        }
      }

      if (memRes.statusCode == 200 && memRes.body != 'null') {
        final d = jsonDecode(memRes.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = Map.from(v);
              item['id'] = k.toString();
              memList.add(item);
            }
          });
        }
      }

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

  Future<void> _fetchBookings({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _statusMsg = 'A sincronizar marcações...';
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKeys = prefs.getStringList(kPrefKnownBookingKeys) ?? [];
      _knownKeys.addAll(savedKeys);

      final uri = Uri.parse(
        '$kFirebaseDbUrl/bookings.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List loaded = [];
        final List brandNew = [];
        final List<String> allKeys = [];

        if (decoded is Map) {
          decoded.forEach((key, val) {
            if (val is Map) {
              final k = key.toString();
              allKeys.add(k);
              final item = Map.from(val);
              item['firebaseKey'] = k;
              loaded.add(item);

              if (_firstLoadDone && !_knownKeys.contains(k)) {
                brandNew.add(item);
              }
              _knownKeys.add(k);
            }
          });
        }

        await prefs.setStringList(kPrefKnownBookingKeys, allKeys);
        _firstLoadDone = true;

        int notifId = 100;
        for (final novo in brandNew) {
          final client = (novo['clientName'] ?? 'Cliente').toString();
          final phone = (novo['clientPhone'] ?? novo['phone'] ?? '').toString();
          final dateLbl = (novo['dateLabel'] ?? '').toString();
          final timeLbl = (novo['time'] ?? '').toString();
          final barber = (novo['barberName'] ?? 'Barbearia Mr Jone').toString();

          await _upsertClientFromBooking(
            name: client,
            phone: phone,
            bookingDate: dateLbl,
            bookingTime: timeLbl,
          );

          await _showBookingNotification(
            'Nova marcação • $client',
            '$dateLbl às $timeLbl ($barber)',
            notifId++,
          );
        }

        loaded.sort((a, b) => (b['createdAt'] ?? '')
            .toString()
            .compareTo((a['createdAt'] ?? '').toString()));

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
      if (mounted && !silent) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _fetchCatalog() async {
    try {
      final srvRes = await http.get(Uri.parse('$kFirebaseDbUrl/services.json'));
      final plnRes = await http.get(Uri.parse('$kFirebaseDbUrl/plans.json'));

      final List srvList = [];
      final List plnList = [];

      if (srvRes.statusCode == 200 && srvRes.body != 'null') {
        final d = jsonDecode(srvRes.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = Map.from(v);
              item['id'] = k.toString();
              srvList.add(item);
            }
          });
        } else if (d is List) {
          for (var i = 0; i < d.length; i++) {
            if (d[i] is Map) {
              final item = Map.from(d[i] as Map);
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
              final item = Map.from(v);
              item['id'] = k.toString();
              plnList.add(item);
            }
          });
        } else if (d is List) {
          for (var i = 0; i < d.length; i++) {
            if (d[i] is Map) {
              final item = Map.from(d[i] as Map);
              item['id'] = i.toString();
              plnList.add(item);
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _services = srvList.isNotEmpty ? srvList : List.from(kDefaultServices);
        _plans = plnList.isNotEmpty ? plnList : List.from(kDefaultPlans);
      });
    } catch (_) {}
  }

  Future<void> _fetchBarbers() async {
    try {
      final res = await http.get(Uri.parse('$kFirebaseDbUrl/barbers.json'));
      final List list = [];
      if (res.statusCode == 200 && res.body != 'null') {
        final d = jsonDecode(res.body);
        if (d is Map) {
          d.forEach((k, v) {
            if (v is Map) {
              final item = Map.from(v);
              item['id'] = k.toString();
              list.add(item);
            }
          });
        } else if (d is List) {
          for (var i = 0; i < d.length; i++) {
            if (d[i] is Map) {
              final item = Map.from(d[i] as Map);
              item['id'] = i.toString();
              list.add(item);
            }
          }
        }
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

  /// Procura membro do plano por telefone ou nome.
  Map? _findPlanMember({String? clientName, String? clientPhone}) {
    final normPhone = _normalizePhone(clientPhone ?? '');
    final cleanName = (clientName ?? '').trim().toLowerCase();

    for (final m in _planMembers) {
      if (m is! Map) continue;
      final mPhone = _normalizePhone((m['phone'] ?? '').toString());
      final mName = (m['clientName'] ?? '').toString().trim().toLowerCase();

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

  /// Retorna opções de catálogo permitidas para o cliente:
  /// Se for membro de plano ativo e válido, retorna SOMENTE opções de plano
  /// (e prioriza o plano vinculado caso exista).
  List _allowedCatalogOptions({String? clientName, String? clientPhone}) {
    final member = _findPlanMember(
      clientName: clientName,
      clientPhone: clientPhone,
    );

    if (member != null && _isPlanMemberValid(member)) {
      final assignedPlanName =
          (member['planName'] ?? '').toString().trim().toLowerCase();
      final List planOnly = [];

      for (final p in _plans) {
        if (p is! Map) continue;
        final pName = (p['name'] ?? '').toString();
        if (assignedPlanName.isEmpty ||
            pName.toLowerCase() == assignedPlanName ||
            pName.toLowerCase().contains(assignedPlanName) ||
            assignedPlanName.contains(pName.toLowerCase())) {
          planOnly.add({
            'name': pName,
            'price': double.tryParse('${p['price'] ?? 0}') ?? 0.0,
            'duration': int.tryParse('${p['duration'] ?? 40}') ?? 40,
            'isPlan': true,
            'sessionsPerMonth':
                int.tryParse('${p['sessionsPerMonth'] ?? 4}') ?? 4,
            'planOnly': true,
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
          'planOnly': true,
        }
      ];
    }

    final List all = [];
    for (final s in _services) {
      all.add({
        'name': (s['name'] ?? '').toString(),
        'price': double.tryParse('${s['price'] ?? 0}') ?? 0.0,
        'duration': int.tryParse('${s['duration'] ?? 30}') ?? 30,
        'isPlan': false,
        'sessionsPerMonth': 1,
        'planOnly': false,
      });
    }
    for (final p in _plans) {
      all.add({
        'name': (p['name'] ?? '').toString(),
        'price': double.tryParse('${p['price'] ?? 0}') ?? 0.0,
        'duration': int.tryParse('${p['duration'] ?? 40}') ?? 40,
        'isPlan': true,
        'sessionsPerMonth': int.tryParse('${p['sessionsPerMonth'] ?? 4}') ?? 4,
        'planOnly': false,
      });
    }
    return all;
  }
    Future<void> _saveManualClient({
    String? existingId,
    required String name,
    required String phone,
  }) async {
    final cleanName = name.trim();
    final normPhone = _normalizePhone(phone);
    if (cleanName.isEmpty) return;

    final payload = {
      'name': cleanName,
      'phone': normPhone.isNotEmpty ? normPhone : phone.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (existingId != null && existingId.isNotEmpty) {
      await http.patch(
        Uri.parse('$kFirebaseDbUrl/clients/$existingId.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } else {
      payload['createdAt'] = DateTime.now().toIso8601String();
      payload['totalBookings'] = 0;
      await http.post(
        Uri.parse('$kFirebaseDbUrl/clients.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    }
    await _fetchClientsAndPlanMembers();
  }

  Future<void> _deleteClient(String id) async {
    if (id.isEmpty) return;
    await http.delete(Uri.parse('$kFirebaseDbUrl/clients/$id.json'));
    await _fetchClientsAndPlanMembers();
  }

  Future<void> _savePlanMember({
    String? existingId,
    required String clientName,
    required String phone,
    required String planName,
    required double planPrice,
    required int duration,
    required int sessionsPerMonth,
    required String expiresAt,
    required bool active,
  }) async {
    final cleanName = clientName.trim();
    final normPhone = _normalizePhone(phone);
    if (cleanName.isEmpty) return;

    final payload = {
      'clientName': cleanName,
      'phone': normPhone.isNotEmpty ? normPhone : phone.trim(),
      'planName': planName.trim(),
      'planPrice': planPrice,
      'duration': duration <= 0 ? 40 : duration,
      'sessionsPerMonth': sessionsPerMonth <= 0 ? 4 : sessionsPerMonth,
      'expiresAt': expiresAt.trim(),
      'active': active,
      'restrictToPlanOnly': true,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (existingId != null && existingId.isNotEmpty) {
      await http.patch(
        Uri.parse('$kFirebaseDbUrl/plan_members/$existingId.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } else {
      payload['createdAt'] = DateTime.now().toIso8601String();
      await http.post(
        Uri.parse('$kFirebaseDbUrl/plan_members.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    }

    await _upsertClientFromBooking(
      name: cleanName,
      phone: normPhone.isNotEmpty ? normPhone : phone.trim(),
    );
    await _fetchClientsAndPlanMembers();
  }

  Future<void> _deletePlanMember(String id) async {
    if (id.isEmpty) return;
    await http.delete(Uri.parse('$kFirebaseDbUrl/plan_members/$id.json'));
    await _fetchClientsAndPlanMembers();
  }

  Future<void> _openClientDialog({Map? client}) async {
    final nameCtrl =
        TextEditingController(text: (client?['name'] ?? '').toString());
    final phoneCtrl =
        TextEditingController(text: (client?['phone'] ?? '').toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: Text(
          client == null ? 'Novo Cliente' : 'Editar Cliente',
          style: const TextStyle(color: Color(0xFFF3D97E)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome do Cliente'),
            ),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Telefone / WhatsApp'),
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
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await _saveManualClient(
                existingId: client?['id']?.toString(),
                name: name,
                phone: phoneCtrl.text,
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPlanMemberDialog({
    Map? existingMember,
    String? prefillName,
    String? prefillPhone,
  }) async {
    final nameCtrl = TextEditingController(
      text: (existingMember?['clientName'] ?? prefillName ?? '').toString(),
    );
    final phoneCtrl = TextEditingController(
      text: (existingMember?['phone'] ?? prefillPhone ?? '').toString(),
    );

    final defaultExpiry = DateTime.now().add(const Duration(days: 30));
    final defExpStr =
        '${defaultExpiry.day.toString().padLeft(2, '0')}/${defaultExpiry.month.toString().padLeft(2, '0')}/${defaultExpiry.year}';
    final expiryCtrl = TextEditingController(
      text: (existingMember?['expiresAt'] ?? defExpStr).toString(),
    );

    String selectedPlanName =
        (existingMember?['planName'] ?? '').toString();
    double selectedPlanPrice =
        double.tryParse('${existingMember?['planPrice'] ?? ''}') ?? 0;
    int selectedDuration =
        int.tryParse('${existingMember?['duration'] ?? ''}') ?? 40;
    int selectedSessions =
        int.tryParse('${existingMember?['sessionsPerMonth'] ?? ''}') ?? 4;
    bool active = existingMember?['active'] != false;

    if (selectedPlanName.isEmpty && _plans.isNotEmpty) {
      final firstPlan = _plans.first as Map;
      selectedPlanName = (firstPlan['name'] ?? 'Plano Mensal').toString();
      selectedPlanPrice = double.tryParse('${firstPlan['price'] ?? 0}') ?? 0;
      selectedDuration = int.tryParse('${firstPlan['duration'] ?? 40}') ?? 40;
      selectedSessions =
          int.tryParse('${firstPlan['sessionsPerMonth'] ?? 4}') ?? 4;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF141417),
          title: Text(
            existingMember == null
                ? 'Adicionar Pessoa ao Plano'
                : 'Editar Membro do Plano',
            style: const TextStyle(color: Color(0xFFF3D97E)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome do Cliente'),
                ),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone / WhatsApp (chave de identificação)',
                  ),
                ),
                const SizedBox(height: 10),
                if (_plans.isNotEmpty)
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: 0,
                    dropdownColor: const Color(0xFF1B1B20),
                    decoration: const InputDecoration(labelText: 'Plano Mensal'),
                    items: [
                      for (var i = 0; i < _plans.length; i++)
                        DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                            '${_plans[i]['name']} (R\$ ${_plans[i]['price']})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (idx) {
                      if (idx == null) return;
                      final p = _plans[idx] as Map;
                      setLocal(() {
                        selectedPlanName = (p['name'] ?? '').toString();
                        selectedPlanPrice =
                            double.tryParse('${p['price'] ?? 0}') ?? 0;
                        selectedDuration =
                            int.tryParse('${p['duration'] ?? 40}') ?? 40;
                        selectedSessions =
                            int.tryParse('${p['sessionsPerMonth'] ?? 4}') ??
                                4;
                      });
                    },
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expiryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Data de Validade (dd/mm/aaaa)',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today,
                          color: Color(0xFFD4AF37)),
                      onPressed: () async {
                        final initDt =
                            _parseDateString(expiryCtrl.text) ?? defaultExpiry;
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initDt,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setLocal(() {
                            expiryCtrl.text =
                                '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Plano ativo (vai direto e só para opções do plano)',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: active,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (v) => setLocal(() => active = v),
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
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                await _savePlanMember(
                  existingId: existingMember?['id']?.toString(),
                  clientName: name,
                  phone: phoneCtrl.text,
                  planName: selectedPlanName.isEmpty
                      ? 'Plano Mensal'
                      : selectedPlanName,
                  planPrice: selectedPlanPrice,
                  duration: selectedDuration,
                  sessionsPerMonth: selectedSessions,
                  expiresAt: expiryCtrl.text,
                  active: active,
                );
              },
              child: const Text('Guardar no Plano'),
            ),
          ],
        ),
      ),
    );
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
      for (final it in b['items'] as List) {
        if (it is Map) {
          total += int.tryParse('${it['duration'] ?? 30}') ?? 30;
        }
      }
      if (total > 0) return total;
    }
    return int.tryParse('${b['duration'] ?? 30}') ?? 30;
  }

  bool _sameBarberName(String? a, String? b) {
    final x = (a ?? '').trim().toLowerCase();
    final y = (b ?? '').trim().toLowerCase();
    if (x.isEmpty || y.isEmpty) return true;
    return x == y || x.contains(y) || y.contains(x);
  }

  List<String> _getAvailableSlots({
    required String dateStr,
    required String barberName,
    required int serviceDurationMin,
    String? ignoreBookingKey,
  }) {
    final dt = _parseDateString(dateStr);
    if (dt == null) return [];

    final expKey = _expedienteKeyForDate(dt);
    final dayExp = _expediente[expKey];
    if (dayExp == null || dayExp['ativo'] != true) {
      return [];
    }

    final List<List<int>> windows = [];
    final t1Start = _timeToMinutes((dayExp['t1Inicio'] ?? '09:00').toString());
    final t1End = _timeToMinutes((dayExp['t1Fim'] ?? '12:00').toString());
    if (t1Start != null && t1End != null && t1End > t1Start) {
      windows.add([t1Start, t1End]);
    }

    if (dayExp['t2Ativo'] == true) {
      final t2Start =
          _timeToMinutes((dayExp['t2Inicio'] ?? '14:00').toString());
      final t2End = _timeToMinutes((dayExp['t2Fim'] ?? '19:30').toString());
      if (t2Start != null && t2End != null && t2End > t2Start) {
        windows.add([t2Start, t2End]);
      }
    }

    final List<List<int>> blockedIntervals = [];
    final targetDay = DateTime(dt.year, dt.month, dt.day);

    for (final p in _pauses) {
      if (p is! Map) continue;
      final pDt = _parseDateString((p['date'] ?? '').toString());
      if (pDt != null &&
          DateTime(pDt.year, pDt.month, pDt.day) != targetDay) {
        continue;
      }
      final ps = _timeToMinutes((p['start'] ?? '').toString());
      final pe = _timeToMinutes((p['end'] ?? '').toString());
      if (ps != null && pe != null && pe > ps) {
        blockedIntervals.add([ps, pe]);
      }
    }

    for (final b in _bookings) {
      if (b is! Map) continue;
      final bKey = (b['firebaseKey'] ?? '').toString();
      if (ignoreBookingKey != null &&
          ignoreBookingKey.isNotEmpty &&
          bKey == ignoreBookingKey) {
        continue;
      }

      final st = (b['status'] ?? 'confirmado').toString().trim().toLowerCase();
      if (st == 'cancelado') continue;

      final bDt = _parseDateString((b['dateLabel'] ?? b['date'] ?? '').toString());
      if (bDt == null) continue;
      if (DateTime(bDt.year, bDt.month, bDt.day) != targetDay) continue;

      if (!_sameBarberName(b['barberName']?.toString(), barberName)) continue;

      final startMin = _timeToMinutes((b['time'] ?? '').toString());
      if (startMin == null) continue;
      final dur = _bookingDurationMinutes(b);
      blockedIntervals.add([startMin, startMin + dur]);
    }

    final int step = _slotStepMinutes <= 0 ? 15 : _slotStepMinutes;
    final int neededDur = serviceDurationMin <= 0 ? 30 : serviceDurationMin;
    final List<String> available = [];

    for (final win in windows) {
      final int winStart = win[0];
      final int winEnd = win[1];

      for (int candidate = winStart;
          candidate + neededDur <= winEnd;
          candidate += step) {
        final int candidateEnd = candidate + neededDur;
        bool overlaps = false;
        for (final blk in blockedIntervals) {
          final int blkStart = blk[0];
          final int blkEnd = blk[1];
          if (candidate < blkEnd && candidateEnd > blkStart) {
            overlaps = true;
            break;
          }
        }
        if (!overlaps) {
          available.add(_minutesToTime(candidate));
        }
      }
    }

    return available;
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

    if (period == 'mensal') {
      return dt.year == today.year && dt.month == today.month;
    }

    final weekStart = today.subtract(const Duration(days: 6));
    final weekEnd = today.add(const Duration(days: 1));
    return !dt.isBefore(weekStart) && dt.isBefore(weekEnd);
  }

  double _getBarberCommissionPct(String? barberName) {
    final target = (barberName ?? '').trim().toLowerCase();
    if (target.isNotEmpty) {
      for (final b in _barbers) {
        if (b is Map) {
          final bName = (b['name'] ?? '').toString().trim().toLowerCase();
          if (bName == target ||
              bName.contains(target) ||
              target.contains(bName)) {
            return double.tryParse('${b['commission'] ?? 50}') ?? 50;
          }
        }
      }
    }
    return 50;
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
      for (final it in items) {
        if (it is Map) {
          sum += _calcReceitaItem(it);
        }
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

  double _totalReceita({bool onlyCompleted = true}) {
    double sum = 0;
    for (final b in _bookings) {
      if (b is Map && _shouldCountBooking(b, onlyCompleted: onlyCompleted)) {
        sum += _calcBookingValue(b);
      }
    }
    return sum;
  }

  double _totalComissoes({bool onlyCompleted = true}) {
    double sum = 0;
    for (final b in _bookings) {
      if (b is Map && _shouldCountBooking(b, onlyCompleted: onlyCompleted)) {
        sum += _calcBookingCommission(b);
      }
    }
    return sum;
  }

  Map<String, dynamic> _barberStats(
    String barberName, {
    String? period,
    bool onlyCompleted = true,
  }) {
    final target = barberName.trim().toLowerCase();
    double produced = 0;
    double commission = 0;
    int count = 0;
    final commPct = _getBarberCommissionPct(barberName);
    final List matchedBookings = [];

    if (target.isNotEmpty) {
      for (final b in _bookings) {
        if (b is! Map) continue;
        final bName = (b['barberName'] ?? '').toString().trim().toLowerCase();
        final sameBarber =
            bName == target || bName.contains(target) || target.contains(bName);
        if (!sameBarber) continue;
        if (!_shouldCountBooking(b, onlyCompleted: onlyCompleted)) continue;
        if (period != null && !_matchesPeriod(b, period)) continue;

        final val = _calcBookingValue(b);
        final comm = val * (commPct / 100.0);
        produced += val;
        commission += comm;
        count++;
        matchedBookings.add(b);
      }
    }

    return {
      'produced': produced,
      'commission': commission,
      'count': count,
      'bookings': matchedBookings,
    };
  }
      String _buildServiceSummary(Map b) {
    final List<String> srvNames = [];
    if (b['items'] is List) {
      for (final it in b['items'] as List) {
        if (it is Map && it['name'] != null) {
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
    final dateLbl = (b['dateLabel'] ?? '').toString().trim();
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

  Future<void> _concluirAtendimento(Map b) async {
    final String firebaseKey = (b['firebaseKey'] ?? '').toString();
    if (firebaseKey.isEmpty) return;

    final double comm = _calcBookingCommission(b);
    final String client = (b['clientName'] ?? 'Cliente').toString();
    final String barber = (b['barberName'] ?? 'Barbeiro').toString();

    setState(() {
      final idx = _bookings.indexWhere(
        (item) =>
            item is Map && (item['firebaseKey'] ?? '').toString() == firebaseKey,
      );
      if (idx != -1 && _bookings[idx] is Map) {
        final updated = Map.from(_bookings[idx] as Map);
        updated['status'] = 'concluído';
        updated['attended'] = true;
        updated['completedAt'] = DateTime.now().toIso8601String();
        _bookings[idx] = updated;
      }
    });

    await http.patch(
      Uri.parse('$kFirebaseDbUrl/bookings/$firebaseKey.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'status': 'concluído',
        'attended': true,
        'completedAt': DateTime.now().toIso8601String(),
      }),
    );

    await _fetchBookings(silent: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$client concluído! Comissão de R\$ ${comm.toStringAsFixed(2)} somada para $barber.',
        ),
      ),
    );
  }

  Future<void> _marcarNaoConcluido(Map b) async {
    final String firebaseKey = (b['firebaseKey'] ?? '').toString();
    if (firebaseKey.isEmpty) return;

    final String client = (b['clientName'] ?? 'Cliente').toString();

    setState(() {
      final idx = _bookings.indexWhere(
        (item) =>
            item is Map && (item['firebaseKey'] ?? '').toString() == firebaseKey,
      );
      if (idx != -1 && _bookings[idx] is Map) {
        final updated = Map.from(_bookings[idx] as Map);
        updated['status'] = 'não concluído';
        updated['attended'] = false;
        updated['completedAt'] = null;
        _bookings[idx] = updated;
      }
    });

    await http.patch(
      Uri.parse('$kFirebaseDbUrl/bookings/$firebaseKey.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'status': 'não concluído',
        'attended': false,
        'completedAt': null,
      }),
    );

    await _fetchBookings(silent: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$client marcado como não concluído (mantido na agenda, fora do caixa).',
        ),
      ),
    );
  }

  Future<void> _updateStatus(String firebaseKey, String newStatus) async {
    if (firebaseKey.isEmpty) return;
    await http.patch(
      Uri.parse('$kFirebaseDbUrl/bookings/$firebaseKey.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus}),
    );
    await _fetchBookings(silent: true);
  }

  Future<void> _deleteBooking(String firebaseKey) async {
    if (firebaseKey.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: const Text(
          'Excluir Agendamento',
          style: TextStyle(color: Color(0xFFF3D97E)),
        ),
        content: const Text(
          'Deseja excluir permanentemente este agendamento?',
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

    if (confirm != true) return;

    setState(() {
      _bookings.removeWhere(
        (item) =>
            item is Map && (item['firebaseKey'] ?? '').toString() == firebaseKey,
      );
    });

    await http.delete(Uri.parse('$kFirebaseDbUrl/bookings/$firebaseKey.json'));
    await _fetchBookings(silent: true);
  }

  Future<void> _openManualEntryDialog() async {
    final clientCtrl = TextEditingController(text: 'Cliente Balcão');
    final phoneCtrl = TextEditingController(text: '');
    String selectedBarberName = _barbers.isNotEmpty
        ? (_barbers.first['name'] ?? 'Mr. Jone').toString()
        : 'Mr. Jone';
    double selectedCommPct = _barbers.isNotEmpty
        ? (double.tryParse('${_barbers.first['commission'] ?? 50}') ?? 50)
        : 50;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          final member = _findPlanMember(
            clientName: clientCtrl.text,
            clientPhone: phoneCtrl.text,
          );
          final bool isValidPlanMember =
              member != null && _isPlanMemberValid(member);
          final List allowedOptions = _allowedCatalogOptions(
            clientName: clientCtrl.text,
            clientPhone: phoneCtrl.text,
          );

          Map selectedItem = allowedOptions.isNotEmpty
              ? Map.from(allowedOptions.first as Map)
              : {
                  'name': 'Plano Mensal',
                  'price': 150.0,
                  'duration': 40,
                  'isPlan': true,
                  'sessionsPerMonth': 4,
                };

          return AlertDialog(
            backgroundColor: const Color(0xFF141417),
            title: const Text(
              'Registar Atendimento Manual',
              style: TextStyle(color: Color(0xFFF3D97E)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: clientCtrl,
                    onChanged: (_) => setLocal(() {}),
                    decoration:
                        const InputDecoration(labelText: 'Nome do Cliente'),
                  ),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setLocal(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Telefone / WhatsApp',
                    ),
                  ),
                  if (isValidPlanMember) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF231D09),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD4AF37)),
                      ),
                      child: Text(
                        'MEMBRO DO PLANO • Validade: ${member['expiresAt'] ?? 'Ativo'}\nApenas opções do plano permitidas.',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFF3D97E)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_barbers.isNotEmpty)
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: 0,
                      dropdownColor: const Color(0xFF1B1B20),
                      decoration: const InputDecoration(labelText: 'Barbeiro'),
                      items: [
                        for (var i = 0; i < _barbers.length; i++)
                          DropdownMenuItem<int>(
                            value: i,
                            child: Text(
                              '${_barbers[i]['name']} (${_barbers[i]['commission'] ?? 50}%)',
                            ),
                          ),
                      ],
                      onChanged: (idx) {
                        if (idx == null) return;
                        setLocal(() {
                          selectedBarberName =
                              (_barbers[idx]['name'] ?? 'Mr. Jone').toString();
                          selectedCommPct = double.tryParse(
                                  '${_barbers[idx]['commission'] ?? 50}') ??
                              50;
                        });
                      },
                    ),
                  const SizedBox(height: 8),
                  if (allowedOptions.isNotEmpty)
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: 0,
                      dropdownColor: const Color(0xFF1B1B20),
                      decoration: InputDecoration(
                        labelText: isValidPlanMember
                            ? 'Opções do Plano (Exclusivo)'
                            : 'Serviço ou Plano',
                      ),
                      items: [
                        for (var i = 0; i < allowedOptions.length; i++)
                          DropdownMenuItem<int>(
                            value: i,
                            child: Text(
                              '${allowedOptions[i]['name']} • R\$ ${allowedOptions[i]['price']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (idx) {
                        if (idx == null) return;
                        setLocal(() {
                          selectedItem = Map.from(allowedOptions[idx] as Map);
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Receita sessão: R\$ ${_calcReceitaItem(selectedItem).toStringAsFixed(2)} • Comissão (${selectedCommPct.toStringAsFixed(0)}%): R\$ ${_calcComissaoItem(selectedItem, selectedCommPct).toStringAsFixed(2)}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.greenAccent),
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
                  if (isValidPlanMember && selectedItem['isPlan'] != true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Este cliente é do plano: só é permitido marcar opções do plano.',
                        ),
                      ),
                    );
                    return;
                  }

                  final now = DateTime.now();
                  final hh = now.hour.toString().padLeft(2, '0');
                  final mm = now.minute.toString().padLeft(2, '0');
                  final dd = now.day.toString().padLeft(2, '0');
                  final mo = now.month.toString().padLeft(2, '0');
                  final dateStr = '$dd/$mo/${now.year}';
                  final timeStr = '$hh:$mm';
                  final cName = clientCtrl.text.trim().isEmpty
                      ? 'Cliente Balcão'
                      : clientCtrl.text.trim();
                  final cPhone = phoneCtrl.text.trim().isEmpty
                      ? 'Balcão'
                      : phoneCtrl.text.trim();

                  Navigator.pop(ctx);

                  await _upsertClientFromBooking(
                    name: cName,
                    phone: cPhone,
                    bookingDate: dateStr,
                    bookingTime: timeStr,
                  );

                  await http.post(
                    Uri.parse('$kFirebaseDbUrl/bookings.json'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'clientName': cName,
                      'clientPhone': cPhone,
                      'barberName': selectedBarberName,
                      'dateLabel': dateStr,
                      'time': timeStr,
                      'status': 'confirmado',
                      'attended': false,
                      'completedAt': null,
                      'isPlanMember': isValidPlanMember,
                      'createdAt': now.toIso8601String(),
                      'items': [
                        {
                          'name': (selectedItem['name'] ?? 'Serviço').toString(),
                          'price': double.tryParse(
                                  '${selectedItem['price'] ?? 0}') ??
                              0,
                          'duration': int.tryParse(
                                  '${selectedItem['duration'] ?? 30}') ??
                              30,
                          'isPlan': selectedItem['isPlan'] == true,
                          'sessionsPerMonth': int.tryParse(
                                  '${selectedItem['sessionsPerMonth'] ?? 4}') ??
                              4,
                        }
                      ],
                    }),
                  );
                  await _fetchBookings(silent: true);
                },
                child: const Text('Registar'),
              ),
            ],
          );
        },
      ),
    );
  }
     Future<void> _openEditBookingDialog(Map b) async {
    final String firebaseKey = (b['firebaseKey'] ?? '').toString();
    if (firebaseKey.isEmpty) return;

    String currentServiceName = '';
    double currentPrice = 0;
    int currentDuration = 30;
    bool currentIsPlan = false;
    int currentSessions = 4;

    if (b['items'] is List && (b['items'] as List).isNotEmpty) {
      final first = (b['items'] as List).first;
      if (first is Map) {
        currentServiceName = (first['name'] ?? '').toString();
        currentPrice = double.tryParse('${first['price'] ?? 0}') ?? 0;
        currentDuration = int.tryParse('${first['duration'] ?? 30}') ?? 30;
        currentIsPlan = first['isPlan'] == true;
        currentSessions = int.tryParse('${first['sessionsPerMonth'] ?? 4}') ?? 4;
      }
    }

    final String clientName = (b['clientName'] ?? '').toString();
    final String clientPhone =
        (b['clientPhone'] ?? b['phone'] ?? '').toString();
    final member =
        _findPlanMember(clientName: clientName, clientPhone: clientPhone);
    final bool isPlanOnlyClient = member != null && _isPlanMemberValid(member);

    final srvCtrl = TextEditingController(text: currentServiceName);
    final priceCtrl =
        TextEditingController(text: currentPrice.toStringAsFixed(2));
    final durCtrl = TextEditingController(text: '$currentDuration');
    final dateCtrl =
        TextEditingController(text: (b['dateLabel'] ?? '').toString());
    final timeCtrl = TextEditingController(text: (b['time'] ?? '').toString());
    final barberCtrl =
        TextEditingController(text: (b['barberName'] ?? 'Mr. Jone').toString());

    String selectedStatus = (b['status'] ?? 'confirmado').toString();
    bool sendWaAfterSave = false;

    final List allowedOptions = _allowedCatalogOptions(
      clientName: clientName,
      clientPhone: clientPhone,
    );

    if (isPlanOnlyClient && !currentIsPlan && allowedOptions.isNotEmpty) {
      final firstPlanOpt = allowedOptions.first as Map;
      srvCtrl.text = (firstPlanOpt['name'] ?? '').toString();
      priceCtrl.text =
          (double.tryParse('${firstPlanOpt['price'] ?? 0}') ?? 0)
              .toStringAsFixed(2);
      durCtrl.text = '${firstPlanOpt['duration'] ?? 40}';
      currentIsPlan = true;
      currentSessions =
          int.tryParse('${firstPlanOpt['sessionsPerMonth'] ?? 4}') ?? 4;
    }

    Future<void> pickCustomDate() async {
      final initialDt = _parseDateString(dateCtrl.text) ?? DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDt,
        firstDate: DateTime(2024),
        lastDate: DateTime(2030),
      );
      if (picked != null) {
        final dd = picked.day.toString().padLeft(2, '0');
        final mm = picked.month.toString().padLeft(2, '0');
        dateCtrl.text = '$dd/$mm/${picked.year}';
      }
    }

    Future<void> pickCustomTime() async {
      TimeOfDay initial = const TimeOfDay(hour: 10, minute: 0);
      final parts = timeCtrl.text.trim().split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
          initial = TimeOfDay(hour: h, minute: m);
        }
      }
      final picked = await showTimePicker(
        context: context,
        initialTime: initial,
      );
      if (picked != null) {
        final hh = picked.hour.toString().padLeft(2, '0');
        final mm = picked.minute.toString().padLeft(2, '0');
        timeCtrl.text = '$hh:$mm';
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          final int activeDur =
              int.tryParse(durCtrl.text.trim()) ?? currentDuration;
          final List<String> availableSlots = _getAvailableSlots(
            dateStr: dateCtrl.text,
            barberName: barberCtrl.text,
            serviceDurationMin: activeDur,
            ignoreBookingKey: firebaseKey,
          );

          return AlertDialog(
            backgroundColor: const Color(0xFF141417),
            title: Text(
              'Reagendar • ${clientName.isEmpty ? 'Cliente' : clientName}',
              style: const TextStyle(color: Color(0xFFF3D97E)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isPlanOnlyClient)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF231D09),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD4AF37)),
                      ),
                      child: Text(
                        'CLIENTE DE PLANO (Validade: ${member['expiresAt'] ?? 'Ativo'})\nApenas opções do plano estão disponíveis.',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFF3D97E)),
                      ),
                    ),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1B1B20),
                    decoration: InputDecoration(
                      labelText: isPlanOnlyClient
                          ? 'Opções do Plano (Exclusivo)'
                          : 'Escolher da tabela de preços',
                    ),
                    items: [
                      for (var i = 0; i < allowedOptions.length; i++)
                        DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                            '${allowedOptions[i]['name']} (R\$ ${(allowedOptions[i]['price'] as double).toStringAsFixed(2)} • ${allowedOptions[i]['duration']} min)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (idx) {
                      if (idx == null) return;
                      final opt = allowedOptions[idx];
                      setLocal(() {
                        srvCtrl.text = opt['name'].toString();
                        priceCtrl.text =
                            (opt['price'] as double).toStringAsFixed(2);
                        durCtrl.text = '${opt['duration'] ?? 30}';
                        currentIsPlan = opt['isPlan'] == true;
                        currentSessions =
                            int.tryParse('${opt['sessionsPerMonth'] ?? 4}') ??
                                4;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: srvCtrl,
                    readOnly: isPlanOnlyClient,
                    decoration: const InputDecoration(
                      labelText: 'Serviço / Plano',
                    ),
                  ),
                  TextField(
                    controller: priceCtrl,
                    readOnly: isPlanOnlyClient,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                  ),
                  TextField(
                    controller: durCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setLocal(() {}),
                    decoration:
                        const InputDecoration(labelText: 'Duração (minutos)'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateCtrl,
                          onChanged: (_) => setLocal(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Data (dd/mm/aaaa)',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Escolher data',
                        icon: const Icon(Icons.calendar_today,
                            color: Color(0xFFD4AF37)),
                        onPressed: () async {
                          await pickCustomDate();
                          setLocal(() {});
                        },
                      ),
                    ],
                  ),
                  TextField(
                    controller: barberCtrl,
                    onChanged: (_) => setLocal(() {}),
                    decoration: const InputDecoration(labelText: 'Barbeiro'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'HORÁRIOS DISPONÍVEIS (TOQUE PARA ESCOLHER):',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF3D97E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (availableSlots.isEmpty)
                    const Text(
                      'Sem horários livres para essa data/barbeiro/duração (ou dia fechado). Pode escolher hora manual abaixo.',
                      style: TextStyle(fontSize: 11, color: Colors.orangeAccent),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: availableSlots.map((slot) {
                        final bool isChosen = timeCtrl.text.trim() == slot;
                        return ChoiceChip(
                          label: Text(
                            slot,
                            style: TextStyle(
                              fontSize: 12,
                              color: isChosen ? Colors.black : Colors.white,
                              fontWeight:
                                  isChosen ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isChosen,
                          selectedColor: const Color(0xFFD4AF37),
                          backgroundColor: const Color(0xFF1E1E24),
                          onSelected: (_) {
                            setLocal(() => timeCtrl.text = slot);
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: timeCtrl,
                          onChanged: (_) => setLocal(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Horário escolhido (HH:MM)',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Escolher hora exata',
                        icon: const Icon(Icons.access_time,
                            color: Color(0xFFD4AF37)),
                        onPressed: () async {
                          await pickCustomTime();
                          setLocal(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: [
                      'confirmado',
                      'concluído',
                      'não concluído',
                      'cancelado',
                    ].contains(selectedStatus.toLowerCase())
                        ? selectedStatus.toLowerCase()
                        : 'confirmado',
                    dropdownColor: const Color(0xFF1B1B20),
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                          value: 'confirmado', child: Text('Confirmado')),
                      DropdownMenuItem(
                          value: 'concluído', child: Text('Concluído')),
                      DropdownMenuItem(
                          value: 'não concluído', child: Text('Não concluído')),
                      DropdownMenuItem(
                          value: 'cancelado', child: Text('Cancelado')),
                    ],
                    onChanged: (v) {
                      if (v != null) setLocal(() => selectedStatus = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Avisar cliente no WhatsApp sobre o novo horário',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: sendWaAfterSave,
                    activeColor: const Color(0xFFD4AF37),
                    onChanged: (v) =>
                        setLocal(() => sendWaAfterSave = v ?? false),
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
                  if (isPlanOnlyClient && !currentIsPlan) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Membro do plano só pode marcar opções do plano.',
                        ),
                      ),
                    );
                    return;
                  }

                  final newService = srvCtrl.text.trim().isEmpty
                      ? 'Serviço'
                      : srvCtrl.text.trim();
                  final newPrice =
                      double.tryParse(priceCtrl.text.replaceAll(',', '.')) ??
                          currentPrice;
                  final newDur =
                      int.tryParse(durCtrl.text.trim()) ?? currentDuration;
                  final newDate = dateCtrl.text.trim();
                  final newTime = timeCtrl.text.trim();
                  final newBarber = barberCtrl.text.trim().isEmpty
                      ? 'Mr. Jone'
                      : barberCtrl.text.trim();

                  final isDone = selectedStatus == 'concluído';

                  Navigator.pop(ctx);

                  final updatedItems = [
                    {
                      'name': newService,
                      'price': newPrice,
                      'duration': newDur,
                      'isPlan': currentIsPlan,
                      'sessionsPerMonth': currentSessions,
                    }
                  ];

                  final patchPayload = {
                    'items': updatedItems,
                    'dateLabel': newDate,
                    'date': newDate,
                    'time': newTime,
                    'barberName': newBarber,
                    'status': selectedStatus,
                    'attended': isDone,
                    'completedAt':
                        isDone ? DateTime.now().toIso8601String() : null,
                    'updatedAt': DateTime.now().toIso8601String(),
                  };

                  await http.patch(
                    Uri.parse('$kFirebaseDbUrl/bookings/$firebaseKey.json'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(patchPayload),
                  );
                  await _fetchBookings(silent: true);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Reagendado para $newDate às $newTime com $newBarber (atualizado no site e Firebase).',
                      ),
                    ),
                  );

                  if (sendWaAfterSave) {
                    final updatedMap = {
                      ...b,
                      ...patchPayload,
                    };
                    await _openWhatsApp(updatedMap, rescheduled: true);
                  }
                },
                child: const Text('Guardar e Atualizar Site'),
              ),
            ],
          );
        },
      ),
    );
     }
        Future<void> _saveCatalogItem({
    required bool isPlan,
    String? existingId,
    required String name,
    required String category,
    required double price,
    required int duration,
    required int sessionsPerMonth,
  }) async {
    final node = isPlan ? 'plans' : 'services';
    final payload = {
      'name': name.trim(),
      'category': category.trim().isEmpty
          ? (isPlan ? 'Planos Mensais' : 'Serviços Avulsos')
          : category.trim(),
      'price': price,
      'duration': duration <= 0 ? 30 : duration,
      'isPlan': isPlan,
      'sessionsPerMonth':
          isPlan ? (sessionsPerMonth <= 0 ? 4 : sessionsPerMonth) : 1,
    };

    if (existingId != null &&
        existingId.isNotEmpty &&
        !existingId.startsWith('def_')) {
      await http.patch(
        Uri.parse('$kFirebaseDbUrl/$node/$existingId.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } else {
      await http.post(
        Uri.parse('$kFirebaseDbUrl/$node.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    }
    await _fetchCatalog();
  }

  Future<void> _deleteCatalogItem(bool isPlan, String id) async {
    if (id.isEmpty) return;
    if (!id.startsWith('def_')) {
      final node = isPlan ? 'plans' : 'services';
      await http.delete(Uri.parse('$kFirebaseDbUrl/$node/$id.json'));
      await _fetchCatalog();
    } else {
      setState(() {
        if (isPlan) {
          _plans.removeWhere((p) => (p['id'] ?? '').toString() == id);
        } else {
          _services.removeWhere((s) => (s['id'] ?? '').toString() == id);
        }
      });
    }
  }

  Future<void> _saveBarber({
    String? existingId,
    required String name,
    required String role,
    required double commissionPct,
  }) async {
    final payload = {
      'name': name.trim(),
      'role': role.trim().isEmpty ? 'Barbeiro' : role.trim(),
      'commission': commissionPct,
    };

    if (existingId != null && existingId.isNotEmpty) {
      await http.patch(
        Uri.parse('$kFirebaseDbUrl/barbers/$existingId.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } else {
      await http.post(
        Uri.parse('$kFirebaseDbUrl/barbers.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    }
    await _fetchBarbers();
  }

  Future<void> _deleteBarber(String id) async {
    if (id.isEmpty) return;
    await http.delete(Uri.parse('$kFirebaseDbUrl/barbers/$id.json'));
    await _fetchBarbers();
  }

  Future<void> _openCatalogDialog({
    required bool isPlan,
    Map? item,
  }) async {
    final nameCtrl =
        TextEditingController(text: (item?['name'] ?? '').toString());
    final catCtrl = TextEditingController(
      text: (item?['category'] ??
              (isPlan ? 'Planos Mensais' : 'Serviços Avulsos'))
          .toString(),
    );
    final priceCtrl =
        TextEditingController(text: (item?['price'] ?? '0').toString());
    final durCtrl =
        TextEditingController(text: (item?['duration'] ?? '30').toString());
    final sessCtrl = TextEditingController(
      text: (item?['sessionsPerMonth'] ?? (isPlan ? '4' : '1')).toString(),
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: Text(
          item == null
              ? (isPlan ? 'Novo Plano Mensal' : 'Novo Serviço / Corte')
              : (isPlan ? 'Editar Plano' : 'Editar Serviço'),
          style: const TextStyle(color: Color(0xFFF3D97E)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preço (R\$)'),
              ),
              TextField(
                controller: durCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Duração média (minutos)'),
              ),
              if (isPlan)
                TextField(
                  controller: sessCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sessões por mês'),
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
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final price =
                  double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
              final dur = int.tryParse(durCtrl.text.trim()) ?? 30;
              final sess = int.tryParse(sessCtrl.text.trim()) ?? 4;
              Navigator.pop(ctx);
              await _saveCatalogItem(
                isPlan: isPlan,
                existingId: item?['id']?.toString(),
                name: name,
                category: catCtrl.text,
                price: price,
                duration: dur,
                sessionsPerMonth: sess,
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openBarberDialog({Map? barber}) async {
    final nameCtrl =
        TextEditingController(text: (barber?['name'] ?? '').toString());
    final roleCtrl =
        TextEditingController(text: (barber?['role'] ?? 'Barbeiro').toString());
    final commCtrl =
        TextEditingController(text: (barber?['commission'] ?? '50').toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: Text(
          barber == null ? 'Adicionar Barbeiro' : 'Editar Barbeiro',
          style: const TextStyle(color: Color(0xFFF3D97E)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome do barbeiro'),
            ),
            TextField(
              controller: roleCtrl,
              decoration:
                  const InputDecoration(labelText: 'Especialidade / Função'),
            ),
            TextField(
              controller: commCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final comm =
                  double.tryParse(commCtrl.text.replaceAll(',', '.')) ?? 50;
              Navigator.pop(ctx);
              await _saveBarber(
                existingId: barber?['id']?.toString(),
                name: name,
                role: roleCtrl.text,
                commissionPct: comm,
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _openBarberReportDialog(String barberName, double commPct) {
    final weekly = _barberStats(
      barberName,
      period: 'semanal',
      onlyCompleted: _onlyCompletedInAccounting,
    );
    final monthly = _barberStats(
      barberName,
      period: 'mensal',
      onlyCompleted: _onlyCompletedInAccounting,
    );
    final activeList = (monthly['bookings'] as List);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: Text(
          'Relatório • $barberName (${commPct.toStringAsFixed(0)}%)',
          style: const TextStyle(color: Color(0xFFF3D97E)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _onlyCompletedInAccounting
                    ? 'Base: Apenas atendimentos CONCLUÍDOS'
                    : 'Base: Todos os atendimentos ativos',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              const Text(
                'SEMANAL (ÚLTIMOS 7 DIAS)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF3D97E),
                  fontSize: 12,
                ),
              ),
              Text(
                'Atendimentos: ${weekly['count']} • Produzido: R\$ ${(weekly['produced'] as double).toStringAsFixed(2)} • Comissão: R\$ ${(weekly['commission'] as double).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              const Text(
                'MENSAL (MÊS ATUAL)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF3D97E),
                  fontSize: 12,
                ),
              ),
              Text(
                'Atendimentos: ${monthly['count']} • Produzido: R\$ ${(monthly['produced'] as double).toStringAsFixed(2)} • Comissão: R\$ ${(monthly['commission'] as double).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12),
              ),
              const Divider(height: 18, color: Colors.white24),
              const Text(
                'DETALHE NO MÊS:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 6),
              if (activeList.isEmpty)
                const Text(
                  'Sem atendimentos registados neste período.',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                )
              else
                ...activeList.map((b) {
                  final mapB = b as Map;
                  final v = _calcBookingValue(mapB);
                  final c = v * (commPct / 100.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${mapB['dateLabel'] ?? ''} ${mapB['time'] ?? ''} — ${mapB['clientName'] ?? 'Cliente'} (${_buildServiceSummary(mapB)}) • R\$ ${v.toStringAsFixed(2)} / Com.: R\$ ${c.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddPauseDialog() async {
    final dateCtrl = TextEditingController(text: '23/11/2026');
    final startCtrl = TextEditingController(text: '12:00');
    final endCtrl = TextEditingController(text: '13:00');
    final reasonCtrl = TextEditingController(text: 'Almoço / Pausa');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: const Text(
          'Nova Pausa / Bloqueio',
          style: TextStyle(color: Color(0xFFF3D97E)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateCtrl,
              decoration: const InputDecoration(labelText: 'Data'),
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
              Navigator.pop(ctx);
              setState(() {
                _pauses.add({
                  'date': dateCtrl.text.trim(),
                  'start': startCtrl.text.trim(),
                  'end': endCtrl.text.trim(),
                  'reason': reasonCtrl.text.trim().isEmpty
                      ? 'Pausa'
                      : reasonCtrl.text.trim(),
                });
              });
              await _savePausesAndSync();
            },
            child: const Text('Guardar Pausa'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.content_cut, color: Color(0xFFD4AF37), size: 18),
              SizedBox(width: 8),
              Text(
                'BARBEARIA MR JONE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Color(0xFFF3D97E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _statusMsg,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountingTab() {
    final double receita =
        _totalReceita(onlyCompleted: _onlyCompletedInAccounting);
    final double totalComissao =
        _totalComissoes(onlyCompleted: _onlyCompletedInAccounting);
    final double liquidoCasa = receita - totalComissao;

    final List visibleBookings = _bookings.where((b) {
      if (b is! Map) return false;
      if (!_onlyCompletedInAccounting) return true;
      return _isCompletedStatus(b) || _isNotCompletedStatus(b) || true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _syncAll,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildHeaderBanner(),
          if (_newAlerts.isNotEmpty) ...[
            Card(
              color: const Color(0xFF231D09),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NOVO HORÁRIO MARCADO (${_newAlerts.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF3D97E),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _newAlerts = []),
                          child: const Text('Limpar aviso'),
                        ),
                      ],
                    ),
                    ..._newAlerts.take(5).map((al) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• ${al['clientName'] ?? 'Cliente'} marcou para ${al['dateLabel'] ?? ''} às ${al['time'] ?? ''} (${al['barberName'] ?? 'Barbearia Mr Jone'})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: Card(
                  color: const Color(0xFF141417),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RECEITA', style: TextStyle(fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${receita.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF3D97E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Card(
                  color: const Color(0xFF141417),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('COMISSÕES', style: TextStyle(fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${totalComissao.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Card(
                  color: const Color(0xFF141417),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LÍQUIDO CASA',
                            style: TextStyle(fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${liquidoCasa.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF3D97E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: _openManualEntryDialog,
            icon: const Icon(Icons.add_card),
            label: const Text('Registar Atendimento Manual (Balcão / Plano)'),
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
                'Ativo por padrão: Concluir soma; Não concluído não conta e fica na agenda até você excluir.',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
              value: _onlyCompletedInAccounting,
              activeColor: const Color(0xFFD4AF37),
              onChanged: (v) => setState(() => _onlyCompletedInAccounting = v),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'AGENDA & ATENDIMENTOS',
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
            final bool countsInTotals = _shouldCountBooking(
              b,
              onlyCompleted: _onlyCompletedInAccounting,
            );
            final double val = _calcBookingValue(b);
            final double comm = _calcBookingCommission(b);
            final String srvNames = _buildServiceSummary(b);
            final String cName = (b['clientName'] ?? 'Cliente').toString();
            final String cPhone =
                (b['clientPhone'] ?? b['phone'] ?? '').toString();
            final member =
                _findPlanMember(clientName: cName, clientPhone: cPhone);
            final bool inPlan = member != null && _isPlanMemberValid(member);

            return Card(
              color: const Color(0xFF141417),
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$cName${inPlan ? ' [PLANO]' : ''} • ${b['dateLabel'] ?? ''} ${b['time'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF3D97E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tel: ${cPhone.isEmpty ? '-' : cPhone} • Barbeiro: ${b['barberName'] ?? 'Mr. Jone'}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Text(
                      'Receita: R\$ ${val.toStringAsFixed(2)} • Comissão: R\$ ${comm.toStringAsFixed(2)} • $status${countsInTotals ? '' : ' (não somado)'}',
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
                          onPressed: () => _concluirAtendimento(b),
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
                          onPressed: () => _marcarNaoConcluido(b),
                          child: Text(
                            isNotDone ? 'Não concluído ✓' : 'Não concluído',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight:
                                  isNotDone ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _updateStatus(key, 'cancelado'),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => _deleteBooking(key),
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
     Widget _buildCatalogTab() {
    return RefreshIndicator(
      onRefresh: _fetchCatalog,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _openCatalogDialog(isPlan: false),
                  icon: const Icon(Icons.add),
                  label: const Text('Serviço / Corte'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222228),
                    foregroundColor: const Color(0xFFF3D97E),
                  ),
                  onPressed: () => _openCatalogDialog(isPlan: true),
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('Plano Mensal'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'SERVIÇOS, PREÇOS E DURAÇÃO',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF3D97E),
            ),
          ),
          const SizedBox(height: 6),
          ..._services.map((s) {
            final price = double.tryParse('${s['price'] ?? 0}') ?? 0;
            final dur = int.tryParse('${s['duration'] ?? 30}') ?? 30;
            return Card(
              color: const Color(0xFF141417),
              child: ListTile(
                title: Text(
                    '${s['name'] ?? 'Serviço'} • R\$ ${price.toStringAsFixed(2)}'),
                subtitle:
                    Text('${s['category'] ?? 'Avulso'} • Duração: $dur min'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFFF3D97E)),
                      onPressed: () => _openCatalogDialog(isPlan: false, item: s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () =>
                          _deleteCatalogItem(false, (s['id'] ?? '').toString()),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          const Text(
            'PLANOS MENSAIS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF3D97E),
            ),
          ),
          const SizedBox(height: 6),
          ..._plans.map((p) {
            final price = double.tryParse('${p['price'] ?? 0}') ?? 0;
            final sessions = int.tryParse('${p['sessionsPerMonth'] ?? 4}') ?? 4;
            final dur = int.tryParse('${p['duration'] ?? 40}') ?? 40;
            return Card(
              color: const Color(0xFF141417),
              child: ListTile(
                title: Text(
                    '${p['name'] ?? 'Plano'} • R\$ ${price.toStringAsFixed(2)}'),
                subtitle: Text(
                  '$sessions sessões/mês • $dur min/atend.',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFFF3D97E)),
                      onPressed: () => _openCatalogDialog(isPlan: true, item: p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () =>
                          _deleteCatalogItem(true, (p['id'] ?? '').toString()),
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

  Widget _buildExpedienteTab() {
    final ordem = ['1', '2', '3', '4', '5', '6', '0'];
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          color: const Color(0xFF141417),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Intervalo de encaixe (min):'),
                DropdownButton<int>(
                  value: _slotStepMinutes,
                  dropdownColor: const Color(0xFF1B1B20),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10 min')),
                    DropdownMenuItem(value: 15, child: Text('15 min')),
                    DropdownMenuItem(value: 20, child: Text('20 min')),
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _slotStepMinutes = v);
                    await _saveExpedienteAndSync();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...ordem.map((d) {
          final info = _expediente[d] ?? {};
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (info['name'] ?? d).toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF3D97E),
                        ),
                      ),
                      Switch(
                        value: ativo,
                        onChanged: (val) async {
                          setState(() => _expediente[d]?['ativo'] = val);
                          await _saveExpedienteAndSync();
                        },
                      ),
                    ],
                  ),
                  Text(
                    'Turno 1: ${info['t1Inicio'] ?? '09:00'} às ${info['t1Fim'] ?? '12:00'}${t2Ativo ? ' • Turno 2: ${info['t2Inicio'] ?? '14:00'} às ${info['t2Fim'] ?? '19:30'}' : ' • Sem 2º turno'}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.black,
          ),
          onPressed: _openAddPauseDialog,
          icon: const Icon(Icons.pause_circle),
          label: const Text('Adicionar Pausa / Bloqueio'),
        ),
        const SizedBox(height: 8),
        ..._pauses.asMap().entries.map((entry) {
          final idx = entry.key;
          final p = entry.value as Map;
          return Card(
            color: const Color(0xFF141417),
            child: ListTile(
              title: Text(
                  '${p['date'] ?? ''} • ${p['start'] ?? ''} às ${p['end'] ?? ''}'),
              subtitle: Text((p['reason'] ?? 'Pausa').toString()),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
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

  Widget _buildClientsAndPlansTab() {
    return RefreshIndicator(
      onRefresh: _fetchClientsAndPlanMembers,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _openPlanMemberDialog(),
                  icon: const Icon(Icons.card_membership),
                  label: const Text('Adicionar ao Plano'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222228),
                    foregroundColor: const Color(0xFFF3D97E),
                  ),
                  onPressed: () => _openClientDialog(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Novo Cliente'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'CLIENTES DO PLANO (${_planMembers.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF3D97E),
            ),
          ),
          const SizedBox(height: 6),
          if (_planMembers.isEmpty)
            const Card(
              color: Color(0xFF141417),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Nenhuma pessoa cadastrada no plano ainda. Toque em "Adicionar ao Plano".',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ),
          ..._planMembers.map((m) {
            final bool valid = _isPlanMemberValid(m);
            final String cName = (m['clientName'] ?? 'Cliente').toString();
            final String phone = (m['phone'] ?? '').toString();
            final String planName = (m['planName'] ?? 'Plano Mensal').toString();
            final String expiresAt = (m['expiresAt'] ?? '-').toString();
            return Card(
              color: const Color(0xFF141417),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  '$cName • ${valid ? 'ATIVO' : 'VENCIDO / INATIVO'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: valid ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
                subtitle: Text(
                  '$planName\nTel: $phone • Validade: $expiresAt',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFFF3D97E)),
                      onPressed: () =>
                          _openPlanMemberDialog(existingMember: m),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () =>
                          _deletePlanMember((m['id'] ?? '').toString()),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          Text(
            'BANCO DE CLIENTES (${_clients.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF3D97E),
            ),
          ),
          const SizedBox(height: 6),
          if (_clients.isEmpty)
            const Card(
              color: Color(0xFF141417),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Nenhum cliente registado ainda.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ),
          ..._clients.map((c) {
            final String name = (c['name'] ?? 'Cliente').toString();
            final String phone = (c['phone'] ?? '').toString();
            final int totalB = int.tryParse('${c['totalBookings'] ?? 0}') ?? 0;
            final member =
                _findPlanMember(clientName: name, clientPhone: phone);
            final bool isMember = member != null && _isPlanMemberValid(member);

            return Card(
              color: const Color(0xFF141417),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  '$name${isMember ? ' • [PLANO]' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Tel: ${phone.isEmpty ? '-' : phone} • Marcações: $totalB',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Colocar no plano',
                      icon: const Icon(Icons.card_membership,
                          color: Colors.greenAccent),
                      onPressed: () => _openPlanMemberDialog(
                        existingMember: member,
                        prefillName: name,
                        prefillPhone: phone,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFFF3D97E)),
                      onPressed: () => _openClientDialog(client: c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteClient((c['id'] ?? '').toString()),
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

  Widget _buildBarbersTab() {
    return RefreshIndicator(
      onRefresh: _fetchBarbers,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () => _openBarberDialog(),
            icon: const Icon(Icons.person_add),
            label: const Text('Adicionar Barbeiro'),
          ),
          const SizedBox(height: 10),
          Card(
            color: const Color(0xFF141417),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RELATÓRIO POR BARBEIRO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF3D97E),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Semanal (7d)')),
                          selected: _barberReportPeriod == 'semanal',
                          selectedColor: const Color(0xFFD4AF37),
                          labelStyle: TextStyle(
                            color: _barberReportPeriod == 'semanal'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) =>
                              setState(() => _barberReportPeriod = 'semanal'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Mensal (Mês)')),
                          selected: _barberReportPeriod == 'mensal',
                          selectedColor: const Color(0xFFD4AF37),
                          labelStyle: TextStyle(
                            color: _barberReportPeriod == 'mensal'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) =>
                              setState(() => _barberReportPeriod = 'mensal'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_barbers.isEmpty)
            const Card(
              color: Color(0xFF141417),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                    'Nenhum barbeiro registado no Firebase. Toque acima para adicionar.'),
              ),
            ),
          ..._barbers.map((b) {
            final name = (b['name'] ?? 'Barbeiro').toString();
            final commPct = double.tryParse('${b['commission'] ?? 50}') ?? 50;

            final weeklyStats = _barberStats(
              name,
              period: 'semanal',
              onlyCompleted: _onlyCompletedInAccounting,
            );
            final monthlyStats = _barberStats(
              name,
              period: 'mensal',
              onlyCompleted: _onlyCompletedInAccounting,
            );

            final selectedStats =
                _barberReportPeriod == 'semanal' ? weeklyStats : monthlyStats;
            final periodLabel =
                _barberReportPeriod == 'semanal' ? 'Semanal' : 'Mensal';
            final selProduced = (selectedStats['produced'] as double?) ?? 0;
            final selComm = (selectedStats['commission'] as double?) ?? 0;
            final selCount = (selectedStats['count'] as int?) ?? 0;

            final wProduced = (weeklyStats['produced'] as double?) ?? 0;
            final wComm = (weeklyStats['commission'] as double?) ?? 0;
            final mProduced = (monthlyStats['produced'] as double?) ?? 0;
            final mComm = (monthlyStats['commission'] as double?) ?? 0;

            return Card(
              color: const Color(0xFF141417),
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$name • Comissão ${commPct.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF3D97E),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Relatório detalhado',
                              icon: const Icon(Icons.assessment,
                                  color: Colors.greenAccent),
                              onPressed: () =>
                                  _openBarberReportDialog(name, commPct),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFFF3D97E)),
                              onPressed: () => _openBarberDialog(barber: b),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () =>
                                  _deleteBarber((b['id'] ?? '').toString()),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${b['role'] ?? 'Barbeiro'} • $periodLabel ($selCount atend.): Produzido R\$ ${selProduced.toStringAsFixed(2)} • Comissão R\$ ${selComm.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Semanal: R\$ ${wProduced.toStringAsFixed(2)} (Com. R\$ ${wComm.toStringAsFixed(2)})  |  Mensal: R\$ ${mProduced.toStringAsFixed(2)} (Com. R\$ ${mComm.toStringAsFixed(2)})',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
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

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          color: const Color(0xFF141417),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Monitorização Mesmo Fechado & Avisos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dica: no Android, deixe a bateria deste app em "Sem restrição" para o serviço em segundo plano não ser encerrado.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _showBookingNotification(
                    'Teste • Barbearia Mr Jone',
                    'Notificações locais ativadas neste dispositivo.',
                    999,
                  ),
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Testar Notificação no Dispositivo'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF141417),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Palavra-passe do Painel (Guardada no Dispositivo)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPassController,
                  keyboardType: TextInputType.visiblePassword,
                  decoration:
                      const InputDecoration(labelText: 'Nova palavra-passe'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _saveNewAdminPass(_newPassController.text),
                  child: const Text('Guardar Palavra-passe'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF141417),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
              onPressed: _logoutAccount,
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('BARBEARIA MR JONE • GESTÃO'),
          backgroundColor: const Color(0xFF141417),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.content_cut, color: gold, size: 44),
              const SizedBox(height: 10),
              const Text(
                'BARBEARIA MR JONE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFFF3D97E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Acesso do Proprietário',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _passController,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                onSubmitted: (_) => _checkPass(),
                decoration: const InputDecoration(
                  labelText: 'Introduza a palavra-passe de acesso',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _checkPass,
                child: const Text(
                  'ENTRAR',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tabs = [
      _buildAccountingTab(),
      _buildCatalogTab(),
      _buildExpedienteTab(),
      _buildClientsAndPlansTab(),
      _buildBarbersTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MR JONE • GESTÃO COMPLETA'),
        backgroundColor: const Color(0xFF141417),
        actions: [
          IconButton(
            tooltip: 'Testar notificação',
            icon: const Icon(Icons.notifications_active),
            onPressed: () => _showBookingNotification(
              'Teste • Barbearia Mr Jone',
              'Notificações ativas no dispositivo.',
              999,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _syncAll,
          ),
        ],
      ),
      body: tabs[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (idx) => setState(() => _tabIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF141417),
        selectedItemColor: gold,
        unselectedItemColor: Colors.white60,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Contábil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Preços'),
          BottomNavigationBarItem(
              icon: Icon(Icons.schedule), label: 'Horários'),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_membership), label: 'Clientes/Planos'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Barbeiros'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
