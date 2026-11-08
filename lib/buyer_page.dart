// buyer_page.dart — Direct Market: buy straight from farmers & producers.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/widgets.dart';
import 'data/sectors.dart';
import 'database_helper.dart';
import 'models.dart';
import 'seller_page.dart';

const kListingCategories = <String, BT>{
  'grain': BT('চাল-ডাল', 'Rice & lentils'),
  'vegetable': BT('সবজি', 'Vegetables'),
  'fruit': BT('ফল', 'Fruits'),
  'fish': BT('মাছ', 'Fish'),
  'meat_egg': BT('মাংস ও ডিম', 'Meat & eggs'),
  'dairy': BT('দুধ', 'Dairy'),
  'spice': BT('মসলা', 'Spices'),
  'other': BT('অন্যান্য', 'Other'),
};

class BuyerPage extends StatefulWidget {
  const BuyerPage({super.key});

  @override
  State<BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {
  final db = DatabaseHelper.instance;
  late final Stream<List<Listing>> _listings = db.listingsStream();
  late final Stream<List<Commodity>> _commodities = db.commoditiesStream();
  String _district = '';
  String _category = '';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _district = context.read<AppState>().user?.district ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('সরাসরি বাজার', 'Direct Market'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerPage())),
        icon: const Icon(Icons.add_business),
        label: Text(context.t('বিক্রি করুন', 'Sell')),
      ),
      body: StreamBuilder<List<Commodity>>(
        stream: _commodities,
        builder: (context, cs) {
          final refs = {for (final c in cs.data ?? <Commodity>[]) c.id: c};
          return StreamBuilder<List<Listing>>(
            stream: _listings,
            builder: (context, snap) {
              final q = _search.text.trim().toLowerCase();
              final list = (snap.data ?? [])
                  .where((l) => _district.isEmpty || l.district == _district)
                  .where((l) => _category.isEmpty || l.category == _category)
                  .where((l) => q.isEmpty || l.product.toLowerCase().contains(q))
                  .toList();
              return ListView(padding: const EdgeInsets.only(bottom: 100), children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const Icon(Icons.handshake, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(context.t(
                          'মধ্যস্বত্বভোগী ছাড়া সরাসরি কৃষক ও উৎপাদকের কাছ থেকে কিনুন — কৃষক পান ন্যায্য দাম, আপনি পান কম দামে।',
                          'Buy directly from farmers and producers without middlemen — farmers earn more, you pay less.')),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: context.t('পণ্য খুঁজুন', 'Search products'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DistrictField(value: _district, allowAll: true, onChanged: (v) => setState(() => _district = v ?? '')),
                ),
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
                          selected: _category.isEmpty,
                          onSelected: (_) => setState(() => _category = ''),
                        ),
                      ),
                      ...kListingCategories.entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(e.value.of(context.isBn)),
                              selected: _category == e.key,
                              onSelected: (_) => setState(() => _category = e.key),
                            ),
                          )),
                    ],
                  ),
                ),
                if (!snap.hasData)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (list.isEmpty)
                  EmptyState(
                      icon: Icons.storefront_outlined,
                      text: context.t('এই এলাকায় এখনো কোনো পণ্য নেই', 'No products in this area yet'))
                else
                  ...list.map((l) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: ListingCard(l, ref: l.commodityId == null ? null : refs[l.commodityId]),
                      )),
              ]);
            },
          );
        },
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  final Listing l;
  final Commodity? ref;
  final Widget? trailing;
  const ListingCard(this.l, {super.key, this.ref, this.trailing});

  @override
  Widget build(BuildContext context) {
    final unit = unitLabel(l.unit).of(context.isBn);
    final fair = ref != null && ref!.unit == l.unit && l.price <= ref!.refMax;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(l.product, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (fair)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(context.t('ন্যায্য দাম', 'Fair price'), style: const TextStyle(color: Colors.green, fontSize: 12)),
                ]),
              ),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 4),
          Text('${context.taka(l.price)} / $unit',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          if (ref != null && ref!.unit == l.unit)
            Text(context.t('বাজার রেফারেন্স: ${context.taka(ref!.refMin)}–${context.taka(ref!.refMax)}',
                'Market reference: ${context.taka(ref!.refMin)}–${context.taka(ref!.refMax)}'),
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.inventory_2_outlined, size: 16, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 4),
            Text(context.t('মজুত: ${context.n(l.quantity.toStringAsFixed(0))} $unit', 'Stock: ${l.quantity.toStringAsFixed(0)} $unit'),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 12),
            Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 4),
            Expanded(child: Text(districtName(context, l.district), style: Theme.of(context).textTheme.bodySmall)),
          ]),
          const Divider(height: 20),
          Row(children: [
            const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text(l.sellerName)),
            FilledButton.tonalIcon(
              onPressed: () => callNumber(context, l.sellerPhone),
              icon: const Icon(Icons.call, size: 18),
              label: Text(context.t('কল করুন', 'Call')),
            ),
          ]),
        ]),
      ),
    );
  }
}
