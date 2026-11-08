import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/bd_locations.dart';
import '../data/sectors.dart';
import '../models.dart';
import 'app_state.dart';

Future<void> callNumber(BuildContext context, String number) async {
  final ok = await launchUrl(Uri(scheme: 'tel', path: number));
  if (!ok && context.mounted) {
    showSnack(context, context.tr('কল করা যায়নি: $number', 'Could not call $number'));
  }
}

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    behavior: SnackBarBehavior.floating,
  ));
}

String fmtDate(BuildContext context, DateTime d) {
  final f = DateFormat('d MMM yyyy, h:mm a', context.isBn ? 'bn' : 'en');
  return f.format(d);
}

String timeAgo(BuildContext context, DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return context.t('এইমাত্র', 'just now');
  if (diff.inHours < 1) return context.t('${context.n(diff.inMinutes)} মিনিট আগে', '${diff.inMinutes} min ago');
  if (diff.inDays < 1) return context.t('${context.n(diff.inHours)} ঘণ্টা আগে', '${diff.inHours} h ago');
  if (diff.inDays < 30) return context.t('${context.n(diff.inDays)} দিন আগে', '${diff.inDays} d ago');
  return fmtDate(context, d);
}

String districtName(BuildContext context, String en) {
  final d = districtByEn(en);
  if (d == null) return en;
  return context.isBn ? d.bn : d.en;
}

String issueLabel(BuildContext context, Report r) {
  final s = sectorById(r.sector);
  for (final t in s.issueTypes) {
    if (t.en == r.issueType) return t.of(context.isBn);
  }
  return r.issueType;
}

BT statusLabel(ReportStatus s) {
  switch (s) {
    case ReportStatus.submitted:
      return const BT('জমা হয়েছে', 'Submitted');
    case ReportStatus.reviewing:
      return const BT('যাচাই চলছে', 'Under review');
    case ReportStatus.verified:
      return const BT('সত্যতা নিশ্চিত', 'Verified');
    case ReportStatus.forwarded:
      return const BT('কর্তৃপক্ষে প্রেরিত', 'Forwarded to authority');
    case ReportStatus.resolved:
      return const BT('ব্যবস্থা নেওয়া হয়েছে', 'Action taken');
    case ReportStatus.rejected:
      return const BT('বাতিল', 'Rejected');
  }
}

Color statusColor(ReportStatus s) {
  switch (s) {
    case ReportStatus.submitted:
      return const Color(0xFF607D8B);
    case ReportStatus.reviewing:
      return const Color(0xFFF39C12);
    case ReportStatus.verified:
      return const Color(0xFF2980B9);
    case ReportStatus.forwarded:
      return const Color(0xFF8E44AD);
    case ReportStatus.resolved:
      return const Color(0xFF27AE60);
    case ReportStatus.rejected:
      return const Color(0xFFC0392B);
  }
}

class StatusChip extends StatelessWidget {
  final ReportStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(statusLabel(status).of(context.isBn),
          style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('DEMO', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Row(children: [
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ]),
      );
}

/// District dropdown with Bangla/English names.
class DistrictField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowAll;
  final String? label;
  const DistrictField({super.key, required this.value, required this.onChanged, this.allowAll = false, this.label});

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<String>>[
      if (allowAll) DropdownMenuItem(value: '', child: Text(context.t('সব জেলা', 'All districts'))),
      ...kDistricts.map((d) => DropdownMenuItem(value: d.en, child: Text(context.isBn ? d.bn : d.en))),
    ];
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      menuMaxHeight: 400,
      decoration: InputDecoration(
        labelText: label ?? context.t('জেলা', 'District'),
        prefixIcon: const Icon(Icons.location_on_outlined),
      ),
      items: items,
      onChanged: onChanged,
      validator: allowAll ? null : (v) => (v == null || v.isEmpty) ? context.tr('জেলা নির্বাচন করুন', 'Select a district') : null,
    );
  }
}

class HotlineTile extends StatelessWidget {
  final Hotline h;
  const HotlineTile(this.h, {super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(h.icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(h.name.of(context.isBn)),
        subtitle: Text(context.n(h.number), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: IconButton.filledTonal(
          icon: const Icon(Icons.call),
          onPressed: () => callNumber(context, h.number),
        ),
      );
}

/// Small stat card used on dashboards.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 2),
          ]),
        ),
      );
}
