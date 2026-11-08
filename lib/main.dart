import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'database_helper.dart';
import 'home_page.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final state = AppState();
  await state.load();
  runApp(ChangeNotifierProvider.value(value: state, child: const SyndicateFreeApp()));
}

class SyndicateFreeApp extends StatelessWidget {
  const SyndicateFreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bn = context.watch<AppState>().isBangla;
    return MaterialApp(
      title: 'সিন্ডিকেটমুক্ত বাংলাদেশ',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: Locale(bn ? 'bn' : 'en'),
      supportedLocales: const [Locale('bn'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const StartupGate(),
    );
  }
}

/// Initialises Firebase, signs in the device anonymously (for DB security
/// rules only) and restores the saved login session.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      await Firebase.initializeApp();
      final db = DatabaseHelper.instance;
      await db.ensureDeviceSession();
      if (!mounted) return;
      final app = context.read<AppState>();
      final phone = app.savedPhone;
      Widget next = const LoginPage();
      if (phone != null) {
        final user = await db.getUser(phone);
        if (user != null) {
          app.setUser(user, admin: await db.isAdmin());
          next = const HomePage();
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next));
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.green, AppColors.greenDark],
          ),
        ),
        child: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const AppLogo(size: 96),
            const SizedBox(height: 20),
            const Text('সিন্ডিকেটমুক্ত বাংলাদেশ',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Syndicate-Free Bangladesh', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            if (_error == null)
              const CircularProgressIndicator(color: Colors.white)
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(children: [
                  Text(context.t('সংযোগ করা যায়নি। ইন্টারনেট চেক করুন।', 'Could not connect. Check your internet.'),
                      style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.tonal(onPressed: _start, child: Text(context.t('আবার চেষ্টা করুন', 'Retry'))),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Simple vector logo: red circle on green (flag) with a broken-chain mark.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Center(
          child: Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
            child: Icon(Icons.link_off, color: Colors.white, size: size * 0.36),
          ),
        ),
      );
}
