/// All 64 districts of Bangladesh grouped by division (English, Bangla).
class District {
  final String en;
  final String bn;
  final String division;
  const District(this.en, this.bn, this.division);
}

const List<District> kDistricts = [
  // Dhaka
  District('Dhaka', 'ঢাকা', 'Dhaka'),
  District('Gazipur', 'গাজীপুর', 'Dhaka'),
  District('Narayanganj', 'নারায়ণগঞ্জ', 'Dhaka'),
  District('Narsingdi', 'নরসিংদী', 'Dhaka'),
  District('Manikganj', 'মানিকগঞ্জ', 'Dhaka'),
  District('Munshiganj', 'মুন্সিগঞ্জ', 'Dhaka'),
  District('Tangail', 'টাঙ্গাইল', 'Dhaka'),
  District('Kishoreganj', 'কিশোরগঞ্জ', 'Dhaka'),
  District('Faridpur', 'ফরিদপুর', 'Dhaka'),
  District('Gopalganj', 'গোপালগঞ্জ', 'Dhaka'),
  District('Madaripur', 'মাদারীপুর', 'Dhaka'),
  District('Rajbari', 'রাজবাড়ী', 'Dhaka'),
  District('Shariatpur', 'শরীয়তপুর', 'Dhaka'),
  // Chattogram
  District('Chattogram', 'চট্টগ্রাম', 'Chattogram'),
  District("Cox's Bazar", 'কক্সবাজার', 'Chattogram'),
  District('Cumilla', 'কুমিল্লা', 'Chattogram'),
  District('Feni', 'ফেনী', 'Chattogram'),
  District('Noakhali', 'নোয়াখালী', 'Chattogram'),
  District('Lakshmipur', 'লক্ষ্মীপুর', 'Chattogram'),
  District('Chandpur', 'চাঁদপুর', 'Chattogram'),
  District('Brahmanbaria', 'ব্রাহ্মণবাড়িয়া', 'Chattogram'),
  District('Rangamati', 'রাঙ্গামাটি', 'Chattogram'),
  District('Khagrachhari', 'খাগড়াছড়ি', 'Chattogram'),
  District('Bandarban', 'বান্দরবান', 'Chattogram'),
  // Rajshahi
  District('Rajshahi', 'রাজশাহী', 'Rajshahi'),
  District('Bogura', 'বগুড়া', 'Rajshahi'),
  District('Pabna', 'পাবনা', 'Rajshahi'),
  District('Sirajganj', 'সিরাজগঞ্জ', 'Rajshahi'),
  District('Naogaon', 'নওগাঁ', 'Rajshahi'),
  District('Natore', 'নাটোর', 'Rajshahi'),
  District('Chapainawabganj', 'চাঁপাইনবাবগঞ্জ', 'Rajshahi'),
  District('Joypurhat', 'জয়পুরহাট', 'Rajshahi'),
  // Khulna
  District('Khulna', 'খুলনা', 'Khulna'),
  District('Jashore', 'যশোর', 'Khulna'),
  District('Satkhira', 'সাতক্ষীরা', 'Khulna'),
  District('Bagerhat', 'বাগেরহাট', 'Khulna'),
  District('Kushtia', 'কুষ্টিয়া', 'Khulna'),
  District('Jhenaidah', 'ঝিনাইদহ', 'Khulna'),
  District('Magura', 'মাগুরা', 'Khulna'),
  District('Narail', 'নড়াইল', 'Khulna'),
  District('Chuadanga', 'চুয়াডাঙ্গা', 'Khulna'),
  District('Meherpur', 'মেহেরপুর', 'Khulna'),
  // Barishal
  District('Barishal', 'বরিশাল', 'Barishal'),
  District('Bhola', 'ভোলা', 'Barishal'),
  District('Patuakhali', 'পটুয়াখালী', 'Barishal'),
  District('Pirojpur', 'পিরোজপুর', 'Barishal'),
  District('Jhalokati', 'ঝালকাঠি', 'Barishal'),
  District('Barguna', 'বরগুনা', 'Barishal'),
  // Sylhet
  District('Sylhet', 'সিলেট', 'Sylhet'),
  District('Moulvibazar', 'মৌলভীবাজার', 'Sylhet'),
  District('Habiganj', 'হবিগঞ্জ', 'Sylhet'),
  District('Sunamganj', 'সুনামগঞ্জ', 'Sylhet'),
  // Rangpur
  District('Rangpur', 'রংপুর', 'Rangpur'),
  District('Dinajpur', 'দিনাজপুর', 'Rangpur'),
  District('Kurigram', 'কুড়িগ্রাম', 'Rangpur'),
  District('Gaibandha', 'গাইবান্ধা', 'Rangpur'),
  District('Nilphamari', 'নীলফামারী', 'Rangpur'),
  District('Lalmonirhat', 'লালমনিরহাট', 'Rangpur'),
  District('Thakurgaon', 'ঠাকুরগাঁও', 'Rangpur'),
  District('Panchagarh', 'পঞ্চগড়', 'Rangpur'),
  // Mymensingh
  District('Mymensingh', 'ময়মনসিংহ', 'Mymensingh'),
  District('Jamalpur', 'জামালপুর', 'Mymensingh'),
  District('Sherpur', 'শেরপুর', 'Mymensingh'),
  District('Netrokona', 'নেত্রকোনা', 'Mymensingh'),
];

District? districtByEn(String? en) {
  if (en == null) return null;
  for (final d in kDistricts) {
    if (d.en == en) return d;
  }
  return null;
}
