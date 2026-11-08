import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Global app state: language, logged-in user and admin flag.
class AppState extends ChangeNotifier {
  static const _kLang = 'lang';
  static const _kPhone = 'session_phone';

  bool isBangla = true;
  AppUser? user;
  bool isAdmin = false;
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    isBangla = _prefs!.getString(_kLang) != 'en';
  }

  String? get savedPhone => _prefs?.getString(_kPhone);

  void toggleLanguage() {
    isBangla = !isBangla;
    _prefs?.setString(_kLang, isBangla ? 'bn' : 'en');
    notifyListeners();
  }

  void setUser(AppUser? u, {bool admin = false}) {
    user = u;
    isAdmin = admin;
    if (u == null) {
      _prefs?.remove(_kPhone);
    } else {
      _prefs?.setString(_kPhone, u.phone);
    }
    notifyListeners();
  }
}

extension Tr on BuildContext {
  /// Pick Bangla or English text based on the current language.
  String t(String bn, String en) =>
      Provider.of<AppState>(this).isBangla ? bn : en;

  /// Same as [t] but without subscribing to changes (for callbacks).
  String tr(String bn, String en) =>
      Provider.of<AppState>(this, listen: false).isBangla ? bn : en;

  bool get isBn => Provider.of<AppState>(this).isBangla;

  AppState get app => Provider.of<AppState>(this, listen: false);
}

const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Convert Latin digits to Bangla digits.
String bnNum(Object n) =>
    n.toString().split('').map((c) {
      final d = int.tryParse(c);
      return d == null ? c : _bnDigits[d];
    }).join();

extension NumTr on BuildContext {
  String n(Object v) => isBn ? bnNum(v) : v.toString();
  String taka(num v) {
    final s = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return '৳${n(s)}';
  }
}
