// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> login() async {
    setState(() => _loading = true);
    try {
      final cred = await AuthService().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (cred.user != null) {
        // Navigate to dashboard (replace route name if different)
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final cred = await AuthService().signInWithGoogle();
      if (cred == null) {
        // user canceled
        return;
      }
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign in failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loading ? null : login, child: _loading ? const CircularProgressIndicator() : const Text('Login')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loading ? null : loginWithGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Login with Google'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/reset'), child: const Text('Forgot password?')),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/signup'), child: const Text('Create account')),
          ],
        ),
      ),
    );
  }
}
