import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'video_splash_screen.dart'; // استدعاء شاشة الفيديو الترحيبية

// دالة التعامل مع الإشعارات والتطبيق مغلق تماماً أو في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة فايربيس واستقبال الإشعارات
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    // طلب إذن الإشعارات لأجهزة Android 13 فما فوق
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // الاشتراك التلقائي في قناة الإشعارات العامة لضمان وصول الرسائل للجميع
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
  // مفتاح للتحكم في التنقل بين الشاشات حتى عند عودة التطبيق من الخلفية
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // الاستماع للإشعارات أثناء تشغيل التطبيق في الواجهة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        debugPrint('Title: ${message.notification?.title}');
        debugPrint('Body: ${message.notification?.body}');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // مراقبة التطبيق: فور فتح التطبيق أو العودة إليه من الخلفية، يعاد تشغيل الفيديو
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
        ),
      ),
      // تشغيل شاشة الفيديو كأول واجهة
      home: const VideoSplashScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D47A1),
          title: const Text(
            'مركز الحطامي للإلكترونيات',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 4,
                color: const Color(0xFF0D47A1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.developer_board, size: 60, color: Colors.cyanAccent),
                      SizedBox(height: 10),
                      Text(
                        'مرحباً بك في مركز الحطامي',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'خدمات صيانة الهواتف الذكية وتفليش وفك الشفرات',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'الخدمات المتاحة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              // Service List
              _buildServiceCard(
                Icons.system_update,
                'برمجة وسوفتوير',
                'تفليش، تعريب، إصلاح الإيميل، وفك الحسابات (FRP).',
              ),
              _buildServiceCard(
                Icons.build_circle_outlined,
                'صيانة هاردوير',
                'تبديل الشاشات، إصلاح دوائر الشحن والباور والمعالجات.',
              ),
              _buildServiceCard(
                Icons.sim_card,
                'فك الشفرات وتفعيل الشبكات',
                'تشغيل الشرائح وفك تشفير الهواتف الموجهة.',
              ),
              _buildServiceCard(
                Icons.screen_search_desktop,
                'استعلام عن جهاز',
                'متابعة حالة إصلاح جهازك في المركز.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(IconData icon, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00ACC1),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
