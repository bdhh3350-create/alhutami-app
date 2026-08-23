import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'video_splash_screen.dart';

// معالجة الإشعارات في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// كلاس مخصص لإرسال الإشعارات التلقائية لجميع الهواتف عبر Firebase Cloud Messaging V1 API
class FcmSenderService {
  static Future<void> sendBroadcastNotification({
    required String title,
    required String body,
  }) async {
    try {
      final jsonString = await rootBundle.loadString('assets/service_account.json');
      final serviceAccountJson = jsonDecode(jsonString);
      
      final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final projectId = serviceAccountJson['project_id'] ?? 'alhutami-app';
      
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');
      
      final messagePayload = {
        'message': {
          'topic': 'all',
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'channel_id': 'high_importance_channel',
            }
          }
        }
      };

      await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(messagePayload),
      );

      client.close();
    } catch (e) {
      debugPrint("Error sending FCM notification: $e");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await messaging.subscribeToTopic('all');
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(const HutamiApp());
}

class HutamiApp extends StatefulWidget {
  const HutamiApp({super.key});

  @override
  State<HutamiApp> createState() => _HutamiAppState();
}

class _HutamiAppState extends State<HutamiApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        debugPrint("Notification: ${message.notification?.title}");
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (context) => const VideoSplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'الحطامي للإلكترونيات',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFF00ACC1),
          surface: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      home: const VideoSplashScreen(),
    );
  }
}

// ------------------- الواجهة الرئيسية (HomeScreen) -------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeTab(),
    ProductsTab(),
    ServicesTab(),
    TrackingTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF0D47A1),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt, color: Colors.cyanAccent, size: 24),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الحطامي للإلكترونيات',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'صيانة • قطع غيار • برمجيات',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لا توجد تنبيهات جديدة')),
                );
              },
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: _pages[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF0D47A1).withOpacity(0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF0D47A1)),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag, color: Color(0xFF0D47A1)),
              label: 'القطع والمنتجات',
            ),
            NavigationDestination(
              icon: Icon(Icons.miscellaneous_services_outlined),
              selectedIcon: Icon(Icons.miscellaneous_services, color: Color(0xFF0D47A1)),
              label: 'خدماتنا',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: Color(0xFF0D47A1)),
              label: 'استعلام صيانة',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF25D366),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('محادثة خدمة العملاء عبر واتساب')),
            );
          },
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
    );
  }
}

// ------------------- 1. تبويب الرئيسية (Home Tab) -------------------
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن شاشة، قطعة غيار، أو خدمة صيانة...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                icon: Icon(Icons.search, color: Color(0xFF0D47A1)),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('عرض خاص ⚡', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.verified, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'شاشات سامسونج وآيفون وكالة',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'متوفر شاشات أصلية مع الضمان وخدمة التركيب الفوري في المركز.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('الوصول السريع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickBtn(context, Icons.phone_android, 'شاشات أصلية', const Color(0xFF0288D1)),
              _buildQuickBtn(context, Icons.developer_mode, 'فك شفرات FRP', const Color(0xFF6A1B9A)),
              _buildQuickBtn(context, Icons.battery_charging_full, 'بطاريات وكالة', const Color(0xFF2E7D32)),
              _buildQuickBtn(context, Icons.headset_mic, 'طلب صيانة', const Color(0xFFE65100)),
            ],
          ),
          const SizedBox(height: 25),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('أقسام المركز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
              Text('عرض الكل', style: TextStyle(fontSize: 13, color: Color(0xFF0D47A1), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            Icons.memory,
            'قسم البرمجة والسوفتوير',
            'تفليش رسمي، تخطي حسابات Google FRP، فك الشفرات، إصلاح أخطاء النظام والشبكات.',
            Colors.blue.shade900,
          ),
          _buildFeatureCard(
            Icons.build_circle,
            'قسم صيانة الهاردوير',
            'تبديل شاشات أصلية، إصلاح آيسيات الباور والشحن، معالجة أجهزة السوائل والأعطال الدقيقة.',
            Colors.teal.shade800,
          ),
          _buildFeatureCard(
            Icons.storefront,
            'بيع قطع الغيار (جملة وتجزئة)',
            'توفير شاشات، فلاتات، بطاريات، وكابلات الصيانة لمهندسي ومحلات الإلكترونيات.',
            Colors.indigo.shade800,
          ),
        ],
      ),
    );
  }

  static Widget _buildQuickBtn(BuildContext context, IconData icon, String title, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFeatureCard(IconData icon, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF263238))),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------- 2. تبويب القطع والمنتجات (قاعدة البيانات المباشرة) -------------------
class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  int _selectedCategory = 0;
  final List<String> _categories = ['الكل', 'شاشات سامسونج', 'شاشات آيفون', 'بطاريات', 'أدوات صيانة', 'إكسسوارات'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 55,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedCategory == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(_categories[index]),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0D47A1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (val) {
                    setState(() {
                      _selectedCategory = index;
                    });
                  },
                ),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('حدث خطأ في جلب المنتجات'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              final filteredDocs = _selectedCategory == 0
                  ? docs
                  : docs.where((d) => (d.data() as Map<String, dynamic>)['category'] == _categories[_selectedCategory]).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      const Text('لا توجد منتجات متوفرة حالياً في هذا القسم', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.76,
                ),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final data = filteredDocs[index].data() as Map<String, dynamic>;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            ),
                            child: Center(
                              child: Icon(Icons.phone_android_rounded, size: 55, color: Colors.blue.shade700),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00ACC1).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(data['tag'] ?? 'متوفر', style: const TextStyle(fontSize: 10, color: Color(0xFF00838F), fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data['name'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(data['price'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                                  InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('طلب ${data['name']}')),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D47A1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ------------------- 3. تبويب الخدمات والبرمجة (Services Tab) -------------------
class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('خدمات البرمجيات والأنظمة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
        const SizedBox(height: 10),
        _buildServiceTile(Icons.lock_open, 'تخطي حسابات جوجل (FRP)', 'فك قفل الحساب لجميع أجهزة سامسونج، شاومي، هواوي بأحدث الحمايات.'),
        _buildServiceTile(Icons.system_update_alt, 'تفليش وتعريب الهواتف', 'تثبيت الرومات الرسمية والمعدلة وحل مشاكل الوقوف على الشعار والريستارت.'),
        _buildServiceTile(Icons.sim_card_download, 'فك الشفرات وتفعيل 4G / 5G', 'تشغيل كافة الشرائح المحلية والدولية وضبط إعدادات التغطية فورياً.'),
        const SizedBox(height: 20),

        const Text('خدمات الصيانة والهاردوير', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
        const SizedBox(height: 10),
        _buildServiceTile(Icons.screen_rotation, 'تبديل الشاشات والزجاج الخارجي', 'تبديل باغة وحماية الشاشة الأصلية باستخدام أحدث أجهزة الكبس الحراري.'),
        _buildServiceTile(Icons.power, 'إصلاح دوائر الشحن والباور', 'فحص المخططات وتبديل آيسيات الشحن والدوائر التالفة بضمان معتمد.'),
        _buildServiceTile(Icons.water_drop_outlined, 'معالجة الأجهزة الساقطة بالماء', 'تنظيف فائق بالموجات فوق الصوتية وإعادة إحياء المسارات المتآكلة.'),
      ],
    );
  }

  static Widget _buildServiceTile(IconData icon, String title, String desc) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF0D47A1)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}

// ------------------- 4. تبويب الاستعلام عن الصيانة (Tracking Tab) -------------------
class TrackingTab extends StatefulWidget {
  const TrackingTab({super.key});

  @override
  State<TrackingTab> createState() => _TrackingTabState();
}

class _TrackingTabState extends State<TrackingTab> {
  final TextEditingController _codeController = TextEditingController();
  Map<String, dynamic>? _ticketData;
  bool _loading = false;
  bool _notFound = false;

  void _searchTicket() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _notFound = false;
      _ticketData = null;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('repairs').doc(code).get();
      if (doc.exists) {
        setState(() {
          _ticketData = doc.data();
          _loading = false;
        });
      } else {
        setState(() {
          _notFound = true;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.receipt_long, size: 55, color: Color(0xFF0D47A1)),
                const SizedBox(height: 12),
                const Text('متابعة حالة إصلاح جهازك', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'أدخل رقم كرت الاستلام لمتابعة مرحلة الصيانة لحظة بلحظة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'مثال: 10452',
                    prefixIcon: const Icon(Icons.tag),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _searchTicket,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('استعلام عن الحالة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_ticketData != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.green.shade600, child: const Icon(Icons.check, color: Colors.white)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('حالة الجهاز: ${_ticketData!['status'] ?? 'قيد الصيانة'}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                            Text('الجهاز: ${_ticketData!['device'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_ticketData!['notes'] != null && _ticketData!['notes'] != '') ...[
                    const Divider(height: 20),
                    Text('ملاحظات الفني: ${_ticketData!['notes']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ],
              ),
            ),

          if (_notFound)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 10),
                  Text('لم يتم العثور على جهاز بهذا الرقم، يرجى التأكد.', style: TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------- 5. لوحة تحكم المشرف مع الإشعارات التلقائية -------------------
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _prodNameCtrl = TextEditingController();
  final _prodPriceCtrl = TextEditingController();
  final _prodTagCtrl = TextEditingController(text: 'وكالة');
  String _selectedProdCat = 'شاشات سامسونج';

  final _repairTicketCtrl = TextEditingController();
  final _repairDeviceCtrl = TextEditingController();
  final _repairNotesCtrl = TextEditingController();
  String _selectedRepairStatus = 'جاهز للاستلام ✅';

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // إضافة منتج جديد + إرسال إشعار فوري لجميع الزبائن
  void _addProduct() async {
    final name = _prodNameCtrl.text.trim();
    final price = _prodPriceCtrl.text.trim();
    final tag = _prodTagCtrl.text.trim();

    if (name.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء اسم القطعة والسعر')));
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. حفظ في قاعدة بيانات Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'price': price,
        'category': _selectedProdCat,
        'tag': tag,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. إرسال إشعار فوري لجميع الهواتف
      await FcmSenderService.sendBroadcastNotification(
        title: 'مركز الحطامي للإلكترونيات ⚡',
        body: 'تم توفير: $name بسعر $price في قسم $_selectedProdCat!',
      );

      _prodNameCtrl.clear();
      _prodPriceCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة القطعة وبث الإشعار لجميع الزبائن بنجاح! 🔔')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // تحديث كرت صيانة + إرسال إشعار تلقائي
  void _saveRepairTicket() async {
    final ticketNo = _repairTicketCtrl.text.trim();
    final device = _repairDeviceCtrl.text.trim();
    final notes = _repairNotesCtrl.text.trim();

    if (ticketNo.isEmpty || device.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال رقم الكرت ونوع الجهاز')));
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. حفظ في Firestore
      await FirebaseFirestore.instance.collection('repairs').doc(ticketNo).set({
        'ticketNumber': ticketNo,
        'device': device,
        'status': _selectedRepairStatus,
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. إرسال إشعار
      await FcmSenderService.sendBroadcastNotification(
        title: 'تحديث حالة الصيانة - الحطامي 📱',
        body: 'الكرت ($ticketNo - $device): $_selectedRepairStatus',
      );

      _repairTicketCtrl.clear();
      _repairDeviceCtrl.clear();
      _repairNotesCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث كرت الصيانة وبث الإشعار بنجاح! ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.redAccent.shade700,
          title: const Text('لوحة إدارة المشرف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.add_shopping_cart), text: 'إدارة المنتجات'),
              Tab(icon: Icon(Icons.build), text: 'إدارة كروت الصيانة'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // تبويب 1: إضافة المنتجات
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إضافة قطعة غيار (مع بث إشعار فوري للجميع)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _prodNameCtrl,
                            decoration: const InputDecoration(labelText: 'اسم القطعة (مثال: شاشة Samsung S21 Ultra)', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _prodPriceCtrl,
                                  decoration: const InputDecoration(labelText: 'السعر (مثال: 90\$)', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _prodTagCtrl,
                                  decoration: const InputDecoration(labelText: 'الحالة (مثال: وكالة)', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedProdCat,
                            decoration: const InputDecoration(labelText: 'القسم', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'شاشات سامسونج', child: Text('شاشات سامسونج')),
                              DropdownMenuItem(value: 'شاشات آيفون', child: Text('شاشات آيفون')),
                              DropdownMenuItem(value: 'بطاريات', child: Text('بطاريات')),
                              DropdownMenuItem(value: 'أدوات صيانة', child: Text('أدوات صيانة')),
                              DropdownMenuItem(value: 'إكسسوارات', child: Text('إكسسوارات')),
                            ],
                            onChanged: (val) => setState(() => _selectedProdCat = val!),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
                              onPressed: _isSending ? null : _addProduct,
                              icon: _isSending
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.send_rounded, color: Colors.white),
                              label: const Text('إضافة وبث الإشعار فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('المنتجات المضافة حالياً (اضغط لحذف أي منتج):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snap.data!.docs;
                      if (docs.isEmpty) return const Text('لا توجد منتجات مضافة بعد.');
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, idx) {
                          final p = docs[idx].data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.shopping_bag, color: Color(0xFF0D47A1)),
                              title: Text(p['name'] ?? ''),
                              subtitle: Text('${p['category']} | ${p['price']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => docs[idx].reference.delete(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // تبويب 2: إدارة الصيانة
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تحديث صيانة جهاز (مع بث إشعار للعميل)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _repairTicketCtrl,
                        decoration: const InputDecoration(labelText: 'رقم كرت الصيانة (مثال: 10452)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _repairDeviceCtrl,
                        decoration: const InputDecoration(labelText: 'نوع الجهاز (مثال: Galaxy S22 Ultra)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedRepairStatus,
                        decoration: const InputDecoration(labelText: 'حالة الصيانة الحالية', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'قيد الفحص والكشف 🔍', child: Text('قيد الفحص والكشف 🔍')),
                          DropdownMenuItem(value: 'جاري العمل والصيانة ⚙️', child: Text('جاري العمل والصيانة ⚙️')),
                          DropdownMenuItem(value: 'جاهز للاستلام ✅', child: Text('جاهز للاستلام ✅')),
                          DropdownMenuItem(value: 'تعذر الإصلاح ❌', child: Text('تعذر الإصلاح ❌')),
                        ],
                        onChanged: (val) => setState(() => _selectedRepairStatus = val!),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _repairNotesCtrl,
                        decoration: const InputDecoration(labelText: 'ملاحظات إضافية للعميل (اختياري)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                          onPressed: _isSending ? null : _saveRepairTicket,
                          icon: _isSending
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check, color: Colors.white),
                          label: const Text('حفظ وبث الإشعار فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- القائمة الجانبية (App Drawer) -------------------
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('رمز دخول المشرف'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'أدخل الرمز السري',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
              onPressed: () {
                if (pinController.text.trim() == '7777') {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرمز السري غير صحيح!')),
                  );
                }
              },
              child: const Text('دخول', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.store, color: Color(0xFF0D47A1), size: 36),
            ),
            accountName: const Text('مركز الحطامي للإلكترونيات', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text('خدمات الهواتف والبرمجيات المتطورة'),
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Color(0xFF0D47A1)),
            title: const Text('اتصل بالمركز مباشرة'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Color(0xFF0D47A1)),
            title: const Text('موقعنا على الخريطة'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.security, color: Color(0xFF0D47A1)),
            title: const Text('سياسة الضمان والاستبدال'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.redAccent),
            title: const Text('لوحة الإدارة (للمشرف فقط)'),
            onTap: () {
              Navigator.pop(context);
              _showPinDialog(context);
            },
          ),
        ],
      ),
    );
  }
}
