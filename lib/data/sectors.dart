import 'package:flutter/material.dart';

/// Bilingual text pair.
class BT {
  final String bn;
  final String en;
  const BT(this.bn, this.en);
  String of(bool isBn) => isBn ? bn : en;
}

class Hotline {
  final String number;
  final BT name;
  final IconData icon;
  const Hotline(this.number, this.name, this.icon);
}

const hEmergency = Hotline('999', BT('জাতীয় জরুরি সেবা', 'National Emergency'), Icons.emergency);
const hInfo = Hotline('333', BT('জাতীয় তথ্য বাতায়ন / সরকারি সেবা', 'National Info & Govt Services'), Icons.info);
const hAcc = Hotline('106', BT('দুর্নীতি দমন কমিশন (দুদক)', 'Anti-Corruption Commission'), Icons.gavel);
const hConsumer = Hotline('16121', BT('জাতীয় ভোক্তা অধিকার সংরক্ষণ অধিদপ্তর', 'Consumer Rights (DNCRP)'), Icons.shopping_bag);
const hHealth = Hotline('16263', BT('স্বাস্থ্য বাতায়ন', 'Shastho Batayon (Health)'), Icons.local_hospital);
const hLand = Hotline('16122', BT('ভূমি সেবা হটলাইন', 'Land Service Hotline'), Icons.landscape);
const hAgri = Hotline('16123', BT('কৃষি কল সেন্টার', 'Krishi Call Center'), Icons.agriculture);
const hWomen = Hotline('109', BT('নারী ও শিশু নির্যাতন প্রতিরোধ', 'Violence Against Women & Children'), Icons.shield);

const kAllHotlines = [hEmergency, hInfo, hAcc, hConsumer, hHealth, hLand, hAgri, hWomen];

/// A sector where syndicates operate, with how they work and how the app fights them.
class Sector {
  final String id;
  final BT name;
  final BT tagline;
  final IconData icon;
  final Color color;
  final List<BT> patterns; // how the syndicate operates
  final List<BT> solutions; // what citizens / the app can do
  final List<BT> issueTypes;
  final BT authority;
  final List<Hotline> hotlines;
  final String? tool; // special in-app tool: fare | prices | farmgate | medicine

  const Sector({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.patterns,
    required this.solutions,
    required this.issueTypes,
    required this.authority,
    required this.hotlines,
    this.tool,
  });
}

const kSectors = <Sector>[
  Sector(
    id: 'transport',
    name: BT('পরিবহন ও বাস', 'Transport & Bus'),
    tagline: BT('অতিরিক্ত ভাড়া ও চাঁদাবাজি', 'Fare gouging & extortion'),
    icon: Icons.directions_bus,
    color: Color(0xFF1E6FD9),
    tool: 'fare',
    patterns: [
      BT('টার্মিনাল, স্ট্যান্ড ও রুটে প্রতিটি গাড়ি থেকে নিয়মিত চাঁদা আদায়, যার খরচ যাত্রীর ভাড়ায় যোগ হয়।',
          'Regular "chanda" collected from every vehicle at terminals, stands and routes — the cost is passed on to passengers.'),
      BT('বিআরটিএ নির্ধারিত ভাড়ার চার্ট না মেনে বেশি ভাড়া, বিশেষ করে ঈদ ও ছুটির সময়।',
          'Fares charged above the BRTA chart, especially around Eid and holidays.'),
      BT('মালিক-শ্রমিক সংগঠনের মাধ্যমে রুট দখল ও নতুন কোম্পানিকে রুটে ঢুকতে বাধা।',
          'Route monopolies enforced by owner/worker associations that block new operators.'),
      BT('অবৈধ ধর্মঘট ডেকে সরকার ও যাত্রীদের জিম্মি করা।', 'Sudden strikes used to hold passengers and government hostage.'),
    ],
    solutions: [
      BT('অ্যাপের ভাড়া ক্যালকুলেটরে সরকারি হারে সঠিক ভাড়া দেখে নিন।', 'Check the lawful fare with the in-app BRTA fare calculator.'),
      BT('বেশি ভাড়া নিলে এক ট্যাপে অভিযোগ — বাসের নাম, রুট ও টাকা সহ।', 'One-tap overcharge report with bus name, route and amount.'),
      BT('চাঁদাবাজির স্থান ম্যাপ-জেলাভিত্তিক হটস্পট হিসেবে কর্তৃপক্ষের ড্যাশবোর্ডে যায়।',
          'Extortion spots aggregate into district hotspots on the authority dashboard.'),
    ],
    issueTypes: [
      BT('অতিরিক্ত ভাড়া', 'Overcharged fare'),
      BT('চাঁদাবাজি', 'Extortion (chanda)'),
      BT('টিকিট কালোবাজারি', 'Ticket black-marketing'),
      BT('রুট দখল / অবৈধ ধর্মঘট', 'Route capture / illegal strike'),
      BT('ফিটনেসবিহীন গাড়ি', 'Unfit vehicle'),
    ],
    authority: BT('বিআরটিএ, হাইওয়ে পুলিশ, জেলা প্রশাসন', 'BRTA, Highway Police, District Administration'),
    hotlines: [hEmergency, hInfo],
  ),
  Sector(
    id: 'food',
    name: BT('খাদ্য ও নিত্যপণ্য', 'Food & Essentials'),
    tagline: BT('মজুতদারি ও কৃত্রিম সংকট', 'Hoarding & artificial shortage'),
    icon: Icons.shopping_basket,
    color: Color(0xFFE67E22),
    tool: 'prices',
    patterns: [
      BT('অল্প কয়েকটি বড় আমদানিকারক ও মিল মালিক চাল, ডাল, তেল, চিনি, পেঁয়াজের সরবরাহ নিয়ন্ত্রণ করে।',
          'A handful of big importers and mill owners control the supply of rice, lentils, oil, sugar and onions.'),
      BT('গুদামে পণ্য মজুত রেখে কৃত্রিম সংকট তৈরি করে দাম বাড়ানো।', 'Goods are hoarded in warehouses to create artificial shortages and push prices up.'),
      BT('পাইকারি ও খুচরা পর্যায়ে একযোগে দাম বাড়ানো (যোগসাজশ)।', 'Coordinated price hikes at wholesale and retail level (collusion).'),
      BT('মূল্যতালিকা না টাঙানো, ওজনে কম দেওয়া ও ভেজাল।', 'No price list displayed, short weight and adulteration.'),
    ],
    solutions: [
      BT('লাইভ ন্যায্যমূল্য বোর্ড: সরকারি রেফারেন্স দামের সাথে জেলাভিত্তিক বাজারদর তুলনা।',
          'Live Fair-Price Board: district market prices compared against the government reference price.'),
      BT('দাম রেফারেন্সের চেয়ে বেশি হলে লাল সতর্কতা ও “প্রাইস স্পাইক” শনাক্তকরণ।', 'Red alert and automatic price-spike detection when prices exceed the reference.'),
      BT('ভোক্তা অধিকার আইন অনুযায়ী অভিযোগ; আদায়কৃত জরিমানার ২৫% অভিযোগকারী পেতে পারেন।',
          'Complaint under the Consumer Rights Protection Act; complainants may receive 25% of the fine collected.'),
    ],
    issueTypes: [
      BT('অতিরিক্ত দাম', 'Overpricing'),
      BT('মজুতদারি', 'Hoarding'),
      BT('মূল্যতালিকা নেই', 'No price list displayed'),
      BT('ওজনে কম', 'Short weight'),
      BT('ভেজাল / মেয়াদোত্তীর্ণ', 'Adulterated / expired'),
    ],
    authority: BT('জাতীয় ভোক্তা অধিকার সংরক্ষণ অধিদপ্তর, প্রতিযোগিতা কমিশন', 'DNCRP, Bangladesh Competition Commission'),
    hotlines: [hConsumer, hInfo],
  ),
  Sector(
    id: 'health',
    name: BT('সরকারি হাসপাতাল', 'Govt Hospitals'),
    tagline: BT('দালাল ও ঘুষ চক্র', 'Brokers & bribery rings'),
    icon: Icons.local_hospital,
    color: Color(0xFFD63031),
    patterns: [
      BT('দালালরা রোগীদের সরকারি হাসপাতাল থেকে বেসরকারি ক্লিনিক ও ডায়াগনস্টিক সেন্টারে নিয়ে যায় কমিশনের বিনিময়ে।',
          'Brokers (dalals) divert patients from government hospitals to private clinics and diagnostic centres for commission.'),
      BT('সিট, ট্রলি, অ্যাম্বুলেন্স বা দ্রুত সেবার জন্য কর্মচারীদের টাকা দাবি।', 'Staff demand money for a bed, trolley, ambulance or faster service.'),
      BT('বিনামূল্যের সরকারি ওষুধ রোগীকে না দিয়ে বাইরে বিক্রি।', 'Free government medicine is not given to patients and sold outside.'),
      BT('অপ্রয়োজনীয় টেস্ট লিখে নির্দিষ্ট ল্যাবে পাঠানো।', 'Unnecessary tests prescribed and sent to specific labs.'),
    ],
    solutions: [
      BT('হাসপাতাল ও ওয়ার্ড উল্লেখ করে গোপনে দালাল/ঘুষের অভিযোগ।', 'Report brokers or bribes anonymously, naming the hospital and ward.'),
      BT('একই হাসপাতালের একাধিক অভিযোগ মিলে “হটস্পট” — পরিচালক ও অধিদপ্তরের কাছে প্রমাণসহ।',
          'Multiple reports on the same hospital form a hotspot, forwarded with evidence to the director and DGHS.'),
      BT('স্বাস্থ্য বাতায়ন ১৬২৬৩-এ সরাসরি কল।', 'Call Shastho Batayon 16263 directly.'),
    ],
    issueTypes: [
      BT('দালাল', 'Broker (dalal)'),
      BT('সিট/সেবার জন্য ঘুষ', 'Bribe for bed/service'),
      BT('বিনামূল্যের ওষুধ না দেওয়া', 'Free medicine withheld'),
      BT('ডায়াগনস্টিক কমিশন', 'Diagnostic commission'),
      BT('অ্যাম্বুলেন্স সিন্ডিকেট', 'Ambulance syndicate'),
    ],
    authority: BT('স্বাস্থ্য অধিদপ্তর (DGHS), হাসপাতাল পরিচালক', 'DGHS, Hospital Director'),
    hotlines: [hHealth, hAcc],
  ),
  Sector(
    id: 'medicine',
    name: BT('ওষুধ ও ফার্মেসি', 'Medicine & Pharmacy'),
    tagline: BT('এমআরপির বেশি দাম ও নকল ওষুধ', 'Above-MRP prices & fake drugs'),
    icon: Icons.medication,
    color: Color(0xFF8E44AD),
    tool: 'medicine',
    patterns: [
      BT('প্যাকেটে লেখা সর্বোচ্চ খুচরা মূল্যের (MRP) বেশি দামে ওষুধ বিক্রি।', 'Medicines sold above the printed maximum retail price (MRP).'),
      BT('নকল, ভেজাল ও মেয়াদোত্তীর্ণ ওষুধ বাজারজাত।', 'Fake, adulterated and expired medicines in the market.'),
      BT('কোম্পানি-চিকিৎসক কমিশনের কারণে দামি ব্র্যান্ড লেখা।', 'Company–doctor commissions push expensive brands.'),
    ],
    solutions: [
      BT('MRP বনাম বিক্রয়মূল্য চেকার — বেশি নিলে সাথে সাথে অভিযোগ।', 'MRP vs charged-price checker with instant complaint.'),
      BT('ফার্মেসির নাম ও ঠিকানা সহ অভিযোগ ঔষধ প্রশাসনে পাঠানো।', 'Complaints with pharmacy name and address go to the Directorate General of Drug Administration.'),
    ],
    issueTypes: [
      BT('MRP-র বেশি দাম', 'Above MRP'),
      BT('নকল/ভেজাল ওষুধ', 'Fake/adulterated drug'),
      BT('মেয়াদোত্তীর্ণ ওষুধ', 'Expired drug'),
      BT('প্রেসক্রিপশন ছাড়া অ্যান্টিবায়োটিক', 'Antibiotic without prescription'),
    ],
    authority: BT('ঔষধ প্রশাসন অধিদপ্তর, ভোক্তা অধিকার', 'DGDA, DNCRP'),
    hotlines: [hConsumer, hHealth],
  ),
  Sector(
    id: 'agriculture',
    name: BT('কৃষি ও কৃষক', 'Agriculture & Farmers'),
    tagline: BT('মধ্যস্বত্বভোগীর শোষণ', 'Middlemen exploitation'),
    icon: Icons.agriculture,
    color: Color(0xFF27AE60),
    tool: 'farmgate',
    patterns: [
      BT('কৃষক মাঠে যে দাম পান আর ভোক্তা শহরে যে দাম দেন — তার বড় অংশ নেয় ফড়িয়া, আড়তদার ও পরিবহন চাঁদা।',
          'Most of the gap between what the farmer gets and what the city consumer pays is taken by middlemen, commission agents and transport extortion.'),
      BT('ডিলারদের সার ও বীজ সরকারি দামের বেশিতে বিক্রি বা কৃত্রিম সংকট।', 'Dealers sell fertiliser and seed above government price or create shortages.'),
      BT('ফসল তোলার মৌসুমে একজোট হয়ে দাম ফেলে দেওয়া।', 'Buyers collude to crash prices at harvest time.'),
    ],
    solutions: [
      BT('“মধ্যস্বত্ব মিটার”: মাঠের দাম বনাম খুচরা দামের ব্যবধান জেলাভিত্তিক দেখায়।',
          '"Middleman Meter": shows the farm-gate vs retail price gap by district.'),
      BT('সরাসরি বাজার: কৃষক/উৎপাদক সরাসরি ক্রেতার কাছে বিক্রি করতে পারেন।', 'Direct Market: farmers and producers sell straight to buyers.'),
      BT('কৃষি কল সেন্টার ১৬১২৩।', 'Krishi Call Center 16123.'),
    ],
    issueTypes: [
      BT('ন্যায্য দাম না পাওয়া', 'Unfair farm-gate price'),
      BT('সারের বাড়তি দাম', 'Fertiliser overpricing'),
      BT('ভেজাল বীজ/কীটনাশক', 'Fake seed/pesticide'),
      BT('আড়তে জোরপূর্বক কমিশন', 'Forced commission at wholesale market'),
    ],
    authority: BT('কৃষি সম্প্রসারণ অধিদপ্তর, কৃষি বিপণন অধিদপ্তর', 'Dept. of Agricultural Extension, Dept. of Agricultural Marketing'),
    hotlines: [hAgri, hConsumer],
  ),
  Sector(
    id: 'tickets',
    name: BT('টিকিট (ট্রেন/লঞ্চ/বিমান)', 'Tickets (Rail/Launch/Air)'),
    tagline: BT('কালোবাজারি ও টিকিট আটকে রাখা', 'Black market & ticket blocking'),
    icon: Icons.confirmation_number,
    color: Color(0xFF16A085),
    patterns: [
      BT('ঈদের সময় ট্রেন ও লঞ্চের টিকিট চক্রের হাতে চলে যায় এবং কয়েক গুণ দামে বিক্রি হয়।',
          'Around Eid, train and launch tickets end up with rings and are resold at several times the price.'),
      BT('কিছু ট্রাভেল এজেন্সি বিমানের আসন আগেই ব্লক করে রেখে দাম কৃত্রিমভাবে বাড়ায়, বিশেষ করে প্রবাসী শ্রমিকদের রুটে।',
          'Some travel agencies block airline seats in advance to inflate fares, especially on migrant-worker routes.'),
    ],
    solutions: [
      BT('কালোবাজারির স্থান, সময় ও দামসহ অভিযোগ।', 'Report black-market tickets with place, time and price.'),
      BT('কর্তৃপক্ষের ড্যাশবোর্ডে ঈদ মৌসুমের প্রবণতা দেখা যায়।', 'Seasonal trends are visible on the authority dashboard.'),
    ],
    issueTypes: [
      BT('ট্রেনের টিকিট কালোবাজারি', 'Train ticket black market'),
      BT('লঞ্চের কেবিন কালোবাজারি', 'Launch cabin black market'),
      BT('বিমান টিকিট সিন্ডিকেট', 'Air ticket syndicate'),
    ],
    authority: BT('বাংলাদেশ রেলওয়ে, বিআইডব্লিউটিএ, বেসামরিক বিমান পরিবহন মন্ত্রণালয়', 'Bangladesh Railway, BIWTA, Civil Aviation Ministry'),
    hotlines: [hInfo, hEmergency],
  ),
  Sector(
    id: 'govt_office',
    name: BT('সরকারি সেবা অফিস', 'Govt Service Offices'),
    tagline: BT('পাসপোর্ট, লাইসেন্স, এনআইডিতে দালাল', 'Brokers at passport, licence, NID'),
    icon: Icons.account_balance,
    color: Color(0xFF34495E),
    patterns: [
      BT('পাসপোর্ট, ড্রাইভিং লাইসেন্স, এনআইডি সংশোধনে দালাল ছাড়া কাজ না হওয়ার পরিবেশ তৈরি।',
          'An environment where passport, driving licence and NID correction work "only moves" through brokers.'),
      BT('“স্পিড মানি” বা ঘুষ ছাড়া ফাইল আটকে রাখা।', 'Files held up without "speed money".'),
    ],
    solutions: [
      BT('অফিস ও ডেস্ক উল্লেখ করে গোপন অভিযোগ; দুদক ১০৬-এ কল।', 'Anonymous report naming office and desk; call ACC 106.'),
      BT('অনলাইনে নিজে আবেদনের সঠিক পদ্ধতি জানতে ৩৩৩।', 'Call 333 to learn the official self-service procedure.'),
    ],
    issueTypes: [
      BT('পাসপোর্ট অফিসে দালাল', 'Broker at passport office'),
      BT('বিআরটিএ লাইসেন্সে ঘুষ', 'Bribe for driving licence'),
      BT('এনআইডি সংশোধনে ঘুষ', 'Bribe for NID correction'),
      BT('অন্যান্য সেবায় ঘুষ', 'Bribe for other service'),
    ],
    authority: BT('দুর্নীতি দমন কমিশন, সংশ্লিষ্ট অধিদপ্তর', 'Anti-Corruption Commission, concerned department'),
    hotlines: [hAcc, hInfo],
  ),
  Sector(
    id: 'land',
    name: BT('ভূমি ও রেজিস্ট্রি', 'Land & Registry'),
    tagline: BT('নামজারি ও দলিলে দালাল', 'Brokers in mutation & deeds'),
    icon: Icons.landscape,
    color: Color(0xFF795548),
    patterns: [
      BT('এসি ল্যান্ড ও ইউনিয়ন ভূমি অফিসে নামজারি, খতিয়ান ও খাজনার জন্য বাড়তি টাকা।',
          'Extra money demanded for mutation, khatian and land tax at AC Land and union land offices.'),
      BT('ভুয়া দলিল ও দখলবাজ চক্র।', 'Forged deeds and land-grabbing rings.'),
    ],
    solutions: [
      BT('ভূমি সেবা হটলাইন ১৬১২২ ও ই-নামজারি ব্যবহারে উৎসাহ।', 'Promotes Land Service Hotline 16122 and e-mutation.'),
      BT('অফিসভিত্তিক অভিযোগ ও হটস্পট বিশ্লেষণ।', 'Office-wise complaints and hotspot analysis.'),
    ],
    issueTypes: [
      BT('নামজারিতে ঘুষ', 'Bribe for mutation'),
      BT('ভুয়া দলিল', 'Forged deed'),
      BT('জমি দখল', 'Land grabbing'),
    ],
    authority: BT('ভূমি মন্ত্রণালয়, জেলা প্রশাসক', 'Ministry of Land, Deputy Commissioner'),
    hotlines: [hLand, hAcc],
  ),
  Sector(
    id: 'education',
    name: BT('শিক্ষা', 'Education'),
    tagline: BT('ভর্তি বাণিজ্য ও কোচিং বাধ্যবাধকতা', 'Admission trade & forced coaching'),
    icon: Icons.school,
    color: Color(0xFF2980B9),
    patterns: [
      BT('ভর্তির জন্য ডোনেশন বা নির্ধারিত ফির বেশি টাকা আদায়।', 'Donations or fees above the set rate demanded for admission.'),
      BT('শিক্ষকের কাছে কোচিং/প্রাইভেট পড়তে বাধ্য করা।', 'Students pressured to take private coaching from their own teachers.'),
      BT('প্রশ্নফাঁস ও নোট-গাইড চক্র।', 'Question-paper leaks and guidebook rings.'),
    ],
    solutions: [
      BT('প্রতিষ্ঠানের নাম সহ গোপন অভিযোগ — শিক্ষার্থীর পরিচয় সুরক্ষিত।', 'Anonymous report naming the institution — student identity protected.'),
    ],
    issueTypes: [
      BT('ভর্তিতে অতিরিক্ত টাকা', 'Extra money for admission'),
      BT('কোচিং বাধ্য করা', 'Forced coaching'),
      BT('প্রশ্নফাঁস', 'Question leak'),
    ],
    authority: BT('মাধ্যমিক ও উচ্চশিক্ষা অধিদপ্তর, শিক্ষা বোর্ড', 'DSHE, Education Boards'),
    hotlines: [hInfo, hAcc],
  ),
  Sector(
    id: 'migration',
    name: BT('বিদেশে কর্মসংস্থান', 'Overseas Jobs'),
    tagline: BT('রিক্রুটিং সিন্ডিকেট ও ভুয়া ভিসা', 'Recruiting cartels & fake visas'),
    icon: Icons.flight_takeoff,
    color: Color(0xFF00897B),
    patterns: [
      BT('কয়েকটি এজেন্সির চক্র শ্রমবাজার নিয়ন্ত্রণ করে অভিবাসন খরচ সরকারি হারের কয়েক গুণ করে।',
          'A small ring of agencies controls labour markets, raising migration costs several times over the official rate.'),
      BT('ভুয়া ভিসা, চুক্তির চেয়ে কম বেতন ও দালালের মাধ্যমে প্রতারণা।', 'Fake visas, lower pay than contracted, and fraud through sub-agents.'),
    ],
    solutions: [
      BT('এজেন্সি ও দালালের নামসহ অভিযোগ; কত টাকা নেওয়া হয়েছে তা রেকর্ড।', 'Report with agency and broker name; records how much was taken.'),
      BT('কর্তৃপক্ষ এজেন্সিভিত্তিক অভিযোগের সংখ্যা দেখতে পারে।', 'Authorities can see complaint counts per agency.'),
    ],
    issueTypes: [
      BT('অতিরিক্ত অভিবাসন খরচ', 'Excess migration cost'),
      BT('ভুয়া ভিসা', 'Fake visa'),
      BT('দালালের প্রতারণা', 'Broker fraud'),
    ],
    authority: BT('প্রবাসী কল্যাণ মন্ত্রণালয়, বিএমইটি', 'Expatriates\' Welfare Ministry, BMET'),
    hotlines: [hInfo, hAcc],
  ),
  Sector(
    id: 'utilities',
    name: BT('বিদ্যুৎ, গ্যাস ও এলপিজি', 'Power, Gas & LPG'),
    tagline: BT('সংযোগে ঘুষ ও সিলিন্ডারের বাড়তি দাম', 'Connection bribes & LPG overpricing'),
    icon: Icons.bolt,
    color: Color(0xFFF39C12),
    tool: 'prices',
    patterns: [
      BT('নতুন সংযোগ বা মিটারের জন্য ঘুষ; অবৈধ সংযোগ চক্র।', 'Bribes for a new connection or meter; illegal connection rings.'),
      BT('বিইআরসি নির্ধারিত দামের বেশিতে এলপিজি সিলিন্ডার বিক্রি।', 'LPG cylinders sold above the BERC-set price.'),
    ],
    solutions: [
      BT('এলপিজি দাম বাজারদর বোর্ডে ট্র্যাক করা যায়।', 'LPG prices can be tracked on the Fair-Price Board.'),
      BT('সংযোগে ঘুষের অভিযোগ অফিসভিত্তিক।', 'Office-wise complaints about connection bribes.'),
    ],
    issueTypes: [
      BT('সংযোগে ঘুষ', 'Bribe for connection'),
      BT('এলপিজির বাড়তি দাম', 'LPG overpricing'),
      BT('ভুতুড়ে বিল', 'Inflated bill'),
      BT('অবৈধ সংযোগ', 'Illegal connection'),
    ],
    authority: BT('বাংলাদেশ এনার্জি রেগুলেটরি কমিশন, বিতরণ কোম্পানি', 'BERC, Distribution companies'),
    hotlines: [hConsumer, hInfo],
  ),
  Sector(
    id: 'construction',
    name: BT('নির্মাণসামগ্রী', 'Construction Materials'),
    tagline: BT('রড, সিমেন্ট, বালুর সিন্ডিকেট', 'Rod, cement & sand cartels'),
    icon: Icons.construction,
    color: Color(0xFF7F8C8D),
    patterns: [
      BT('রড ও সিমেন্ট উৎপাদকরা একযোগে দাম বাড়ায়।', 'Rod and cement makers raise prices in step.'),
      BT('অবৈধ বালু উত্তোলন ও বালুমহাল নিয়ন্ত্রণকারী চক্র।', 'Illegal sand extraction and rings that control sand quarries.'),
    ],
    solutions: [
      BT('অবৈধ বালু উত্তোলনের স্থানসহ ছবি-প্রমাণ অভিযোগ।', 'Report illegal sand extraction with location and photo evidence.'),
    ],
    issueTypes: [
      BT('অতিরিক্ত দাম', 'Overpricing'),
      BT('অবৈধ বালু উত্তোলন', 'Illegal sand extraction'),
    ],
    authority: BT('প্রতিযোগিতা কমিশন, জেলা প্রশাসন', 'Competition Commission, District Administration'),
    hotlines: [hConsumer, hInfo],
  ),
  Sector(
    id: 'extortion',
    name: BT('হাট-ঘাট ও ফুটপাত চাঁদা', 'Market, Ghat & Footpath Extortion'),
    tagline: BT('ইজারার নামে অতিরিক্ত টোল', 'Excess tolls in the name of leases'),
    icon: Icons.storefront,
    color: Color(0xFFC0392B),
    patterns: [
      BT('হাট, ঘাট ও বাজারে ইজারাদার নির্ধারিত টোলের বেশি আদায় করে।', 'Lease-holders at markets and ferry ghats collect more than the fixed toll.'),
      BT('ফুটপাতের হকার ও দোকান থেকে দৈনিক চাঁদা।', 'Daily extortion from footpath hawkers and shops.'),
    ],
    solutions: [
      BT('স্থানসহ গোপন অভিযোগ; পুনরাবৃত্ত স্থান হটস্পট হিসেবে চিহ্নিত হয়।', 'Anonymous report with location; repeated places are flagged as hotspots.'),
      BT('জরুরি হুমকিতে ৯৯৯।', 'Call 999 for immediate threats.'),
    ],
    issueTypes: [
      BT('অতিরিক্ত টোল', 'Excess toll'),
      BT('দোকান/হকার চাঁদা', 'Shop/hawker extortion'),
    ],
    authority: BT('জেলা প্রশাসন, পুলিশ, স্থানীয় সরকার', 'District Administration, Police, Local Government'),
    hotlines: [hEmergency, hAcc],
  ),
  Sector(
    id: 'other',
    name: BT('অন্যান্য', 'Other'),
    tagline: BT('অন্য যেকোনো সিন্ডিকেট', 'Any other syndicate'),
    icon: Icons.more_horiz,
    color: Color(0xFF95A5A6),
    patterns: [
      BT('যেকোনো খাতে একটি গোষ্ঠী যদি দাম, সরবরাহ বা সেবা নিয়ন্ত্রণ করে জনগণকে ঠকায়।',
          'Any group that controls price, supply or service in a sector to cheat the public.'),
    ],
    solutions: [
      BT('বিস্তারিত বিবরণসহ অভিযোগ করুন; কর্তৃপক্ষ সঠিক দপ্তরে পাঠাবে।', 'Report with details; authorities route it to the right office.'),
    ],
    issueTypes: [BT('অন্যান্য', 'Other')],
    authority: BT('সংশ্লিষ্ট কর্তৃপক্ষ', 'Concerned authority'),
    hotlines: [hInfo, hAcc],
  ),
];

Sector sectorById(String id) =>
    kSectors.firstWhere((s) => s.id == id, orElse: () => kSectors.last);

/// Default commodities with reference price ranges (Tk). These are starting
/// values only; admins must keep them updated from TCB / DAM daily market data.
const kDefaultCommodities = <Map<String, dynamic>>[
  {'id': 'rice_coarse', 'nameBn': 'মোটা চাল', 'nameEn': 'Rice (coarse)', 'unit': 'kg', 'refMin': 50, 'refMax': 56, 'icon': '🍚'},
  {'id': 'rice_fine', 'nameBn': 'সরু চাল', 'nameEn': 'Rice (fine)', 'unit': 'kg', 'refMin': 72, 'refMax': 85, 'icon': '🍚'},
  {'id': 'lentil', 'nameBn': 'মসুর ডাল (মোটা)', 'nameEn': 'Lentil (coarse)', 'unit': 'kg', 'refMin': 95, 'refMax': 110, 'icon': '🫘'},
  {'id': 'soybean_oil', 'nameBn': 'সয়াবিন তেল (বোতল)', 'nameEn': 'Soybean oil (bottled)', 'unit': 'litre', 'refMin': 185, 'refMax': 195, 'icon': '🛢️'},
  {'id': 'sugar', 'nameBn': 'চিনি', 'nameEn': 'Sugar', 'unit': 'kg', 'refMin': 110, 'refMax': 120, 'icon': '🧂'},
  {'id': 'onion', 'nameBn': 'পেঁয়াজ (দেশি)', 'nameEn': 'Onion (local)', 'unit': 'kg', 'refMin': 60, 'refMax': 75, 'icon': '🧅'},
  {'id': 'potato', 'nameBn': 'আলু', 'nameEn': 'Potato', 'unit': 'kg', 'refMin': 25, 'refMax': 35, 'icon': '🥔'},
  {'id': 'egg', 'nameBn': 'ডিম (ফার্ম)', 'nameEn': 'Egg (farm)', 'unit': 'dozen', 'refMin': 130, 'refMax': 150, 'icon': '🥚'},
  {'id': 'broiler', 'nameBn': 'ব্রয়লার মুরগি', 'nameEn': 'Broiler chicken', 'unit': 'kg', 'refMin': 170, 'refMax': 190, 'icon': '🐔'},
  {'id': 'green_chili', 'nameBn': 'কাঁচা মরিচ', 'nameEn': 'Green chilli', 'unit': 'kg', 'refMin': 80, 'refMax': 120, 'icon': '🌶️'},
  {'id': 'garlic', 'nameBn': 'রসুন (দেশি)', 'nameEn': 'Garlic (local)', 'unit': 'kg', 'refMin': 180, 'refMax': 220, 'icon': '🧄'},
  {'id': 'beef', 'nameBn': 'গরুর মাংস', 'nameEn': 'Beef', 'unit': 'kg', 'refMin': 750, 'refMax': 800, 'icon': '🥩'},
  {'id': 'lpg_12kg', 'nameBn': 'এলপিজি (১২ কেজি)', 'nameEn': 'LPG (12 kg)', 'unit': 'cylinder', 'refMin': 1400, 'refMax': 1450, 'icon': '🔥'},
];

BT unitLabel(String unit) {
  switch (unit) {
    case 'kg':
      return const BT('কেজি', 'kg');
    case 'litre':
      return const BT('লিটার', 'litre');
    case 'dozen':
      return const BT('ডজন', 'dozen');
    case 'cylinder':
      return const BT('সিলিন্ডার', 'cylinder');
    case 'piece':
      return const BT('পিস', 'piece');
    case 'maund':
      return const BT('মণ', 'maund');
    default:
      return BT(unit, unit);
  }
}
