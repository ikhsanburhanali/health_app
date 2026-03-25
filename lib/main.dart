import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math' as math;

void main() => runApp(const HealthTrackerApp());

class HealthTrackerApp extends StatelessWidget {
  const HealthTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthApp',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF8FAFB),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// --- DATABASE HELPER ---
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('health_app_v2026.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('CREATE TABLE records(id INTEGER PRIMARY KEY, type TEXT, val TEXT, status TEXT, date TEXT, timestamp TEXT)');
      await db.execute('CREATE TABLE profile(id INTEGER PRIMARY KEY, age INTEGER, sex TEXT)');
      await db.insert('profile', {'id': 1, 'age': 0, 'sex': 'Male'});
    });
  }

  Future<void> saveRecord(String type, String val, String status) async {
    final db = await instance.database;
    final now = DateTime.now();
    await db.insert('records', {
      'type': type,
      'val': val,
      'status': status,
      'date': DateFormat('yyyy-MM-dd').format(now),
      'timestamp': DateFormat('HH:mm:ss').format(now),
    });
  }

  Future<List<Map<String, dynamic>>> fetchRecords() async => await (await instance.database).query('records', orderBy: 'id ASC');
  Future<Map<String, dynamic>> getProfile() async => (await (await instance.database).query('profile')).first;
  Future<void> updateProfile(int age, String sex) async => (await instance.database).update('profile', {'age': age, 'sex': sex}, where: 'id = 1');
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00695C), Color(0xFF00897B)],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Far Background - Subtle floating shapes
              _buildParallaxLayer(
                offset: Offset(_animation.value * 30, _animation.value * 20),
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.health_and_safety, size: 400, color: Colors.white),
                ),
              ),
              
              // Mid Background - Moving circles
              _buildParallaxLayer(
                offset: Offset(-_animation.value * 50, _animation.value * 30),
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),

              _buildParallaxLayer(
                offset: Offset(_animation.value * 40, -_animation.value * 40),
                child: Opacity(
                  opacity: 0.08,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),

              // Foreground Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  _buildParallaxLayer(
                    offset: Offset(0, _animation.value * 10),
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        shape: BoxShape.circle, 
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2), 
                            blurRadius: 20, 
                            spreadRadius: 5,
                            offset: Offset(0, 10 + (_animation.value * 5))
                          )
                        ]
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/87820.jpg', 
                          fit: BoxFit.cover, 
                          errorBuilder: (c,e,s) => const Icon(Icons.health_and_safety, size: 80, color: Colors.teal)
                        )
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildParallaxLayer(
                    offset: Offset(0, _animation.value * 5),
                    child: Column(
                      children: [
                        Text(
                          "HealthApp", 
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 36, 
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 1.2,
                            shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                          )
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Created with coffee by Ikhsan", 
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                ]
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _buildParallaxLayer({required Offset offset, required Widget child}) {
    return Transform.translate(
      offset: offset,
      child: child,
    );
  }
}

// --- HOME SCREEN ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Dashboard"), actions: [
        IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())))
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Expanded(flex: 6, child: GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
            children: [
              _menuItem(context, "eGFR Calc", "assets/egfr.jpg", const EGFRPage()),
              _menuItem(context, "BMI Index", "assets/bmi_index.jpg", const BMIPage()),
              _menuItem(context, "Blood Pressure", "assets/blood_pressure.jpg", const BPPage()),
              _menuItem(context, "Blood Glucose", "assets/blood_glucose.jpg", const GlucosePage()),
            ],
          )),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage())),
            icon: const Icon(Icons.history, color: Colors.white),
            label: const Text("History, Trends & PDF", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
          ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _menuItem(BuildContext context, String title, String path, Widget page) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
    child: Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                  path,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (c,e,s) => const Icon(Icons.image_not_supported, size: 40)
              ),
            )
        ),
        Padding(padding: const EdgeInsets.all(8), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
      ]),
    ),
  );
}

// --- PROFILE PAGE ---
class ProfilePage extends StatefulWidget { 
  const ProfilePage({super.key});
  @override State<ProfilePage> createState() => _ProfilePageState(); 
}
class _ProfilePageState extends State<ProfilePage> {
  final aCtrl = TextEditingController(); String sex = "Male";
  @override void initState() { super.initState(); DatabaseHelper.instance.getProfile().then((p) => setState(() { aCtrl.text = p['age'] == 0 ? "" : p['age'].toString(); sex = p['sex']; })); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Profile")), body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
    TextField(controller: aCtrl, decoration: const InputDecoration(labelText: "Age", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    const SizedBox(height: 15),
    DropdownButtonFormField<String>(initialValue: sex, decoration: const InputDecoration(border: OutlineInputBorder()), items: ["Male", "Female"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => sex = v!)),
    const SizedBox(height: 30),
    ElevatedButton(onPressed: () async { await DatabaseHelper.instance.updateProfile(int.tryParse(aCtrl.text) ?? 0, sex); if(mounted) Navigator.pop(context); }, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("Save Profile")),
  ])));
}

// --- CALCULATORS ---
class EGFRPage extends StatefulWidget { 
  const EGFRPage({super.key});
  @override State<EGFRPage> createState() => _EGFRPageState(); 
}
class _EGFRPageState extends State<EGFRPage> {
  final cCtrl = TextEditingController(), aCtrl = TextEditingController(); String res = "", stat = "", uSex = "Male";
  @override void initState() { super.initState(); DatabaseHelper.instance.getProfile().then((p) => setState(() { aCtrl.text = p['age'].toString(); uSex = p['sex']; })); }
  void calc() {
    double c = double.tryParse(cCtrl.text) ?? 0, a = double.tryParse(aCtrl.text) ?? 0;
    if (c > 0 && a > 0) {
      double val = (186 * math.pow(c, -1.154) * math.pow(a, -0.203)).toDouble();
      if (uSex == "Female") val *= 0.742;
      setState(() { res = val.toStringAsFixed(1); stat = val >= 60 ? "Normal/Mild" : "Kidney Damage Analysis Required"; });
    }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("eGFR")), body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
    TextField(controller: cCtrl, decoration: const InputDecoration(labelText: "Creatinine (mg/dL)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    const SizedBox(height: 15),
    TextField(controller: aCtrl, decoration: const InputDecoration(labelText: "Age", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: calc, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("Calculate")),
    if (res.isNotEmpty) ...[
      const SizedBox(height: 20),
      Text(res, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal)),
      Text(stat),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: () {
        DatabaseHelper.instance.saveRecord("eGFR", res, stat);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("eGFR Record Saved!")));
      }, child: const Text("Save Record"))
    ]
  ])));
}

class BMIPage extends StatefulWidget { 
  const BMIPage({super.key});
  @override State<BMIPage> createState() => _BMIPageState(); 
}
class _BMIPageState extends State<BMIPage> {
  final hCtrl = TextEditingController(), wCtrl = TextEditingController(); String res = "", stat = "";
  void calc() {
    double h = double.tryParse(hCtrl.text) ?? 0, w = double.tryParse(wCtrl.text) ?? 0;
    if (h > 0 && w > 0) {
      double val = w / ((h / 100) * (h / 100));
      setState(() { res = val.toStringAsFixed(1); stat = val < 25 ? "Normal" : val < 30 ? "Overweight" : "Obese"; });
    }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("BMI")), body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
    TextField(controller: hCtrl, decoration: const InputDecoration(labelText: "Height (cm)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    const SizedBox(height: 15),
    TextField(controller: wCtrl, decoration: const InputDecoration(labelText: "Weight (kg)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: calc, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("Calculate")),
    if (res.isNotEmpty) ...[
      const SizedBox(height: 20),
      Text(res, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal)),
      Text(stat),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: () {
        DatabaseHelper.instance.saveRecord("BMI", res, stat);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("BMI Record Saved!")));
      }, child: const Text("Save Record"))
    ]
  ])));
}

class BPPage extends StatefulWidget { 
  const BPPage({super.key});
  @override State<BPPage> createState() => _BPPageState(); 
}
class _BPPageState extends State<BPPage> {
  final sCtrl = TextEditingController(), dCtrl = TextEditingController(); String res = "", stat = "";
  void calc() {
    int s = int.tryParse(sCtrl.text) ?? 0, d = int.tryParse(dCtrl.text) ?? 0;
    if (s > 0 && d > 0) {
      setState(() {
        res = "$s/$d";
        if (s > 180 || d > 120) {
          stat = "Hypertensive Crisis";
        } else if (s >= 140 || d >= 90) {
          stat = "Stage 2 Hypertension";
        } else if ((s >= 130 && s <= 139) || (d >= 80 && d <= 89)) {
          stat = "Stage 1 Hypertension";
        } else if ((s >= 120 && s <= 129) && d < 80) {
          stat = "Elevated";
        } else if (s < 120 && d < 80) {
          stat = "Normal";
        } else {
          stat = "Unclassified";
        }
      });
    }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Blood Pressure")), body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
    TextField(controller: sCtrl, decoration: const InputDecoration(labelText: "Systolic (mmHg)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    const SizedBox(height: 15),
    TextField(controller: dCtrl, decoration: const InputDecoration(labelText: "Diastolic (mmHg)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: calc, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("Analyze")),
    if (res.isNotEmpty) ...[
      const SizedBox(height: 20),
      Text(res, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal)),
      Text(stat),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: () {
        DatabaseHelper.instance.saveRecord("BP", res, stat);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Blood Pressure Saved!")));
      }, child: const Text("Save Record"))
    ]
  ])));
}

class GlucosePage extends StatefulWidget { 
  const GlucosePage({super.key});
  @override State<GlucosePage> createState() => _GlucosePageState(); 
}
class _GlucosePageState extends State<GlucosePage> {
  final gCtrl = TextEditingController();
  bool isFasting = true; 
  String res = "", stat = "";

  void calc() {
    double v = double.tryParse(gCtrl.text) ?? 0;
    if (v > 0) {
      setState(() {
        res = v.toStringAsFixed(0);
        if (isFasting) {
          stat = (v < 100) ? "Normal (Fasting)" : (v < 126) ? "Prediabetes" : "Diabetes Risk";
        } else {
          stat = (v < 140) ? "Normal (Random)" : "High Glucose";
        }
      });
    }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Blood Glucose")), body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
    SwitchListTile(
      title: Text(isFasting ? "Fasting" : "Random / After Meal"),
      value: isFasting,
      onChanged: (val) => setState(() => isFasting = val),
      activeThumbColor: Colors.teal,
    ),
    TextField(controller: gCtrl, decoration: const InputDecoration(labelText: "Glucose Level (mg/dL)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: calc, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("Analyze")),
    if (res.isNotEmpty) ...[
      const SizedBox(height: 20),
      Text(res, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal)),
      Text(stat),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: () {
        DatabaseHelper.instance.saveRecord("Glucose", res, stat);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Glucose Record Saved!")));
      }, child: const Text("Save Record"))
    ]
  ])));
}

// --- HISTORY & TRENDS ---
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("History"), actions: [IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () async => _pdf(await DatabaseHelper.instance.fetchRecords()))]),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: DatabaseHelper.instance.fetchRecords(), builder: (c, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final data = snap.data!;
      if (data.isEmpty) return const Center(child: Text("No records found."));
      return Column(children: [
        Padding(padding: const EdgeInsets.all(10), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ["BMI", "BP", "Glucose", "eGFR"].map((t) => Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChartPage(type: t, data: data))), child: Text(t)))).toList()))),
        Expanded(child: ListView.builder(itemCount: data.length, itemBuilder: (c, i) {
          final item = data[data.length - 1 - i];
          return ListTile(title: Text("${item['type']}: ${item['val']}"), subtitle: Text("${item['status']}\n${item['date']} at ${item['timestamp']}"));
        })),
      ]);
    }),
  );
  void _pdf(List<Map<String, dynamic>> data) async {
    final doc = pw.Document(); 
    doc.addPage(pw.Page(build: (c) => pw.TableHelper.fromTextArray(data: [['Date', 'Time', 'Type', 'Value', 'Status'], ...data.map((e) => [e['date'], e['timestamp'] ?? '', e['type'], e['val'], e['status']])])));
    await Printing.layoutPdf(onLayout: (f) async => doc.save());
  }
}

class ChartPage extends StatefulWidget {
  final String type;
  final List<Map<String, dynamic>> data;
  const ChartPage({super.key, required this.type, required this.data});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  bool isGlucoseFasting = true;
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filtered = widget.data.where((e) => e['type'] == widget.type).toList();
    
    if (widget.type == "Glucose") {
      filtered = filtered.where((e) => (e['status'] as String).contains(isGlucoseFasting ? "Fasting" : "Random")).toList();
    }

    if (filtered.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("${widget.type} Trend")),
        body: Column(
          children: [
            if (widget.type == "Glucose") _glucoseToggle(),
            const Expanded(child: Center(child: Text("Not enough data"))),
          ],
        ),
      );
    }

    List<FlSpot> mainSpots = [];
    List<FlSpot> secondarySpots = [];

    for (int i = 0; i < filtered.length; i++) {
      if (widget.type == "BP") {
        final parts = filtered[i]['val'].split('/');
        mainSpots.add(FlSpot(i.toDouble(), double.tryParse(parts[0]) ?? 0));
        if (parts.length > 1) {
          secondarySpots.add(FlSpot(i.toDouble(), double.tryParse(parts[1]) ?? 0));
        }
      } else {
        mainSpots.add(FlSpot(i.toDouble(), double.tryParse(filtered[i]['val']) ?? 0));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text("${widget.type} Trend"), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Detailed statistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    const Text("Last entries analysis", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                if (widget.type == "Glucose") _glucoseToggle(),
              ],
            ),
            const SizedBox(height: 20),
            // Persistent Info Card
            if (touchedIndex != null && touchedIndex! < filtered.length) _buildInfoCard(filtered[touchedIndex!]),
            const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 40,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[100]!, strokeWidth: 1),
                    getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[100]!, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx >= 0 && idx < filtered.length) {
                            String date = filtered[idx]['date'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(date.substring(5), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            );
                          }
                          return const Text("");
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _createLineBarData(mainSpots, const Color(0xFF673AB7), const Color(0xFFE91E63)),
                    if (secondarySpots.isNotEmpty)
                      _createLineBarData(secondarySpots, Colors.orange, Colors.yellow),
                  ],
                  lineTouchData: LineTouchData(
                    touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                      if (!event.isInterestedForInteractions || touchResponse == null || touchResponse.lineBarSpots == null) {
                        return;
                      }
                      setState(() {
                        touchedIndex = touchResponse.lineBarSpots!.first.spotIndex;
                      });
                    },
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.transparent, // Disable standard tooltip
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) => touchedBarSpots.map((barSpot) => null).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _indicator(widget.type == "BP" ? "Systolic" : widget.type, const Color(0xFF673AB7)),
                if (widget.type == "BP") ...[
                  const SizedBox(width: 20),
                  _indicator("Diastolic", Colors.orange),
                ]
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['type'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
              Text("${data['date']} | ${data['timestamp']}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 8),
          Text("Value: ${data['val']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text("Status: ${data['status']}", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _glucoseToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn("Fasting", isGlucoseFasting, () => setState(() => isGlucoseFasting = true)),
          _toggleBtn("Random", !isGlucoseFasting, () => setState(() => isGlucoseFasting = false)),
        ],
      ),
    );
  }

  Widget _toggleBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  LineChartBarData _createLineBarData(List<FlSpot> spots, Color color1, Color color2) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      gradient: LinearGradient(colors: [color1, color2]),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          bool isTouched = touchedIndex == index;
          return FlDotCirclePainter(
            radius: isTouched ? 10 : 6,
            color: isTouched ? color1 : Colors.white,
            strokeWidth: 3,
            strokeColor: color1,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color1.withValues(alpha: 0.2), color1.withValues(alpha: 0.01)],
        ),
      ),
    );
  }

  Widget _indicator(String label, Color color) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
  ]);
}
