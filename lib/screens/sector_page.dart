import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/widgets.dart';
import '../data/sectors.dart';
import '../database_helper.dart';
import '../models.dart';
import 'fare_calculator_page.dart';
import 'prices_page.dart';
import 'report_form_page.dart';
import 'reports_feed_page.dart';

class SectorPage extends StatelessWidget {
  final Sector sector;
  const SectorPage({super.key, required this.sector});

  @override
  Widget build(BuildContext context) {
    final s = sector;
    final bn = context.isBn;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: s.color,
        title: Text(s.name.of(bn)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportFormPage(sectorId: s.id))),
        icon: const Icon(Icons.campaign),
        label: Text(context.t('এই খাতে অভিযোগ', 'Report in this sector')),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 100), children: [
        Container(
          color: s.color.withValues(alpha: 0.08),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(s.icon, size: 40, color: s.color),
            const SizedBox(width: 12),
            Expanded(child: Text(s.tagline.of(bn), style: Theme.of(context).textTheme.titleMedium)),
          ]),
        ),
        if (s.tool != null) _ToolCard(sector: s),
        SectionTitle(context.t('সিন্ডিকেট কীভাবে কাজ করে', 'How the syndicate works')),
        ...s.patterns.map((p) => _Bullet(p.of(bn), Icons.report_gmailerrorred, Colors.red)),
        SectionTitle(context.t('সমাধান — আপনি কী করতে পারেন', 'Solutions — what you can do')),
        ...s.solutions.map((p) => _Bullet(p.of(bn), Icons.check_circle_outline, Colors.green)),
        SectionTitle(context.t('দায়িত্বপ্রাপ্ত কর্তৃপক্ষ', 'Responsible authority')),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(s.authority.of(bn))),
        ...s.hotlines.map((h) => HotlineTile(h)),
        SectionTitle(
          context.t('সাম্প্রতিক অভিযোগ', 'Recent reports'),
          trailing: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsFeedPage(sectorId: s.id))),
            child: Text(context.t('সব দেখুন', 'See all')),
          ),
        ),
        _SectorRecent(sectorId: s.id),
      ]),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _Bullet(this.text, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
        ]),
      );
}

class _SectorRecent extends StatefulWidget {
  final String sectorId;
  const _SectorRecent({required this.sectorId});

  @override
  State<_SectorRecent> createState() => _SectorRecentState();
}

class _SectorRecentState extends State<_SectorRecent> {
  late final Stream<List<Report>> _stream = DatabaseHelper.instance.reportsStream();

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Report>>(
        stream: _stream,
        builder: (context, snap) {
          final list = (snap.data ?? [])
              .where((r) => r.sector == widget.sectorId && r.status != ReportStatus.rejected)
              .take(5)
              .toList();
          if (list.isEmpty) {
            return EmptyState(icon: Icons.inbox_outlined, text: context.t('এখনো কোনো অভিযোগ নেই', 'No reports yet'));
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: list.map((r) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ReportCard(r))).toList(),
            ),
          );
        },
      );
}

/// Sector-specific smart tool card.
class _ToolCard extends StatelessWidget {
  final Sector sector;
  const _ToolCard({required this.sector});

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final String title;
    late final String sub;
    late final VoidCallback onTap;
    switch (sector.tool) {
      case 'fare':
        icon = Icons.calculate;
        title = context.t('বিআরটিএ ভাড়া ক্যালকুলেটর', 'BRTA fare calculator');
        sub = context.t('দূরত্ব দিন, সরকারি ভাড়া জানুন, বেশি নিলে অভিযোগ করুন', 'Enter distance, see the lawful fare, report overcharging');
        onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FareCalculatorPage()));
        break;
      case 'medicine':
        icon = Icons.medication_liquid;
        title = context.t('এমআরপি চেকার', 'MRP checker');
        sub = context.t('প্যাকেটের দামের চেয়ে বেশি নিল কি না যাচাই করুন', 'Check if you were charged above the printed price');
        onTap = () => showMrpChecker(context);
        break;
      case 'farmgate':
        icon = Icons.agriculture;
        title = context.t('মধ্যস্বত্ব মিটার ও বাজারদর', 'Middleman meter & prices');
        sub = context.t('কৃষক কত পান আর ভোক্তা কত দেন', 'What farmers get vs what consumers pay');
        onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PricesPage()));
        break;
      default:
        icon = Icons.price_check;
        title = context.t('লাইভ ন্যায্যমূল্য বোর্ড', 'Live fair-price board');
        sub = context.t('জেলাভিত্তিক বাজারদর বনাম রেফারেন্স দাম', 'District market prices vs reference price');
        onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PricesPage()));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: sector.color,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(icon, color: Colors.white, size: 36),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(sub, style: const TextStyle(color: Colors.white70)),
          trailing: const Icon(Icons.arrow_forward, color: Colors.white),
        ),
      ),
    );
  }
}

Future<void> showMrpChecker(BuildContext context) async {
  final mrp = TextEditingController();
  final paid = TextEditingController();
  final name = TextEditingController();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final m = double.tryParse(mrp.text) ?? 0;
      final p = double.tryParse(paid.text) ?? 0;
      final over = p - m;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(ctx.t('এমআরপি চেকার', 'MRP checker'), style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(controller: name, decoration: InputDecoration(labelText: ctx.t('ওষুধের নাম', 'Medicine name'))),
          const SizedBox(height: 10),
          TextField(
            controller: mrp,
            keyboardType: TextInputType.number,
            onChanged: (_) => setS(() {}),
            decoration: InputDecoration(labelText: ctx.t('প্যাকেটে লেখা MRP (৳)', 'MRP printed on pack (Tk)')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: paid,
            keyboardType: TextInputType.number,
            onChanged: (_) => setS(() {}),
            decoration: InputDecoration(labelText: ctx.t('আপনি কত দিলেন (৳)', 'Amount you paid (Tk)')),
          ),
          const SizedBox(height: 16),
          if (m > 0 && p > 0)
            Card(
              color: (over > 0 ? Colors.red : Colors.green).withValues(alpha: 0.1),
              child: ListTile(
                leading: Icon(over > 0 ? Icons.error : Icons.check_circle, color: over > 0 ? Colors.red : Colors.green),
                title: Text(over > 0
                    ? ctx.t('${ctx.taka(over)} বেশি নেওয়া হয়েছে — এটি আইনত অপরাধ', 'Overcharged by ${ctx.taka(over)} — this is illegal')
                    : ctx.t('দাম ঠিক আছে', 'Price is within MRP')),
              ),
            ),
          const SizedBox(height: 12),
          if (m > 0 && p > m)
            FilledButton.icon(
              icon: const Icon(Icons.campaign),
              label: Text(ctx.t('অভিযোগ করুন', 'Report it')),
              onPressed: () {
                final desc = ctx.tr(
                  '${name.text} ওষুধের MRP ৳${mrp.text}, কিন্তু নেওয়া হয়েছে ৳${paid.text}।',
                  '${name.text}: MRP Tk ${mrp.text}, but charged Tk ${paid.text}.',
                );
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ReportFormPage(
                            sectorId: 'medicine', issueType: 'Above MRP', prefillDescription: desc, prefillAmount: over)));
              },
            ),
        ]),
      );
    }),
  );
}
