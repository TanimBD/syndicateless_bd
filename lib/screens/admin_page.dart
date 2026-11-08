import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/widgets.dart';
import '../data/sectors.dart';
import '../database_helper.dart';
import '../models.dart';
import 'reports_feed_page.dart';

/// Authority / admin dashboard: analytics, case queue and reference data.
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final db = DatabaseHelper.instance;
  late final Stream<List<Report>> _stream = db.reportsStream(limit: 1000);
  bool _busy = false;

  Future<void> _run(Future<void> Function() job, String doneBn, String doneEn) async {
    setState(() => _busy = true);
    try {
      await job();
      if (mounted) showSnack(context, context.tr(doneBn, doneEn));
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.t('কর্তৃপক্ষ ড্যাশবোর্ড', 'Authority dashboard')),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: context.t('বিশ্লেষণ', 'Analytics')),
              Tab(text: context.t('কেস সারি', 'Case queue')),
              Tab(text: context.t('সেটিংস', 'Settings')),
            ],
          ),
        ),
        body: StreamBuilder<List<Report>>(
          stream: _stream,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final reports = snap.data!;
            return TabBarView(children: [
              _Analytics(reports),
              _Queue(reports),
              _settings(context),
            ]);
          },
        ),
      ),
    );
  }

  Widget _settings(BuildContext context) {
    final user = context.app.user!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_busy) const LinearProgressIndicator(),
      Card(
        child: ListTile(
          leading: const Icon(Icons.price_change),
          title: Text(context.t('পণ্যের রেফারেন্স দাম', 'Commodity reference prices')),
          subtitle: Text(context.t('টিসিবি/কৃষি বিপণন অধিদপ্তরের দৈনিক দর অনুযায়ী হালনাগাদ করুন', 'Update from TCB / DAM daily market rates')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommodityEditorPage())),
        ),
      ),
      const SizedBox(height: 10),
      Card(
        child: ListTile(
          leading: const Icon(Icons.directions_bus),
          title: Text(context.t('বাস ভাড়ার হার', 'Bus fare rates')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _editFares(context),
        ),
      ),
      const SizedBox(height: 10),
      Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_upload),
          title: Text(context.t('ডিফল্ট রেফারেন্স তথ্য লোড করুন', 'Load default reference data')),
          subtitle: Text(context.t('পণ্যের তালিকা ও ভাড়ার হার (একবার)', 'Commodity list and fare rates (once)')),
          onTap: _busy ? null : () => _run(db.seedReferenceData, 'লোড হয়েছে', 'Loaded'),
        ),
      ),
      const SizedBox(height: 24),
      Text(context.t('উপস্থাপনার জন্য ডেমো তথ্য', 'Demo data for presentations'), style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(
          context.t('সব ডেমো রেকর্ডে “DEMO” চিহ্ন থাকে এবং এক ক্লিকে মুছে ফেলা যায়।',
              'All demo records carry a "DEMO" badge and can be removed with one tap.'),
          style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : () => _run(() => db.seedDemoData(user), 'ডেমো তথ্য যুক্ত হয়েছে', 'Demo data added'),
            icon: const Icon(Icons.auto_awesome),
            label: Text(context.t('ডেমো যোগ', 'Add demo')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _busy ? null : () => _run(() async => db.clearDemoData(), 'ডেমো তথ্য মুছে ফেলা হয়েছে', 'Demo data removed'),
            icon: const Icon(Icons.delete_sweep),
            label: Text(context.t('ডেমো মুছুন', 'Clear demo')),
          ),
        ),
      ]),
    ]);
  }

  Future<void> _editFares(BuildContext context) async {
    final f = await db.fareStream().first;
    if (!context.mounted) return;
    final city = TextEditingController(text: '${f.cityBusPerKm}');
    final mini = TextEditingController(text: '${f.minibusPerKm}');
    final long = TextEditingController(text: '${f.longRoutePerKm}');
    final minF = TextEditingController(text: '${f.cityMinFare}');
    final src = TextEditingController(text: f.source);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final e in [
            [city, ctx.t('সিটি বাস (৳/কিমি)', 'City bus (Tk/km)')],
            [mini, ctx.t('মিনিবাস (৳/কিমি)', 'Minibus (Tk/km)')],
            [long, ctx.t('দূরপাল্লা (৳/কিমি)', 'Long route (Tk/km)')],
            [minF, ctx.t('সর্বনিম্ন ভাড়া (৳)', 'Minimum fare (Tk)')],
          ]) ...[
            TextField(
              controller: e[0] as TextEditingController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: e[1] as String),
            ),
            const SizedBox(height: 10),
          ],
          TextField(controller: src, decoration: InputDecoration(labelText: ctx.t('সূত্র', 'Source'))),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await db.saveFares(FareConfig(
                cityBusPerKm: double.tryParse(city.text) ?? f.cityBusPerKm,
                minibusPerKm: double.tryParse(mini.text) ?? f.minibusPerKm,
                longRoutePerKm: double.tryParse(long.text) ?? f.longRoutePerKm,
                cityMinFare: double.tryParse(minF.text) ?? f.cityMinFare,
                source: src.text.trim(),
                updatedAt: DateTime.now(),
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(ctx.t('সংরক্ষণ', 'Save')),
          ),
        ]),
      ),
    );
  }
}

class _Analytics extends StatelessWidget {
  final List<Report> reports;
  const _Analytics(this.reports);

  @override
  Widget build(BuildContext context) {
    final bySector = <String, int>{};
    final byDistrict = <String, int>{};
    final byStatus = <ReportStatus, int>{};
    final hotspots = <String, int>{};
    double money = 0;
    for (final r in reports) {
      bySector[r.sector] = (bySector[r.sector] ?? 0) + 1;
      byDistrict[r.district] = (byDistrict[r.district] ?? 0) + 1;
      byStatus[r.status] = (byStatus[r.status] ?? 0) + 1;
      final key = '${r.place.trim().toLowerCase()}|${r.district}';
      hotspots[key] = (hotspots[key] ?? 0) + 1 + r.supportCount;
      money += r.amount;
    }
    final sectors = bySector.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final districts = byDistrict.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final spots = hotspots.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final resolved = byStatus[ReportStatus.resolved] ?? 0;
    final pending = (byStatus[ReportStatus.submitted] ?? 0) + (byStatus[ReportStatus.reviewing] ?? 0);
    final maxSector = sectors.isEmpty ? 1 : sectors.first.value;

    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: [
          StatCard(label: context.t('মোট অভিযোগ', 'Total reports'), value: context.n(reports.length), icon: Icons.campaign, color: Colors.red),
          StatCard(label: context.t('অপেক্ষমাণ', 'Pending review'), value: context.n(pending), icon: Icons.hourglass_top, color: Colors.orange),
          StatCard(label: context.t('ব্যবস্থা নেওয়া হয়েছে', 'Action taken'), value: context.n(resolved), icon: Icons.task_alt, color: Colors.green),
          StatCard(
              label: context.t('জড়িত অর্থ', 'Money involved'),
              value: context.taka(money >= 100000 ? (money / 100000).roundToDouble() : money) + (money >= 100000 ? context.t(' লাখ', ' lakh') : ''),
              icon: Icons.payments,
              color: Colors.deepPurple),
        ],
      ),
      SectionTitle(context.t('খাতভিত্তিক অভিযোগ', 'Reports by sector')),
      SizedBox(
        height: 220,
        child: sectors.isEmpty
            ? Center(child: Text(context.t('তথ্য নেই', 'No data')))
            : BarChart(BarChartData(
                maxY: maxSector * 1.2,
                gridData: const FlGridData(drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, m) => Text(context.n(v.toInt()), style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i < 0 || i >= sectors.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(sectorById(sectors[i].key).icon, size: 18, color: sectorById(sectors[i].key).color),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < sectors.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: sectors[i].value.toDouble(),
                        width: 16,
                        color: sectorById(sectors[i].key).color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ]),
                ],
              )),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 4,
        children: sectors
            .map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(sectorById(e.key).icon, size: 14, color: sectorById(e.key).color),
                  const SizedBox(width: 4),
                  Text('${sectorById(e.key).name.of(context.isBn)} (${context.n(e.value)})', style: const TextStyle(fontSize: 12)),
                ]))
            .toList(),
      ),
      SectionTitle(context.t('অবস্থা অনুযায়ী', 'By status')),
      if (reports.isNotEmpty)
        SizedBox(
          height: 180,
          child: Row(children: [
            Expanded(
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: byStatus.entries
                    .map((e) => PieChartSectionData(
                          value: e.value.toDouble(),
                          color: statusColor(e.key),
                          title: context.n(e.value),
                          radius: 44,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ))
                    .toList(),
              )),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: byStatus.keys
                  .map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Icon(Icons.circle, size: 10, color: statusColor(s)),
                          const SizedBox(width: 6),
                          Text(statusLabel(s).of(context.isBn), style: const TextStyle(fontSize: 12)),
                        ]),
                      ))
                  .toList(),
            ),
          ]),
        ),
      SectionTitle(context.t('শীর্ষ জেলা', 'Top districts')),
      ...districts.take(8).map((e) => _BarRow(
            label: districtName(context, e.key),
            value: e.value,
            max: districts.first.value,
          )),
      SectionTitle(context.t('🔥 হটস্পট (স্থান + সমর্থন)', '🔥 Hotspots (place + corroboration)')),
      ...spots.take(8).map((e) {
        final parts = e.key.split('|');
        return ListTile(
          dense: true,
          leading: const Icon(Icons.local_fire_department, color: Colors.deepOrange),
          title: Text(parts[0]),
          subtitle: Text(districtName(context, parts.length > 1 ? parts[1] : '')),
          trailing: Text(context.n(e.value), style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      }),
      const SizedBox(height: 24),
    ]);
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  const _BarRow({required this.label, required this.value, required this.max});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(width: 100, child: Text(label, overflow: TextOverflow.ellipsis)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: value / (max == 0 ? 1 : max), minHeight: 14),
            ),
          ),
          const SizedBox(width: 8),
          Text(context.n(value), style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      );
}

class _Queue extends StatefulWidget {
  final List<Report> reports;
  const _Queue(this.reports);

  @override
  State<_Queue> createState() => _QueueState();
}

class _QueueState extends State<_Queue> {
  ReportStatus? _filter = ReportStatus.submitted;

  @override
  Widget build(BuildContext context) {
    final list = widget.reports.where((r) => _filter == null || r.status == _filter).toList()
      ..sort((a, b) => b.credibility.compareTo(a.credibility));
    return Column(children: [
      SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(context.t('সব', 'All')),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
            ),
            ...ReportStatus.values.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(statusLabel(s).of(context.isBn)),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = s),
                  ),
                )),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(context.t('বিশ্বাসযোগ্যতা স্কোর অনুযায়ী সাজানো', 'Sorted by credibility score'),
            style: Theme.of(context).textTheme.bodySmall),
      ),
      Expanded(
        child: list.isEmpty
            ? EmptyState(icon: Icons.inbox, text: context.t('কিছু নেই', 'Nothing here'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => ReportCard(list[i]),
              ),
      ),
    ]);
  }
}

class CommodityEditorPage extends StatefulWidget {
  const CommodityEditorPage({super.key});

  @override
  State<CommodityEditorPage> createState() => _CommodityEditorPageState();
}

class _CommodityEditorPageState extends State<CommodityEditorPage> {
  late final Stream<List<Commodity>> _stream = DatabaseHelper.instance.commoditiesStream();

  Future<void> _edit(Commodity? c) async {
    final id = TextEditingController(text: c?.id ?? '');
    final bn = TextEditingController(text: c?.nameBn ?? '');
    final en = TextEditingController(text: c?.nameEn ?? '');
    final icon = TextEditingController(text: c?.icon ?? '🛒');
    final min = TextEditingController(text: c == null ? '' : '${c.refMin}');
    final max = TextEditingController(text: c == null ? '' : '${c.refMax}');
    String unit = c?.unit ?? 'kg';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (c == null) ...[
                TextField(controller: id, decoration: const InputDecoration(labelText: 'ID (e.g. red_lentil)')),
                const SizedBox(height: 10),
              ],
              TextField(controller: bn, decoration: const InputDecoration(labelText: 'নাম (বাংলা)')),
              const SizedBox(height: 10),
              TextField(controller: en, decoration: const InputDecoration(labelText: 'Name (English)')),
              const SizedBox(height: 10),
              Row(children: [
                SizedBox(width: 80, child: TextField(controller: icon, decoration: const InputDecoration(labelText: 'Icon'))),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: unit,
                    decoration: InputDecoration(labelText: ctx.t('একক', 'Unit')),
                    items: ['kg', 'litre', 'dozen', 'piece', 'cylinder', 'maund']
                        .map((u) => DropdownMenuItem(value: u, child: Text(unitLabel(u).of(ctx.isBn))))
                        .toList(),
                    onChanged: (v) => setS(() => unit = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: min,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: ctx.t('সর্বনিম্ন ৳', 'Min Tk')))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        controller: max,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: ctx.t('সর্বোচ্চ ৳', 'Max Tk')))),
              ]),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final docId = c?.id ?? id.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
                  if (docId.isEmpty) return;
                  await DatabaseHelper.instance.saveCommodity(docId, {
                    'nameBn': bn.text.trim(),
                    'nameEn': en.text.trim(),
                    'icon': icon.text.trim(),
                    'unit': unit,
                    'refMin': double.tryParse(min.text) ?? 0,
                    'refMax': double.tryParse(max.text) ?? 0,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(ctx.t('সংরক্ষণ', 'Save')),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.t('রেফারেন্স দাম', 'Reference prices'))),
        floatingActionButton: FloatingActionButton(onPressed: () => _edit(null), child: const Icon(Icons.add)),
        body: StreamBuilder<List<Commodity>>(
          stream: _stream,
          builder: (context, snap) {
            final list = snap.data ?? [];
            return ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: list
                  .map((c) => ListTile(
                        leading: Text(c.icon, style: const TextStyle(fontSize: 26)),
                        title: Text(context.isBn ? c.nameBn : c.nameEn),
                        subtitle: Text('${context.taka(c.refMin)} – ${context.taka(c.refMax)} / ${unitLabel(c.unit).of(context.isBn)}'),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _edit(c),
                      ))
                  .toList(),
            );
          },
        ),
      );
}
