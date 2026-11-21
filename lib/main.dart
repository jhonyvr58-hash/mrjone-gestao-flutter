import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const String kFirebaseDbUrl =
    'https://barbeariamrjone-f3e8a-default-rtdb.firebaseio.com';
const String kDefaultAdminPass = '1234';

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
  await androidImpl?.requestNotificationsPermission();
}

Future<void> _showBookingNotification(String title, String body, int id) async {
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'mrjone_bookings_channel',
    'Novos Agendamentos',
    channelDescription: 'Avisos quando um cliente faz um novo agendamento',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails details =
      NotificationDetails(android: androidDetails);

  await kNotificationsPlugin.show(id, title, body, details);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initNotifications();
  runApp(const MrJoneGestaoApp());
}

class MrJoneGestaoApp extends StatelessWidget {
  const MrJoneGestaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão Mr Jone',
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
  String _statusMsg = 'Aguardando conexão com o Firebase';
  final TextEditingController _passController = TextEditingController();
  List> _bookings = [];
  final Set<String> _knownKeys = {};
  bool _firstLoadDone = false;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _passController.dispose();
    super.dispose();
  }

  void _checkPass() {
    if (_passController.text.trim() == kDefaultAdminPass) {
      setState(() => _unlocked = true);
      _fetchBookings();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 25),
        (_) => _fetchBookings(silent: true),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha incorreta (padrão: 1234).')),
      );
    }
  }

  Future<void> _fetchBookings({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _statusMsg = 'Sincronizando agendamentos...';
      });
    }
    try {
      final uri = Uri.parse(
        '$kFirebaseDbUrl/bookings.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List> loaded = [];
        final List> brandNew = [];

        if (decoded is Map) {
          decoded.forEach((key, val) {
            if (val is Map) {
              final k = key.toString();
              final item = Map<String, dynamic>.from(val);
              item['firebaseKey'] = k;
              loaded.add(item);

              if (_firstLoadDone && !_knownKeys.contains(k)) {
                brandNew.add(item);
              }
              _knownKeys.add(k);
            }
          });
        }

        _firstLoadDone = true;

        int notifId = 100;
        for (final novo in brandNew) {
          final client = (novo['clientName'] ?? 'Cliente').toString();
          final dateLbl = (novo['dateLabel'] ?? '').toString();
          final timeLbl = (novo['time'] ?? '').toString();
          final barber = (novo['barberName'] ?? 'Barbearia Mr Jone').toString();
          await _showBookingNotification(
            'Novo agendamento • $client',
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
          _statusMsg = 'Online • ${loaded.length} registro(s)';
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

  Future<void> _openWhatsApp(Map<String, dynamic> b) async {
    final client = (b['clientName'] ?? 'Cliente').toString();
    final dateLbl = (b['dateLabel'] ?? '').toString();
    final timeLbl = (b['time'] ?? '').toString();
    final rawPhone = (b['clientPhone'] ?? b['phone'] ?? '5521989622789')
        .toString()
        .replaceAll(RegExp(r'\D'), '');
    final phone = rawPhone.startsWith('55') ? rawPhone : '55$rawPhone';
    final msg = Uri.encodeComponent(
      'Olá $client! Aqui é da Barbearia Mr Jone. Confirmando seu horário em $dateLbl às $timeLbl.',
    );
    final url = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _updateStatus(String firebaseKey, String newStatus) async {
    if (firebaseKey.isEmpty) return;
    try {
      final uri = Uri.parse('$kFirebaseDbUrl/bookings/$firebaseKey.json');
      await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );
      await _fetchBookings();
    } catch (_) {}
  }

  Future<void> _deleteBooking(String firebaseKey) async {
    if (firebaseKey.isEmpty) return;
    try {
      final uri = Uri.parse('$kFirebaseDbUrl/bookings/$firebaseKey.json');
      await http.delete(uri);
      await _fetchBookings();
    } catch (_) {}
  }

  double _calcReceitaItem(Map<String, dynamic> item) {
    final double price = double.tryParse('${item['price'] ?? 0}') ?? 0;
    final bool isPlan = item['isPlan'] == true;
    final int sessions =
        int.tryParse('${item['sessionsPerMonth'] ?? 4}') ?? 4;
    return isPlan ? (price / (sessions <= 0 ? 4 : sessions)) : price;
  }

  double _totalReceita() {
    double sum = 0;
    for (final b in _bookings) {
      if ((b['status'] ?? '') == 'cancelado') continue;
      final items = b['items'];
      if (items is List) {
        for (final it in items) {
          if (it is Map) {
            sum += _calcReceitaItem(Map<String, dynamic>.from(it));
          }
        }
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('GESTÃO MR JONE • APP'),
          backgroundColor: const Color(0xFF141417),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Acesso do Proprietário',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF3D97E),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Senha de acesso (padrão: 1234)',
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

    final double receita = _totalReceita();
    final double comissao50 = receita * 0.5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GESTÃO MR JONE'),
        backgroundColor: const Color(0xFF141417),
        actions: [
          IconButton(
            tooltip: 'Testar notificação',
            icon: const Icon(Icons.notifications_active),
            onPressed: () => _showBookingNotification(
              'Teste • Barbearia Mr Jone',
              'Notificações ativas no aparelho.',
              999,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchBookings(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchBookings(),
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(
              _statusMsg,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFF141417),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RECEITA',
                              style: TextStyle(fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            'R\$ ${receita.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF3D97E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: const Color(0xFF141417),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('COMISSÃO 50%',
                              style: TextStyle(fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            'R\$ ${comissao50.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading && _bookings.isEmpty)
              const Center(child: CircularProgressIndicator()),
            ..._bookings.map((b) {
              final String key = (b['firebaseKey'] ?? '').toString();
              final String status = (b['status'] ?? 'confirmado').toString();
              final List<String> srvNames = [];
              if (b['items'] is List) {
                for (final it in b['items']) {
                  if (it is Map && it['name'] != null) {
                    srvNames.add(it['name'].toString());
                  }
                }
              }
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
                        'Barbeiro: ${b['barberName'] ?? 'Mr. Jone'} • Status: $status',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (srvNames.isNotEmpty)
                        Text(
                          srvNames.join(' + '),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => _openWhatsApp(b),
                            child: const Text(
                              'WhatsApp',
                              style: TextStyle(color: Colors.greenAccent),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _updateStatus(key, 'concluído'),
                            child: const Text('Concluir'),
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
      ),
    );
  }
}
