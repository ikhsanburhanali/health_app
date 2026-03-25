import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math' as math;

void main() => runApp(HealthTrackerApp());

class HealthTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthApp',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Color(0xFFF8FAFB),
        appBarTheme: AppBarTheme(centerTitle: true, elevation: 0),
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
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
  @override _SplashScreenState createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 5), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen())));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00695C), Color(0xFF00897B)])),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 160, height: 160,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: ClipOval(child: Image.asset('assets/87820.jpg', fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.health_and_safety, size: 80, color: Colors.teal))),
        ),
        SizedBox(height: 30),
        Text("HealthApp", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        Text("Created with coffee by Ikhsan", style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic)),
        SizedBox(height: 50),
        CircularProgressIndicator(color: Colors.white),
      ]),
    ),
  );
}

// --- HOME SCREEN ---
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Health Dashboard"), actions: [
        IconButton(icon: Icon(Icons.person), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage())))
      ]),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          Expanded(flex: 6, child: GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
            children: [
              _menuItem(context, "eGFR Calc", "assets/egfr.jpg", EGFRPage()),
              _menuItem(context, "BMI Index", "assets/bmi_index.jpg", BMIPage()),
              _menuItem(context, "Blood Pressure", "assets/blood_pressure.jpg", BPPage()),
              _menuItem(context, "Blood Glucose", "assets/blood_glucose.jpg", GlucosePage()),
            ],
          )),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryPage())),
            icon: Icon(Icons.history, color: Colors.white),
            label: Text("History, Trends & PDF", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
          ),
          SizedBox(height: 80), // History button remains high
        ]),
      ),
    );
  }

  Widget _menuItem(context, title, path, page) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
    child: Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Smaller logo padding
              child: Image.asset(
                  path,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (c,e,s) => Icon(Icons.image_not_supported, size: 40)
              ),
            )
        ),
        Padding(padding: EdgeInsets.all(8), child: Text(title, style: TextStyle(fontWeight: FontWeight.bold))),
      ]),
    ),
  );
}

// --- PROFILE PAGE ---
class ProfilePage extends StatefulWidget { @override _ProfilePageState createState() => _ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage> {
  final aCtrl = TextEditingController(); String sex = "Male";
  @override void initState() { super.initState(); DatabaseHelper.instance.getProfile().then((p) => setState(() { aCtrl.text = p['age'] == 0 ? "" : p['age'].toString(); sex = p['sex']; })); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("Profile")), body: Padding(padding: EdgeInsets.all(20), child: Column(children: [
    TextField(controller: aCtrl, decoration: InputDecoration(labelText: "Age", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    SizedBox(height: 15),
    DropdownButtonFormField<String>(value: sex, decoration: InputDecoration(border: OutlineInputBorder()), items: ["Male", "Female"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => sex = v!)),
    SizedBox(height: 30),
    ElevatedButton(onPressed: () async { await DatabaseHelper.instance.updateProfile(int.tryParse(aCtrl.text) ?? 0, sex); Navigator.pop(context); }, child: Text("Save Profile"), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
  ])));
}

// --- CALCULATORS ---
class EGFRPage extends StatefulWidget { @override _EGFRPageState createState() => _EGFRPageState(); }
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
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("eGFR")), body: Padding(padding: EdgeInsets.all(20), child: Column(children: [
    TextField(controller: cCtrl, decoration: InputDecoration(labelText: "Creatinine (mg/dL)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    SizedBox(height: 15),
    TextField(controller: aCtrl, decoration: InputDecoration(labelText: "Age", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    SizedBox(height: 20),
    ElevatedButton(onPressed: calc, child: Text("Calculate"), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
    if (res.isNotEmpty) ...[
      SizedBox(height: 20),
      Text(res, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal)),
      Text(stat),
      SizedBox(height: 10),
      ElevatedButton(onPressed: () {
        DatabaseHelper.instance.saveRecord("eGFR", res, stat);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("eGFR Record Saved!")));
      }, child: Text("Save Record"))
    ]
  ])));
}

class BMIPage extends StatefulWidget { @override _BMIPageState createState() => _BMIPageState(); }
class _BMIPageState extends State<BMIPage> {
  final hCtrl = TextEditingController(), wCtrl = TextEditingController(); String res = "", stat = "";
  void calc() {
    double h = double.tryParse(hCtrl.text) ?? 0, w = double.tryParse(wCtrl.text) ?? 0;
    if (h > 0 && w > 0) {
      double val = w / ((h / 100) * (h / 100));
      setState(() { res = val.toStringAsFixed(1); stat = val < 25 ? "Normal" : val < 30 ? "Overweight" : "Obese"; });
    }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("BMI")), body: Padding(padding: EdgeInsets.all(20), child: Column(children: [
    TextField(controller: hCtrl, decoration: InputDecoration(labelText: "Height (cm)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    SizedBox(height: 15),
    TextField(controller: wCtrl, decoration: InputDecoration(labelText: "Weight (kg)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    SizedBox(height: 20),
    ElevatedButton(onPressed: calc, child: Text("Calculate"), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
    if (res.isNotEmpty) ...[
      SizedBox(height: 20),
      Text(res, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal)),
      Text(stat),
      SizedBox(height: 10),
      ElevatedButton(onPressed: () {
        DatabaseHelper.instance.saveRecord("BMI", res, stat);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("BMI Record Saved!")));
      }, child: Text("Save Record"))
    ]
  ])));
}

class BPPage extends StatefulWidget { @override _BPPageState createState() => _BPPageState(); }
class _BPPageState extends State<BPPage> {
  final sCtrl = TextEditingController(), dCtrl = TextEditingController(); String res = "", stat = "";
  void calc() {
    int s = int.tryParse(sCtrl.text) ?? 0, d = int.tryParse(dCtrl.text) ?? 0;
    if (s > 0 && d > 0) {
      setState(() { res = "$s/$d"; stat = (s <= 120 && d <= 80) ? "Normal" : "High Blood Pressure"; });
    }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("Blood Pressure")), body: Padding(padding: EdgeInsets.all(20), child: Column(children: [
    TextField(controller: sCtrl, decoration: InputDecoration(labelText: "Systolic (mmHg)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    SizedBox(height: 15),
    TextField(controller: dCtrl, decoration: InputDecoration(labelText: "Diastolic (mmHg)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    SizedBox(height: 20),
    ElevatedButton(onPressed: calc, child: Text("Analyze"), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
    if (res.isNotEmpty) ...[
      SizedBox(height: 20),
      Text(res, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal)),
      Text(stat),
      SizedBox(height: 10),
      ElevatedButton(onPressed: () {
        DatabaseHelper.instance.saveRecord("BP", res, stat);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Blood Pressure Saved!")));
      }, child: Text("Save Record"))
    ]
  ])));
}

class GlucosePage extends StatefulWidget { @override _GlucosePageState createState() => _GlucosePageState(); }
class _GlucosePageState extends State<GlucosePage> {
  final gCtrl = TextEditingController();
  bool isFasting = true; // Restored Fasting Option
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
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("Blood Glucose")), body: Padding(padding: EdgeInsets.all(20), child: Column(children: [
    SwitchListTile(
      title: Text(isFasting ? "Fasting" : "Random / After Meal"),
      value: isFasting,
      onChanged: (val) => setState(() => isFasting = val),
      activeColor: Colors.teal,
    ),
    TextField(controller: gCtrl, decoration: InputDecoration(labelText: "Glucose Level (mg/dL)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
    SizedBox(height: 20),
    ElevatedButton(onPressed: calc, child: Text("Analyze"), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
    if (res.isNotEmpty) ...[
      SizedBox(height: 20),
      Text(res, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal)),
      Text(stat),
      SizedBox(height: 10),
      ElevatedButton(onPressed: () {
        DatabaseHelper.instance.saveRecord("Glucose", res, stat);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Glucose Record Saved!")));
      }, child: Text("Save Record"))
    ]
  ])));
}

// --- HISTORY & TRENDS ---
class HistoryPage extends StatelessWidget {
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("History"), actions: [IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: () async => _pdf(await DatabaseHelper.instance.fetchRecords()))]),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: DatabaseHelper.instance.fetchRecords(), builder: (c, snap) {
      if (!snap.hasData) return Center(child: CircularProgressIndicator());
      final data = snap.data!;
      if (data.isEmpty) return Center(child: Text("No records found."));
      return Column(children: [
        Padding(padding: EdgeInsets.all(10), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ["BMI", "BP", "Glucose", "eGFR"].map((t) => Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChartPage(type: t, data: data))), child: Text(t)))).toList()))),
        Expanded(child: ListView.builder(itemCount: data.length, itemBuilder: (c, i) {
          final item = data[data.length - 1 - i];
          return ListTile(title: Text("${item['type']}: ${item['val']}"), subtitle: Text("${item['status']}\n${item['date']} at ${item['timestamp']}"));
        })),
      ]);
    }),
  );
  void _pdf(data) async {
    final doc = pw.Document(); doc.addPage(pw.Page(build: (c) => pw.Table.fromTextArray(data: [['Date', 'Time', 'Type', 'Value', 'Status'], ...data.map((e) => [e['date'], e['timestamp'] ?? '', e['type'], e['val'], e['status']])])));
    await Printing.layoutPdf(onLayout: (f) async => doc.save());
  }
}

class ChartPage extends StatelessWidget {
  final String type; final List<Map<String, dynamic>> data;
  ChartPage({required this.type, required this.data});
  @override Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    final filtered = data.where((e) => e['type'] == type).toList();
    for (int i = 0; i < filtered.length; i++) {
      double v = 0;
      if (type == "BP") { v = double.tryParse(filtered[i]['val'].split('/')[0]) ?? 0; }
      else { v = double.tryParse(filtered[i]['val']) ?? 0; }
      spots.add(FlSpot(i.toDouble(), v));
    }
    return Scaffold(appBar: AppBar(title: Text("$type Trend")), body: Padding(padding: EdgeInsets.all(20), child: spots.isEmpty ? Center(child: Text("Not enough data for chart")) : LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Colors.teal, barWidth: 4)]))));
  }
}