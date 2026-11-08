import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/widgets.dart';
import '../data/sectors.dart';
import '../database_helper.dart';
import '../models.dart';
import 'report_detail_page.dart';

class ReportsFeedPage extends StatefulWidget {
  final String? sectorId;
  const ReportsFeedPage({super.key, this.sectorId});

  @override
  State<ReportsFeedPage> createState() => _ReportsFeedPageState();
}

class _ReportsFeedPageState extends State<ReportsFeedPage> {
  late final Stream<List<Report>> _stream = DatabaseHelper.instance.reportsStream();
  late String _sector = widget.sectorId ?? '';
  String _district = '';
  bool _sortBySupport = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectorId == null
            ? context.t('নাগরিক অভিযোগ', 'Citizen reports')
            : sectorById(widget.sectorId!).name.of(context.isBn)),
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.sort),
            initialValue: _sortBySupport,
            onSelected: (v) => setState(() => _sortBySupport = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: false, child: Text(context.t('নতুন আগে', 'Newest first'))),
              PopupMenuItem(value: true, child: Text(context.t('সবচেয়ে বেশি সমর্থিত', 'Most supported'))),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Report>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(icon: Icons.cloud_off, text: context.t('তথ্য আনা যায়নি', 'Could not load reports'));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var list = snap.data!
              .where((r) => r.status != ReportStatus.rejected)
              .where((r) => _sector.isEmpty || r.sector == _sector)
              .where((r) => _district.isEmpty || r.district == _district)
              .toList();
          if (_sortBySupport) list.sort((a, b) => b.supportCount.compareTo(a.supportCount));
          return Column(children: [
            if (widget.sectorId == null)
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(context.t('সব খাত', 'All sectors')),
                        selected: _sector.isEmpty,
                        onSelected: (_) => setState(() => _sector = ''),
                      ),
                    ),
                    ...kSectors.map((s) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            avatar: Icon(s.icon, size: 16, color: s.color),
                            label: Text(s.name.of(context.isBn)),
                            selected: _sector == s.id,
                            onSelected: (_) => setState(() => _sector = s.id),
                          ),
                        )),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: DistrictField(value: _district, allowAll: true, onChanged: (v) => setState(() => _district = v ?? '')),
            ),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(icon: Icons.inbox_outlined, text: context.t('কোনো অভিযোগ নেই', 'No reports yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => ReportCard(list[i]),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final Report r;
  const ReportCard(this.r, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = sectorById(r.sector);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailPage(reportId: r.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: s.color.withValues(alpha: 0.12),
                child: Icon(s.icon, color: s.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(issueLabel(context, r),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (r.isDemo) const DemoBadge(),
                  ]),
                  Text('${districtName(context, r.district)} • ${timeAgo(context, r.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              StatusChip(r.status),
            ]),
            const SizedBox(height: 10),
            Text(r.place, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(r.description, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.people_alt_outlined, size: 16, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 4),
              Text(context.t('${context.n(r.supportCount)} জন একই সমস্যায়', '${r.supportCount} faced this too'),
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              if (r.amount > 0)
                Text(context.taka(r.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
              if (r.imageBase64 != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.photo, size: 16, color: Theme.of(context).colorScheme.outline),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}
