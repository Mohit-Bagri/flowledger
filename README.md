<div align="center">

<img src="logo.jpeg" alt="FlowLedger" width="110" height="110" style="border-radius: 20px;">

# FlowLedger

**Track all your income streams, understand your expenses and detect money leaks automatically.**

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.38+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Riverpod-State-F75757?style=for-the-badge" alt="Riverpod">
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License: MIT">
</p>

</div>

---

## Overview

FlowLedger is a cross-platform personal finance app built with Flutter. From a
single codebase it runs on Android, iOS, Web, macOS, Linux and Windows. Data is
stored locally first (on-device) with optional encrypted cloud sync, and the app
is localized into 12+ languages.

## Features

### Income & Expenses
- Multi-stream income tracking — salary, freelance, investments, rental and passive income
- Smart expense categorization with custom categories and merchant tracking
- Receipt scanning (OCR) with Google ML Kit — capture an expense from a photo
- Recurring transactions with confirmation prompts
- Multi-currency support with conversion rates

### Banking & Payments
- 53+ bank accounts (39 Indian and 14 international)
- Payment method tracking — UPI, cards, cash, wallets and cheques
- Per-account income/expense analytics

### Planning & Insights
- Savings goals with progress and milestones
- Monthly budgets per category with overspend alerts
- Financial health score
- Interactive charts, category comparisons and daily spending patterns
- Money-leak detection for unnecessary or overlapping subscriptions

### Reports & Export
- PDF reports and CSV export with detailed columns
- Custom date-range and category filters
- Share via any app

### Security & Privacy
- Local-first storage with Hive
- Optional, user-controlled encrypted cloud sync
- Biometric (FaceID/TouchID) and PIN/pattern app lock
- No third-party tracking — financial data is never sold or shared

### Notifications & Localization
- Daily reminders, budget alerts, goal milestones and weekly summaries
- 12+ languages with full RTL support (Arabic)

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter (Android, iOS, Web, Desktop) |
| Language | Dart |
| State Management | Riverpod |
| Local Database | Hive (on-device) |
| Cloud Backend | Supabase (Auth + Database + Realtime) |
| Navigation | GoRouter |
| Charts | FL Chart |
| OCR / ML | Google ML Kit Text Recognition |
| Notifications | Flutter Local Notifications |
| PDF | pdf + printing |
| Biometrics | local_auth |
| i18n | Flutter Intl + ARB (12+ languages) |

## Getting Started

### Prerequisites
- Flutter 3.38+ and Dart 3.0+
- A device or emulator (or Chrome for web)

### Run locally
```bash
git clone https://github.com/Mohit-Bagri/flowledger.git
cd flowledger
flutter pub get
flutter run
```

The app works fully offline with local storage out of the box.

### Optional: cloud sync with Supabase
1. Create a free project at [supabase.com](https://supabase.com).
2. Run the SQL in [`supabase_migration.sql`](supabase_migration.sql) (and
   [`supabase_migration_currency.sql`](supabase_migration_currency.sql)) against your project.
3. Add your Supabase URL and anon key to the app's configuration.

## Project Structure

```
lib/
  core/          # theming, constants, utilities
  data/          # models and repositories
  services/      # OCR, notifications, export, sync
  providers/     # Riverpod state
  navigation/    # GoRouter routes
  presentation/  # screens and widgets
  l10n/          # localization (ARB files)
```

## Contributing

Issues and pull requests are welcome. For larger changes, please open an issue
first to discuss what you'd like to change.

## License

Released under the [MIT License](LICENSE) — free to use, modify and distribute.

---

<div align="center">

Built with Flutter by [Mohit Bagri](https://github.com/Mohit-Bagri)

</div>
