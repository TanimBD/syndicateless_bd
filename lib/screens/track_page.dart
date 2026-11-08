import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/widgets.dart';
import '../database_helper.dart';
import '../models.dart';
import 'report_detail_page.dart';
import 'reports_feed_page.dart';

/// Track a report by its code, and list the reports made from this device.
class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final _code = TextEditingController();
  late final Stream<List<Report>> _mine = DatabaseHelper.instance.myReportsStream();
  bool _busy = false;

  Future<void> _find() async {
    if (_code.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final r = await DatabaseHelper.instance.findByCode(_code.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r == null) {
      showSnack(context, context.tr('এই কোডের কোনো অভিযোগ পাওয়া যায়নি', 'No report found with this code'), error: true);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailPage(reportId: r.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('অভিযোগ ট্র্যাক করুন', 'Track a report'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: context.t('ট্র্যাকিং কোড', 'Tracking code'),
            hintText: 'SBD-26-XXXXXX',
            prefixIcon: const Icon(Icons.qr_code),
            suffixIcon: _busy
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(icon: const Icon(Icons.search), onPressed: _find),
          ),
          onSubmitted: (_) => _find(),
        ),
        SectionTitle(context.t('আমার অভিযোগসমূহ', 'My reports')),
        StreamBuilder<List<Report>>(
          stream: _mine,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final list = snap.data!;
            if (list.isEmpty) {
              return EmptyState(
                  icon: Icons.assignment_outlined,
                  text: context.t('এই ডিভাইস থেকে কোনো অভিযোগ করা হয়নি', 'No reports made from this device yet'));
            }
            return Column(
              children: list.map((r) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ReportCard(r))).toList(),
            );
          },
        ),
      ]),
    );
  }
}
