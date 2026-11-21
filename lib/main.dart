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
  int _tabIndex = 0;
  String _statusMsg = 'Aguardando conexão com o Firebase';
  String _adminPass = kDefaultAdminPass;

  final TextEditingController _passController = TextEditingController();

  List _bookings = [];
  List _services = [];
  List _plans = [];
  List _barbers = [];

  final Set _knownKeys = {};
  bool _firstLoadDone = false;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _passController.dispose();
    super.dispose();
  }

  void _checkPass() {
    if (_passController.text.trim() == _adminPass) {
      setState(() => _unlocked = true);
      _syncAll();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 25),
        (_) => _fetchBookings(silent: true),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha incorreta.')),
      );
    }
  }

  Future<void> _syncAll() async {
    setState(() {
      _loading = true;
      _statusMsg = 'Sincronizando dados com o Firebase...';
    });
    await Future.wait([
      _fetchBookings(silent: true),
      _fetchCatalog(),
      _fetchBarbers(),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _statusMsg =
          'Online • ${_bookings.length} agendamento(s) • ${_services.length} serviço(s) • ${_barbers.length} barbeiro(s)';
    });
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
        final List loaded = [];
        final List brandNew = [];

        if (decoded is Map) {
          decoded.forEach((key, val) {
            if (val is Map) {
              final k = key.toString();
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
              final item = Map.from(d[i]);
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
              final item = Map.from(d[i]);
              item['id'] = i.toString();
              plnList.add(item);
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _services = srvList;
        _plans = plnList;
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
              final item = Map.from(d[i]);
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
     Future<void> _saveCatalogItem({
    required bool isPlan,
    String? existingId,
    required String name,
    required String category,
    required double price,
    required int sessionsPerMonth,
  }) async {
    final node = isPlan ? 'plans' : 'services';
    final payload = {
      'name': name.trim(),
      'category': category.trim().isEmpty
          ? (isPlan ? 'Planos Mensais' : 'Serviços Avulsos')
          : category.trim(),
      'price': price,
      'isPlan': isPlan,
      'sessionsPerMonth':
          isPlan ? (sessionsPerMonth <= 0 ? 4 : sessionsPerMonth) : 1,
    };

    if (existingId != null && existingId.isNotEmpty) {
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
    final node = isPlan ? 'plans' : 'services';
    await http.delete(Uri.parse('$kFirebaseDbUrl/$node/$id.json'));
    await _fetchCatalog();
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

  Future<void> _openCatalogDialog({required bool isPlan, Map? item}) async {
    final nameCtrl =
        TextEditingController(text: (item?['name'] ?? '').toString());
    final catCtrl = TextEditingController(
      text: (item?['category'] ??
              (isPlan ? 'Planos Mensais' : 'Serviços Avulsos'))
          .toString(),
    );
    final priceCtrl =
        TextEditingController(text: (item?['price'] ?? '0').toString());
    final sessCtrl = TextEditingController(
      text: (item?['sessionsPerMonth'] ?? (isPlan ? '4' : '1')).toString(),
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: Text(
          item == null
              ? (isPlan ? 'Novo Plano / Categoria' : 'Novo Serviço Avulso')
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
              final sess = int.tryParse(sessCtrl.text.trim()) ?? 4;
              Navigator.pop(ctx);
              await _saveCatalogItem(
                isPlan: isPlan,
                existingId: item?['id']?.toString(),
                name: name,
                category: catCtrl.text,
                price: price,
                sessionsPerMonth: sess,
              );
            },
            child: const Text('Salvar'),
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
              decoration: const InputDecoration(labelText: 'Especialidade / Função'),
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
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(Map b) async {
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

  double _calcReceitaItem(Map item) {
    final double price = double.tryParse('${item['price'] ?? 0}') ?? 0;
    final bool isPlan = item['isPlan'] == true;
    final int sessions = int.tryParse('${item['sessionsPerMonth'] ?? 4}') ?? 4;
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
            sum += _calcReceitaItem(it);
          }
        }
      }
    }
    return sum;
  }
     Widget _buildBookingsTab() {
    final double receita = _totalReceita();
    final double comissao50 = receita * 0.5;

    return RefreshIndicator(
      onRefresh: _syncAll,
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
                        const Text('RECEITA', style: TextStyle(fontSize: 11)),
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
            final List srvNames = [];
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
                  label: const Text('Serviço Avulso'),
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
                  label: const Text('Plano / Categoria'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'SERVIÇOS AVULSOS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF3D97E),
            ),
          ),
          const SizedBox(height: 6),
          if (_services.isEmpty)
            const Card(
              color: Color(0xFF141417),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhum serviço avulso cadastrado no Firebase.'),
              ),
            ),
          ..._services.map((s) {
            final price = double.tryParse('${s['price'] ?? 0}') ?? 0;
            return Card(
              color: const Color(0xFF141417),
              child: ListTile(
                title: Text(
                    '${s['name'] ?? 'Serviço'} • R\$ ${price.toStringAsFixed(2)}'),
                subtitle: Text('Categoria: ${s['category'] ?? 'Avulso'}'),
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
            'PLANOS & CATEGORIAS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF3D97E),
            ),
          ),
          const SizedBox(height: 6),
          if (_plans.isEmpty)
            const Card(
              color: Color(0xFF141417),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhum plano cadastrado no Firebase.'),
              ),
            ),
          ..._plans.map((p) {
            final price = double.tryParse('${p['price'] ?? 0}') ?? 0;
            final sessions = int.tryParse('${p['sessionsPerMonth'] ?? 4}') ?? 4;
            return Card(
              color: const Color(0xFF141417),
              child: ListTile(
                title: Text(
                    '${p['name'] ?? 'Plano'} • R\$ ${price.toStringAsFixed(2)}'),
                subtitle: Text(
                  'Categoria: ${p['category'] ?? 'Planos'} • $sessions sessões/mês',
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
                child: Text('Nenhum barbeiro cadastrado no Firebase.'),
              ),
            ),
          ..._barbers.map((b) {
            return Card(
              color: const Color(0xFF141417),
              child: ListTile(
                title: Text((b['name'] ?? 'Barbeiro').toString()),
                subtitle: Text(
                  '${b['role'] ?? 'Barbeiro'} • Comissão: ${b['commission'] ?? 50}%',
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
    final newPassCtrl = TextEditingController(text: _adminPass);
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
                  'Notificações & Suporte',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showBookingNotification(
                    'Teste • Barbearia Mr Jone',
                    'Notificações locais ativadas neste aparelho.',
                    999,
                  ),
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Testar Notificação no Aparelho'),
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
                  'Senha do Painel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newPassCtrl,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    if (newPassCtrl.text.trim().isNotEmpty) {
                      setState(() => _adminPass = newPassCtrl.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Senha atualizada na sessão.')),
                      );
                    }
                  },
                  child: const Text('Salvar Senha'),
                ),
              ],
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

    final tabs = [
      _buildBookingsTab(),
      _buildCatalogTab(),
      _buildBarbersTab(),
      _buildSettingsTab(),
    ];

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
              icon: Icon(Icons.calendar_month), label: 'Agenda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Preços'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Barbeiros'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
