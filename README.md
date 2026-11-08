# সিন্ডিকেটমুক্ত বাংলাদেশ — Syndicate-Free Bangladesh

A bilingual (Bangla/English) Flutter app that helps citizens, farmers and authorities identify and fight syndicates across the sectors of Bangladesh. Data is stored in **Cloud Firestore**.

## What the app does

| Module | What it does |
|---|---|
| **13 sectors** | Transport & bus, food & essentials, govt hospitals, medicine & pharmacy, agriculture, tickets (rail/launch/air), govt service offices, land & registry, education, overseas jobs, power/gas/LPG, construction materials, market/ghat/footpath extortion. Each sector explains how its syndicate works, what citizens can do, which authority is responsible, and gives one-tap hotlines. |
| **Syndicate reporting** | Sector, issue type, district, place, details, money involved, photo evidence. Reporters can stay anonymous. Every report gets a tracking code such as `SBD-26-4F7K2Q`. |
| **Case workflow** | Submitted → Under review → Verified → Forwarded to authority → Action taken (or Rejected). Authority notes and a status timeline are shown publicly. |
| **Credibility score** | Calculated from citizen corroboration ("I faced this too"), photo evidence and official verification. Authorities see the most credible cases first. |
| **Fair-Price Board** | Citizens report market prices by district. The app shows the 7-day median against the admin-set reference price and flags prices that are above fair or spiking. |
| **Middleman Meter** | Farm-gate vs retail price gap for each item, showing how much middlemen take. |
| **BRTA fare calculator** | Lawful fare for city buses, minibuses and long routes (rates are admin-editable). Detects overcharging and prefills a report. |
| **MRP checker** | Checks the price you paid for a medicine against the printed MRP and lets you report the difference. |
| **Direct Market** | Farmers and producers list products for buyers to call directly, without middlemen. A "Fair price" badge shows when a listing is at or below the reference price. |
| **Authority dashboard** | KPIs, reports by sector (bar chart), by status (pie chart), top districts, place hotspots, a case queue sorted by credibility, reference-price and fare editors, and one-tap demo data for presentations. |
| **Know your rights & hotlines** | 999, 333, 106 (ACC), 16121 (consumer rights), 16263 (health), 16122 (land), 16123 (agriculture), 109. |

## Setup

1. Install Flutter 3.27 or newer and Android Studio.
2. In the Firebase console, create a project, then:
   - Add an Android app with package name `com.tanimbd.syndicatelessbd` and put `google-services.json` in `android/app/`.
   - Under **Authentication → Sign-in method**, enable **Anonymous**. This is used only to secure the database. Users log in with their mobile number and password.
   - Create a **Firestore database** and publish the rules in `firestore.rules`.
3. Run `flutter pub get`, then `flutter run`.
4. **Make yourself an admin.** Open the app and go to **More → Device ID** to copy your ID. In Firestore, create the document `admins/<that ID>` with any field (for example `name: "Admin"`). Restart the app. **More → Authority dashboard** then appears.
5. In **Authority dashboard → Settings**, tap **Load default reference data**. Keep the reference prices updated from TCB/DAM daily market rates.

## Release build for Google Play

```
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (it is git-ignored):

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=../../upload-keystore.jks
```

Then run `flutter build appbundle --release`.

## Security notes

- Passwords are salted and hashed (iterated SHA-256) before they are stored. NID numbers are never shown publicly.
- `firestore.rules` stops citizens from changing roles, editing other people's data or changing a case's status.
- For production at national scale, move login verification to a Cloud Function or Firebase phone OTP, and add NID verification through the government Porichoy API.
