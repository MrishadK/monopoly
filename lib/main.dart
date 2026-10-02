import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/theme_provider.dart';
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('DotEnv load failed: $e');
  }

  try {
    await Firebase.initializeApp();
    if (!kIsWeb) {
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('MobileAds init failed: $e');
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }



  runApp(
    const ProviderScope(
      child: KuthakaApp(),
    ),
  );
}

class KuthakaApp extends ConsumerWidget {
  const KuthakaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Kuthaka: A Kerala Game',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: KuthakaTheme.lightTheme(),
      darkTheme: KuthakaTheme.darkTheme(),
      home: const HomeScreen(),
    );
  }
}
