import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../database_helper.dart';
import '../models.dart';
import 'report_form_page.dart';

class FareCalculatorPage extends StatefulWidget {
  const FareCalculatorPage({super.key});

  @override
  State<FareCalculatorPage> createState() => _FareCalculatorPageState();
}

class _FareCalculatorPageState extends State<FareCalculatorPage> {
  late final Stream<FareConfig> _stream = DatabaseHelper.instance.fareStream();
  final _km = TextEditingController();
  final _paid = TextEditingController();
  final _route = TextEditingController();
  String _type = 'city';

  double _fare(FareConfig f, double km) {
    switch (_type) {
      case 'long':
        return (km * f.longRoutePerKm).roundToDouble();
      case 'minibus':
        return max(f.cityMinFare, (km * f.minibusPerKm).roundToDouble());
      default:
        return max(f.cityMinFare, (km * f.cityBusPerKm).roundToDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('ভাড়া ক্যালকুলেটর', 'Fare calculator'))),
      body: StreamBuilder<FareConfig>(
        stream: _stream,
        builder: (context, snap) {
          final f = snap.data ?? FareConfig.defaults;
          final km = double.tryParse(_km.text) ?? 0;
          final paid = double.tryParse(_paid.text) ?? 0;
          final fare = km > 0 ? _fare(f, km) : 0.0;
          final over = paid - fare;
          final rate = _type == 'long' ? f.longRoutePerKm : (_type == 'minibus' ? f.minibusPerKm : f.cityBusPerKm);
          return ListView(padding: const EdgeInsets.all(16), children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'city', label: Text(context.t('সিটি বাস', 'City bus'))),
                ButtonSegment(value: 'minibus', label: Text(context.t('মিনিবাস', 'Minibus'))),
                ButtonSegment(value: 'long', label: Text(context.t('দূরপাল্লা', 'Long route'))),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _route,
              decoration: InputDecoration(
                labelText: context.t('রুট (যেমন: মিরপুর–মতিঝিল)', 'Route (e.g. Mirpur–Motijheel)'),
                prefixIcon: const Icon(Icons.alt_route),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _km,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.t('দূরত্ব (কিলোমিটার)', 'Distance (km)'),
                prefixIcon: const Icon(Icons.straighten),
                helperText: context.t('গুগল ম্যাপ থেকে দূরত্ব দেখে নিতে পারেন', 'You can check distance on Google Maps'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paid,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.t('আপনার কাছ থেকে নেওয়া ভাড়া (৳)', 'Fare you were charged (Tk)'),
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text(context.t('সরকার নির্ধারিত ভাড়া', 'Government-set fare'), style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(km > 0 ? context.taka(fare) : '—',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 6),
                  Text(
                    context.t('হার: প্রতি কিমি ${context.taka(rate)}${_type == 'long' ? '' : ' • সর্বনিম্ন ${context.taka(f.cityMinFare)}'}',
                        'Rate: ${context.taka(rate)}/km${_type == 'long' ? '' : ' • minimum ${context.taka(f.cityMinFare)}'}'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(context.t('সূত্র: ${f.source}', 'Source: ${f.source}'), style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
            if (km > 0 && paid > 0) ...[
              const SizedBox(height: 12),
              Card(
                color: (over > 0 ? Colors.red : Colors.green).withValues(alpha: 0.1),
                child: ListTile(
                  leading: Icon(over > 0 ? Icons.error : Icons.check_circle, color: over > 0 ? Colors.red : Colors.green, size: 32),
                  title: Text(over > 0
                      ? context.t('${context.taka(over)} বেশি নেওয়া হয়েছে', 'Overcharged by ${context.taka(over)}')
                      : context.t('ভাড়া ন্যায্য', 'Fare is fair')),
                  subtitle: over > 0
                      ? Text(context.t('${context.n((over / fare * 100).toStringAsFixed(0))}% বেশি', '${(over / fare * 100).toStringAsFixed(0)}% above the lawful fare'))
                      : null,
                ),
              ),
              if (over > 0) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
                  icon: const Icon(Icons.campaign),
                  label: Text(context.t('অতিরিক্ত ভাড়ার অভিযোগ করুন', 'Report overcharging')),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportFormPage(
                        sectorId: 'transport',
                        issueType: 'Overcharged fare',
                        prefillAmount: over,
                        prefillDescription: context.tr(
                          'রুট: ${_route.text}। দূরত্ব ${_km.text} কিমি। সরকারি ভাড়া ৳${fare.toStringAsFixed(0)}, কিন্তু নেওয়া হয়েছে ৳${_paid.text}।',
                          'Route: ${_route.text}. Distance ${_km.text} km. Lawful fare Tk ${fare.toStringAsFixed(0)}, but charged Tk ${_paid.text}.',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            Text(
              context.t(
                  'বিআরটিএ নির্ধারিত হারে হিসাব। প্রকৃত রুটভিত্তিক চার্ট বিআরটিএ প্রকাশ করে; অ্যাডমিন হার হালনাগাদ রাখেন।',
                  'Calculated with BRTA per-km rates. BRTA publishes route-wise charts; admins keep the rates updated.'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ]);
        },
      ),
    );
  }
}
