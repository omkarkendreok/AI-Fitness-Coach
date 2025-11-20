// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/db_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DbService _db = DbService();
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _editing = false;
  Map<String, dynamic> _profile = {};

  // controllers for editing
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  String _workoutLevel = 'beginner';

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _user?.uid;
    final email = _user?.email ?? '';
    if (uid == null) {
      // Not logged in
      setState(() {
        _profile = {
          'firstName': '',
          'lastName': '',
          'email': email,
          'heightCm': null,
          'weightKg': null,
          'workoutLevel': 'beginner',
        };
        _loading = false;
      });
      return;
    }

    final p = await _db.getOrCreateUserProfile(uid, email: email);
    _profile = p;

    _firstName.text = _profile['firstName'] ?? '';
    _lastName.text = _profile['lastName'] ?? '';
    _height.text = _profile['heightCm']?.toString() ?? '';
    _weight.text = _profile['weightKg']?.toString() ?? '';
    _workoutLevel = _profile['workoutLevel'] ?? 'beginner';

    setState(() {
      _loading = false;
    });
  }

  double? _calculateBmi() {
    final h = _profile['heightCm'];
    final w = _profile['weightKg'];
    if (h == null || w == null) return null;
    if (h == 0) return null;
    final heightM = (h as num).toDouble() / 100.0;
    final bmi = (w as num).toDouble() / (heightM * heightM);
    return double.parse(bmi.toStringAsFixed(1));
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = _user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }

    final update = <String, dynamic>{
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'heightCm': _height.text.trim().isEmpty ? null : double.parse(_height.text.trim()),
      'weightKg': _weight.text.trim().isEmpty ? null : double.parse(_weight.text.trim()),
      'workoutLevel': _workoutLevel,
    };

    setState(() => _loading = true);
    await _db.updateUserProfile(uid, update);
    await _loadProfile(); // reload updated profile
    setState(() {
      _editing = false;
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _editing = !_editing;
                if (!_editing) {
                  // discard unsaved changes by reloading
                  _firstName.text = _profile['firstName'] ?? '';
                  _lastName.text = _profile['lastName'] ?? '';
                  _height.text = _profile['heightCm']?.toString() ?? '';
                  _weight.text = _profile['weightKg']?.toString() ?? '';
                  _workoutLevel = _profile['workoutLevel'] ?? 'beginner';
                }
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Gradient header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFff6a00), Color(0xFFee0979)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // avatar
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.grey.shade200,
                            child: _buildAvatarChild(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${(_profile['firstName'] ?? '').toString().trim()} ${(_profile['lastName'] ?? '').toString().trim()}'
                              .trim()
                              .isEmpty
                              ? 'Your Name'
                              : '${(_profile['firstName'] ?? '').toString().trim()} ${(_profile['lastName'] ?? '').toString().trim()}',
                          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (_profile['email'] ?? '').toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BMI card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Body Mass Index", style: TextStyle(fontSize: 14, color: Colors.black54)),
                                  const SizedBox(height: 8),
                                  Builder(builder: (_) {
                                    final bmi = _calculateBmi();
                                    if (bmi == null) {
                                      return const Text("Add height & weight", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(bmi.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(_bmiCategory(bmi), style: const TextStyle(color: Colors.black54)),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const Icon(Icons.monitor_heart, size: 40, color: Color(0xFFee0979)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Profile details / edit form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _editing ? _buildEditForm() : _buildReadOnly(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (_editing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Profile'),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarChild() {
    final photo = _profile['photoURL'];
    if (photo != null && photo is String && photo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.network(photo, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
          return _initialsText();
        }),
      );
    }
    return _initialsText();
  }

  Widget _initialsText() {
    final f = (_profile['firstName'] ?? '').toString().trim();
    final l = (_profile['lastName'] ?? '').toString().trim();
    final initials = ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '')).toUpperCase();
    return Text(initials.isEmpty ? 'U' : initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildReadOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Profile Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _infoRow('First name', _profile['firstName'] ?? ''),
        const Divider(),
        _infoRow('Last name', _profile['lastName'] ?? ''),
        const Divider(),
        _infoRow('Height (cm)', _profile['heightCm']?.toString() ?? '—'),
        const Divider(),
        _infoRow('Weight (kg)', _profile['weightKg']?.toString() ?? '—'),
        const Divider(),
        _infoRow('Workout level', _profile['workoutLevel'] ?? 'beginner'),
      ],
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.black54))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _firstName,
            decoration: const InputDecoration(labelText: 'First name'),
            validator: (v) => null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lastName,
            decoration: const InputDecoration(labelText: 'Last name'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _height,
            decoration: const InputDecoration(labelText: 'Height (cm)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final parsed = double.tryParse(v);
              if (parsed == null || parsed <= 0) return 'Enter valid height';
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _weight,
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final parsed = double.tryParse(v);
              if (parsed == null || parsed <= 0) return 'Enter valid weight';
              return null;
            },
          ),
          const SizedBox(height: 12),
          const Text('Workout level', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['beginner', 'intermediate', 'pro', 'other'].map((lvl) {
              final selected = _workoutLevel == lvl;
              return ChoiceChip(
                label: Text(lvl[0].toUpperCase() + lvl.substring(1)),
                selected: selected,
                onSelected: (s) {
                  setState(() {
                    _workoutLevel = lvl;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
