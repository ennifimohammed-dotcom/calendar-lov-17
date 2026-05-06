// Pure-Dart Hijri date conversion (Umm al-Qura tabular / Kuwaiti algorithm).
// IMPORTANT: For region-aware computations (Morocco, etc.) ALWAYS go through
// RegionalHijri (services/regional_hijri_service.dart). Only use this class
// directly when the region does not matter (raw conversions, fallback math).

import 'dart:math' as math;

class HijriDate {
  final int year;
  final int month; // 1-12
  final int day;   // 1-30

  const HijriDate(this.year, this.month, this.day);

  static const List<String> monthNamesAr = [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر',
    'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
    'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
  ];
  static const List<String> monthNamesEn = [
    'Muharram','Safar','Rabi al-Awwal','Rabi al-Thani',
    'Jumada al-Ula','Jumada al-Thaniyah','Rajab','Sha\'ban',
    'Ramadan','Shawwal','Dhu al-Qi\'dah','Dhu al-Hijjah'
  ];
  static const List<String> monthNamesFr = [
    'Mouharram','Safar','Rabi al-Awwal','Rabi al-Thani',
    'Joumada al-Oula','Joumada al-Thania','Rajab','Cha\'ban',
    'Ramadan','Chawwal','Dhou al-Qi\'da','Dhou al-Hijja'
  ];
  static const List<String> monthNamesEs = [
    'Muharram','Safar','Rabi al-Awwal','Rabi al-Thani',
    'Yumada al-Ula','Yumada al-Zania','Rayab','Shaban',
    'Ramadán','Shawwal','Du al-Qida','Du al-Hiyya'
  ];

  String monthName(String lang) {
    switch (lang) {
      case 'ar': return monthNamesAr[month - 1];
      case 'fr': return monthNamesFr[month - 1];
      case 'es': return monthNamesEs[month - 1];
      default: return monthNamesEn[month - 1];
    }
  }

  /// RAW algorithmic conversion (Umm al-Qura tabular).
  /// Use RegionalHijri for region-aware results.
  static HijriDate fromGregorian(DateTime g) {
    final jd = _gregorianToJulianDay(g.year, g.month, g.day);
    return _julianDayToHijri(jd);
  }

  /// RAW algorithmic conversion (Umm al-Qura tabular).
  /// Use RegionalHijri for region-aware results.
  DateTime toGregorian() => _julianDayToGregorian(_hijriToJulianDay(year, month, day));

  static HijriDate now() => fromGregorian(DateTime.now());

  // ────────────── algorithmic core (verified roundtrip) ──────────────
  static int _gregorianToJulianDay(int y, int m, int d) {
    if (m < 3) { y -= 1; m += 12; }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return ((365.25 * (y + 4716)).floor()
            + (30.6001 * (m + 1)).floor()
            + d + b - 1524).toInt();
  }

  static DateTime _julianDayToGregorian(int jd) {
    final a = jd + 32044;
    final b = ((4 * a + 3) / 146097).floor();
    final c = a - ((146097 * b) / 4).floor();
    final d = ((4 * c + 3) / 1461).floor();
    final e = c - ((1461 * d) / 4).floor();
    final m = ((5 * e + 2) / 153).floor();
    final day = e - ((153 * m + 2) / 5).floor() + 1;
    final month = m + 3 - 12 * (m / 10).floor();
    final year = 100 * b + d - 4800 + (m / 10).floor();
    return DateTime(year, month, day);
  }

  static int _hijriToJulianDay(int y, int m, int d) {
    return d
        + ((29.5001 * (m - 1) + 0.99).floor())
        + (y - 1) * 354
        + ((11 * y + 3) / 30).floor()
        + 1948439;
  }

  static HijriDate _julianDayToHijri(int jd) {
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final l2 = l - 10631 * n + 354;
    final j = (((10985 - l2) / 5316).floor()) * (((50 * l2) / 17719).floor())
        + ((l2 / 5670).floor()) * (((43 * l2) / 15238).floor());
    final l3 = l2 - (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor())
        - ((j / 16).floor()) * (((15238 * j) / 43).floor()) + 29;
    final month = ((24 * l3) / 709).floor();
    final day = l3 - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;
    return HijriDate(year, month, day);
  }

  /// Days in a Hijri month (raw algorithm, region-agnostic).
  static int daysInMonth(int year, int month) {
    final start = HijriDate(year, month, 1).toGregorian();
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final end = HijriDate(nextYear, nextMonth, 1).toGregorian();
    return end.difference(start).inDays;
  }

  HijriDate addMonths(int delta) {
    int m = month + delta;
    int y = year;
    while (m > 12) { m -= 12; y += 1; }
    while (m < 1)  { m += 12; y -= 1; }
    final dim = daysInMonth(y, m);
    return HijriDate(y, m, math.min(day, dim));
  }

  HijriDate addDays(int delta) =>
      fromGregorian(toGregorian().add(Duration(days: delta)));

  bool isSameDay(HijriDate other) =>
      year == other.year && month == other.month && day == other.day;

  @override
  String toString() => '$day ${monthNamesEn[month - 1]} $year';
}
