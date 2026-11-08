import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/widgets.dart';
import '../data/sectors.dart';
import '../database_helper.dart';
import '../models.dart';
import 'report_form_page.dart';

double median(List<double> v) {
  if (v.isEmpty) return 0;
  final s = [...v]..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
}

/// Market price summary for one commodity.
class PriceSummary {
  final Commodity c;
  final double retail; // median retail price, last 7 days (0 = no data)
  final double farmgate; // median farm-gate price, last 14 days
  final int samples;
  PriceSummary(this.c, this.retail, this.farmgate, this.samples);

  bool get hasData => samples > 0;
  double get overPct => (hasData && c.refMax > 0) ? (retail - c.refMax) / c.refMax * 100 : 0;
  bool get isOver => overPct > 5;
  bool get isSpike => overPct > 15;
  double get middlemanPct => (farmgate > 0 && retail > 0) ? (retail - farmgate) / retail * 100 : 0;
}

List<PriceSummary> summarize(List<Commodity> cs, List<PriceObservation> obs, {String? district}) {
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  return cs.map((c) {
    final mine = obs.where((o) => o.commodityId == c.id && (district == null || district.isEmpty || o.district == district));
    final retail = mine.where((o) => o.kind == 'retail' && o.createdAt.isAfter(weekAgo)).map((o) => o.price).toList();
    final farm = mine.where((o) => o.kind == 'farmgate').map((o) => o.price).toList();
    return PriceSummary(c, median(retail), median(farm), retail.length);
  }).toList();
}

Color priceColor(PriceSummary s) {
  if (!s.hasData) return Colors.grey;
  if (s.isSpike) return const Color(0xFFC0392B);
  if (s.isOver) return const Color(0xFFE67E22);
  return const Color(0xFF27AE60);
}

/// Horizontal strip of the worst over-priced items, used on the home screen.
class PriceAlertStrip extends StatelessWidget {
  final String? district;
  final VoidCallback onOpen;
  const PriceAlertStrip({super.key, this.district, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper.instance;
    return StreamBuilder<List<Commodity>>(
      stream: db.commoditiesStream(),
      builder: (context, cs) => StreamBuilder<List<PriceObservation>>(
        stream: db.recentPricesStream(),
        builder: (context, ps) {
          final list = summarize(cs.data ?? [], ps.data ?? [])
              .where((s) => s.isOver)
              .toList()
            ..sort((a, b) => b.overPct.compareTo(a.overPct));
          if (list.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionTitle(context.t('⚠️ দাম সতর্কতা', '⚠️ Price alerts'),
                trailing: TextButton(onPressed: onOpen, child: Text(context.t('সব দেখুন', 'See all')))),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length.clamp(0, 6),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final s = list[i];
                  return Card(
                    color: priceColor(s).withValues(alpha: 0.08),
                    child: Container(
                      width: 170,
                      padding: const EdgeInsets.all(10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${s.c.icon} ${context.isBn ? s.c.nameBn : s.c.nameEn}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(context.taka(s.retail), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(context.t('রেফারেন্সের চেয়ে ${context.n(s.overPct.toStringAsFixed(0))}% বেশি',
                            '${s.overPct.toStringAsFixed(0)}% above reference'),
                            style: TextStyle(color: priceColor(s), fontSize: 12)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class PricesPage extends StatefulWidget {
  const PricesPage({super.key});

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  final db = DatabaseHelper.instance;
  late final Stream<List<Commodity>> _cs = db.commoditiesStream();
  late final Stream<List<PriceObservation>> _ps = db.recentPricesStream();
  String _district = '';
  bool _middleman = false;

  @override
  void initState() {
    super.initState();
    _district = context.read<AppState>().user?.district ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('ন্যায্যমূল্য বোর্ড', 'Fair-Price Board')),
        actions: [
          IconButton(
            tooltip: context.t('দাম জানান', 'Report a price'),
            icon: const Icon(Icons.add_chart),
            onPressed: () => showPriceSubmitSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Commodity>>(
        stream: _cs,
        builder: (context, cs) => StreamBuilder<List<PriceObservation>>(
          stream: _ps,
          builder: (context, ps) {
            if (!cs.hasData) return const Center(child: CircularProgressIndicator());
            final commodities = cs.data!;
            if (commodities.isEmpty) {
              return EmptyState(
                  icon: Icons.price_change_outlined,
                  text: context.t('এখনো কোনো পণ্যের রেফারেন্স দাম যোগ করা হয়নি। অ্যাডমিন প্যানেল থেকে যোগ করুন।',
                      'No reference prices yet. An admin can add them from the admin panel.'));
            }
            final obs = ps.data ?? [];
            final list = summarize(commodities, obs, district: _district);
            final over = list.where((s) => s.isOver).length;
            return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: DistrictField(
                  value: _district,
                  allowAll: true,
                  onChanged: (v) => setState(() => _district = v ?? ''),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, icon: const Icon(Icons.store), label: Text(context.t('খুচরা দাম', 'Retail price'))),
                    ButtonSegment(value: true, icon: const Icon(Icons.agriculture), label: Text(context.t('মধ্যস্বত্ব মিটার', 'Middleman meter'))),
                  ],
                  selected: {_middleman},
                  onSelectionChanged: (s) => setState(() => _middleman = s.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Card(
                  color: (over > 0 ? Colors.orange : Colors.green).withValues(alpha: 0.08),
                  child: ListTile(
                    leading: Icon(over > 0 ? Icons.warning_amber : Icons.check_circle,
                        color: over > 0 ? Colors.orange : Colors.green),
                    title: Text(_middleman
                        ? context.t('কৃষক কত পান আর আপনি কত দেন', 'What farmers get vs what you pay')
                        : context.t('${context.n(over)}টি পণ্য রেফারেন্স দামের চেয়ে বেশি', '$over items above reference price')),
                    subtitle: Text(context.t(
                        'গত ৭ দিনে নাগরিকদের জানানো দামের মধ্যমা (median)। রেফারেন্স দাম অ্যাডমিন হালনাগাদ করেন।',
                        'Median of citizen-reported prices in the last 7 days. Reference prices are set by admins.')),
                  ),
                ),
              ),
              ...list.map((s) => _middleman ? _MiddlemanTile(s) : _PriceTile(s, obs: obs, district: _district)),
            ]);
          },
        ),
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  final PriceSummary s;
  final List<PriceObservation> obs;
  final String district;
  const _PriceTile(this.s, {required this.obs, required this.district});

  @override
  Widget build(BuildContext context) {
    final unit = unitLabel(s.c.unit).of(context.isBn);
    final color = priceColor(s);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => CommodityDetailPage(c: s.c, obs: obs, district: district))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Text(s.c.icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.isBn ? s.c.nameBn : s.c.nameEn, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                      context.t('রেফারেন্স: ${context.taka(s.c.refMin)}–${context.taka(s.c.refMax)}/$unit',
                          'Reference: ${context.taka(s.c.refMin)}–${context.taka(s.c.refMax)}/$unit'),
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(s.hasData ? context.taka(s.retail) : '—',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
                Text(
                  !s.hasData
                      ? context.t('তথ্য নেই', 'No data')
                      : s.isSpike
                          ? context.t('অস্বাভাবিক বেশি', 'Price spike')
                          : s.isOver
                              ? context.t('বেশি', 'Above fair')
                              : context.t('ন্যায্য', 'Fair'),
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _MiddlemanTile extends StatelessWidget {
  final PriceSummary s;
  const _MiddlemanTile(this.s);

  @override
  Widget build(BuildContext context) {
    final has = s.farmgate > 0 && s.retail > 0;
    final pct = s.middlemanPct.clamp(0, 100) / 100;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(s.c.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(child: Text(context.isBn ? s.c.nameBn : s.c.nameEn, style: const TextStyle(fontWeight: FontWeight.w600))),
              if (has)
                Text(context.t('মধ্যস্বত্ব ${context.n(s.middlemanPct.toStringAsFixed(0))}%', 'Middlemen ${s.middlemanPct.toStringAsFixed(0)}%'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
            ]),
            const SizedBox(height: 10),
            if (!has)
              Text(context.t('মাঠ পর্যায়ের দামের তথ্য নেই — কৃষকরা দাম জানালে দেখা যাবে।', 'No farm-gate data yet — appears when farmers report prices.'),
                  style: Theme.of(context).textTheme.bodySmall)
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(children: [
                  Expanded(
                    flex: ((1 - pct) * 100).round().clamp(1, 100),
                    child: Container(height: 14, color: const Color(0xFF27AE60)),
                  ),
                  Expanded(
                    flex: (pct * 100).round().clamp(1, 100),
                    child: Container(height: 14, color: const Color(0xFFC0392B)),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(context.t('কৃষক পান ${context.taka(s.farmgate)}', 'Farmer gets ${context.taka(s.farmgate)}'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF27AE60))),
                Text(context.t('আপনি দেন ${context.taka(s.retail)}', 'You pay ${context.taka(s.retail)}'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFFC0392B))),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

class CommodityDetailPage extends StatelessWidget {
  final Commodity c;
  final List<PriceObservation> obs;
  final String district;
  const CommodityDetailPage({super.key, required this.c, required this.obs, required this.district});

  @override
  Widget build(BuildContext context) {
    final mine = obs.where((o) => o.commodityId == c.id && o.kind == 'retail').toList();
    // Daily median over the last 14 days (national).
    final today = DateTime.now();
    final spots = <FlSpot>[];
    for (var d = 13; d >= 0; d--) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: d));
      final vals = mine
          .where((o) => o.createdAt.year == day.year && o.createdAt.month == day.month && o.createdAt.day == day.day)
          .map((o) => o.price)
          .toList();
      if (vals.isNotEmpty) spots.add(FlSpot((13 - d).toDouble(), median(vals)));
    }
    // District ranking by median.
    final byDistrict = <String, List<double>>{};
    for (final o in mine) {
      byDistrict.putIfAbsent(o.district, () => []).add(o.price);
    }
    final ranking = byDistrict.entries.map((e) => MapEntry(e.key, median(e.value))).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final unit = unitLabel(c.unit).of(context.isBn);
    final maxY = [c.refMax * 1.4, ...spots.map((s) => s.y * 1.1)].reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text('${c.icon} ${context.isBn ? c.nameBn : c.nameEn}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPriceSubmitSheet(context, commodity: c),
        icon: const Icon(Icons.add),
        label: Text(context.t('দাম জানান', 'Report price')),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(context.t('রেফারেন্স দাম: ${context.taka(c.refMin)} – ${context.taka(c.refMax)} / $unit',
            'Reference price: ${context.taka(c.refMin)} – ${context.taka(c.refMax)} / $unit'),
            style: Theme.of(context).textTheme.titleMedium),
        Text(context.t('হালনাগাদ: ${fmtDate(context, c.updatedAt)}', 'Updated: ${fmtDate(context, c.updatedAt)}'),
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Text(context.t('১৪ দিনের প্রবণতা (জাতীয় মধ্যমা)', '14-day trend (national median)'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: spots.isEmpty
              ? Center(child: Text(context.t('পর্যাপ্ত তথ্য নেই', 'Not enough data')))
              : LineChart(LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 3,
                        getTitlesWidget: (v, m) {
                          final day = today.subtract(Duration(days: 13 - v.toInt()));
                          return Text(context.n(day.day), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, m) => Text(context.n(v.toInt()), style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: c.refMax,
                      color: Colors.red.withValues(alpha: 0.6),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) => context.tr('সর্বোচ্চ ন্যায্য', 'Fair max'),
                        style: const TextStyle(fontSize: 10, color: Colors.red),
                      ),
                    ),
                  ]),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                  ],
                )),
        ),
        const SizedBox(height: 20),
        Text(context.t('জেলাভিত্তিক দাম (বেশি থেকে কম)', 'Price by district (highest first)'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (ranking.isEmpty) Text(context.t('তথ্য নেই', 'No data')),
        ...ranking.take(15).map((e) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.location_on, color: e.value > c.refMax ? Colors.red : Colors.green),
              title: Text(districtName(context, e.key)),
              trailing: Text(context.taka(e.value), style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ReportFormPage(
                        sectorId: c.id.startsWith('lpg') ? 'utilities' : 'food',
                        prefillDescription: context.tr(
                            '${c.nameBn} রেফারেন্স দামের চেয়ে বেশিতে বিক্রি হচ্ছে।', '${c.nameEn} is being sold above the reference price.'),
                      ))),
          icon: const Icon(Icons.campaign),
          label: Text(context.t('অতিরিক্ত দামের অভিযোগ করুন', 'Report overpricing')),
        ),
        const SizedBox(height: 80),
      ]),
    );
  }
}

/// Bottom sheet for citizens (or farmers) to report an observed price.
Future<void> showPriceSubmitSheet(BuildContext context, {Commodity? commodity}) async {
  final db = DatabaseHelper.instance;
  final user = context.read<AppState>().user;
  final commodities = await db.commoditiesStream().first;
  if (!context.mounted) return;
  String? cid = commodity?.id ?? (commodities.isEmpty ? null : commodities.first.id);
  String? district = user?.district;
  String kind = user?.isSeller == true ? 'farmgate' : 'retail';
  final market = TextEditingController();
  final price = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(ctx.t('আজকের বাজারদর জানান', "Report today's market price"),
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: cid,
              isExpanded: true,
              decoration: InputDecoration(labelText: ctx.t('পণ্য', 'Item')),
              items: commodities
                  .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.icon} ${ctx.isBn ? c.nameBn : c.nameEn}')))
                  .toList(),
              onChanged: (v) => setS(() => cid = v),
            ),
            const SizedBox(height: 12),
            DistrictField(value: district, onChanged: (v) => setS(() => district = v)),
            const SizedBox(height: 12),
            TextFormField(
              controller: market,
              decoration: InputDecoration(labelText: ctx.t('বাজারের নাম', 'Market name'), prefixIcon: const Icon(Icons.store)),
              validator: (v) => (v ?? '').trim().isEmpty ? ctx.tr('বাজারের নাম লিখুন', 'Enter market name') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: ctx.t('দাম (টাকা, প্রতি একক)', 'Price (Tk per unit)'),
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              validator: (v) {
                final p = double.tryParse(v ?? '');
                return (p == null || p <= 0 || p > 100000) ? ctx.tr('সঠিক দাম দিন', 'Enter a valid price') : null;
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'retail', label: Text(ctx.t('খুচরা (ক্রেতা)', 'Retail (buyer)'))),
                ButtonSegment(value: 'farmgate', label: Text(ctx.t('মাঠ পর্যায় (কৃষক)', 'Farm-gate (farmer)'))),
              ],
              selected: {kind},
              onSelectionChanged: (s) => setS(() => kind = s.first),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (cid == null || district == null || !formKey.currentState!.validate()) return;
                await db.submitPrice(
                  commodityId: cid!,
                  district: district!,
                  market: market.text.trim(),
                  price: double.parse(price.text),
                  kind: kind,
                );
                if (ctx.mounted) {
                  final messenger = ScaffoldMessenger.of(ctx);
                  final msg = ctx.tr('ধন্যবাদ! দাম যুক্ত হয়েছে।', 'Thank you! Price added.');
                  Navigator.pop(ctx);
                  messenger.showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
                }
              },
              child: Text(ctx.t('জমা দিন', 'Submit')),
            ),
          ]),
        ),
      ),
    ),
  );
}
