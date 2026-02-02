import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/search_screen.dart';
import 'screens/home/notification_screen.dart';
import 'screens/item/add_item_screen.dart';
import 'screens/item/item_detail_screen.dart';
import 'screens/item/item_list_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/about/about_screen.dart';
import 'utils/firebase_test.dart';
import 'utils/firebase_debug.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Test Firebase connection
    await FirebaseTestUtil.printConnectionStatus();
    // Debug Firebase data
    await FirebaseDebugUtil.debugFirebaseConnection();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lost & Found',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case AppRoutes.register:
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case AppRoutes.search:
            return MaterialPageRoute(builder: (_) => const SearchScreen());
          case AppRoutes.notifications:
            return MaterialPageRoute(
              builder: (_) => const NotificationScreen(),
            );
          case AppRoutes.addItem:
            return MaterialPageRoute(builder: (_) => const AddItemScreen());
          case AppRoutes.itemDetail:
            final itemId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => ItemDetailScreen(itemId: itemId),
            );
          case AppRoutes.itemList:
            return MaterialPageRoute(builder: (_) => const ItemListScreen());
          case AppRoutes.profile:
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case AppRoutes.editProfile:
            return MaterialPageRoute(builder: (_) => const EditProfileScreen());
          case AppRoutes.about:
            return MaterialPageRoute(builder: (_) => const AboutScreen());
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
