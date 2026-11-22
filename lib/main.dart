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
  bool _onlyCompletedInAccounting = false;
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
      _fetchRemoteSettings(),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _statusMsg =
          'Sincronizado • ${_bookings.length} marcação(ões) • ${_services.length + _plans.length} item(ns) • ${_barbers.length} barbeiro(s)';
    });
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
          final dateLbl = (novo['dateLabel'] ?? '').toString();
          final timeLbl = (novo['time'] ?? '').toString();
          final barber = (novo['barberName'] ?? 'Barbearia Mr Jone').toString();
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
    return sum;
  }

  double _calcBookingCommission(Map b) {
    final pct = _getBarberCommissionPct(b['barberName']?.toString());
    return _calcBookingValue(b) * (pct / 100.0);
  }

  double _totalReceita({bool onlyCompleted = false}) {
    double sum = 0;
    for (final b in _bookings) {
      final st = (b['status'] ?? 'confirmado').toString().toLowerCase();
      if (st == 'cancelado') continue;
      if (onlyCompleted && st != 'concluído' && st != 'concluido') continue;
      sum += _calcBookingValue(b);
    }
    return sum;
  }

  double _totalComissoes({bool onlyCompleted = false}) {
    double sum = 0;
    for (final b in _bookings) {
      final st = (b['status'] ?? 'confirmado').toString().toLowerCase();
      if (st == 'cancelado') continue;
      if (onlyCompleted && st != 'concluído' && st != 'concluido') continue;
      sum += _calcBookingCommission(b);
    }
    return sum;
  }

  double _barberTotalGenerated(String barberName, {bool onlyCompleted = false}) {
    final target = barberName.trim().toLowerCase();
    if (target.isEmpty) return 0;
    double sum = 0;
    for (final b in _bookings) {
      final st = (b['status'] ?? 'confirmado').toString().toLowerCase();
      if (st == 'cancelado') continue;
      if (onlyCompleted && st != 'concluído' && st != 'concluido') continue;
      final bName = (b['barberName'] ?? '').toString().trim().toLowerCase();
      if (bName == target || bName.contains(target) || target.contains(bName)) {
        sum += _calcBookingValue(b);
      }
    }
    return sum;
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

  Future<void> _openWhatsApp(Map b) async {
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

    final reminderText =
        'Olá $client! Lembrete da Barbearia Mr Jone: marcou o horário das *$timeLbl* em *$dateLbl* para o serviço *$srvSummary* com *$barber*. Estamos à sua espera!';

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
          '$client concluído! Comissão de R\$ ${comm.toStringAsFixed(2)} registada para $barber.',
        ),
      ),
    );
  }

  Future<void> _marcarNaoConcluido(Map b) async {
    final String firebaseKey = (b['firebaseKey'] ?? '').toString();
    if (firebaseKey.isEmpty) return;

    final String client = (b['clientName'] ?? 'Cliente').toString();

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
        content: Text('$client marcado como não concluído.'),
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
    await http.delete(Uri.parse('$kFirebaseDbUrl/bookings/$firebaseKey.json'));
    await _fetchBookings(silent: true);
  }
      Future<void> _openManualEntryDialog() async {
    final clientCtrl = TextEditingController(text: 'Cliente Balcão');
    String selectedBarberName = _barbers.isNotEmpty
        ? (_barbers.first['name'] ?? 'Mr. Jone').toString()
        : 'Mr. Jone';
    double selectedCommPct = _barbers.isNotEmpty
        ? (double.tryParse('${_barbers.first['commission'] ?? 50}') ?? 50)
        : 50;

    final List allCatalog = [..._services, ..._plans];
    Map selectedItem = allCatalog.isNotEmpty
        ? Map.from(allCatalog.first as Map)
        : {
            'name': 'Cabelo e Barba (Combo Completo)',
            'price': 65.0,
            'duration': 50,
            'isPlan': false,
            'sessionsPerMonth': 1,
          };

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
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
                  decoration: const InputDecoration(labelText: 'Nome do Cliente'),
                ),
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
                if (allCatalog.isNotEmpty)
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: 0,
                    dropdownColor: const Color(0xFF1B1B20),
                    decoration:
                        const InputDecoration(labelText: 'Serviço ou Plano'),
                    items: [
                      for (var i = 0; i < allCatalog.length; i++)
                        DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                            '${allCatalog[i]['name']} • R\$ ${allCatalog[i]['price']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (idx) {
                      if (idx == null) return;
                      setLocal(() {
                        selectedItem = Map.from(allCatalog[idx] as Map);
                      });
                    },
                  ),
                const SizedBox(height: 12),
                Text(
                  'Receita sessão: R\$ ${_calcReceitaItem(selectedItem).toStringAsFixed(2)} • Comissão (${selectedCommPct.toStringAsFixed(0)}%): R\$ ${_calcComissaoItem(selectedItem, selectedCommPct).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
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
                final now = DateTime.now();
                final hh = now.hour.toString().padLeft(2, '0');
                final mm = now.minute.toString().padLeft(2, '0');
                final dd = now.day.toString().padLeft(2, '0');
                final mo = now.month.toString().padLeft(2, '0');
                Navigator.pop(ctx);

                await http.post(
                  Uri.parse('$kFirebaseDbUrl/bookings.json'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'clientName': clientCtrl.text.trim().isEmpty
                        ? 'Cliente Balcão'
                        : clientCtrl.text.trim(),
                    'clientPhone': 'Balcão',
                    'barberName': selectedBarberName,
                    'dateLabel': '$dd/$mo/${now.year}',
                    'time': '$hh:$mm',
                    'status': 'concluído',
                    'attended': true,
                    'completedAt': now.toIso8601String(),
                    'createdAt': now.toIso8601String(),
                    'items': [
                      {
                        'name': (selectedItem['name'] ?? 'Serviço').toString(),
                        'price': double.tryParse(
                                '${selectedItem['price'] ?? 0}') ??
                            0,
                        'duration':
                            int.tryParse('${selectedItem['duration'] ?? 30}') ??
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
        ),
      ),
    );
  }

  List _buildCatalogOptions() {
    final List options = [];
    for (final s in _services) {
      options.add({
        'name': (s['name'] ?? '').toString(),
        'price': double.tryParse('${s['price'] ?? 0}') ?? 0.0,
        'duration': int.tryParse('${s['duration'] ?? 30}') ?? 30,
        'isPlan': false,
        'sessionsPerMonth': 1,
      });
    }
    for (final p in _plans) {
      options.add({
        'name': (p['name'] ?? '').toString(),
        'price': double.tryParse('${p['price'] ?? 0}') ?? 0.0,
        'duration': int.tryParse('${p['duration'] ?? 40}') ?? 40,
        'isPlan': true,
        'sessionsPerMonth': int.tryParse('${p['sessionsPerMonth'] ?? 4}') ?? 4,
      });
    }
    return options;
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

    final srvCtrl = TextEditingController(text: currentServiceName);
    final priceCtrl =
        TextEditingController(text: currentPrice.toStringAsFixed(2));
    final durCtrl = TextEditingController(text: '$currentDuration');
    final dateCtrl =
        TextEditingController(text: (b['dateLabel'] ?? '').toString());
    final timeCtrl = TextEditingController(text: (b['time'] ?? '').toString());
    final barberCtrl =
        TextEditingController(text: (b['barberName'] ?? 'Mr. Jone').toString());

    final List allOptions = _buildCatalogOptions();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: Text(
          'Editar • ${b['clientName'] ?? 'Cliente'}',
          style: const TextStyle(color: Color(0xFFF3D97E)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                isExpanded: true,
                dropdownColor: const Color(0xFF1B1B20),
                decoration: const InputDecoration(
                  labelText: 'Escolher da tabela de preços',
                ),
                items: [
                  for (var i = 0; i < allOptions.length; i++)
                    DropdownMenuItem<int>(
                      value: i,
                      child: Text(
                        '${allOptions[i]['name']} (R\$ ${(allOptions[i]['price'] as double).toStringAsFixed(2)} • ${allOptions[i]['duration']} min)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (idx) {
                  if (idx == null) return;
                  final opt = allOptions[idx];
                  srvCtrl.text = opt['name'].toString();
                  priceCtrl.text = (opt['price'] as double).toStringAsFixed(2);
                  durCtrl.text = '${opt['duration'] ?? 30}';
                  currentIsPlan = opt['isPlan'] == true;
                  currentSessions =
                      int.tryParse('${opt['sessionsPerMonth'] ?? 4}') ?? 4;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: srvCtrl,
                decoration: const InputDecoration(labelText: 'Serviço / Plano'),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              ),
              TextField(
                controller: durCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Duração (minutos)'),
              ),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Data (ex: 22/11/2026)',
                ),
              ),
              TextField(
                controller: timeCtrl,
                decoration:
                    const InputDecoration(labelText: 'Horário (ex: 10:30)'),
              ),
              TextField(
                controller: barberCtrl,
                decoration: const InputDecoration(labelText: 'Barbeiro'),
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
              final newService = srvCtrl.text.trim().isEmpty
                  ? 'Serviço'
                  : srvCtrl.text.trim();
              final newPrice =
                  double.tryParse(priceCtrl.text.replaceAll(',', '.')) ??
                      currentPrice;
              final newDur = int.tryParse(durCtrl.text.trim()) ?? currentDuration;
              final newDate = dateCtrl.text.trim();
              final newTime = timeCtrl.text.trim();
              final newBarber = barberCtrl.text.trim().isEmpty
                  ? 'Mr. Jone'
                  : barberCtrl.text.trim();

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

              await http.patch(
                Uri.parse('$kFirebaseDbUrl/bookings/$firebaseKey.json'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'items': updatedItems,
                  'dateLabel': newDate,
                  'time': newTime,
                  'barberName': newBarber,
                }),
              );
              await _fetchBookings(silent: true);
            },
            child: const Text('Guardar Alterações'),
          ),
        ],
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

  Future<void> _openAddPauseDialog() async {
    final dateCtrl = TextEditingController(text: '22/11/2026');
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
      if (!_onlyCompletedInAccounting) return true;
      final st = (b['status'] ?? '').toString().toLowerCase();
      return st == 'concluído' || st == 'concluido';
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
                'Ao clicar em Concluir ou Não concluído, o total e a comissão do barbeiro são atualizados.',
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
            final bool isDone = status.toLowerCase() == 'concluído' ||
                status.toLowerCase() == 'concluido';
            final double val = _calcBookingValue(b);
            final double comm = _calcBookingCommission(b);
            final String srvNames = _buildServiceSummary(b);

            return Card(
              color: const Color(0xFF141417),
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${b['clientName'] ?? 'Cliente'} • ${b['dateLabel'] ?? ''} ${b['time'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF3D97E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Barbeiro: ${b['barberName'] ?? 'Mr. Jone'} • Receita: R\$ ${val.toStringAsFixed(2)} • Comissão: R\$ ${comm.toStringAsFixed(2)} • $status',
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
                            'Editar',
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
                          child: const Text(
                            'Não concluído',
                            style: TextStyle(color: Colors.orangeAccent),
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
          const SizedBox(height: 12),
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
            final generated = _barberTotalGenerated(
              name,
              onlyCompleted: _onlyCompletedInAccounting,
            );
            final commissionVal = generated * (commPct / 100.0);
            return Card(
              color: const Color(0xFF141417),
              child: ListTile(
                title: Text('$name • Comissão ${commPct.toStringAsFixed(0)}%'),
                subtitle: Text(
                  '${b['role'] ?? 'Barbeiro'} • Produzido: R\$ ${generated.toStringAsFixed(2)} • Total Comissão: R\$ ${commissionVal.toStringAsFixed(2)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFFF3D97E)),
                      onPressed: () => _openBarberDialog(barber: b),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteBarber((b['id'] ?? '').toString()),
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
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Barbeiros'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
