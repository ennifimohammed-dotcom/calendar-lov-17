# v10 — CRITICAL FIX

## 🐛 The single biggest bug in the app: notifications never fired

### Root cause
`HijriDate._hijriToJulianDay` used the wrong epoch constant
(`1948440 - 385` = 1948055) instead of the correct civil-tabular Islamic
epoch JD `1948439`. Every Hijri → Gregorian conversion was therefore
off by ~384 days.

### Why notifications were silent
When the user picked a Hijri date for an event, the engine converted
it to Gregorian using the broken function → the resulting trigger time
was almost always in the past → `flutter_local_notifications` silently
skipped it (you can see `schedule skipped (past)` in the logs).
Result: no popup, no sound, no vibration. Ever.

### Fix
- Replaced the constant in `lib/utils/hijri_utils.dart`. Roundtrip
  verified for multiple known dates (1 Muharram 1447, 1 Ramadan 1447,
  today 28 April 2026 = 11 Dhu al-Qi'dah 1447).

## 🇲🇦 Morocco — official calendar greatly extended

`lib/services/regional_hijri_service.dart` now embeds the full month-by-month
anchor table for Hijri years 1446–1448 published by **habous.gov.ma**
(Ministère des Habous). Eid al-Fitr, Eid al-Adha, Mawlid, Ramadan, Muharram
all match the official Moroccan announcements:

- 1 Ramadan 1447 = 19 février 2026
- 1 Shawwal 1447 (Eid al-Fitr) = 21 mars 2026
- 1 Dhu al-Hijjah 1447 (Eid al-Adha) = 19 mai 2026
- 1 Muharram 1448 = 17 juin 2026

When region = Morocco, every screen and the notification engine read
from this table instead of falling back to Umm al-Qura.

## ✅ Result

Test scenario (10:00 event, reminder 10 min before):
- Notification scheduled at 09:50 of the **correct** real-world day.
- Pop-up + sound + vibration trigger as configured globally.
