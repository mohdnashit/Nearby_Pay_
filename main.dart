// lib/main.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NearbyPayApp());
}

class NearbyPayApp extends StatelessWidget {
  const NearbyPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nearby Pay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}

/* ----------------------------------------------------------
 *  LOGIN & REGISTER
 * --------------------------------------------------------*/

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    final username = _userController.text.trim();
    final password = _passController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnack('Please enter username and password');
      return;
    }

    setState(() => _loading = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _showSnack('Invalid username or password');
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(username: username),
          ),
        );
      }
    } catch (e) {
      _showSnack('Login error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            child: _GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nearby Pay',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to continue',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('LOGIN'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    final username = _userController.text.trim();
    final password = _passController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnack('Please enter username and password');
      return;
    }

    setState(() => _loading = true);

    try {
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _showSnack('Username already taken');
      } else {
        await FirebaseFirestore.instance.collection('users').add({
          'username': username,
          'password': password,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });

        if (!mounted) return;
        _showSnack('Registered! Please login.');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Registration error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            child: _GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_add),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('REGISTER'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Back to login",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------------------------------------------------------
 *  HOME
 * --------------------------------------------------------*/

class HomeScreen extends StatelessWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  String _generateUserId() {
    final random = Random();
    return 'user_${random.nextInt(999999)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthBackground(
        child: Center(
          child: _GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payments_rounded,
                    size: 64, color: Colors.white.withOpacity(0.9)),
                const SizedBox(height: 10),
                Text(
                  'Welcome, $username',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose what you want to do',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 32),

                // PAY
                _RoundedButton(
                  label: 'PAY',
                  color: Colors.greenAccent,
                  onTap: () {
                    final myId = _generateUserId();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanReceiversScreen(
                          myId: myId,
                          myName: username,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // RECEIVE (normal)
                _RoundedButton(
                  label: 'RECEIVE',
                  color: Colors.orangeAccent,
                  onTap: () {
                    final myId = _generateUserId();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiverWaitingScreen(
                          myId: myId,
                          myName: username,
                          isMerchant: false,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // MERCHANT RECEIVE
                _RoundedButton(
                  label: 'MERCHANT RECEIVE',
                  color: Colors.lightBlueAccent,
                  onTap: () {
                    final myId = _generateUserId();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiverWaitingScreen(
                          myId: myId,
                          myName: username,
                          isMerchant: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // TRANSACTION HISTORY
                _RoundedButton(
                  label: 'TRANSACTIONS',
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TransactionHistoryScreen(username: username),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------------------------------------------------------
 *  RECEIVER WAITING SCREEN
 * --------------------------------------------------------*/

class ReceiverWaitingScreen extends StatefulWidget {
  final String myId;
  final String myName;
  final bool isMerchant;

  const ReceiverWaitingScreen({
    super.key,
    required this.myId,
    required this.myName,
    required this.isMerchant,
  });

  @override
  State<ReceiverWaitingScreen> createState() => _ReceiverWaitingScreenState();
}

class _ReceiverWaitingScreenState extends State<ReceiverWaitingScreen> {
  @override
  void initState() {
    super.initState();
    _broadcast();
  }

  Future<void> _broadcast() async {
    await FirebaseFirestore.instance
        .collection('broadcast')
        .doc(widget.myId)
        .set({
      'user_id': widget.myId,
      'user_name': widget.myName,
      'isMerchant': widget.isMerchant,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'role': 'receiver',
    });
  }

  Future<void> _removeBroadcast() async {
    await FirebaseFirestore.instance
        .collection('broadcast')
        .doc(widget.myId)
        .delete()
        .catchError((_) {});
  }

  @override
  void dispose() {
    _removeBroadcast();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isMerchant ? 'Waiting as Merchant' : 'Waiting for payment';
    final sub = widget.isMerchant
        ? 'Payers will see you as PRIORITY merchant.'
        : 'Other device should press PAY to send you money.';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_bottom,
                  size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text(
                'You are now visible to nearby payers.\nKeep this screen open.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                sub,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------------------------------------------
 *  PAYER: SCAN RECEIVERS
 * --------------------------------------------------------*/

class ScanReceiversScreen extends StatefulWidget {
  final String myId;
  final String myName;

  const ScanReceiversScreen({
    super.key,
    required this.myId,
    required this.myName,
  });

  @override
  State<ScanReceiversScreen> createState() => _ScanReceiversScreenState();
}

class _ScanReceiversScreenState extends State<ScanReceiversScreen> {
  Timer? cleanupTimer;

  @override
  void initState() {
    super.initState();
    _startCleanupTimer();
  }

  void _startCleanupTimer() {
    cleanupTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _cleanupOldBroadcasts();
    });
  }

  Future<void> _cleanupOldBroadcasts() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - 20000; // 20 seconds

    final oldDocs = await FirebaseFirestore.instance
        .collection('broadcast')
        .where('timestamp', isLessThan: cutoff)
        .get();

    for (var d in oldDocs.docs) {
      await d.reference.delete();
    }
  }

  @override
  void dispose() {
    cleanupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanning for receivers...'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 8),
          const Text(
            'Ask the other device to press RECEIVE.\nThey will appear here.',
            textAlign: TextAlign.center,
          ),
          const Divider(height: 32),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('broadcast')
                  .where('role', isEqualTo: 'receiver')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading receivers:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final now = DateTime.now().millisecondsSinceEpoch;
                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final ts = (data['timestamp'] ?? 0) as int;
                  return now - ts <= 20000; // last 20s
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No receivers yet.\nWaiting...',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Sort newest first
                docs.sort((a, b) {
                  final da = a.data() as Map<String, dynamic>;
                  final db = b.data() as Map<String, dynamic>;
                  final ta = (da['timestamp'] ?? 0) as int;
                  final tb = (db['timestamp'] ?? 0) as int;
                  return tb.compareTo(ta);
                });

                // merchants first
                final merchants = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['isMerchant'] == true;
                }).toList();
                final normal = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['isMerchant'] != true;
                }).toList();

                final all = [...merchants, ...normal];

                return ListView.builder(
                  itemCount: all.length,
                  itemBuilder: (context, index) {
                    final data =
                        all[index].data() as Map<String, dynamic>;
                    final id = data['user_id'] ?? 'unknown';
                    final name = data['user_name'] ?? 'Unknown';
                    final bool isMerchant = data['isMerchant'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isMerchant ? Colors.blueAccent : Colors.grey,
                          child: Icon(
                            isMerchant ? Icons.store : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          isMerchant ? 'Merchant: $name' : name,
                        ),
                        subtitle: Text(
                          isMerchant
                              ? 'Priority receiver'
                              : 'Ready to receive',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PayToUserScreen(
                                  fromUser: widget.myName,
                                  targetUserId: id,
                                  targetUserName: name,
                                ),
                              ),
                            );
                          },
                          child: const Text('PAY'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------------------------------------
 *  PAYMENT SCREEN
 * --------------------------------------------------------*/

class PayToUserScreen extends StatelessWidget {
  final String fromUser;
  final String targetUserId;
  final String targetUserName;

  PayToUserScreen({
    super.key,
    required this.fromUser,
    required this.targetUserId,
    required this.targetUserName,
  });

  final TextEditingController amountController = TextEditingController();

  Future<void> _sendPayment(BuildContext context) async {
    final amount = amountController.text.trim();
    if (amount.isEmpty) return;

    await FirebaseFirestore.instance.collection('transactions').add({
      'fromUser': fromUser,
      'toUserId': targetUserId,
      'toUserName': targetUserName,
      'amount': amount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Payment Sent'),
        content: Text(
          '₹$amount sent to $targetUserName ($targetUserId) successfully.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Pay to: $targetUserName',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $targetUserId',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter amount',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _sendPayment(context),
                child: const Text('CONFIRM PAYMENT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------------------------------------
 *  TRANSACTION HISTORY SCREEN
 * --------------------------------------------------------*/

class TransactionHistoryScreen extends StatelessWidget {
  final String username;

  const TransactionHistoryScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("transactions")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading transactions:\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;

          // Only show transactions related to this user
          final docs = allDocs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final from = data["fromUser"] as String?;
            final toName = data["toUserName"] as String?;
            return from == username || toName == username;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No transactions yet.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final from = data["fromUser"] ?? "Unknown";
              final toName = data["toUserName"] ?? "Unknown";
              final amount = data["amount"] ?? "0";
              final ts = data["timestamp"] ?? 0;
              final date =
                  DateTime.fromMillisecondsSinceEpoch(ts is int ? ts : 0);

              final bool sentByUser = from == username;

              final title = sentByUser
                  ? "You paid $toName"
                  : "$from paid you";

              final color = sentByUser ? Colors.redAccent : Colors.green;
              final icon = sentByUser ? Icons.arrow_upward : Icons.arrow_downward;

              final timeStr =
                  "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  •  "
                  "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(icon, color: Colors.white),
                  ),
                  title: Text(title),
                  subtitle: Text(timeStr),
                  trailing: Text(
                    "₹$amount",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/* ----------------------------------------------------------
 *  SMALL UI HELPERS (BACKGROUND + GLASS CARD + BUTTON)
 * --------------------------------------------------------*/

class _AuthBackground extends StatelessWidget {
  final Widget child;
  const _AuthBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E3C72),
            Color(0xFF2A5298),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RoundedButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RoundedButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}