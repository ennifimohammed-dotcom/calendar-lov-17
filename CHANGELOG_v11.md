# v11 - Badr (بدر)

- App renamed to **بدر / Badr** (Android label, MaterialApp title, app_name labels)
- New launcher icon (gold crescent on green) generated for all mipmap densities
- Accent colour palette wired into theme: 8 colours (4 dark + 4 light), live updates light/dark themes
- Removed Ramadan pre-reminder from settings (default 0 days = disabled)
- Monthly calendar view: 50/50 split — top half = grid, bottom half = scrollable day events (≈3 visible)
- Removed event dots and Friday colour highlight from monthly grid for a cleaner Google-Calendar look
- Removed all blue accents from event-screen UI (header now green; personal-event badge uses gold)
- Converter screen: added a date picker on the Hijri side (pick a Gregorian date → converts via active region)
- Hijri date source unchanged (already correct):
  • Morocco anchor → 28 Apr 2026 = 10 Dhū al-Qiʿdah 1447 (habous.gov.ma)
  • Global Umm al-Qura → 28 Apr 2026 = 11 Dhū al-Qiʿdah 1447
- All settings persist via SharedPreferences (region, language, accent, theme, view, etc.)
- pubspec bumped to 1.0.11+11
