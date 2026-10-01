import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/canciones_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cjlhesdgeqovkmlemwzr.supabase.co',
    publishableKey: 'sb_publishable_mNB8gIs6PEALy0O1-xvhkg_uTnzQkBL',
  );

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CancionesScreen(),
    ),
  );
}