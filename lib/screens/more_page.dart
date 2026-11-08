import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/widgets.dart';
import '../data/sectors.dart';
import '../database_helper.dart';
import '../login_page.dart';
import '../seller_page.dart';
import 'admin_page.dart';
import 'track_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final u = app.user;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('আরও', 'More'))),
      body: ListView(children: [
        if (u != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  radius: 26,
                  child: Text(u.name.isEmpty ? '?' : u.name.characters.first, style: const TextStyle(fontSize: 22)),
                ),
                title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${context.n(u.phone)}\n${districtName(context, u.district)} • ${u.isSeller ? context.t('কৃষক/বিক্রেতা', 'Farmer/Seller') : context.t('নাগরিক', 'Citizen')}\nNID ${u.maskedNid}'),
                isThreeLine: true,
                trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _editProfile(context)),
              ),
            ),
          ),
        ListTile(
          leading: const Icon(Icons.translate),
          title: Text(context.t('ভাষা', 'Language')),
          trailing: SegmentedButton<bool>(
            segments: const [ButtonSegment(value: true, label: Text('বাংলা')), ButtonSegment(value: false, label: Text('EN'))],
            selected: {app.isBangla},
            onSelectionChanged: (_) => app.toggleLanguage(),
            showSelectedIcon: false,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.manage_search),
          title: Text(context.t('অভিযোগ ট্র্যাক / আমার অভিযোগ', 'Track / my reports')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackPage())),
        ),
        ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text(context.t('আমার বিক্রয় তালিকা', 'My listings')),
          subtitle: Text(context.t('সরাসরি বাজারে পণ্য বিক্রি', 'Sell directly on the market')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerPage())),
        ),
        ListTile(
          leading: const Icon(Icons.phone_in_talk),
          title: Text(context.t('জরুরি হটলাইন', 'Emergency hotlines')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HotlinesPage())),
        ),
        ListTile(
          leading: const Icon(Icons.menu_book),
          title: Text(context.t('আপনার অধিকার জানুন', 'Know your rights')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RightsPage())),
        ),
        if (app.isAdmin)
          ListTile(
            leading: const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
            title: Text(context.t('কর্তৃপক্ষ ড্যাশবোর্ড', 'Authority dashboard')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage())),
          ),
        ListTile(
          leading: const Icon(Icons.fingerprint),
          title: Text(context.t('ডিভাইস আইডি', 'Device ID')),
          subtitle: Text(DatabaseHelper.instance.uid, style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.copy, size: 18),
          onTap: () {
            Clipboard.setData(ClipboardData(text: DatabaseHelper.instance.uid));
            showSnack(context, context.tr('কপি হয়েছে — অ্যাডমিন করার জন্য এটি ব্যবহার হয়', 'Copied — used to grant admin access'));
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(context.t('অ্যাপ সম্পর্কে', 'About')),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: context.tr('সিন্ডিকেটমুক্ত বাংলাদেশ', 'Syndicate-Free Bangladesh'),
            applicationVersion: '2.0.0',
            children: [
              Text(context.tr(
                  'নাগরিকদের অভিযোগ, বাজারদর ও প্রমাণের ভিত্তিতে বিভিন্ন খাতের সিন্ডিকেট শনাক্ত করে কর্তৃপক্ষের কাছে পৌঁছে দেওয়ার একটি প্ল্যাটফর্ম।',
                  'A platform that detects syndicates across sectors from citizen reports, market prices and evidence, and routes them to the authorities.')),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: Text(context.t('লগআউট', 'Log out'), style: const TextStyle(color: Colors.red)),
          onTap: () {
            context.app.setUser(null);
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
          },
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final app = context.app;
    final u = app.user!;
    final name = TextEditingController(text: u.name);
    String? district = u.district;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: name, decoration: InputDecoration(labelText: ctx.t('নাম', 'Name'))),
            const SizedBox(height: 12),
            DistrictField(value: district, onChanged: (v) => setS(() => district = v)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await DatabaseHelper.instance.updateProfile(u.phone, name: name.text.trim(), district: district ?? u.district);
                final fresh = await DatabaseHelper.instance.getUser(u.phone);
                app.setUser(fresh, admin: app.isAdmin);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(ctx.t('সংরক্ষণ', 'Save')),
            ),
          ]),
        ),
      ),
    );
  }
}

class HotlinesPage extends StatelessWidget {
  const HotlinesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.t('জরুরি হটলাইন', 'Emergency hotlines'))),
        body: ListView(children: kAllHotlines.map((h) => HotlineTile(h)).toList()),
      );
}

class RightsPage extends StatelessWidget {
  const RightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <BT>[
      const BT('প্যাকেটে লেখা সর্বোচ্চ খুচরা মূল্যের (MRP) বেশি দাম নেওয়া ভোক্তা-অধিকার বিরোধী অপরাধ।',
          'Charging above the printed maximum retail price (MRP) is an offence under consumer rights law.'),
      const BT('প্রতিটি দোকানে পণ্যের মূল্যতালিকা প্রকাশ্যে টাঙানো বাধ্যতামূলক।', 'Every shop must display a price list in public view.'),
      const BT('ভোক্তা অধিকার সংরক্ষণ আইন, ২০০৯ অনুযায়ী অভিযোগ প্রমাণিত হলে আদায়কৃত জরিমানার ২৫% অভিযোগকারী পেতে পারেন।',
          'Under the Consumer Rights Protection Act 2009, a complainant may receive 25% of the fine collected when a complaint is proven.'),
      const BT('ভোক্তা অধিকারে অভিযোগ ঘটনার ৩০ দিনের মধ্যে করতে হয় — রসিদ/প্রমাণ রাখুন।',
          'Consumer complaints should be filed within 30 days of the incident — keep receipts and evidence.'),
      const BT('বাসে বিআরটিএ নির্ধারিত ভাড়ার চার্ট থাকা উচিত; বেশি ভাড়া দাবি করলে অভিযোগ করুন।',
          'Buses should follow the BRTA fare chart; report any fare demanded above it.'),
      const BT('সরকারি সেবা পেতে কোনো দালাল বা ঘুষের প্রয়োজন নেই। ঘুষ চাইলে দুদক ১০৬-এ জানান।',
          'No broker or bribe is needed for any government service. Report bribe demands to ACC at 106.'),
      const BT('মিথ্যা অভিযোগ করাও অপরাধ — সত্য ও নির্ভুল তথ্য দিন।', 'Filing false complaints is also an offence — provide truthful, accurate information.'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(context.t('আপনার অধিকার', 'Your rights'))),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(context.n(i + 1))),
            title: Text(items[i].of(context.isBn), style: const TextStyle(height: 1.45)),
          ),
        ),
      ),
    );
  }
}
