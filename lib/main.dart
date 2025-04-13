import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:wardrobeapp/Login Page.dart'; // Fix: Change "login page.dart" to "login_page.dart"
import 'package:firebase_core/firebase_core.dart';
import 'Firebase_options.dart';
import 'Components.dart';
import 'package:camera/camera.dart';


List<CameraDescription>? cameras;
bool isCameraloaded = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error during initialization: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(),
    );
  }
}
