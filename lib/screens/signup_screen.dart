// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _height = TextEditingController(); // cm
  final _weight = TextEditingController(); // kg
  String _level = "Beginner";
  bool _busy = false;
  String? _error;

  Future<void> signup() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final heightCm = double.tryParse(_height.text) ?? 0.0;
      final weightKg = double.tryParse(_weight.text) ?? 0.0;

      final cred = await AuthService().signup(
        email: _email.text.trim(),
        password: _pass.text,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        heightCm: heightCm,
        weightKg: weightKg,
        workoutLevel: _level,
      );

      if (cred.user != null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _first.dispose();
    _last.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController c, String hint, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _field(_first, "First name"),
            const SizedBox(height: 8),
            _field(_last, "Last name"),
            const SizedBox(height: 8),
            _field(_email, "Email"),
            const SizedBox(height: 8),
            _field(_pass, "Password", obscure: true),
            const SizedBox(height: 8),
            _field(_height, "Height (cm)"),
            const SizedBox(height: 8),
            _field(_weight, "Weight (kg)"),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _level,
              items: const [
                DropdownMenuItem(value: "Beginner", child: Text("Beginner")),
                DropdownMenuItem(value: "Intermediate", child: Text("Intermediate")),
                DropdownMenuItem(value: "Pro", child: Text("Pro")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
              ],
              onChanged: (v) => setState(() => _level = v ?? "Beginner"),
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Fitness level"),
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _busy ? null : signup,
              child: _busy ? const CircularProgressIndicator() : const Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
