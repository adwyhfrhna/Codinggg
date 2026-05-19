import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Auth screens
import 'features/auth/login_screen.dart';
import 'features/auth/signup_step1.dart';
import 'features/auth/signup_step2.dart';
import 'features/auth/forgot_password.dart';
import 'features/auth/reset_password.dart';

// Home screen
import 'home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(StudySmartPlanner());
}

class StudySmartPlanner extends StatelessWidget {
  const StudySmartPlanner({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Study Smart Planner',
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup1': (context) => SignupStep1(),
        '/signup2': (context) => SignupStep2(),
        '/forgot': (context) => ForgotPasswordScreen(),
        '/reset': (context) => ResetPasswordScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}



