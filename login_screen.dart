import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 👇 Added state variable for password visibility
  bool _obscurePassword = true;

  Future<void> _login() async {
    try {
      if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login failed. Please try again.")),
        );
        return;
      }

      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.pushReplacementNamed(context, '/home', arguments: emailController.text.trim());
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = "No account found with this email.";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password. Try again.";
      } else {
        message = "Login failed. Please try again.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed. Please try again."), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Group logo + text together
                Column(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        "assets/images/orchid_logo.png",
                        height: 180, // smaller size
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 6), // very small gap
                    Text(
                      "Welcome Back",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Please, Log In",
                      style: TextStyle(fontSize: 20, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                SizedBox(height: 25), // spacing before fields

                // Email field
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                SizedBox(height: 20),

                // Password field with eye icon
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: Text("Forgot Password?", style: TextStyle(fontSize: 13, color: Colors.black54)),
                    onPressed: () => Navigator.pushNamed(context, '/forgot'),
                  ),
                ),
                SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                    backgroundColor: Colors.deepPurple,
                  ),
                  onPressed: _login,
                  child: Text("Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                SizedBox(height: 15),

                TextButton(
                  child: Text("Create Account", style: TextStyle(fontSize: 16, color: Colors.black54, decoration: TextDecoration.underline)),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/signup1'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
