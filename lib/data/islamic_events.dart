import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../theme.dart';

/// Frequency of an Islamic event configuration.
/// - daily   : every single day (e.g. adhkar)
/// - weekly  : a specific weekday (Mon=1..Sun=7)
/// - monthly : specific Hijri days every Hijri month (month=0)
/// - annual  : a specific Hijri month + days
enum IslamicFrequency { daily, weekly, monthly, annual }

class IslamicEventConfig {
  final String key;
  final Map<String, String> titles;
  final Map<String, String> descriptions;
  final Map<String, String> virtues;
  final IslamicFrequency frequency;
  final int month;       // for annual: 1..12 ; for monthly: 0 ; for weekly/daily: -1
  final List<int> days;  // for annual/monthly: hijri days
  final int? weekday;    // for weekly: DateTime.monday..sunday
  final int? hour;       // suggested reminder hour
  final int? minute;     // suggested reminder minute
  final Color color;
  final String emoji;
  final bool defaultEnabled;
  final bool alwaysOn;   // cannot be disabled by user (e.g. Day of Arafat)

  const IslamicEventConfig({
    required this.key,
    required this.titles,
    required this.descriptions,
    this.virtues = const {},
    required this.frequency,
    this.month = -1,
    this.days = const [],
    this.weekday,
    this.hour,
    this.minute,
    required this.color,
    required this.emoji,
    this.defaultEnabled = true,
    this.alwaysOn = false,
  });
}

class IslamicEventsData {
  static final List<IslamicEventConfig> all = [
    // ─────────── DAILY ───────────
    IslamicEventConfig(
      key: 'adhkar_morning',
      titles: {
        'ar': 'أذكار الصباح',
        'fr': 'Adhkar du matin',
        'en': 'Morning Adhkar',
        'es': 'Adhkar de la mañana',
      },
      descriptions: {
        'ar': 'بعد صلاة الصبح من كل يوم',
        'fr': 'Après la prière de Fajr, chaque jour',
        'en': 'After Fajr prayer, every day',
        'es': 'Después de la oración del Fajr, cada día',
      },
      virtues: {
        'ar': '«من قال حين يصبح…» — رواه أبو داود',
        'fr': "Hisn al-Muslim — Forteresse du musulman",
        'en': 'From Hisn al-Muslim — daily protection',
        'es': 'De Hisn al-Muslim — protección diaria',
      },
      frequency: IslamicFrequency.daily,
      hour: 6, minute: 30,
      color: AppColors.green,
      emoji: '🌅',
    ),
    IslamicEventConfig(
      key: 'adhkar_evening',
      titles: {
        'ar': 'أذكار المساء',
        'fr': 'Adhkar du soir',
        'en': 'Evening Adhkar',
        'es': 'Adhkar de la tarde',
      },
      descriptions: {
        'ar': 'بعد صلاة العصر من كل يوم',
        'fr': 'Après la prière de Asr, chaque jour',
        'en': 'After Asr prayer, every day',
        'es': 'Después de la oración del Asr, cada día',
      },
      virtues: {
        'ar': '«من قال حين يمسي…» — رواه أبو داود',
        'fr': "Récompense immense — Hisn al-Muslim",
        'en': 'Immense reward — Hisn al-Muslim',
        'es': 'Inmensa recompensa — Hisn al-Muslim',
      },
      frequency: IslamicFrequency.daily,
      hour: 17, minute: 0,
      color: AppColors.green,
      emoji: '🌇',
    ),
    IslamicEventConfig(
      key: 'adhkar_sleep',
      titles: {
        'ar': 'أذكار النوم',
        'fr': 'Adhkar du coucher',
        'en': 'Sleep Adhkar',
        'es': 'Adhkar antes de dormir',
      },
      descriptions: {
        'ar': 'كل يوم بعد صلاة العشاء بساعة',
        'fr': 'Chaque soir, 1h après Isha',
        'en': 'Each night, 1h after Isha',
        'es': 'Cada noche, 1h después de Isha',
      },
      virtues: {
        'ar': 'حماية وحفظ من الله طوال الليل',
        'fr': 'Protection durant la nuit',
        'en': 'Protection through the night',
        'es': 'Protección durante la noche',
      },
      frequency: IslamicFrequency.daily,
      hour: 22, minute: 0,
      color: AppColors.gold,
      emoji: '🌙',
    ),

    // ─────────── WEEKLY ───────────
    IslamicEventConfig(
      key: 'jumua',
      titles: {
        'ar': 'الجمعة', 'fr': 'Joumoua',
        'en': "Jumu'ah", 'es': "Yumu'ah",
      },
      descriptions: {
        'ar': 'صلاة الجمعة - أعظم يوم في الأسبوع',
        'fr': 'Prière du vendredi - le meilleur jour de la semaine',
        'en': 'Friday prayer - the best day of the week',
        'es': 'Oración del viernes - el mejor día de la semana',
      },
      virtues: {
        'ar': '«خير يوم طلعت عليه الشمس يوم الجمعة» — مسلم',
        'fr': "« Le meilleur jour est le vendredi » — Mouslim",
        'en': '"The best day is Friday" — Muslim',
        'es': '"El mejor día es el viernes" — Muslim',
      },
      frequency: IslamicFrequency.weekly,
      weekday: DateTime.friday,
      hour: 12, minute: 0,
      color: AppColors.green,
      emoji: '🕌',
    ),
    IslamicEventConfig(
      key: 'fast_mon_thu',
      titles: {
        'ar': 'صيام الاثنين والخميس',
        'fr': 'Jeûne lundi & jeudi',
        'en': 'Monday & Thursday fast',
        'es': 'Ayuno lunes y jueves',
      },
      descriptions: {
        'ar': 'صيام التطوع كل اثنين وخميس',
        'fr': 'Jeûne surérogatoire chaque lundi et jeudi',
        'en': 'Voluntary fast every Monday and Thursday',
        'es': 'Ayuno voluntario cada lunes y jueves',
      },
      virtues: {
        'ar': '«تُعرض الأعمال يوم الاثنين والخميس» — الترمذي',
        'fr': "« Les œuvres sont présentées les lundis et jeudis »",
        'en': '"Deeds are presented on Mondays and Thursdays"',
        'es': '"Las obras se presentan los lunes y jueves"',
      },
      frequency: IslamicFrequency.weekly,
      weekday: DateTime.monday, // we expand to monday + thursday in helper
      hour: 5, minute: 0,
      color: AppColors.gold,
      emoji: '🤲',
      defaultEnabled: false,
    ),

    // ─────────── MONTHLY ───────────
    IslamicEventConfig(
      key: 'ayyam_albid',
      titles: {
        'ar': 'الأيام البيض', 'fr': 'Ayyam Al-Bid',
        'en': 'White Days', 'es': 'Días Blancos',
      },
      descriptions: {
        'ar': 'صيام أيام 13، 14، 15 من كل شهر هجري',
        'fr': 'Jeûne des 13, 14 et 15 de chaque mois Hijri',
        'en': 'Fasting on the 13th, 14th, 15th of each Hijri month',
        'es': 'Ayuno los días 13, 14, 15 de cada mes Hijri',
      },
      virtues: {
        'ar': '«صيام ثلاثة أيام من كل شهر صيام الدهر» — البخاري',
        'fr': "« Trois jours par mois équivalent au jeûne perpétuel »",
        'en': '"Fasting 3 days each month equals fasting all year"',
        'es': '"Ayunar 3 días al mes equivale a ayunar todo el año"',
      },
      frequency: IslamicFrequency.monthly,
      month: 0, days: [13, 14, 15],
      hour: 5, minute: 0,
      color: AppColors.green,
      emoji: '🌕',
    ),
    IslamicEventConfig(
      key: 'hijama',
      titles: {
        'ar': 'الحجامة', 'fr': 'Hijama',
        'en': 'Hijama (Cupping)', 'es': 'Hijama',
      },
      descriptions: {
        'ar': 'يوم 17، 19، 21 من كل شهر هجري',
        'fr': 'Les 17, 19 et 21 de chaque mois Hijri',
        'en': '17th, 19th, 21st of each Hijri month',
        'es': 'Los 17, 19 y 21 de cada mes Hijri',
      },
      virtues: {
        'ar': '«إن أمثل ما تداويتم به الحجامة» — البخاري ومسلم',
        'fr': "« Le meilleur remède est la Hijama » — Boukhari/Mouslim",
        'en': '"The best remedy is Hijama" — Bukhari/Muslim',
        'es': '"El mejor remedio es la Hijama" — Bukhari/Muslim',
      },
      frequency: IslamicFrequency.monthly,
      month: 0, days: [17, 19, 21],
      hour: 9, minute: 0,
      color: AppColors.red,
      emoji: '🩸',
      defaultEnabled: false,
    ),

    // ─────────── ANNUAL ───────────
    IslamicEventConfig(
      key: 'ashura',
      titles: {'ar': 'عاشوراء', 'fr': 'Achoura', 'en': 'Ashura', 'es': 'Ashura'},
      descriptions: {
        'ar': 'اليوم العاشر من محرم - يوم نجاة موسى عليه السلام',
        'fr': '10e jour de Muharram - jour du salut de Moïse',
        'en': '10th of Muharram - day of Moses\' salvation',
        'es': '10 de Muharram - día de la salvación de Moisés',
      },
      virtues: {
        'ar': '«صيام يوم عاشوراء يكفر السنة الماضية» — مسلم',
        'fr': "« Le jeûne d'Achoura efface l'année écoulée » — Mouslim",
        'en': '"Fasting Ashura expiates the past year" — Muslim',
        'es': '"Ayunar Ashura expía el año anterior" — Muslim',
      },
      frequency: IslamicFrequency.annual,
      month: 1, days: [10],
      hour: 5, minute: 0,
      color: AppColors.gold, emoji: '🕯',
    ),
    IslamicEventConfig(
      key: 'ramadan_start',
      titles: {
        'ar': 'بداية رمضان', 'fr': 'Début du Ramadan',
        'en': 'Start of Ramadan', 'es': 'Inicio del Ramadán',
      },
      descriptions: {
        'ar': 'أول يوم من شهر رمضان المبارك',
        'fr': 'Premier jour du mois béni de Ramadan',
        'en': 'First day of the blessed month of Ramadan',
        'es': 'Primer día del bendito mes de Ramadán',
      },
      virtues: {
        'ar': '«من صام رمضان إيماناً واحتساباً غُفر له ما تقدم من ذنبه» — البخاري',
        'fr': "« Pardon de tous les péchés passés » — Boukhari",
        'en': '"All previous sins forgiven" — Bukhari',
        'es': '"Perdón de los pecados pasados" — Bukhari',
      },
      frequency: IslamicFrequency.annual,
      month: 9, days: [1],
      hour: 4, minute: 30,
      color: AppColors.gold, emoji: '🌙',
    ),
    IslamicEventConfig(
      key: 'eid_fitr',
      titles: {
        'ar': 'عيد الفطر', 'fr': 'Aïd al-Fitr',
        'en': 'Eid al-Fitr', 'es': 'Eid al-Fitr',
      },
      descriptions: {
        'ar': 'عيد الفطر المبارك - 1 شوال',
        'fr': 'Fête de la rupture du jeûne - 1 Chawwal',
        'en': 'Festival of breaking the fast - 1 Shawwal',
        'es': 'Fiesta de la ruptura del ayuno - 1 Shawwal',
      },
      virtues: {
        'ar': 'يوم فرح وشكر لله تعالى',
        'fr': "Jour de joie et de gratitude envers Allah",
        'en': 'A day of joy and gratitude to Allah',
        'es': 'Día de alegría y gratitud hacia Allah',
      },
      frequency: IslamicFrequency.annual,
      month: 10, days: [1],
      hour: 7, minute: 0,
      color: AppColors.gold, emoji: '🎉',
    ),
    IslamicEventConfig(
      key: 'first_dhulhijja',
      titles: {
        'ar': 'أول أيام عشر ذي الحجة',
        'fr': 'Premiers jours de Dhoul Hijja',
        'en': 'First 10 days of Dhul Hijjah',
        'es': 'Primeros 10 días de Dhul Hijjah',
      },
      descriptions: {
        'ar': 'أيام عشر ذي الحجة المباركة (1-9)',
        'fr': 'Les 10 jours bénis de Dhoul Hijja (1-9)',
        'en': 'The blessed first 10 days of Dhul Hijjah (1-9)',
        'es': 'Los 10 días bendecidos de Dhul Hijjah (1-9)',
      },
      virtues: {
        'ar': '«ما من أيام العمل الصالح فيها أحب إلى الله من هذه الأيام» — البخاري',
        'fr': "« Aucune œuvre n'est plus aimée d'Allah qu'en ces jours » — Boukhari",
        'en': '"No deeds more beloved to Allah than in these days" — Bukhari',
        'es': '"Ninguna obra es más amada por Allah que en estos días" — Bukhari',
      },
      frequency: IslamicFrequency.annual,
      month: 12, days: [1, 2, 3, 4, 5, 6, 7, 8, 9],
      hour: 6, minute: 0,
      color: AppColors.gold, emoji: '📅',
    ),
    IslamicEventConfig(
      key: 'arafat',
      titles: {
        'ar': 'يوم عرفة', 'fr': 'Jour de Arafat',
        'en': 'Day of Arafat', 'es': 'Día de Arafat',
      },
      descriptions: {
        'ar': 'يوم عرفة - أفضل أيام السنة (9 ذو الحجة)',
        'fr': "Jour de Arafat - le meilleur jour de l'année (9 Dhoul Hijja)",
        'en': 'Day of Arafat - the best day of the year (9 Dhul Hijjah)',
        'es': 'Día de Arafat - el mejor día del año (9 Dhul Hijjah)',
      },
      virtues: {
        'ar': '«صيام يوم عرفة يكفر سنتين: ماضية ومستقبلة» — مسلم',
        'fr': "« Le jeûne de Arafat efface 2 ans : passé et à venir » — Mouslim",
        'en': '"Fasting Arafat expiates 2 years: past and coming" — Muslim',
        'es': '"Ayunar Arafat expía 2 años: pasado y futuro" — Muslim',
      },
      frequency: IslamicFrequency.annual,
      month: 12, days: [9],
      hour: 5, minute: 0,
      color: AppColors.gold, emoji: '🏔',
      alwaysOn: true,
    ),
    IslamicEventConfig(
      key: 'eid_adha',
      titles: {
        'ar': 'عيد الأضحى', 'fr': 'Aïd al-Adha',
        'en': 'Eid al-Adha', 'es': 'Eid al-Adha',
      },
      descriptions: {
        'ar': 'عيد الأضحى المبارك - 10 ذو الحجة',
        'fr': 'Fête du sacrifice - 10 Dhoul Hijja',
        'en': 'Festival of sacrifice - 10 Dhul Hijjah',
        'es': 'Fiesta del sacrificio - 10 Dhul Hijjah',
      },
      virtues: {
        'ar': '«أعظم الأيام عند الله يوم النحر» — أبو داود',
        'fr': "« Le plus grand jour auprès d'Allah est le jour du sacrifice »",
        'en': '"The greatest day with Allah is the day of sacrifice"',
        'es': '"El día más grande ante Allah es el día del sacrificio"',
      },
      frequency: IslamicFrequency.annual,
      month: 12, days: [10],
      hour: 7, minute: 0,
      color: AppColors.gold, emoji: '🎊',
    ),
  ];

  /// Returns events occurring on a specific Hijri date (for the calendar grid).
  static List<AppEvent> eventsForDate(
    int hijriDay, int hijriMonth, int hijriYear,
    Set<String> enabledKeys,
    DateTime gregorianDate,
  ) {
    final List<AppEvent> result = [];
    for (final cfg in all) {
      final isEnabled = cfg.alwaysOn || enabledKeys.contains(cfg.key);
      if (!isEnabled) continue;

      bool occurs = false;
      switch (cfg.frequency) {
        case IslamicFrequency.daily:
          occurs = true;
          break;
        case IslamicFrequency.weekly:
          if (cfg.key == 'fast_mon_thu') {
            occurs = gregorianDate.weekday == DateTime.monday ||
                     gregorianDate.weekday == DateTime.thursday;
          } else {
            occurs = gregorianDate.weekday == cfg.weekday;
          }
          break;
        case IslamicFrequency.monthly:
          occurs = cfg.days.contains(hijriDay);
          break;
        case IslamicFrequency.annual:
          occurs = cfg.month == hijriMonth && cfg.days.contains(hijriDay);
          break;
      }
      if (!occurs) continue;

      result.add(AppEvent(
        id: 'islamic_${cfg.key}_${hijriYear}_${hijriMonth}_$hijriDay',
        titles: cfg.titles,
        description: cfg.descriptions['ar'] ?? '',
        descriptions: cfg.descriptions,
        virtues: cfg.virtues,
        hijriDay: hijriDay,
        hijriMonth: hijriMonth,
        hijriYear: 0,
        hour: cfg.hour,
        minute: cfg.minute,
        color: cfg.color,
        isIslamic: true,
        isRecurring: true,
        emoji: cfg.emoji,
        category: 'religious',
      ));
    }
    return result;
  }

  static IslamicEventConfig? byKey(String key) {
    for (final c in all) {
      if (c.key == key) return c;
    }
    return null;
  }
}
