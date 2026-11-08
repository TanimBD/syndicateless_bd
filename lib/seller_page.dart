// seller_page.dart — add and manage Direct Market listings.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'buyer_page.dart';
import 'core/app_state.dart';
import 'core/widgets.dart';
import 'data/sectors.dart';
import 'database_helper.dart';
import 'models.dart';

class SellerPage extends StatefulWidget {
  const SellerPage({super.key});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final db = DatabaseHelper.instance;
  late final Stream<List<Listing>> _mine = db.myListingsStream();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('আমার বিক্রয় তালিকা', 'My listings'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingPage())),
        icon: const Icon(Icons.add),
        label: Text(context.t('নতুন পণ্য', 'New product')),
      ),
      body: StreamBuilder<List<Listing>>(
        stream: _mine,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return EmptyState(
                icon: Icons.inventory_2_outlined,
                text: context.t('আপনার কোনো পণ্য তালিকাভুক্ত নেই। “নতুন পণ্য” চাপুন।', 'You have no listings. Tap "New product".'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final l = list[i];
              return Opacity(
                opacity: l.active ? 1 : 0.5,
                child: ListingCard(
                  l,
                  trailing: Switch(
                    value: l.active,
                    onChanged: (v) => db.setListingActive(l.id, v),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _product = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();
  String _category = 'vegetable';
  String _unit = 'kg';
  String? _commodityId;
  String? _district;
  bool _busy = false;
  late final Stream<List<Commodity>> _commodities = DatabaseHelper.instance.commoditiesStream();

  @override
  void initState() {
    super.initState();
    _district = context.read<AppState>().user?.district;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final u = context.read<AppState>().user!;
    setState(() => _busy = true);
    try {
      await DatabaseHelper.instance.addListing({
        'product': _product.text.trim(),
        'category': _category,
        'price': double.parse(_price.text),
        'unit': _unit,
        'quantity': double.tryParse(_qty.text) ?? 0,
        'district': _district,
        'sellerName': u.name,
        'sellerPhone': u.phone,
        'commodityId': _commodityId,
      });
      if (mounted) {
        showSnack(context, context.tr('পণ্য যুক্ত হয়েছে', 'Product listed'));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: Text(context.t('নতুন পণ্য বিক্রি', 'List a product'))),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          StreamBuilder<List<Commodity>>(
            stream: _commodities,
            builder: (context, snap) {
              final cs = snap.data ?? [];
              return DropdownButtonFormField<String?>(
                value: _commodityId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.t('বাজার তালিকার পণ্য (ঐচ্ছিক)', 'Match a market item (optional)'),
                  helperText: context.t('মেলালে ক্রেতারা “ন্যায্য দাম” চিহ্ন দেখবেন', 'Matching shows buyers a "Fair price" badge'),
                ),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(context.t('কোনোটি নয়', 'None'))),
                  ...cs.map((c) => DropdownMenuItem<String?>(
                      value: c.id, child: Text('${c.icon} ${context.isBn ? c.nameBn : c.nameEn}'))),
                ],
                onChanged: (v) => setState(() {
                  _commodityId = v;
                  final c = cs.where((c) => c.id == v).firstOrNull;
                  if (c != null) {
                    _unit = c.unit;
                    if (_product.text.isEmpty) _product.text = context.tr(c.nameBn, c.nameEn);
                  }
                }),
              );
            },
          ),
          gap,
          TextFormField(
            controller: _product,
            decoration: InputDecoration(labelText: context.t('পণ্যের নাম', 'Product name'), prefixIcon: const Icon(Icons.shopping_basket)),
            validator: (v) => (v ?? '').trim().length < 2 ? context.tr('নাম লিখুন', 'Enter a name') : null,
          ),
          gap,
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(labelText: context.t('ধরন', 'Category')),
            items: kListingCategories.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.of(context.isBn))))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          gap,
          Row(children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: context.t('দাম (৳)', 'Price (Tk)'), prefixText: '৳ '),
                validator: (v) {
                  final p = double.tryParse(v ?? '');
                  return (p == null || p <= 0) ? context.tr('সঠিক দাম', 'Valid price') : null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _unit,
                decoration: InputDecoration(labelText: context.t('প্রতি', 'Per')),
                items: ['kg', 'maund', 'litre', 'dozen', 'piece']
                    .map((u) => DropdownMenuItem(value: u, child: Text(unitLabel(u).of(context.isBn))))
                    .toList(),
                onChanged: (v) => setState(() => _unit = v!),
              ),
            ),
          ]),
          gap,
          TextFormField(
            controller: _qty,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.t('মোট পরিমাণ (মজুত)', 'Quantity available'), prefixIcon: const Icon(Icons.inventory)),
          ),
          gap,
          DistrictField(value: _district, onChanged: (v) => setState(() => _district = v)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(context.t('তালিকাভুক্ত করুন', 'Publish listing')),
          ),
        ]),
      ),
    );
  }
}
