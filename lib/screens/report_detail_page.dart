import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/widgets.dart';
import '../data/sectors.dart';
import '../database_helper.dart';
import '../models.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;
  const ReportDetailPage({super.key, required this.reportId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final db = DatabaseHelper.instance;
  late final Stream<Report> _stream = db.reportStream(widget.reportId);
  bool _supported = false;

  @override
  void initState() {
    super.initState();
    db.hasSupported(widget.reportId).then((v) {
      if (mounted) setState(() => _supported = v);
    });
  }

  Future<void> _support() async {
    final ok = await db.supportReport(widget.reportId);
    if (!mounted) return;
    setState(() => _supported = true);
    showSnack(context, ok
        ? context.tr('আপনার সমর্থন যুক্ত হয়েছে', 'Your support was added')
        : context.tr('আপনি আগেই সমর্থন করেছেন', 'You already supported this'));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AppState>().isAdmin;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('অভিযোগের বিস্তারিত', 'Report details'))),
      body: StreamBuilder<Report>(
        stream: _stream,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final r = snap.data!;
          final s = sectorById(r.sector);
          final mine = r.ownerUid == db.uid;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Icon(s.icon, color: s.color),
              const SizedBox(width: 8),
              Expanded(child: Text(s.name.of(context.isBn), style: TextStyle(color: s.color, fontWeight: FontWeight.w600))),
              if (r.isDemo) const DemoBadge(),
            ]),
            const SizedBox(height: 8),
            Text(issueLabel(context, r), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              StatusChip(r.status),
              const Spacer(),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: r.code));
                  showSnack(context, context.tr('কোড কপি হয়েছে', 'Code copied'));
                },
                child: Row(children: [
                  Text(r.code, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy, size: 14),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            _info(context, Icons.place_outlined, '${r.place}, ${districtName(context, r.district)}'),
            _info(context, Icons.schedule, fmtDate(context, r.createdAt)),
            if (r.amount > 0)
              _info(context, Icons.payments_outlined,
                  context.t('জড়িত অর্থ: ${context.taka(r.amount)}', 'Money involved: ${context.taka(r.amount)}')),
            _info(context, Icons.person_outline,
                r.anonymous ? context.t('বেনামি অভিযোগকারী', 'Anonymous reporter') : r.reporterName),
            const SizedBox(height: 12),
            Text(r.description, style: const TextStyle(fontSize: 15, height: 1.5)),
            if (r.imageBase64 != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(base64Decode(r.imageBase64!), fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(context.t('বিশ্বাসযোগ্যতা স্কোর', 'Credibility score'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${context.n(r.credibility)}/${context.n(100)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: r.credibility / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: r.credibility >= 60 ? Colors.green : (r.credibility >= 35 ? Colors.orange : Colors.red),
                  ),
                  const SizedBox(height: 6),
                  Text(
                      context.t('অন্য নাগরিকদের সমর্থন, ছবি-প্রমাণ ও কর্তৃপক্ষের যাচাইয়ের ভিত্তিতে গণনা করা হয়।',
                          'Based on corroboration by other citizens, photo evidence and official verification.'),
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            if (!mine)
              FilledButton.tonalIcon(
                onPressed: _supported ? null : _support,
                icon: Icon(_supported ? Icons.check : Icons.front_hand),
                label: Text(_supported
                    ? context.t('আপনি সমর্থন করেছেন (${context.n(r.supportCount)})', 'You supported this (${r.supportCount})')
                    : context.t('আমিও এই সমস্যায় পড়েছি (${context.n(r.supportCount)})', 'I faced this too (${r.supportCount})')),
              ),
            if (r.authorityNote.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.withValues(alpha: 0.08),
                child: ListTile(
                  leading: const Icon(Icons.account_balance, color: Colors.blue),
                  title: Text(context.t('কর্তৃপক্ষের মন্তব্য', 'Authority note')),
                  subtitle: Text(r.authorityNote),
                ),
              ),
            ],
            SectionTitle(context.t('অগ্রগতি', 'Progress')),
            ...r.history.reversed.map((h) {
              final st = statusFrom(h['status']);
              final at = h['at'] is Timestamp ? (h['at'] as Timestamp).toDate() : r.createdAt;
              return ListTile(
                dense: true,
                leading: Icon(Icons.circle, size: 14, color: statusColor(st)),
                title: Text(statusLabel(st).of(context.isBn), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text([fmtDate(context, at), if ((h['note'] ?? '').toString().isNotEmpty) h['note']].join('\n')),
              );
            }),
            SectionTitle(context.t('সংশ্লিষ্ট কর্তৃপক্ষ', 'Responsible authority')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(s.authority.of(context.isBn)),
            ),
            ...s.hotlines.map((h) => HotlineTile(h)),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => showStatusSheet(context, r),
                icon: const Icon(Icons.admin_panel_settings),
                label: Text(context.t('অবস্থা হালনাগাদ করুন (অ্যাডমিন)', 'Update status (admin)')),
              ),
            ],
            const SizedBox(height: 32),
          ]);
        },
      ),
    );
  }

  Widget _info(BuildContext context, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}

/// Admin sheet to move a case through the workflow.
Future<void> showStatusSheet(BuildContext context, Report r) async {
  var status = r.status;
  final note = TextEditingController(text: r.authorityNote);
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(ctx.t('অবস্থা পরিবর্তন', 'Change status'), style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ReportStatus.values
                .map((s) => ChoiceChip(
                      label: Text(statusLabel(s).of(ctx.isBn)),
                      selected: status == s,
                      selectedColor: statusColor(s).withValues(alpha: 0.2),
                      onSelected: (_) => setS(() => status = s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLines: 3,
            decoration: InputDecoration(labelText: ctx.t('কর্তৃপক্ষের মন্তব্য (প্রকাশ্য)', 'Authority note (public)')),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await DatabaseHelper.instance.updateStatus(r.id, status, note.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(ctx.t('সংরক্ষণ', 'Save')),
          ),
        ]),
      ),
    ),
  );
}
