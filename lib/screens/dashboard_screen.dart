// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/db_service.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  // optional callback from main to toggle theme
  final VoidCallback? onToggleTheme;
  const DashboardScreen({super.key, this.onToggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DbService _db = DbService();
  final User? _user = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> _recentSessions = [];
  List<Map<String, dynamic>> _weeklyPlan = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final uid = _user?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final sessions = await _db.getRecentSessions(uid, limit: 8);
      final plan = await _db.getWeeklyPlan(uid);
      setState(() {
        _recentSessions = sessions;
        _weeklyPlan = plan; // list of {day, exercises}
      });
    } catch (e) {
      debugPrint("DASHBOARD_LOAD_ERROR: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // open profile screen
  void _openProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    // reload after potential profile changes
    await _loadAll();
  }

  // sign out
  Future<void> _signOut() async {
    // keep small dependency on AuthService implementation (exists in your project)
    try {
      // import AuthService where needed; to avoid circular issues we call FirebaseAuth directly here
      await FirebaseAuth.instance.signOut();
      // navigate to login
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    } catch (e) {
      debugPrint("SIGNOUT_ERROR: $e");
    }
  }

  // edit weekly plan modal
  Future<void> _editWeeklyPlan() async {
    if (_weeklyPlan.isEmpty) return;
    final updated = List<Map<String, dynamic>>.from(_weeklyPlan.map((d) => Map<String, dynamic>.from(d)));
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Weekly Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 380,
                child: ListView.builder(
                  itemCount: updated.length,
                  itemBuilder: (c, i) {
                    final day = updated[i];
                    final dayLabel = (day['day'] as String).substring(0, 1).toUpperCase() +
                        (day['day'] as String).substring(1);
                    final exercises = List<Map<String, dynamic>>.from(day['exercises'] as List<dynamic>);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dayLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...List.generate(exercises.length, (ei) {
                              final ex = exercises[ei];
                              final nameController = TextEditingController(text: ex['name']?.toString() ?? '');
                              final setsController =
                                  TextEditingController(text: ex['sets']?.toString() ?? '');
                              final repsController =
                                  TextEditingController(text: ex['reps']?.toString() ?? '');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: TextField(
                                        controller: nameController,
                                        decoration: const InputDecoration(labelText: 'Exercise'),
                                        onChanged: (v) => ex['name'] = v,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: setsController,
                                        decoration: const InputDecoration(labelText: 'Sets'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => ex['sets'] = int.tryParse(v) ?? 0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: repsController,
                                        decoration: const InputDecoration(labelText: 'Reps'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => ex['reps'] = int.tryParse(v) ?? 0,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () {
                                        setState(() {
                                          exercises.removeAt(ei);
                                        });
                                      },
                                    )
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  exercises.add({'name': 'New Exercise', 'sets': 3, 'reps': 10});
                                  setState(() {});
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Build plan map and save
                        final planMap = <String, dynamic>{};
                        for (final d in updated) {
                          planMap[d['day']] = d['exercises'];
                        }
                        final uid = _user?.uid;
                        if (uid != null) {
                          await _db.updateWeeklyPlan(uid, planMap);
                          Navigator.of(ctx).pop();
                          await _loadAll();
                        }
                      },
                      child: const Text('Save Plan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final displayName = (_user?.displayName ?? 'Omkar');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6A00), Color(0xFFEE0979)], // B1 gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                (displayName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').join()).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hello,', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.color_lens_outlined, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: _openProfile,
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 28),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    if (_recentSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Progress', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('No recent sessions. Start an exercise to see progress here.'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._recentSessions.map((s) {
              final name = (s['exercise'] ?? 'Exercise').toString();
              final reps = s['reps']?.toString() ?? '-';
              final form = s['form'] ?? '-';
              final createdAt = s['createdAtIso'] ?? s['createdAt']?.toString() ?? '';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(name),
                subtitle: Text('Form: $form • ${createdAt.toString().split('T').first}'),
                trailing: Text(reps),
              );
            }).toList(),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // expand to a full progress screen later (placeholder)
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Progress'),
                      content: const Text('More detailed progress will be added here.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                      ],
                    ),
                  );
                },
                child: const Text('View all'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyPlanTable() {
    if (_weeklyPlan.isEmpty) {
      return const SizedBox();
    }

    // Render as compact table: day + first exercise summary
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const Expanded(child: Text('Weekly Plan', style: TextStyle(fontWeight: FontWeight.bold))),
              TextButton.icon(
                onPressed: _editWeeklyPlan,
                icon: const Icon(Icons.edit),
                label: const Text('Edit plan'),
              )
            ],
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(4),
            },
            children: [
              const TableRow(children: [
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('Day', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('Planned Exercises', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ]),
              ..._weeklyPlan.map((d) {
                final dayLabel = (d['day'] as String).substring(0, 1).toUpperCase() +
                    (d['day'] as String).substring(1);
                final exList = (d['exercises'] as List<dynamic>).cast<Map<String, dynamic>>();
                final summary = exList.isEmpty
                    ? '—'
                    : exList.map((e) {
                        final name = e['name'] ?? '';
                        final sets = e['sets'] ?? '';
                        final reps = e['reps'] ?? e['durationSec'] ?? '';
                        return "$name (${sets}x$reps)";
                      }).join(', ');
                return TableRow(children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(dayLabel)),
                  Padding(padding: const EdgeInsets.all(6), child: Text(summary)),
                ]);
              }).toList()
            ],
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // keep AppBar slim; primary header is the gradient container
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          // Stats row
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Today', style: TextStyle(color: Colors.black54)),
                                        const SizedBox(height: 8),
                                        Text('${_recentSessions.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        const Text('Completed sessions', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Recommended', style: TextStyle(color: Colors.black54)),
                                        const SizedBox(height: 8),
                                        const Text('Full Body', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        const Text('Based on profile', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildProgressCard(),
                          const SizedBox(height: 12),
                          _buildWeeklyPlanTable(),
                          const SizedBox(height: 16),
                          // CTA row
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.pushNamed(context, '/exercise_select'),
                                  icon: const Icon(Icons.fitness_center),
                                  label: const Text('Start Exercise'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _loadAll,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
