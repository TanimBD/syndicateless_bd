// home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'buyer_page.dart';
import 'core/app_state.dart';
import 'core/widgets.dart';
import 'data/sectors.dart';
import 'database_helper.dart';
import 'models.dart';
import 'screens/fare_calculator_page.dart';
import 'screens/more_page.dart';
import 'screens/prices_page.dart';
import 'screens/report_form_page.dart';
import 'screens/reports_feed_page.dart';
import 'screens/sector_page.dart';
import 'screens/track_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(onOpenTab: (i) => setState(() => _tab = i)),
      const ReportsFeedPage(),
      const PricesPage(),
      const BuyerPage(),
      const MorePage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      floatingActionButton: _tab <= 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportFormPage())),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.campaign),
              label: Text(context.t('অভিযোগ করুন', 'Report')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: context.t('হোম', 'Home')),
          NavigationDestination(icon: const Icon(Icons.feed_outlined), selectedIcon: const Icon(Icons.feed), label: context.t('অভিযোগ', 'Reports')),
          NavigationDestination(icon: const Icon(Icons.price_check_outlined), selectedIcon: const Icon(Icons.price_check), label: context.t('বাজারদর', 'Prices')),
          NavigationDestination(icon: const Icon(Icons.storefront_outlined), selectedIcon: const Icon(Icons.storefront), label: context.t('সরাসরি বাজার', 'Market')),
          NavigationDestination(icon: const Icon(Icons.menu), label: context.t('আরও', 'More')),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final ValueChanged<int> onOpenTab;
  const DashboardTab({super.key, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user;
    final db = DatabaseHelper.instance;
    return CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        expandedHeight: 150,
        actions: [
          IconButton(
            tooltip: context.t('ভাষা', 'Language'),
            icon: const Icon(Icons.translate),
            onPressed: app.toggleLanguage,
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14),
          title: Text(context.t('সিন্ডিকেটমুক্ত বাংলাদেশ', 'Syndicate-Free Bangladesh'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF00895F)]),
            ),
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
            alignment: Alignment.topLeft,
            child: Text(
              context.t('আসসালামু আলাইকুম, ${user?.name ?? ''}', 'Welcome, ${user?.name ?? ''}'),
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            _QuickAction(Icons.campaign, context.t('অভিযোগ', 'Report'), const Color(0xFFF42A41),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportFormPage()))),
            _QuickAction(Icons.directions_bus, context.t('ভাড়া যাচাই', 'Fare check'), const Color(0xFF1E6FD9),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FareCalculatorPage()))),
            _QuickAction(Icons.price_check, context.t('বাজারদর', 'Prices'), const Color(0xFFE67E22), () => onOpenTab(2)),
            _QuickAction(Icons.manage_search, context.t('ট্র্যাক', 'Track'), const Color(0xFF8E44AD),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackPage()))),
          ]),
        ),
      ),
      SliverToBoxAdapter(
        child: StreamBuilder<List<Report>>(
          stream: db.reportsStream(),
          builder: (context, snap) {
            final reports = snap.data ?? [];
            final since = DateTime.now().subtract(const Duration(days: 30));
            final recent = reports.where((r) => r.createdAt.isAfter(since)).toList();
            final acted = reports.where((r) =>
                r.status == ReportStatus.resolved || r.status == ReportStatus.forwarded || r.status == ReportStatus.verified);
            final byDistrict = <String, int>{};
            for (final r in recent) {
              byDistrict[r.district] = (byDistrict[r.district] ?? 0) + 1;
            }
            final top = byDistrict.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionTitle(context.t('জাতীয় চিত্র (৩০ দিন)', 'National picture (30 days)')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                      child: StatCard(
                          label: context.t('অভিযোগ', 'Reports'),
                          value: context.n(recent.length),
                          icon: Icons.campaign,
                          color: Colors.redAccent)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: StatCard(
                          label: context.t('যাচাই/ব্যবস্থা', 'Verified/acted'),
                          value: context.n(acted.length),
                          icon: Icons.verified,
                          color: Colors.green)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: StatCard(
                          label: context.t('শীর্ষ হটস্পট', 'Top hotspot'),
                          value: top.isEmpty ? '—' : districtName(context, top.first.key),
                          icon: Icons.local_fire_department,
                          color: Colors.orange)),
                ]),
              ),
            ]);
          },
        ),
      ),
      SliverToBoxAdapter(child: PriceAlertStrip(district: user?.district, onOpen: () => onOpenTab(2))),
      SliverToBoxAdapter(child: SectionTitle(context.t('খাতভিত্তিক সিন্ডিকেট', 'Syndicates by sector'))),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 130,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => _SectorTile(kSectors[i]),
            childCount: kSectors.length,
          ),
        ),
      ),
      SliverToBoxAdapter(child: SectionTitle(context.t('জরুরি হটলাইন', 'Emergency hotlines'))),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: kAllHotlines.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final h = kAllHotlines[i];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => callNumber(context, h.number),
                child: Card(
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(h.icon, size: 18, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(context.n(h.number), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ]),
                      const SizedBox(height: 4),
                      Text(h.name.of(context.isBn), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]);
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              CircleAvatar(radius: 26, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}

class _SectorTile extends StatelessWidget {
  final Sector s;
  const _SectorTile(this.s);

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SectorPage(sector: s))),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: s.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(s.icon, color: s.color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(s.name.of(context.isBn),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}
