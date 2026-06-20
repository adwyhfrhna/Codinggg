import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/features/home_screen.dart';
import 'package:flutter_application_1/features/todolist_screen.dart';

// Auth screens
import 'features/auth/login_screen.dart';
import 'features/auth/signup_step1.dart';
import 'features/auth/signup_step2.dart';
import 'features/auth/forgot_password.dart';
import 'features/auth/reset_password.dart';



// To-Do List screen
import 'features/todolist_screen.dart';
import 'features/schedule_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const StudySmartPlanner());
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
        '/todo': (context) => TodoListScreen(), // 
        '/organizer' : (context) => ScheduleScreen(),
      },
    );
  }
}
