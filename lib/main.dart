import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ui/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://nudbsagwyhaslaajwvoh.supabase.co',
    publishableKey: 'sb_publishable_DRoKSQBEUW4c4DiTiVAeYw_kw09KLl0',
  );

  runApp(
    const ProviderScope(
      child: KuthakaApp(),
    ),
  );
}

class KuthakaApp extends StatelessWidget {
  const KuthakaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuthaka: A Kerala Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF00695C), // Kerala Green
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const HomeScreen(),
    );
  }
}
