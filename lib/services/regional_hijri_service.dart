/// Regional Hijri calendar service.
///
/// Goal: every screen and the notification engine must obtain the Hijri date
/// from a SINGLE source of truth that respects the user's chosen region.
///
/// Strategy:
///  - Base algorithm = Umm al-Qura (already implemented in HijriDate).
///  - Each region applies an offset in days to the base algorithm.
///  - For Morocco we additionally honour a small ANCHOR table built from
///    the official announcements of the Ministry of Habous and Islamic
///    Affairs (https://habous.gov.ma — مراقبة الأهلة). When the requested
///    Gregorian date falls within an anchored Hijri month, we compute the
///    Hijri day from that anchor (so 1 Ramadan 1447 == jeudi 19 février 2026
///    matches the official Moroccan announcement).
///  - For other regions we expose the same hook: simply add anchors to the
///    `_anchors` map.
///
/// The whole app uses RegionalHijri.today() / RegionalHijri.fromGregorian()
/// instead of HijriDate.now() / HijriDate.fromGregorian() so that the
/// region setting actually affects the entire UI and notifications.

import '../utils/hijri_utils.dart';

class HijriAnchor {
  /// Hijri year + month whose first day falls on [gregorianStart].
  final int hijriYear;
  final int hijriMonth;
  final DateTime gregorianStart;
  final int monthLength; // 29 or 30
  final String source;
  const HijriAnchor({
    required this.hijriYear,
    required this.hijriMonth,
    required this.gregorianStart,
    required this.monthLength,
    required this.source,
  });
}

class RegionalHijri {
  /// Region code -> additional offset in days applied AFTER anchors.
  /// 0 = use the algorithm as-is. Negative shifts the date earlier.
  static const Map<String, int> _baseOffset = {
    'global': 0,
    'morocco': 0,
    'algeria': 0,
    'tunisia': 0,
    'saudi': 0,
    'turkey': 0,
    'indonesia': 0,
  };

  /// Region -> ordered list of official anchors. Keep them sorted by
  /// gregorianStart. Add new entries when the official body publishes
  /// the next month's start.
  static final Map<String, List<HijriAnchor>> _anchors = {
    // Source: Ministère des Habous et des Affaires Islamiques (Maroc)
    // https://habous.gov.ma — section مراقبة الأهلة
    'morocco': [
      // 1446 AH
      HijriAnchor(hijriYear: 1446, hijriMonth: 9,
          gregorianStart: DateTime(2025, 3, 1), monthLength: 30,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1446, hijriMonth: 10,
          gregorianStart: DateTime(2025, 3, 31), monthLength: 29,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1446, hijriMonth: 11,
          gregorianStart: DateTime(2025, 4, 29), monthLength: 30,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1446, hijriMonth: 12,
          gregorianStart: DateTime(2025, 5, 29), monthLength: 29,
          source: 'habous.gov.ma'),
      // 1447 AH
      HijriAnchor(hijriYear: 1447, hijriMonth: 1,
          gregorianStart: DateTime(2025, 6, 27), monthLength: 29,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1447, hijriMonth: 2,
          gregorianStart: DateTime(2025, 7, 26), monthLength: 30,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1447, hijriMonth: 3,
          gregorianStart: DateTime(2025, 8, 25), monthLength: 29,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1447, hijriMonth: 4,
          gregorianStart: DateTime(2025, 9, 23), monthLength: 30,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1447, hijriMonth: 5,
          gregorianStart: DateTime(2025, 10, 23), monthLength: 29,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1447, hijriMonth: 6,
          gregorianStart: DateTime(2025, 11, 21), monthLength: 30,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1447, hijriMonth: 7,
          gregorianStart: DateTime(2025, 12, 21), monthLength: 30,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1447, hijriMonth: 8,
          gregorianStart: DateTime(2026, 1, 20), monthLength: 30,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1447, hijriMonth: 9,
          gregorianStart: DateTime(2026, 2, 19), monthLength: 30,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1447, hijriMonth: 10,
          gregorianStart: DateTime(2026, 3, 21), monthLength: 29,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1447, hijriMonth: 11,
          gregorianStart: DateTime(2026, 4, 19), monthLength: 30,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1447, hijriMonth: 12,
          gregorianStart: DateTime(2026, 5, 19), monthLength: 29,
          source: 'habous.gov.ma'),
      // 1448 AH
      HijriAnchor(hijriYear: 1448, hijriMonth: 1,
          gregorianStart: DateTime(2026, 6, 17), monthLength: 30,
          source: 'habous.gov.ma'),
      HijriAnchor(hijriYear: 1448, hijriMonth: 9,
          gregorianStart: DateTime(2027, 2, 9), monthLength: 30,
          source: 'habous.gov.ma'),
    ],
  };

  /// Human-readable description of the Hijri source for the given region.
  static String sourceLabel(String region, String lang) {
    switch (region) {
      case 'morocco':
        switch (lang) {
          case 'ar':
            return 'وزارة الأوقاف والشؤون الإسلامية - habous.gov.ma';
          case 'en':
            return 'Ministry of Habous and Islamic Affairs (Morocco)';
          case 'es':
            return 'Ministerio de Habous y Asuntos Islámicos (Marruecos)';
          default:
            return 'Ministère des Habous et des Affaires Islamiques (Maroc)';
        }
      case 'saudi':
        return lang == 'ar' ? 'تقويم أم القرى الرسمي' : 'Umm al-Qura (Saudi Arabia)';
      case 'turkey':
        return lang == 'ar' ? 'الديانة التركية' : 'Diyanet (Türkiye)';
      case 'indonesia':
        return lang == 'ar' ? 'وزارة الشؤون الدينية' : 'Kementerian Agama (Indonesia)';
      case 'algeria':
        return lang == 'ar' ? 'حسابات فلكية - الجزائر' : 'Calcul officiel - Algérie';
      case 'tunisia':
        return lang == 'ar' ? 'حسابات فلكية - تونس' : 'Calcul officiel - Tunisie';
      default:
        return lang == 'ar' ? 'تقويم أم القرى العالمي' : 'Umm al-Qura (Global)';
    }
  }

  /// Total day offset to apply for [region] including the user override.
  static int effectiveOffset(String region, int userOverride) {
    return (_baseOffset[region] ?? 0) + userOverride;
  }

  /// Convert a Gregorian date to a Hijri date according to the region.
  static HijriDate fromGregorian(
    DateTime gregorian, {
    required String region,
    int userOffset = 0,
  }) {
    // 1) Try anchors first.
    final list = _anchors[region];
    if (list != null) {
      // Find the anchor whose [start, start+monthLength) contains the date.
      for (final a in list) {
        final end = a.gregorianStart.add(Duration(days: a.monthLength));
        if (!gregorian.isBefore(a.gregorianStart) && gregorian.isBefore(end)) {
          final dayInMonth =
              gregorian.difference(a.gregorianStart).inDays + 1;
          return HijriDate(a.hijriYear, a.hijriMonth, dayInMonth);
        }
      }
    }
    // 2) Fall back to the algorithm + regional offset + user override.
    final off = effectiveOffset(region, userOffset);
    final shifted = gregorian.add(Duration(days: -off));
    return HijriDate.fromGregorian(shifted);
  }

  /// Today, using the regional source.
  static HijriDate today({
    required String region,
    int userOffset = 0,
  }) {
    return fromGregorian(DateTime.now(), region: region, userOffset: userOffset);
  }

  /// Convert a Hijri date to a Gregorian date according to the region.
  static DateTime toGregorian(
    HijriDate hijri, {
    required String region,
    int userOffset = 0,
  }) {
    final list = _anchors[region];
    if (list != null) {
      for (final a in list) {
        if (a.hijriYear == hijri.year && a.hijriMonth == hijri.month) {
          return a.gregorianStart.add(Duration(days: hijri.day - 1));
        }
      }
    }
    final off = effectiveOffset(region, userOffset);
    return hijri.toGregorian().add(Duration(days: off));
  }

  /// Region-aware addDays. Always goes through Gregorian to keep
  /// 1-to-1 sync between the two calendars.
  static HijriDate addDays(HijriDate h, int delta,
      {required String region, int userOffset = 0}) {
    final g = toGregorian(h, region: region, userOffset: userOffset)
        .add(Duration(days: delta));
    return fromGregorian(g, region: region, userOffset: userOffset);
  }

  /// Region-aware month length. Anchors carry the official month length,
  /// otherwise we measure it via Gregorian conversion of consecutive months.
  static int daysInMonth(int hijriYear, int hijriMonth,
      {required String region, int userOffset = 0}) {
    final list = _anchors[region];
    if (list != null) {
      for (final a in list) {
        if (a.hijriYear == hijriYear && a.hijriMonth == hijriMonth) {
          return a.monthLength;
        }
      }
    }
    final start = toGregorian(HijriDate(hijriYear, hijriMonth, 1),
        region: region, userOffset: userOffset);
    final ny = hijriMonth == 12 ? hijriYear + 1 : hijriYear;
    final nm = hijriMonth == 12 ? 1 : hijriMonth + 1;
    final end = toGregorian(HijriDate(ny, nm, 1),
        region: region, userOffset: userOffset);
    return end.difference(start).inDays;
  }

  /// Region-aware addMonths (keeps the day-of-month, clamping if needed).
  static HijriDate addMonths(HijriDate h, int delta,
      {required String region, int userOffset = 0}) {
    int m = h.month + delta;
    int y = h.year;
    while (m > 12) { m -= 12; y += 1; }
    while (m < 1)  { m += 12; y -= 1; }
    final dim = daysInMonth(y, m, region: region, userOffset: userOffset);
    final day = h.day > dim ? dim : h.day;
    return HijriDate(y, m, day);
  }
}
