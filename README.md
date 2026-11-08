# 🇧🇩 Syndicate-Free Bangladesh

### A Bilingual Civic-Tech Platform for Market Transparency, Citizen Empowerment & Digital Accountability

Syndicate-Free Bangladesh is a Bangla/English Flutter application
concept designed to help citizens, farmers, producers, and relevant
authorities identify, report, and address syndicate-related problems
across 13 important sectors in Bangladesh.

The platform brings citizen reporting, case tracking, market-price
monitoring, transport fare checking, medicine MRP checking, and a direct
farmer-to-buyer marketplace into one mobile application. App data is
stored in **Cloud Firestore**.

> **Project status:** Developed as an independent software
> project/prototype. It is not an official government service,
> regulator, or authority platform. Information, reports, and reference
> prices should be independently verified before real-world decisions
> are made.

------------------------------------------------------------------------

## 📱 Screenshots

  ----------------------------------------------------------------------------------------
  Home Dashboard                               Citizen Reports
  -------------------------------------------- -------------------------------------------
  ![Home                                       ![Citizen
  dashboard](screenshots/home-dashboard.jpg)   reports](screenshots/citizen-reports.jpg)

  ----------------------------------------------------------------------------------------

  -----------------------------------------------------------------------------------
  Direct Market                            Fair-Price Board
  ---------------------------------------- ------------------------------------------
  ![Direct                                 ![Fair-price
  market](screenshots/direct-market.jpg)   board](screenshots/fair-price-board.jpg)

  -----------------------------------------------------------------------------------

  ------------------------------------------------------------------------------------
  Report Submission                    Complaint Tracking
  ------------------------------------ -----------------------------------------------
  ![Report                             ![Complaint
  form](screenshots/report-form.jpg)   tracking](screenshots/complaint-tracking.jpg)

  ------------------------------------------------------------------------------------

  -----------------------------------------------------------------------------------
  Login                               Registration
  ----------------------------------- -----------------------------------------------
  ![Login](screenshots/login.jpg)     ![Registration](screenshots/registration.jpg)

  -----------------------------------------------------------------------------------

------------------------------------------------------------------------

## 🎯 Problem & Purpose

People may face unfair pricing, excessive transport fares, market
manipulation, extortion, and barriers to accessing essential services.
These problems can be difficult to document and escalate consistently.

This project explores how a digital platform can:

-   Make it easier for citizens to submit structured reports.
-   Provide a traceable workflow for submitted cases.
-   Help people compare reported market prices with configurable
    reference prices.
-   Give farmers and producers a direct channel to reach buyers.
-   Make sector-specific guidance, rights information, and hotline
    numbers easier to access.

The app is intended to support awareness, reporting, and transparency.
It does not independently establish that a reported allegation is true.

------------------------------------------------------------------------

## 🧭 13 Sectors Covered

The app organizes information and reporting around 13 sectors:

1.  Transport and buses
2.  Food and essential commodities
3.  Government hospitals
4.  Medicine and pharmacies
5.  Agriculture
6.  Tickets --- rail, launch, and air
7.  Government service offices
8.  Land and registry
9.  Education
10. Overseas employment
11. Electricity, gas, and LPG
12. Construction materials
13. Markets, ghats, and footpath extortion

Each sector is designed to explain common issues, suggest what citizens
can do, identify relevant responsible authorities, and provide useful
hotline information.

------------------------------------------------------------------------

## ✨ Key Features

### 1. Citizen Syndicate Reporting

Citizens can submit a report with details such as:

-   Sector and issue type
-   District and specific location
-   Description of the incident
-   Optional amount of money involved
-   Optional photo evidence
-   Option to keep the reporter's identity private

Each report receives a tracking code, for example:

`SBD-26-4F7K2Q`

### 2. Case Tracking & Workflow

The documented case workflow includes:

`Submitted → Under review → Verified → Forwarded to authority → Action taken`

A report may also be rejected. The app is designed to show status
updates, authority notes, and a case timeline where available.

### 3. Credibility Scoring

The project includes a credibility model intended to prioritize reports
using signals such as:

-   Citizen corroboration
-   Photo evidence
-   Official verification

A credibility score is an aid for prioritization, not proof that an
allegation is true.

### 4. Fair-Price Board

Citizens can submit local market-price observations by district. The app
is designed to compare a seven-day median with an
administrator-configured reference price and flag prices that appear
unusually high or are increasing sharply.

**Current demo screenshot note:** The supplied Fair-Price Board
screenshot shows the empty state because no reference prices have been
added yet.

### 5. Middleman Meter

Shows the difference between farm-gate and retail prices for selected
products to help users understand the price gap along the supply chain.

### 6. Direct Market

A marketplace area where farmers and producers can list products so
buyers can contact sellers directly.

-   Product search
-   District selection
-   Product-category filters
-   Seller listings
-   Direct buyer-to-seller contact
-   Fair-price indicator when a listing meets the configured reference
    price

**Current demo screenshot note:** The supplied Direct Market screenshot
shows the empty state because no products are listed in the selected
area.

### 7. BRTA Fare Calculator

Calculates configured lawful fares for city buses, minibuses, and long
routes. Fare rates are administrator-editable, and the feature is
intended to help users identify possible overcharging and prepare a
report.

### 8. Medicine MRP Checker

Helps users compare the amount paid for a medicine with its printed
Maximum Retail Price (MRP), and provides a route to report a
discrepancy.

### 9. Authority Dashboard

The administrator/authority dashboard is designed to provide:

-   Key performance indicators
-   Reports by sector and status
-   District and location hotspots
-   Case queue prioritized by credibility
-   Reference-price and fare configuration
-   Demo-data loading for presentations

Dashboard access is restricted to authorized administrator
devices/accounts according to the app's Firebase configuration.

### 10. Rights Information & Hotlines

The app includes rights guidance and commonly used hotline references,
including:

-   999 --- Emergency service
-   333 --- Government information and services
-   106 --- Anti-Corruption Commission
-   16121 --- Consumer rights
-   16263 --- Health service
-   16122 --- Land service
-   16123 --- Agriculture
-   109 --- Women and children support

Users should confirm hotline availability and the appropriate service
before relying on a number.

### 11. Bangla & English Interface

The app provides a bilingual interface to make the platform more
accessible to Bangla-speaking citizens while also supporting English.

------------------------------------------------------------------------

## 🛠 Technology Stack

  Area                      Technology
  ------------------------- --------------------------
  Mobile application        Flutter
  Programming language      Dart
  Authentication            Firebase Authentication
  Cloud database            Cloud Firestore
  Database access control   Firestore Security Rules
  Target platform           Android

------------------------------------------------------------------------

## ⚙️ Setup & Installation

### Prerequisites

-   Flutter 3.27 or newer
-   Android Studio
-   Android SDK
-   A Firebase project

### 1. Clone the repository

``` bash
git clone https://github.com/TanimBD/syndicateless_bd.git
cd syndicateless_bd
```

### 2. Configure Firebase

In the Firebase Console:

1.  Create or select a Firebase project.

2.  Register an Android app using the package name:

    `com.tanimbd.syndicatelessbd`

3.  Download `google-services.json` and place it in:

    `android/app/google-services.json`

4.  Enable **Anonymous** sign-in under **Authentication → Sign-in
    method**, as required by the app's database-access implementation.

5.  Create a Cloud Firestore database.

6.  Review and publish the project's `firestore.rules`.

> Keep Firebase configuration and credentials appropriate to the
> repository's security model. Never commit service-account private
> keys, signing keys, passwords, or other secrets.

### 3. Install dependencies

``` bash
flutter pub get
```

### 4. Run the application

``` bash
flutter run
```

------------------------------------------------------------------------

## 🔐 Administrator Setup

The current setup guide uses a device-ID-based administrator allowlist:

1.  Open the app and navigate to **More → Device ID**.

2.  Copy the device ID shown by the app.

3.  In Cloud Firestore, create a document under:

    `admins/<device-id>`

4.  Add an appropriate field, for example:

    `name: "Admin"`

5.  Restart the app.

6.  The **More → Authority dashboard** entry should become available to
    the authorized device.

In **Authority Dashboard → Settings**, use **Load default reference
data** to populate initial reference values. Reference prices and fares
must be maintained using reliable, current sources.

> Do not publish real users' device IDs, phone numbers, NID information,
> or private case details in screenshots, documentation, or public issue
> reports.

------------------------------------------------------------------------

## 🔒 Security & Privacy Notes

The project documentation describes the following safeguards:

-   Passwords are salted and hashed before storage.
-   NID numbers are not displayed publicly.
-   Firestore rules are intended to prevent citizens from changing
    roles, editing other users' data, or changing case statuses.
-   Anonymous reporting is supported as an app feature.

### Production hardening

Before a public production launch, further review is recommended:

-   Move sensitive authentication and verification logic to trusted
    server-side code, such as Cloud Functions.
-   Consider Firebase Phone Authentication/OTP for phone-number
    verification.
-   Integrate a lawful, authorized identity-verification process if NID
    verification is required.
-   Review Firestore rules with automated tests and a least-privilege
    approach.
-   Add abuse prevention, rate limiting, moderation, audit logs, and
    secure evidence-file access.
-   Establish clear retention, consent, privacy, and complaint-handling
    policies.

The password hashing approach and client-side checks should not be
treated as a substitute for secure server-side authentication and
authorization.

------------------------------------------------------------------------

## 🏗 Release Build

For an Android App Bundle:

``` bash
flutter build appbundle --release
```

Configure Android signing securely before creating a production release.
Keep the upload keystore and `key.properties` outside version control.

------------------------------------------------------------------------

## 🗺 Roadmap

Potential next steps include:

-   Populate the demo with clearly labeled sample products and reference
    prices.
-   Add more screenshots, a short walkthrough video, and a live demo
    where appropriate.
-   Expand automated tests for reporting, case status transitions, and
    Firestore access rules.
-   Improve moderation and anti-spam safeguards.
-   Complete production security and privacy reviews.
-   Validate hotline and reference-price data with authoritative
    sources.

------------------------------------------------------------------------

## 🤝 Contributing

Suggestions, bug reports, and contributions are welcome. Please avoid
including personal information, NID numbers, phone numbers, private case
evidence, or credentials in public issues.

------------------------------------------------------------------------

## 👨‍💻 Developer

**MD Tanim Hossen**\
GitHub: [@TanimBD](https://github.com/TanimBD)

**Repository:**
[github.com/TanimBD/syndicateless_bd](https://github.com/TanimBD/syndicateless_bd)

------------------------------------------------------------------------

*Built as a technology-driven project exploring fair markets, citizen
participation, and digital accountability in Bangladesh.*
