import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-not-found':
        return 'Email belum terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter)';
      case 'user-disabled':
        return 'Akun dinonaktifkan';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Autentikasi gagal ($code)';
    }
  }

  Future<void> _loginOrRegister({required bool register}) async {
    final email = _emailC.text.trim();
    final password = _passC.text.trim();

    // Validasi input
    if (email.isEmpty || password.isEmpty) {
      _showError('Email dan password wajib diisi');
      return;
    }

    // Validasi password minimal 6
    if (password.length < 6) {
      _showError('Password minimal 6 karakter');
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;
      UserCredential cred;

      if (register) {
        cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        cred = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final u = cred.user;
      if (u == null) {
        _showError('Login gagal. User tidak ditemukan.');
        return;
      }

      await FirestoreService.instance.upsertUser(uid: u.uid, email: u.email);
      // Tidak perlu Navigator manual karena main.dart pakai authStateChanges()
    } on FirebaseAuthException catch (e) {
      _showError(_mapAuthError(e.code));
    } catch (_) {
      _showError('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailC,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passC,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                if (!_loading) _loginOrRegister(register: false);
              },
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () => _loginOrRegister(register: false),
                child: const Text('Login'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _loginOrRegister(register: true),
                child: const Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
