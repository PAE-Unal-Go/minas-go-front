import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/login/presentation/screens/login_view.dart';




// const supabaseUrl = 'https://minas-go.supabase.co';
// const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

const supabaseUrl = 'https://rsihncxomdrdjiykbcks.supabase.co';
const supabaseAnonKey = 'sb_publishable_eaSxWxsR-YJz72TF6JD1BA_S2Hhvt5Z';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const LoginView(),
    );
  }
}
