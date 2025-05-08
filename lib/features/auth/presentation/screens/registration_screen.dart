import 'package:flutter/material.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField('Username', Icons.person, _usernameController),
            SizedBox(
              height: 20,
            ),
            _buildTextField('Email', Icons.email, _emailController),
            SizedBox(
              height: 20,
            ),
            _buildTextField('Password', Icons.lock, _passwordController,
                isPassword: true),
            SizedBox(
              height: 20,
            ),
            _buildTextField(
                'Confirm Password', Icons.lock, _confirmPasswordController,
                isPassword: true),
          ],
        ),
      ),
    ));
  }

  Widget _buildTextField(
      String hint, IconData icon, TextEditingController controller,
      {bool isPassword = false}) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey),
            SizedBox(
              width: 10,
            ),
            Expanded(
                child: TextField(
              controller: controller,
              obscureText: isPassword,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ))
          ],
        ));
  }


}
