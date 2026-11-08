// login_page.dart

import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'core/widgets.dart';
import 'database_helper.dart';
import 'home_page.dart';
import 'main.dart';
import 'signup_page.dart';

final phoneRegex = RegExp(r'^01[3-9]\d{8}$');

String normalizePhone(String v) {
  var p = v.replaceAll(RegExp(r'[\s-]'), '');
  if (p.startsWith('+88')) p = p.substring(3);
  if (p.startsWith('88') && p.length == 13) p = p.substring(2);
  return p;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final db = DatabaseHelper.instance;
    try {
      final user = await db.login(normalizePhone(_phone.text), _password.text);
      final admin = await db.isAdmin();
      if (!mounted) return;
      context.app.setUser(user, admin: admin);
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()), (_) => false);
    } on AuthException catch (e) {
      if (mounted) showSnack(context, context.tr(e.bn, e.en), error: true);
    } catch (e) {
      if (mounted) {
        showSnack(context, context.tr('সমস্যা হয়েছে, আবার চেষ্টা করুন।', 'Something went wrong, try again.'),
            error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.green, AppColors.greenDark],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton.icon(
                onPressed: context.app.toggleLanguage,
                icon: const Icon(Icons.translate, color: Colors.white),
                label: Text(context.t('English', 'বাংলা'), style: const TextStyle(color: Colors.white)),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    const AppLogo(size: 84),
                    const SizedBox(height: 16),
                    Text(context.t('সিন্ডিকেটমুক্ত বাংলাদেশ', 'Syndicate-Free Bangladesh'),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(context.t('ন্যায্য দাম, স্বচ্ছ সেবা, জবাবদিহিমূলক রাষ্ট্র', 'Fair prices. Transparent services. Accountable state.'),
                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Text(context.t('লগইন', 'Log in'),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: context.t('মোবাইল নম্বর', 'Mobile number'),
                                hintText: '01XXXXXXXXX',
                                prefixIcon: const Icon(Icons.phone_android),
                              ),
                              validator: (v) => phoneRegex.hasMatch(normalizePhone(v ?? ''))
                                  ? null
                                  : context.tr('সঠিক মোবাইল নম্বর দিন', 'Enter a valid mobile number'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: context.t('পাসওয়ার্ড', 'Password'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v ?? '').length < 6
                                  ? context.tr('কমপক্ষে ৬ অক্ষর', 'At least 6 characters')
                                  : null,
                              onFieldSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _busy ? null : _login,
                              child: _busy
                                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(context.t('লগইন করুন', 'Log in')),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const SignupPage())),
                              child: Text(context.t('নতুন অ্যাকাউন্ট খুলুন', 'Create a new account')),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.t('জরুরি প্রয়োজনে ৯৯৯ • দুর্নীতির অভিযোগ ১০৬ • ভোক্তা অধিকার ১৬১২১',
                          'Emergency 999 • Anti-corruption 106 • Consumer rights 16121'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
