import 'package:flutter/material.dart';

import 'config/supabase_config.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.ensureInitialized();
  runApp(const NovitierraApp());
}

class NovitierraApp extends StatelessWidget {
  const NovitierraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novitierra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
