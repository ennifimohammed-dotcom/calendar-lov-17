# Badr v12 — Calendar UX & Hijri/Gregorian sync

## Calendar
- Monthly view: full 6×7 grid (always complete, prev/next month days shown faded).
- Monthly view: vertical scroll disabled — only horizontal swipe between months.
- Monthly view: removed bottom day-events panel (full grid uses the screen).
- Week starts on **Monday** everywhere (header + grid + weekly view).
- **Double-tap on any day** opens the New-Event screen pre-filled with that day.
- Weekly view: full weekday names visible (الإثنين / Lundi / Monday / Lunes).
- Weekly view: **infinite horizontal paging** between weeks (Google-Agenda style)
  using `PageView` with ±5000 weeks epoch.

## Hijri / Gregorian sync (root cause fix)
- All screens (calendar, agenda, converter, events) now go through the
  **regional** service (`RegionalHijri`) instead of the raw algorithm.
- New region-aware helpers: `RegionalHijri.addDays`, `addMonths`, `daysInMonth`.
- `AppProvider.eventsForHijri`, `setFocusedHijri`, `setFocusedGregorian` and
  the calendar grid all derive Gregorian↔Hijri through the active region.
- Result, with region = Morocco: 2 May 2026 = **14 ذو القعدة 1447** (anchor
  habous.gov.ma). With region = Saudi (Umm al-Qura): 2 May 2026 =
  **15 ذو القعدة 1447**. Both match official sources.
- Initial focus on app launch is computed from the regional source so the
  header opens on the correct Hijri month.

## Add-Event
- New `initialDate` parameter so the screen opens on the day the user
  double-tapped in the calendar.

## Files touched
- `lib/utils/hijri_utils.dart`
- `lib/services/regional_hijri_service.dart`
- `lib/providers/app_provider.dart`
- `lib/screens/calendar_screen.dart`
- `lib/screens/add_event_screen.dart`
- `lib/screens/converter_screen.dart`
- `pubspec.yaml` (1.0.12+12)
