import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Pre-load fonts before first frame to prevent flash of unstyled text.
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.reemKufi(),
      GoogleFonts.ibmPlexSansArabic(),
    ]);
  } catch (_) {
    // No internet on first launch — system fallback will be used.
  }

  runApp(
    const ProviderScope(
      child: ShajarahApp(),
    ),
  );
}
