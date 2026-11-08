// database_helper.dart
// Cloud Firestore data layer (replaces the old local SQLite database).

import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'data/sectors.dart';
import 'models.dart';

class AuthException implements Exception {
  final String bn;
  final String en;
  AuthException(this.bn, this.en);
}

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  factory DatabaseHelper() => instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _creds => _db.collection('credentials');
  CollectionReference<Map<String, dynamic>> get _reports => _db.collection('reports');
  CollectionReference<Map<String, dynamic>> get _commodities => _db.collection('commodities');
  CollectionReference<Map<String, dynamic>> get _prices => _db.collection('prices');
  CollectionReference<Map<String, dynamic>> get _listings => _db.collection('listings');

  /// Firebase anonymous auth is used only to secure the database with
  /// security rules. User login itself is phone + password below.
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> ensureDeviceSession() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  // ---------------------------------------------------------------- Accounts

  static String _hash(String password, String salt) {
    var bytes = utf8.encode('$salt:$password');
    var digest = sha256.convert(bytes);
    for (var i = 0; i < 5000; i++) {
      digest = sha256.convert([...digest.bytes, ...bytes]);
    }
    return digest.toString();
  }

  static String _randomSalt() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  Future<AppUser> signUp({
    required String name,
    required String phone,
    required String nid,
    required String district,
    required String role,
    required String password,
  }) async {
    final existing = await _creds.doc(phone).get();
    if (existing.exists) {
      throw AuthException('এই মোবাইল নম্বরে আগেই অ্যাকাউন্ট আছে।',
          'An account already exists for this mobile number.');
    }
    final salt = _randomSalt();
    final batch = _db.batch();
    batch.set(_creds.doc(phone), {
      'salt': salt,
      'hash': _hash(password, salt),
      'ownerUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final data = {
      'phone': phone,
      'name': name,
      'nid': nid,
      'district': district,
      'role': role,
      'ownerUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    };
    batch.set(_users.doc(phone), data);
    await batch.commit();
    return AppUser.fromMap({...data, 'createdAt': DateTime.now()});
  }

  Future<AppUser> login(String phone, String password) async {
    final c = await _creds.doc(phone).get();
    if (!c.exists) {
      throw AuthException('এই নম্বরে কোনো অ্যাকাউন্ট নেই।', 'No account found for this number.');
    }
    final m = c.data()!;
    if (_hash(password, m['salt']) != m['hash']) {
      throw AuthException('পাসওয়ার্ড সঠিক নয়।', 'Incorrect password.');
    }
    final u = await _users.doc(phone).get();
    return AppUser.fromMap(u.data() ?? {'phone': phone});
  }

  Future<AppUser?> getUser(String phone) async {
    final u = await _users.doc(phone).get();
    return u.exists ? AppUser.fromMap(u.data()!) : null;
  }

  Future<void> updateProfile(String phone, {required String name, required String district}) =>
      _users.doc(phone).update({'name': name, 'district': district});

  /// Admins are registered by device id in the `admins` collection
  /// (created from the Firebase console).
  Future<bool> isAdmin() async {
    if (uid.isEmpty) return false;
    try {
      final d = await _db.collection('admins').doc(uid).get();
      return d.exists;
    } catch (_) {
      return false;
    }
  }

  // ----------------------------------------------------------------- Reports

  static String _trackingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    final yy = DateTime.now().year % 100;
    return 'SBD-$yy-${List.generate(6, (_) => chars[r.nextInt(chars.length)]).join()}';
  }

  Future<String> submitReport({
    required String sector,
    required String issueType,
    required String district,
    required String place,
    required String description,
    required double amount,
    required bool anonymous,
    required AppUser user,
    String? imageBase64,
    bool isDemo = false,
    int supportCount = 0,
    String status = 'submitted',
    DateTime? createdAt,
  }) async {
    final code = _trackingCode();
    final ts = createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt);
    await _reports.add({
      'code': code,
      'sector': sector,
      'issueType': issueType,
      'district': district,
      'place': place,
      'description': description,
      'amount': amount,
      'anonymous': anonymous,
      'reporterName': anonymous ? '' : user.name,
      'ownerUid': uid,
      'status': status,
      'authorityNote': '',
      'supportCount': supportCount,
      'image': imageBase64,
      'isDemo': isDemo,
      'createdAt': ts,
      'updatedAt': ts,
      'history': [
        {'status': 'submitted', 'note': '', 'at': Timestamp.fromDate(createdAt ?? DateTime.now())}
      ],
    });
    return code;
  }

  /// Latest reports (client-side filtering keeps the app free of composite indexes).
  Stream<List<Report>> reportsStream({int limit = 300}) => _reports
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Report.fromDoc).toList());

  Stream<List<Report>> myReportsStream() => _reports
      .where('ownerUid', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map(Report.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Stream<Report> reportStream(String id) =>
      _reports.doc(id).snapshots().map(Report.fromDoc);

  Future<Report?> findByCode(String code) async {
    final q = await _reports.where('code', isEqualTo: code.trim().toUpperCase()).limit(1).get();
    return q.docs.isEmpty ? null : Report.fromDoc(q.docs.first);
  }

  /// "I faced this too" — one corroboration per device.
  Future<bool> supportReport(String reportId) async {
    final ref = _reports.doc(reportId);
    final sRef = ref.collection('supporters').doc(uid);
    return _db.runTransaction((tx) async {
      final s = await tx.get(sRef);
      if (s.exists) return false;
      tx.set(sRef, {'at': FieldValue.serverTimestamp()});
      tx.update(ref, {'supportCount': FieldValue.increment(1)});
      return true;
    });
  }

  Future<bool> hasSupported(String reportId) async {
    final s = await _reports.doc(reportId).collection('supporters').doc(uid).get();
    return s.exists;
  }

  Future<void> updateStatus(String reportId, ReportStatus status, String note) =>
      _reports.doc(reportId).update({
        'status': status.name,
        'authorityNote': note,
        'updatedAt': FieldValue.serverTimestamp(),
        'history': FieldValue.arrayUnion([
          {'status': status.name, 'note': note, 'at': Timestamp.now()}
        ]),
      });

  // ------------------------------------------------------------------ Prices

  Stream<List<Commodity>> commoditiesStream() => _commodities
      .snapshots()
      .map((s) => s.docs.map(Commodity.fromDoc).toList()
        ..sort((a, b) => a.nameEn.compareTo(b.nameEn)));

  Future<void> saveCommodity(String id, Map<String, dynamic> data) =>
      _commodities.doc(id).set({...data, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

  Future<void> submitPrice({
    required String commodityId,
    required String district,
    required String market,
    required double price,
    required String kind,
    DateTime? at,
  }) =>
      _prices.add({
        'commodityId': commodityId,
        'district': district,
        'market': market,
        'price': price,
        'kind': kind,
        'ownerUid': uid,
        'createdAt': at == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(at),
      });

  /// Price observations of the last [days] days.
  Stream<List<PriceObservation>> recentPricesStream({int days = 14}) => _prices
      .where('createdAt',
          isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(Duration(days: days))))
      .snapshots()
      .map((s) => s.docs.map(PriceObservation.fromDoc).toList());

  // ------------------------------------------------------------ Fare config

  Stream<FareConfig> fareStream() =>
      _db.collection('config').doc('fares').snapshots().map((d) => FareConfig.fromMap(d.data()));

  Future<void> saveFares(FareConfig f) =>
      _db.collection('config').doc('fares').set(f.toMap());

  // ------------------------------------------------------------ Marketplace

  Future<void> addListing(Map<String, dynamic> data) => _listings.add({
        ...data,
        'ownerUid': uid,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<List<Listing>> listingsStream() => _listings
      .where('active', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(Listing.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Stream<List<Listing>> myListingsStream() => _listings
      .where('ownerUid', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map(Listing.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<void> setListingActive(String id, bool active) =>
      _listings.doc(id).update({'active': active});

  // --------------------------------------------------------------- Seeding

  /// Creates default commodities and fare rates if they don't exist yet.
  Future<void> seedReferenceData() async {
    final batch = _db.batch();
    for (final c in kDefaultCommodities) {
      final m = Map<String, dynamic>.from(c)..remove('id');
      batch.set(_commodities.doc(c['id']), {...m, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
    }
    batch.set(_db.collection('config').doc('fares'), FareConfig.defaults.toMap(),
        SetOptions(merge: true));
    await batch.commit();
  }

  /// Demo data for presentations. Every record is flagged `isDemo` and shown
  /// with a DEMO badge in the app; remove with [clearDemoData].
  Future<void> seedDemoData(AppUser admin) async {
    await seedReferenceData();
    final r = Random();
    const districts = ['Dhaka', 'Chattogram', 'Gazipur', 'Narayanganj', 'Sylhet', 'Rajshahi',
      'Khulna', 'Cumilla', 'Bogura', 'Rangpur', 'Mymensingh', 'Barishal'];
    const samples = [
      ['transport', 'Overcharged fare', 'Gabtoli Bus Terminal', 'Charged Tk 700 on the Dhaka–Bogura route; BRTA chart fare is far lower.', 250.0],
      ['transport', 'Extortion (chanda)', 'Sayedabad terminal gate', 'Every bus pays a daily token at the gate. Drivers say it is added to fares.', 300.0],
      ['food', 'Overpricing', 'Karwan Bazar', 'Onion sold well above the reference price; traders blame "supply shortage".', 30.0],
      ['food', 'No price list displayed', 'Local kitchen market', 'No price list displayed at any shop in the market.', 0.0],
      ['health', 'Broker (dalal)', 'Medical college hospital, outdoor', 'Brokers at the outdoor gate push patients to a private diagnostic centre.', 0.0],
      ['health', 'Bribe for bed/service', 'District hospital, ward 3', 'Ward staff asked Tk 500 for a bed.', 500.0],
      ['medicine', 'Above MRP', 'Pharmacy near the hospital', 'Antibiotic sold Tk 20 above MRP per strip.', 20.0],
      ['agriculture', 'Unfair farm-gate price', 'Village market', 'Potato bought from farmers at a fraction of the city price.', 0.0],
      ['agriculture', 'Fertiliser overpricing', 'Union dealer', 'Urea sold above government price; dealer says stock is short.', 200.0],
      ['tickets', 'Train ticket black market', 'Kamalapur station', 'Eid tickets sold outside the station at double the price.', 600.0],
      ['govt_office', 'Broker at passport office', 'Regional passport office', 'Brokers promise delivery in 7 days for extra Tk 3,000.', 3000.0],
      ['land', 'Bribe for mutation', 'AC Land office', 'Asked for extra money beyond the official mutation fee.', 5000.0],
      ['extortion', 'Shop/hawker extortion', 'Footpath, main road', 'Hawkers pay a daily amount to local men.', 100.0],
      ['utilities', 'LPG overpricing', 'Neighbourhood dealer', '12 kg LPG cylinder sold above the BERC price.', 150.0],
      ['migration', 'Excess migration cost', 'Recruiting sub-agent', 'Asked for several lakh taka for a job visa.', 450000.0],
      ['education', 'Extra money for admission', 'Secondary school', 'Donation demanded for class six admission.', 5000.0],
    ];
    const statuses = ['submitted', 'reviewing', 'verified', 'forwarded', 'resolved'];
    for (var i = 0; i < 40; i++) {
      final s = samples[i % samples.length];
      await submitReport(
        sector: s[0] as String,
        issueType: s[1] as String,
        district: districts[r.nextInt(districts.length)],
        place: s[2] as String,
        description: s[3] as String,
        amount: s[4] as double,
        anonymous: r.nextBool(),
        user: admin,
        isDemo: true,
        supportCount: r.nextInt(12),
        status: statuses[r.nextInt(statuses.length)],
        createdAt: DateTime.now().subtract(Duration(days: r.nextInt(28), hours: r.nextInt(24))),
      );
    }
    // Price observations around (and sometimes above) the reference range.
    for (final c in kDefaultCommodities) {
      final min = (c['refMin'] as num).toDouble();
      final max = (c['refMax'] as num).toDouble();
      for (var d = 0; d < 10; d++) {
        final district = districts[r.nextInt(districts.length)];
        final spike = r.nextDouble() < 0.3 ? 1.15 + r.nextDouble() * 0.2 : 1.0;
        final price = (min + r.nextDouble() * (max - min)) * spike;
        await submitPrice(
          commodityId: c['id'] as String,
          district: district,
          market: 'Demo market',
          price: double.parse(price.toStringAsFixed(0)),
          kind: 'retail',
          at: DateTime.now().subtract(Duration(days: r.nextInt(13), hours: r.nextInt(20))),
        );
        if (d < 3) {
          await submitPrice(
            commodityId: c['id'] as String,
            district: district,
            market: 'Demo farm-gate',
            price: double.parse((min * (0.45 + r.nextDouble() * 0.2)).toStringAsFixed(0)),
            kind: 'farmgate',
            at: DateTime.now().subtract(Duration(days: r.nextInt(13))),
          );
        }
      }
    }
  }

  Future<int> clearDemoData() async {
    var n = 0;
    final reps = await _reports.where('isDemo', isEqualTo: true).get();
    for (final d in reps.docs) {
      await d.reference.delete();
      n++;
    }
    for (final market in ['Demo market', 'Demo farm-gate']) {
      final p = await _prices.where('market', isEqualTo: market).get();
      for (final d in p.docs) {
        await d.reference.delete();
        n++;
      }
    }
    return n;
  }
}
