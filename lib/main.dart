import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const String kFirebaseDbUrl =
    'https://agendamento-mrjone-default-rtdb.firebaseio.com';
const String kAdminPasscode = '1234';
const String kBarbershopPhone = '5521989622789';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MrJoneGestaoApp());
}

class MrJoneGestaoApp extends StatelessWidget {
  const MrJoneGestaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const goldPrimary = Color(0xFFD4AF37);
    const goldLight = Color(0xFFF3D97E);
    const bgMain = Color(0xFF0B0B0C);
    const bgSurface = Color(0xFF141417);

    return MaterialApp(
      title: 'Gestão Mr Jone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgMain,
        primaryColor: goldPrimary,
        colorScheme: const ColorScheme.dark(
          primary: goldPrimary,
          secondary: goldLight,
          surface: bgSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF101013),
          foregroundColor: goldLight,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0B0B0C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: goldPrimary, width: 1.5),
          ),
        ),
      ),
      home: const AdminGateScreen(),
    );
  }
}
class AdminGateScreen extends StatefulWidget {
  const AdminGateScreen({super.key});

  @override
  State<AdminGateScreen> createState() => _AdminGateScreenState();
}

class _AdminGateScreenState extends State<AdminGateScreen> {
  final TextEditingController _passController = TextEditingController();
  String? _error;

  void _login() {
    if (_passController.text.trim() == kAdminPasscode) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GestaoHomeScreen()),
      );
    } else {
      setState(() => _error = 'Senha inválida.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF141417),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x73D4AF37)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.content_cut,
                    size: 44,
                    color: Color(0xFFF3D97E),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BARBEARIA MR JONE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF3D97E),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'App de Gestão • Agenda, Equipe & Contábil',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha do Proprietário',
                      hintText: 'Digite 1234',
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF0B0B0C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _login,
                      child: const Text(
                        'ENTRAR',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GestaoHomeScreen extends StatefulWidget {
  const GestaoHomeScreen({super.key});

  @override
  State<GestaoHomeScreen> createState() => _GestaoHomeScreenState();
}
class _GestaoHomeScreenState extends State<GestaoHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _pollTimer;

  bool _loading = true;
  bool _isFirstLoad = true;
  String? _lastError;
  final Set<String> _knownBookingKeys = <String>{};

  List> _bookings = [];
  List> _services = [];
  List> _barbers = [];
  Map<String, dynamic> _expediente = {};

  String _selectedBarberFilter = 'todos';
  String _selectedAgendaBarberFilter = 'todos';
  bool _onlyCompletedInAccounting = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _fetchBookings(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _loading = true;
      _lastError = null;
    });

    await Future.wait([
      _fetchBookings(silent: true),
      _fetchServices(),
      _fetchBarbers(),
      _fetchExpediente(),
    ]);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _isFirstLoad = false;
    });
  }

  void _playAlertFeedback() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  Future<void> _fetchBookings({bool silent = false}) async {
    try {
      final res = await http.get(Uri.parse('$kFirebaseDbUrl/bookings.json'));
      if (res.statusCode != 200) {
        if (!silent && mounted) {
          setState(() => _lastError = 'Falha ao ler agendamentos (${res.statusCode}).');
        }
        return;
      }

      final decoded = jsonDecode(res.body);
      final List> parsed = [];
      final List> newlyArrived = [];

      if (decoded is Map) {
        decoded.forEach((key, value) {
          if (value is Map) {
            final item = Map<String, dynamic>.from(value);
            item['firebaseKey'] = key.toString();
            parsed.add(item);

            final k = key.toString();
            if (!_isFirstLoad && !_knownBookingKeys.contains(k)) {
              final st = (item['status'] ?? '').toString().toLowerCase();
              if (st != 'cancelado') {
                newlyArrived.add(item);
              }
            }
            _knownBookingKeys.add(k);
          }
        });
      }

      parsed.sort((a, b) {
        final dA = '${a['dateISO'] ?? ''} ${a['time'] ?? ''}';
        final dB = '${b['dateISO'] ?? ''} ${b['time'] ?? ''}';
        return dA.compareTo(dB);
      });

      if (!mounted) return;
      setState(() {
        _bookings = parsed;
        _lastError = null;
      });

      if (newlyArrived.isNotEmpty) {
        _playAlertFeedback();
        final first = newlyArrived.first;
        final cli = (first['clientName'] ?? 'Cliente').toString();
        final hr = (first['time'] ?? '').toString();
        final dt = (first['dateISO'] ?? '').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1F1D18),
            duration: const Duration(seconds: 6),
            content: Text(
              newlyArrived.length == 1
                  ? '🔔 Novo agendamento: $cli • $dt às $hr'
                  : '🔔 ${newlyArrived.length} novos agendamentos recebidos!',
              style: const TextStyle(
                color: Color(0xFFF3D97E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() => _lastError = 'Erro de conexão: $e');
      }
    }
  }
     Future<void> _fetchServices() async {
    try {
      final res = await http.get(Uri.parse('$kFirebaseDbUrl/services.json'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List> list = [];
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (value is Map) {
              final m = Map<String, dynamic>.from(value);
              m['firebaseKey'] = key.toString();
              list.add(m);
            }
          });
        } else if (decoded is List) {
          for (int i = 0; i < decoded.length; i++) {
            final v = decoded[i];
            if (v is Map) {
              final m = Map<String, dynamic>.from(v);
              m['firebaseKey'] = i.toString();
              list.add(m);
            }
          }
        }
        if (mounted) setState(() => _services = list);
      }
    } catch (_) {}
  }

  Future<void> _fetchBarbers() async {
    try {
      final res = await http.get(Uri.parse('$kFirebaseDbUrl/barbers.json'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List> list = [];
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (value is Map) {
              final m = Map<String, dynamic>.from(value);
              m['firebaseKey'] = key.toString();
              list.add(m);
            }
          });
        } else if (decoded is List) {
          for (int i = 0; i < decoded.length; i++) {
            final v = decoded[i];
            if (v is Map) {
              final m = Map<String, dynamic>.from(v);
              m['firebaseKey'] = i.toString();
              list.add(m);
            }
          }
        }
        if (mounted) setState(() => _barbers = list);
      }
    } catch (_) {}
  }

  Future<void> _fetchExpediente() async {
    try {
      final res = await http.get(Uri.parse('$kFirebaseDbUrl/expediente.json'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && mounted) {
          setState(() {
            _expediente = decoded.map((k, v) => MapEntry(k.toString(), v));
          });
        }
      }
    } catch (_) {}
  }
      String _brl(num value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = fixed.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }

  bool _isBookingCompleted(Map b) {
    final st = (b['status'] ?? '').toString().toLowerCase();
    return st == 'concluído' || st == 'concluido' || b['attended'] == true;
  }

  Map<String, double> _calcBookingFinancials(Map b) {
    double sessionRevenue = 0;
    double barberCommission = 0;
    double clientPaidToday = 0;

    final payment = (b['payment'] ?? '').toString();
    final items = b['items'];

    if (items is List && items.isNotEmpty) {
      for (final rawItem in items) {
        if (rawItem is Map) {
          final price = ((rawItem['price'] ?? 0) as num).toDouble();
          final isPlan = rawItem['isPlan'] == true;
          final sessions = isPlan
              ? (((rawItem['sessionsPerMonth'] ?? 4) as num).toDouble().clamp(1, 30))
              : 1.0;

          final perSession = price / sessions;
          sessionRevenue += perSession;
          barberCommission += perSession * 0.50;

          if (payment == 'Plano Mensal (Assinante)' && isPlan) {
            clientPaidToday += 0;
          } else {
            clientPaidToday += price;
          }
        }
      }
    } else {
      final total = ((b['total'] ?? 0) as num).toDouble();
      sessionRevenue = total;
      barberCommission = total * 0.50;
      clientPaidToday = total;
    }

    return {
      'sessionRevenue': sessionRevenue,
      'barberCommission': barberCommission,
      'shopNet': sessionRevenue - barberCommission,
      'clientPaidToday': clientPaidToday,
    };
  }

  Future<void> _generateAndPrintAccountingPdf({
    required String barberLabel,
    required List> rows,
    required double totalRevenue,
    required double totalCommission,
    required double totalShopNet,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'BARBEARIA MR JONE - FECHAMENTO CONTABIL (50%)',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Filtro Profissional: $barberLabel'),
          pw.Text('Gerado em: ${DateTime.now().toString().substring(0, 16)}'),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Faturamento do Periodo: ${_brl(totalRevenue)}'),
                pw.Text('Comissao dos Barbeiros (50%): ${_brl(totalCommission)}'),
                pw.Text('Liquido da Barbearia (50%): ${_brl(totalShopNet)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: ['Data/Hora', 'Cliente', 'Barbeiro', 'Status', 'Comissao (50%)'],
            data: rows.map((b) {
              final fin = _calcBookingFinancials(b);
              final dt = '${b['dateISO'] ?? ''} ${b['time'] ?? ''}';
              final cli = (b['clientName'] ?? '').toString();
              final barb = (b['barberName'] ?? '').toString();
              final st = (b['status'] ?? 'confirmado').toString();
              return [dt, cli, barb, st, _brl(fin['barberCommission']!)];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'fechamento_mr_jone.pdf',
    );
  }
      Future<void> _concluirAtendimento(Map b) async {
    final String firebaseKey = (b['firebaseKey'] ?? '').toString();
    if (firebaseKey.isEmpty) return;

    final String client = (b['clientName'] ?? 'Cliente').toString();

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
        content: Text('$client marcado como concluído! Comissão de 50% contabilizada.'),
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

  Future<void> _excluirAgendamento(Map b) async {
    final String firebaseKey = (b['firebaseKey'] ?? '').toString();
    if (firebaseKey.isEmpty) return;

    final String client = (b['clientName'] ?? 'Cliente').toString();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        title: const Text(
          'Excluir agendamento?',
          style: TextStyle(color: Color(0xFFF3D97E)),
        ),
        content: Text(
          'Deseja remover permanentemente o registro de $client?',
          style: const TextStyle(color: Colors.white70),
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

    await http.delete(Uri.parse('$kFirebaseDbUrl/bookings/$firebaseKey.json'));
    _knownBookingKeys.remove(firebaseKey);
    await _fetchBookings(silent: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Agendamento de $client excluído.')),
    );
  }
      @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestão Mr Jone',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar agora',
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminGateScreen()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFF3D97E),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Contábil'),
            Tab(text: 'Agenda'),
            Tab(text: 'Serviços & Planos'),
            Tab(text: 'Equipe'),
            Tab(text: 'Expediente & Logo'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            )
          : _lastError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _lastError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadAllData,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContabilTab(),
                    _buildAgendaTab(),
                    _buildServicesTab(),
                    _buildBarbersTab(),
                    _buildExpedienteAndLogoTab(),
                  ],
                ),
    );
  }
      Widget _buildContabilTab() {
    final activeBookings = _bookings.where((b) {
      final st = (b['status'] ?? '').toString().toLowerCase();
      if (st == 'cancelado') return false;
      if (_selectedBarberFilter != 'todos' &&
          (b['barberId'] ?? '').toString() != _selectedBarberFilter) {
        return false;
      }
      if (_onlyCompletedInAccounting && !_isBookingCompleted(b)) {
        return false;
      }
      return true;
    }).toList();

    double totalRevenue = 0;
    double totalCommission = 0;
    double totalShopNet = 0;

    for (final b in activeBookings) {
      final fin = _calcBookingFinancials(b);
      totalRevenue += fin['sessionRevenue']!;
      totalCommission += fin['barberCommission']!;
      totalShopNet += fin['shopNet']!;
    }

    String selectedBarberName = 'Todos os barbeiros';
    if (_selectedBarberFilter != 'todos') {
      final found = _barbers.where(
        (m) => (m['id'] ?? m['firebaseKey']).toString() == _selectedBarberFilter,
      );
      if (found.isNotEmpty) {
        selectedBarberName = (found.first['name'] ?? _selectedBarberFilter).toString();
      } else {
        selectedBarberName = _selectedBarberFilter;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedBarberFilter,
                decoration: const InputDecoration(
                  labelText: 'Filtrar Profissional',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem(value: 'todos', child: Text('Todos os barbeiros')),
                  ..._barbers.map((m) {
                    final id = (m['id'] ?? m['firebaseKey'] ?? '').toString();
                    final name = (m['name'] ?? id).toString();
                    return DropdownMenuItem(value: id, child: Text(name));
                  }),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBarberFilter = val);
                },
              ),
            ),
            const SizedBox(width: 10),
            FilterChip(
              label: Text(_onlyCompletedInAccounting ? 'Só concluídos' : 'Todos ativos'),
              selected: _onlyCompletedInAccounting,
              selectedColor: const Color(0x33D4AF37),
              onSelected: (v) => setState(() => _onlyCompletedInAccounting = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141417),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x73D4AF37)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumo Contábil • $selectedBarberName',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF3D97E),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              _kpiRow('Faturamento (sessões):', _brl(totalRevenue), Colors.white),
              _kpiRow('Comissão Barbeiros (50%):', _brl(totalCommission), Colors.greenAccent),
              _kpiRow('Líquido Barbearia (50%):', _brl(totalShopNet), const Color(0xFFF3D97E)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF3D97E),
                    side: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                  onPressed: () => _generateAndPrintAccountingPdf(
                    barberLabel: selectedBarberName,
                    rows: activeBookings,
                    totalRevenue: totalRevenue,
                    totalCommission: totalCommission,
                    totalShopNet: totalShopNet,
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Gerar / Imprimir PDF Contábil'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Atendimentos',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (activeBookings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nenhum atendimento encontrado para o filtro selecionado.',
                style: TextStyle(color: Colors.white60),
              ),
            ),
          )
        else
          ...activeBookings.map((b) {
            final fin = _calcBookingFinancials(b);
            final isDone = _isBookingCompleted(b);
            final status = (b['status'] ?? 'confirmado').toString();
            final items = (b['items'] is List)
                ? (b['items'] as List).map((e) => (e is Map ? (e['name'] ?? '').toString() : '')).where((s) => s.isNotEmpty).join(' + ')
                : (b['serviceName'] ?? '').toString();

            return Card(
              color: const Color(0xFF141417),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDone ? Colors.green.withOpacity(0.45) : Colors.white12,
                ),
              ),
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
                            '${b['clientName'] ?? 'Cliente'} • ${b['dateISO'] ?? ''} ${b['time'] ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF3D97E),
                            ),
                          ),
                        ),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDone
                                ? Colors.greenAccent
                                : (status.toLowerCase() == 'não concluído'
                                    ? Colors.orangeAccent
                                    : Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Barbeiro: ${b['barberName'] ?? '-'} • $items',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sessão: ${_brl(fin['sessionRevenue']!)} • Comissão (50%): ${_brl(fin['barberCommission']!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
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
                            status.toLowerCase() == 'não concluído'
                                ? 'Não concluído ✓'
                                : 'Não concluído',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _excluirAgendamento(b),
                          child: const Text(
                            'Excluir',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }

  Widget _kpiRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
      Widget _buildAgendaTab() {
    final filtered = _bookings.where((b) {
      if (_selectedAgendaBarberFilter != 'todos' &&
          (b['barberId'] ?? '').toString() != _selectedAgendaBarberFilter) {
        return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          value: _selectedAgendaBarberFilter,
          decoration: const InputDecoration(
            labelText: 'Filtrar Agenda por Profissional',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: [
            const DropdownMenuItem(value: 'todos', child: Text('Todos os barbeiros')),
            ..._barbers.map((m) {
              final id = (m['id'] ?? m['firebaseKey'] ?? '').toString();
              final name = (m['name'] ?? id).toString();
              return DropdownMenuItem(value: id, child: Text(name));
            }),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedAgendaBarberFilter = val);
          },
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum agendamento na agenda.',
                style: TextStyle(color: Colors.white60),
              ),
            ),
          )
        else
          ...filtered.map((b) {
            final status = (b['status'] ?? 'confirmado').toString();
            final isCancelled = status.toLowerCase() == 'cancelado';
            final items = (b['items'] is List)
                ? (b['items'] as List).map((e) => (e is Map ? (e['name'] ?? '').toString() : '')).where((s) => s.isNotEmpty).join(' + ')
                : (b['serviceName'] ?? '').toString();

            return Card(
              color: const Color(0xFF141417),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(
                  '${b['dateISO'] ?? ''} • ${b['time'] ?? ''} às ${b['endTime'] ?? ''} — ${b['clientName'] ?? 'Cliente'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D97E),
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  'Barbeiro: ${b['barberName'] ?? '-'} • $items\nTel: ${b['clientPhone'] ?? '-'} • Status: $status',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCancelled ? Colors.redAccent : Colors.white70,
                  ),
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    final key = (b['firebaseKey'] ?? '').toString();
                    if (key.isEmpty) return;
                    if (action == 'concluir') {
                      await _concluirAtendimento(b);
                    } else if (action == 'nao_concluido') {
                      await _marcarNaoConcluido(b);
                    } else if (action == 'cancelar') {
                      await http.patch(
                        Uri.parse('$kFirebaseDbUrl/bookings/$key.json'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'status': 'cancelado', 'attended': false}),
                      );
                      await _fetchBookings(silent: true);
                    } else if (action == 'excluir') {
                      await _excluirAgendamento(b);
                    }
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'concluir', child: Text('Marcar Concluído')),
                    PopupMenuItem(value: 'nao_concluido', child: Text('Marcar Não concluído')),
                    PopupMenuItem(value: 'cancelar', child: Text('Cancelar Horário')),
                    PopupMenuItem(value: 'excluir', child: Text('Excluir Registro')),
                  ],
                ),
              ),
            );
          }),
      ],
    );
      }
      Widget _buildServicesTab() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '30');
    final categoryCtrl = TextEditingController(text: 'Cortes');
    bool isPlan = false;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF141417),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x73D4AF37)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Novo Serviço ou Plano Mensal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF3D97E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome do serviço ou plano'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: durationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Duração (min)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: categoryCtrl,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                  CheckboxListTile(
                    value: isPlan,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'É Plano Mensal (4x/mês)?',
                      style: TextStyle(fontSize: 13),
                    ),
                    onChanged: (v) => setLocalState(() => isPlan = v ?? false),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF0B0B0C),
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
                        final duration = int.tryParse(durationCtrl.text) ?? 30;
                        final cat = categoryCtrl.text.trim().isEmpty ? 'Cortes' : categoryCtrl.text.trim();
                        if (name.isEmpty) return;

                        final id = 'srv-${DateTime.now().millisecondsSinceEpoch}';
                        await http.post(
                          Uri.parse('$kFirebaseDbUrl/services.json'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'id': id,
                            'name': name,
                            'price': price,
                            'duration': duration,
                            'category': cat,
                            'isPlan': isPlan,
                            'sessionsPerMonth': isPlan ? 4 : 1,
                          }),
                        );
                        nameCtrl.clear();
                        priceCtrl.clear();
                        await _fetchServices();
                      },
                      child: const Text(
                        'SALVAR SERVIÇO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._services.map((s) {
              final key = (s['firebaseKey'] ?? '').toString();
              return Card(
                color: const Color(0xFF141417),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    (s['name'] ?? '').toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${s['category'] ?? ''} • ${_brl((s['price'] ?? 0) as num)} • ${s['duration'] ?? 30} min',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      if (key.isEmpty) return;
                      await http.delete(Uri.parse('$kFirebaseDbUrl/services/$key.json'));
                      await _fetchServices();
                    },
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
      }
      Widget _buildBarbersTab() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Barbeiro Profissional');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF141417),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x73D4AF37)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adicionar Barbeiro à Equipe',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF3D97E),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome do barbeiro'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(labelText: 'Especialidade / Cargo'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0B0B0C),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final id = name
                        .toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                        .replaceAll(RegExp(r'^-|-$'), '');
                    final initials = name
                        .split(' ')
                        .where((p) => p.isNotEmpty)
                        .map((p) => p[0])
                        .take(2)
                        .join()
                        .toUpperCase();

                    await http.post(
                      Uri.parse('$kFirebaseDbUrl/barbers.json'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'id': id.isEmpty ? 'barb-${DateTime.now().millisecondsSinceEpoch}' : id,
                        'name': name,
                        'role': roleCtrl.text.trim().isEmpty
                            ? 'Barbeiro Profissional'
                            : roleCtrl.text.trim(),
                        'initials': initials.isEmpty ? 'BJ' : initials,
                        'active': true,
                        'commissionRate': 0.50,
                      }),
                    );
                    nameCtrl.clear();
                    await _fetchBarbers();
                  },
                  child: const Text(
                    'ADICIONAR BARBEIRO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._barbers.map((m) {
          final key = (m['firebaseKey'] ?? '').toString();
          final active = m['active'] != false;
          return Card(
            color: const Color(0xFF141417),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0x33D4AF37),
                child: Text(
                  (m['initials'] ?? 'B').toString(),
                  style: const TextStyle(
                    color: Color(0xFFF3D97E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                (m['name'] ?? '').toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${m['role'] ?? 'Barbeiro'} • ${active ? 'Ativo' : 'Inativo'}',
                style: TextStyle(
                  color: active ? Colors.greenAccent : Colors.white54,
                  fontSize: 12,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: active,
                    activeColor: const Color(0xFFD4AF37),
                    onChanged: (val) async {
                      if (key.isEmpty) return;
                      await http.patch(
                        Uri.parse('$kFirebaseDbUrl/barbers/$key.json'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'active': val}),
                      );
                      await _fetchBarbers();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      if (key.isEmpty) return;
                      await http.delete(Uri.parse('$kFirebaseDbUrl/barbers/$key.json'));
                      await _fetchBarbers();
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
      }
      Widget _buildExpedienteAndLogoTab() {
    final daysOrder = ['1', '2', '3', '4', '5', '6', '0'];
    final dayNames = {
      '1': 'Segunda',
      '2': 'Terça',
      '3': 'Quarta',
      '4': 'Quinta',
      '5': 'Sexta',
      '6': 'Sábado',
      '0': 'Domingo',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF141417),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x73D4AF37)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Logo da Barbearia no Site',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF3D97E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Envie uma imagem para atualizar a logo sincronizada no site via Firebase.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF3D97E),
                    side: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final XFile? picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 900,
                      imageQuality: 85,
                    );
                    if (picked == null) return;
                    final Uint8List bytes = await picked.readAsBytes();
                    final base64Str = 'data:image/png;base64,${base64Encode(bytes)}';

                    await http.put(
                      Uri.parse('$kFirebaseDbUrl/customLogo.json'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(base64Str),
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logo enviada para o site!')),
                    );
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Escolher Imagem da Logo'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Expediente Semanal (Ativo / Fechado)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...daysOrder.map((dKey) {
          final rawDay = _expediente[dKey];
          final dayMap = rawDay is Map
              ? Map<String, dynamic>.from(rawDay)
              : <String, dynamic>{
                  'name': dayNames[dKey] ?? dKey,
                  'ativo': true,
                  't1Inicio': '09:00',
                  't1Fim': '19:00',
                };
          final bool ativo = dayMap['ativo'] != false;
          final String label = (dayMap['name'] ?? dayNames[dKey] ?? dKey).toString();

          return Card(
            color: const Color(0xFF141417),
            margin: const EdgeInsets.only(bottom: 8),
            child: SwitchListTile(
              value: ativo,
              activeColor: const Color(0xFFD4AF37),
              title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                ativo
                    ? 'Aberto • ${dayMap['t1Inicio'] ?? '09:00'}–${dayMap['t1Fim'] ?? '19:00'}${dayMap['t2Ativo'] == true ? ' / ${dayMap['t2Inicio'] ?? ''}–${dayMap['t2Fim'] ?? ''}' : ''}'
                    : 'Fechado',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              onChanged: (val) async {
                dayMap['ativo'] = val;
                await http.patch(
                  Uri.parse('$kFirebaseDbUrl/expediente/$dKey.json'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'ativo': val}),
                );
                await _fetchExpediente();
              },
            ),
          );
        }),
      ],
    );
  }
}
