import 'package:flutter/material.dart';
import 'RegisterPage.dart';
import 'Login Page.dart';  // Corrected import to match your file naming convention

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(onTap: togglePages);  // Pass togglePages function as onTap to switch to RegisterPage
    } else {
      return RegisterPage( onTap: togglePages,);  // Return RegisterPage when showLoginPage is false
    }
  }
}
