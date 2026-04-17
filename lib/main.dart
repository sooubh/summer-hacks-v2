import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/app/student_fin_os_app.dart';
import 'package:student_fin_os/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const ProviderScope(child: StudentFinOsApp()));
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    await Firebase.initializeApp();
  }
}
