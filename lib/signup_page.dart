// signup_page.dart

import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/widgets.dart';
import 'database_helper.dart';
import 'home_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _nid = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _district;
  String _role = 'citizen';
  bool _agree = false;
  bool _busy = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      showSnack(context, context.tr('শর্তাবলিতে সম্মতি দিন', 'Please accept the terms'), error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final user = await DatabaseHelper.instance.signUp(
        name: _name.text.trim(),
        phone: normalizePhone(_phone.text),
        nid: _nid.text.trim(),
        district: _district!,
        role: _role,
        password: _password.text,
      );
      if (!mounted) return;
      context.app.setUser(user);
      showSnack(context, context.tr('অ্যাকাউন্ট তৈরি হয়েছে', 'Account created'));
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
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: Text(context.t('নতুন অ্যাকাউন্ট', 'Create account'))),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: context.t('পূর্ণ নাম', 'Full name'), prefixIcon: const Icon(Icons.person_outline)),
            validator: (v) => (v ?? '').trim().length < 3 ? context.tr('নাম লিখুন', 'Enter your name') : null,
          ),
          gap,
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                labelText: context.t('মোবাইল নম্বর', 'Mobile number'), hintText: '01XXXXXXXXX', prefixIcon: const Icon(Icons.phone_android)),
            validator: (v) => phoneRegex.hasMatch(normalizePhone(v ?? ''))
                ? null
                : context.tr('সঠিক মোবাইল নম্বর দিন (০১ দিয়ে শুরু, ১১ সংখ্যা)', 'Enter a valid 11-digit number starting with 01'),
          ),
          gap,
          TextFormField(
            controller: _nid,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.t('জাতীয় পরিচয়পত্র (NID) নম্বর', 'National ID (NID) number'),
              helperText: context.t('১০, ১৩ বা ১৭ সংখ্যা। অন্য কেউ দেখতে পাবে না।', '10, 13 or 17 digits. Never shown to others.'),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            validator: (v) {
              final s = (v ?? '').trim();
              if (!RegExp(r'^\d+$').hasMatch(s) || ![10, 13, 17].contains(s.length)) {
                return context.tr('সঠিক NID নম্বর দিন', 'Enter a valid NID number');
              }
              return null;
            },
          ),
          gap,
          DistrictField(value: _district, onChanged: (v) => setState(() => _district = v)),
          gap,
          Text(context.t('আপনি কে?', 'I am a'), style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'citizen', icon: const Icon(Icons.person), label: Text(context.t('নাগরিক/ক্রেতা', 'Citizen/Buyer'))),
              ButtonSegment(value: 'seller', icon: const Icon(Icons.agriculture), label: Text(context.t('কৃষক/বিক্রেতা', 'Farmer/Seller'))),
            ],
            selected: {_role},
            onSelectionChanged: (s) => setState(() => _role = s.first),
          ),
          gap,
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: context.t('পাসওয়ার্ড', 'Password'), prefixIcon: const Icon(Icons.lock_outline)),
            validator: (v) => (v ?? '').length < 6 ? context.tr('কমপক্ষে ৬ অক্ষর', 'At least 6 characters') : null,
          ),
          gap,
          TextFormField(
            controller: _confirm,
            obscureText: true,
            decoration: InputDecoration(labelText: context.t('পাসওয়ার্ড নিশ্চিত করুন', 'Confirm password'), prefixIcon: const Icon(Icons.lock_outline)),
            validator: (v) => v != _password.text ? context.tr('পাসওয়ার্ড মেলেনি', 'Passwords do not match') : null,
          ),
          gap,
          CheckboxListTile(
            value: _agree,
            onChanged: (v) => setState(() => _agree = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(context.t(
                'আমি সত্য তথ্য দেব। মিথ্যা অভিযোগ আইনত দণ্ডনীয় অপরাধ।',
                'I will provide truthful information. False complaints are punishable by law.')),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _signup,
            child: _busy
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(context.t('অ্যাকাউন্ট তৈরি করুন', 'Create account')),
          ),
        ]),
      ),
    );
  }
}
