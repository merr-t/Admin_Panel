import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const MaterialApp(title: "Admin Panel",debugShowCheckedModeBanner: false, home: AuthCheckScreen()) );

// ===================================
// 1. OTURUM KONTROLÜ
// ===================================
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});
  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final nextScreen = (prefs.getBool('isLoggedIn') ?? false) ? const ControlPanelScreen() : const LoginScreen();
    // AuthCheckScreen'in context'i mounted iken Navigation yapılır
    if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => nextScreen));
  }git init

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

// ===================================
// 2. GİRİŞ EKRANI
// ===================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    if (_usernameController.text == 'Admin' && _passwordController.text == 'Admin123') {
      await SharedPreferences.getInstance().then((prefs) => prefs.setBool('isLoggedIn', true));
      // ignore: use_build_context_synchronously
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const ControlPanelScreen()));
      }
    } else {
      // ignore: use_build_context_synchronously
      if (mounted) {
        showDialog(context: context, builder: (context) => AlertDialog(
          title: const Text('Hata!'), content: const Text('Kullanıcı adı veya parola yanlış.'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tamam'))],
        ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(centerTitle: true, backgroundColor: Colors.grey, title: const Text('Giriş Ekranı', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 150.0,
                backgroundImage: AssetImage('images/Logo.2.png'),
                backgroundColor: Colors.white,
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 30.0), child: TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Kullanıcı Adı', border: OutlineInputBorder()))),
              const SizedBox(height: 20),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 30.0), child: TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Parola', border: OutlineInputBorder()))),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _login, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)), child: const Text('Giriş Yap')),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================================
// 3. KONTROL PANELİ (ANA EKRAN)
// ===================================
class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({super.key});
  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> {
  int _selectedIndex = 0;
  final List<String> _days = const ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'];
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _authorController = TextEditingController(text: 'Müdür');

  Map<String, Map<String, List<String>>> _guardSchedule = {};
  List<Map<String, String>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _announcementController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  // --- VERİ YÖNETİM METOTLARI ---
  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Nöbetçi yükle
    String? jsonGuard = prefs.getString('guardScheduleJson');
    if (jsonGuard != null) {
      try {
        final decodedData = json.decode(jsonGuard) as Map<String, dynamic>;
        _guardSchedule = decodedData.map((key, value) => MapEntry(key, {
          'Ogretmen': (value['Ogretmen'] as List?)?.cast<String>() ?? [],
          'Ogrenci': (value['Ogrenci'] as List?)?.cast<String>() ?? [],
        }));
      } catch (e) {
        debugPrint('Nöbetçi yükleme hatası: $e');
      }
    } else {
      // Başlangıç verisi
      _guardSchedule = {
        'Pazartesi': {'Ogretmen': ['Öğr. A'], 'Ogrenci': ['Öğr. 1']},
        'Salı': {'Ogretmen': ['Öğr. B'], 'Ogrenci': ['Öğr. 2']},
        'Çarşamba': {'Ogretmen': ['Öğr. C'], 'Ogrenci': ['Öğr. 3']},
        'Perşembe': {'Ogretmen': ['Öğr. D'], 'Ogrenci': ['Öğr. 4']},
        'Cuma': {'Ogretmen': ['Öğr. E'], 'Ogrenci': ['Öğr. 5']},
      };
    }

    // Duyuru yükle
    String? jsonAnnouncements = prefs.getString('announcementsJson');
    if (jsonAnnouncements != null) {
      try {
        _announcements = (json.decode(jsonAnnouncements) as List).map((item) => Map<String, String>.from(item)).toList();
      } catch (e) {
        debugPrint('Duyuru yükleme hatası: $e');
      }
    }
    setState(() {});
  }

  void _saveAnnouncements() async {
    await SharedPreferences.getInstance().then((prefs) => prefs.setString('announcementsJson', json.encode(_announcements)));
  }

  void _saveGuardSchedule() async {
    await SharedPreferences.getInstance().then((prefs) => prefs.setString('guardScheduleJson', json.encode(_guardSchedule)));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Nöbetçi Programı Başarıyla Kaydedildi!')));
  }

  void _logout() async {
    await SharedPreferences.getInstance().then((prefs) => prefs.setBool('isLoggedIn', false));
    if (mounted) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
    }
  }

  // --- NÖBETÇİ METOTLARI (GÜNCELLENMİŞ) ---
  void _editGuardSchedule() async {
    final Map<String, Map<String, List<String>>>? newSchedule = await showDialog<Map<String, Map<String, List<String>>>>(
      context: context,
      // Yeni diyalog widget'ı çağrılıyor
      builder: (context) => _GuardScheduleEditDialog(initialSchedule: _guardSchedule, days: _days),
    );

    if (newSchedule != null) {
      setState(() => _guardSchedule = newSchedule);
      _saveGuardSchedule();
    }
  }

  // --- DUYURU METOTLARI ---
  void _publishAnnouncement() {
    final content = _announcementController.text.trim();
    final author = _authorController.text.trim().isEmpty ? 'Bilinmiyor' : _authorController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen yayınlamak istediğiniz duyuruyu girin!')));
      return;
    }

    _announcements.insert(0, {'content': content, 'author': author});
    _announcementController.clear();

    setState(() {}); // Anında güncelleme
    _saveAnnouncements();

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Yeni Duyuru Başarıyla Yayınlandı!')));
  }

  void _deleteAnnouncement(int index) {
    _announcements.removeAt(index);

    setState(() {}); // Anında güncelleme
    _saveAnnouncements();

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Duyuru başarıyla silindi.')));
  }

  // --- WIDGET YAPILARI (HATA VEREN METOTLAR) ---
  Widget _buildGuardTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(2.7)},
      children: [
        // Başlık Satırı
        TableRow(decoration: BoxDecoration(color: Colors.grey.shade200), children: const [
          TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('GÜN', style: TextStyle(fontWeight: FontWeight.bold))))),
          TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('ÖĞRETMEN', style: TextStyle(fontWeight: FontWeight.bold))))),
          TableCell(child: Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('ÖĞRENCİ', style: TextStyle(fontWeight: FontWeight.bold))))),
        ]),
        // Veri Satırları (Günler alt alta)
        ..._guardSchedule.entries.map((entry) {
          // Öğretmen ve öğrenci isimleri satır sonu ile birleştirilir.
          final teachers = entry.value['Ogretmen']?.join('\n') ?? '';
          final students = entry.value['Ogrenci']?.join('\n') ?? '';
          return TableRow(children: [
            TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(entry.key, style: const TextStyle(fontSize: 12)))),
            // maxLines: null ile birden fazla satır gösterilir
            TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(teachers, style: const TextStyle(fontSize: 12), maxLines: null,))),
            TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(students, style: const TextStyle(fontSize: 12), maxLines: null,))),
          ]);
        }),
      ],
    );
  }

  Widget _buildGuardScheduleTab() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _editGuardSchedule,
              icon: const Icon(Icons.edit_calendar),
              label: const Text('NÖBETÇİ PROGRAMINI DÜZENLE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade100,
                foregroundColor: Colors.orange.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),
            const Text('🗓️ HAFTALIK NÖBETÇİ LİSTESİ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildGuardTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, String> announcement, int index) {
    return Card(
      elevation: 2, margin: const EdgeInsets.only(bottom: 15.0), color: Colors.blue.shade50,
      child: Padding(padding: const EdgeInsets.fromLTRB(15, 15, 5, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(announcement['content']!, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(announcement['author']!, style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
          IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _deleteAnnouncement(index), tooltip: 'Duyuruyu Sil'),
        ]),
      ])),
    );
  }

  Widget _buildAnnouncementTab() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // YENİ DUYURU YAYIMLAMA ALANI
            const Text('📢 Yeni Duyuru Yayınla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Padding(padding: const EdgeInsets.only(bottom: 10.0), child: TextField(controller: _authorController, decoration: const InputDecoration(labelText: 'Yazar Adı', border: OutlineInputBorder(), isDense: true))),
            TextField(controller: _announcementController, maxLines: 5, decoration: const InputDecoration(hintText: 'Yeni idari duyurunuzu buraya yazın...', border: OutlineInputBorder(), fillColor: Colors.white, filled: true)),
            const SizedBox(height: 15),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _publishAnnouncement, icon: const Icon(Icons.send), label: const Text('YAYINLA', style: TextStyle(fontSize: 16)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15)))),

            const SizedBox(height: 30),

            // YAYINLANMIŞ DUYURULAR LİSTESİ
            const Text('📌 YAYINLANMIŞ DUYURULAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 10),

            if (_announcements.isEmpty)
              Container(width: double.infinity, padding: const EdgeInsets.all(15.0), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.white), child: const Text('Henüz yayınlanmış bir idari duyuru yok.', style: TextStyle(fontStyle: FontStyle.italic)))
            else
              ..._announcements.asMap().entries.map((entry) => _buildAnnouncementCard(entry.value, entry.key)),
          ],
        ),
      ),
    );
  }

  // --- ANA BİLDİRİM WIDGET'I ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(_selectedIndex == 0 ? 'NÖBETÇİ YÖNETİMİ' : 'DUYURU YÖNETİMİ', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey,
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Oturumu Kapat')],
      ),
      body: Center(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildGuardScheduleTab(),
            _buildAnnouncementTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Nöbetçi'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Duyuru'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

// ===================================
// 4. NÖBETÇİ DÜZENLEME DİYALOĞU (YENİ EK)
// ===================================
class _GuardScheduleEditDialog extends StatefulWidget {
  final Map<String, Map<String, List<String>>> initialSchedule;
  final List<String> days;

  const _GuardScheduleEditDialog({required this.initialSchedule, required this.days});

  @override
  State<_GuardScheduleEditDialog> createState() => _GuardScheduleEditDialogState();
}

class _GuardScheduleEditDialogState extends State<_GuardScheduleEditDialog> {
  // Düzenleme sırasında kullanılacak Controller'lar
  late final Map<String, List<TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (var day in widget.days) {
      // Değişiklik: Listeleri SATIR SONU (\n) ile birleştirerek TextController'a yüklüyoruz.
      _controllers[day] = [
        TextEditingController(text: widget.initialSchedule[day]?['Ogretmen']?.join('\n') ?? ''),
        TextEditingController(text: widget.initialSchedule[day]?['Ogrenci']?.join('\n') ?? ''),
      ];
    }
  }

  @override
  void dispose() {
    // Controller'lar diyaloğun kapanmasıyla temizlenir (ÇÖKME ÖNLENİR)
    for (var list in _controllers.values) {
      for (var controller in list) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _saveSchedule() {
    Map<String, Map<String, List<String>>> newSchedule = {};
    for (var day in widget.days) {
      // Değişiklik: Metni SATIR SONUNA (\n) göre ayırıyoruz.
      // trim() ve where((s) => s.isNotEmpty) ile boş satırlar ve boşluklar temizlenir.
      newSchedule[day] = {
        'Ogretmen': _controllers[day]![0].text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'Ogrenci': _controllers[day]![1].text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      };
    }
    // Yeni çizelgeyi döndürerek diyaloğu kapat
    Navigator.of(context).pop(newSchedule);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nöbetçi Programını Manuel Düzenle'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
              children: widget.days.map((day) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      // Çok satırlı giriş için ayarlar
                      TextField(
                        controller: _controllers[day]![0],
                        keyboardType: TextInputType.multiline,
                        maxLines: null, // Birden fazla satır desteği (Alt alta yazma)
                        decoration: const InputDecoration(labelText: 'Öğretmenler (Alt alta yazın)', border: OutlineInputBorder(borderSide: BorderSide(width: 0.5)), isDense: true),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _controllers[day]![1],
                        keyboardType: TextInputType.multiline,
                        maxLines: null, // Birden fazla satır desteği (Alt alta yazma)
                        decoration: const InputDecoration(labelText: 'Öğrenciler (Alt alta yazın)', border: OutlineInputBorder(borderSide: BorderSide(width: 0.5)), isDense: true),
                      ),
                    ],
                  )),
              ).toList()),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('İptal')),
        ElevatedButton(onPressed: _saveSchedule, child: const Text('Kaydet')),
      ],
    );
  }
}