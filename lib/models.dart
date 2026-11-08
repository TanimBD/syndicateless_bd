import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _date(dynamic v) =>
    v is Timestamp ? v.toDate() : (v is DateTime ? v : DateTime.now());

double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

/// Registered user. Document id = phone number.
class AppUser {
  final String phone;
  final String name;
  final String nid;
  final String district;
  final String role; // citizen | seller
  final DateTime createdAt;

  AppUser({
    required this.phone,
    required this.name,
    required this.nid,
    required this.district,
    required this.role,
    required this.createdAt,
  });

  bool get isSeller => role == 'seller';

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        phone: m['phone'] ?? '',
        name: m['name'] ?? '',
        nid: m['nid'] ?? '',
        district: m['district'] ?? 'Dhaka',
        role: m['role'] ?? 'citizen',
        createdAt: _date(m['createdAt']),
      );

  String get maskedNid =>
      nid.length > 4 ? '${'•' * (nid.length - 4)}${nid.substring(nid.length - 4)}' : nid;
}

/// Case workflow for a syndicate report.
enum ReportStatus { submitted, reviewing, verified, forwarded, resolved, rejected }

ReportStatus statusFrom(String? s) => ReportStatus.values
    .firstWhere((e) => e.name == s, orElse: () => ReportStatus.submitted);

/// A citizen complaint about a syndicate / extortion / overcharging.
class Report {
  final String id;
  final String code; // public tracking code e.g. SBD-26-4F7K2Q
  final String sector;
  final String issueType;
  final String district;
  final String place;
  final String description;
  final double amount; // money demanded / overcharged, taka
  final bool anonymous;
  final String reporterName;
  final String ownerUid;
  final ReportStatus status;
  final String authorityNote;
  final int supportCount;
  final String? imageBase64;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, dynamic>> history;

  Report({
    required this.id,
    required this.code,
    required this.sector,
    required this.issueType,
    required this.district,
    required this.place,
    required this.description,
    required this.amount,
    required this.anonymous,
    required this.reporterName,
    required this.ownerUid,
    required this.status,
    required this.authorityNote,
    required this.supportCount,
    required this.imageBase64,
    required this.isDemo,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
  });

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Report(
      id: d.id,
      code: m['code'] ?? d.id,
      sector: m['sector'] ?? 'other',
      issueType: m['issueType'] ?? '',
      district: m['district'] ?? '',
      place: m['place'] ?? '',
      description: m['description'] ?? '',
      amount: _num(m['amount']),
      anonymous: m['anonymous'] ?? true,
      reporterName: m['reporterName'] ?? '',
      ownerUid: m['ownerUid'] ?? '',
      status: statusFrom(m['status']),
      authorityNote: m['authorityNote'] ?? '',
      supportCount: (m['supportCount'] ?? 0) as int,
      imageBase64: m['image'],
      isDemo: m['isDemo'] ?? false,
      createdAt: _date(m['createdAt']),
      updatedAt: _date(m['updatedAt']),
      history: List<Map<String, dynamic>>.from(
          (m['history'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []),
    );
  }

  /// Credibility score 0-100 from corroboration, evidence and verification.
  int get credibility {
    var s = 20;
    s += (supportCount * 8).clamp(0, 40);
    if (imageBase64 != null) s += 15;
    if (!anonymous) s += 5;
    if (status == ReportStatus.verified ||
        status == ReportStatus.forwarded ||
        status == ReportStatus.resolved) {
      s += 20;
    }
    if (status == ReportStatus.rejected) s = 5;
    return s.clamp(0, 100);
  }
}

/// A market commodity with a reference (fair) price range set by admin.
class Commodity {
  final String id;
  final String nameBn;
  final String nameEn;
  final String unit; // kg, litre, dozen, piece
  final double refMin;
  final double refMax;
  final String icon;
  final DateTime updatedAt;

  Commodity({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.unit,
    required this.refMin,
    required this.refMax,
    required this.icon,
    required this.updatedAt,
  });

  factory Commodity.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Commodity(
      id: d.id,
      nameBn: m['nameBn'] ?? d.id,
      nameEn: m['nameEn'] ?? d.id,
      unit: m['unit'] ?? 'kg',
      refMin: _num(m['refMin']),
      refMax: _num(m['refMax']),
      icon: m['icon'] ?? '🛒',
      updatedAt: _date(m['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'nameBn': nameBn,
        'nameEn': nameEn,
        'unit': unit,
        'refMin': refMin,
        'refMax': refMax,
        'icon': icon,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

/// A crowd-sourced observed market price.
class PriceObservation {
  final String id;
  final String commodityId;
  final String district;
  final String market;
  final double price;
  final String kind; // retail | farmgate
  final DateTime createdAt;

  PriceObservation({
    required this.id,
    required this.commodityId,
    required this.district,
    required this.market,
    required this.price,
    required this.kind,
    required this.createdAt,
  });

  factory PriceObservation.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return PriceObservation(
      id: d.id,
      commodityId: m['commodityId'] ?? '',
      district: m['district'] ?? '',
      market: m['market'] ?? '',
      price: _num(m['price']),
      kind: m['kind'] ?? 'retail',
      createdAt: _date(m['createdAt']),
    );
  }
}

/// A direct producer-to-consumer marketplace listing.
class Listing {
  final String id;
  final String product;
  final String category;
  final double price;
  final String unit;
  final double quantity;
  final String district;
  final String sellerName;
  final String sellerPhone;
  final String ownerUid;
  final String? commodityId;
  final bool active;
  final DateTime createdAt;

  Listing({
    required this.id,
    required this.product,
    required this.category,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.district,
    required this.sellerName,
    required this.sellerPhone,
    required this.ownerUid,
    required this.commodityId,
    required this.active,
    required this.createdAt,
  });

  factory Listing.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Listing(
      id: d.id,
      product: m['product'] ?? '',
      category: m['category'] ?? 'other',
      price: _num(m['price']),
      unit: m['unit'] ?? 'kg',
      quantity: _num(m['quantity']),
      district: m['district'] ?? '',
      sellerName: m['sellerName'] ?? '',
      sellerPhone: m['sellerPhone'] ?? '',
      ownerUid: m['ownerUid'] ?? '',
      commodityId: m['commodityId'],
      active: m['active'] ?? true,
      createdAt: _date(m['createdAt']),
    );
  }
}

/// Official fare rates (admin-editable).
class FareConfig {
  final double longRoutePerKm;
  final double cityBusPerKm;
  final double minibusPerKm;
  final double cityMinFare;
  final String source;
  final DateTime updatedAt;

  FareConfig({
    required this.longRoutePerKm,
    required this.cityBusPerKm,
    required this.minibusPerKm,
    required this.cityMinFare,
    required this.source,
    required this.updatedAt,
  });

  /// Rates published by BRTA in September 2026 (Tk per km).
  static FareConfig get defaults => FareConfig(
        longRoutePerKm: 2.40,
        cityBusPerKm: 2.70,
        minibusPerKm: 2.59,
        cityMinFare: 10,
        source: 'BRTA, Sep 2026',
        updatedAt: DateTime(2026, 9, 22),
      );

  factory FareConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return defaults;
    final d = defaults;
    return FareConfig(
      longRoutePerKm: m['longRoutePerKm'] == null ? d.longRoutePerKm : _num(m['longRoutePerKm']),
      cityBusPerKm: m['cityBusPerKm'] == null ? d.cityBusPerKm : _num(m['cityBusPerKm']),
      minibusPerKm: m['minibusPerKm'] == null ? d.minibusPerKm : _num(m['minibusPerKm']),
      cityMinFare: m['cityMinFare'] == null ? d.cityMinFare : _num(m['cityMinFare']),
      source: m['source'] ?? d.source,
      updatedAt: _date(m['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'longRoutePerKm': longRoutePerKm,
        'cityBusPerKm': cityBusPerKm,
        'minibusPerKm': minibusPerKm,
        'cityMinFare': cityMinFare,
        'source': source,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
