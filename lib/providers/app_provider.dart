import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../data/islamic_events.dart';
import '../utils/hijri_utils.dart';
import '../services/notification_service.dart';
import '../services/regional_hijri_service.dart';

enum CalendarView { monthly, weekly, agenda }
enum AppThemeMode { light, dark, system }
enum CalendarDensity { compact, normal, expanded }

class AppProvider extends ChangeNotifier {
  static const _kEventsKey = 'events_v1';
  static const _kEnabledIslamicKey = 'enabled_islamic_v1';
  static const _kLanguageKey = 'language_v1';
  static const _kThemeKey = 'theme_v1';
  static const _kOnboardingKey = 'onboarding_v1';
  static const _kAccentColorKey = 'accent_color_v1';
  static const _kFontScaleKey = 'font_scale_v1';
  static const _kHijriOffsetKey = 'hijri_offset_v1';
  static const _kRegionKey = 'region_v1';
  static const _kProfileNameKey = 'profile_name_v1';
  static const _kDefaultViewKey = 'default_view_v1';
  static const _kDensityKey = 'density_v1';
  static const _kShowAyyamBidKey = 'show_ayyam_bid_v1';
  static const _kShowRamadanKey = 'show_ramadan_v1';
  static const _kShowGregorianInCellKey = 'show_greg_cell_v1';
  static const _kShowDualHeaderKey = 'show_dual_header_v1';
  static const _kShowGregorianMonthsKey = 'show_greg_months_v1';
  static const _kHighlightFridayKey = 'highlight_friday_v1';
  static const _k29thReminderKey = '29th_reminder_v1';
  static const _k29thTimeKey = '29th_time_v1';
  static const _kDailySummaryKey = 'daily_summary_v1';
  static const _kDailySummaryTimeKey = 'daily_summary_time_v1';
  static const _kRamadanReminderDaysKey = 'ramadan_reminder_days_v1';
  static const _k29thChoicePrefix = '29th_choice_';

  final _uuid = const Uuid();

  // State
  List<AppEvent> _events = [];
  Set<String> _enabledIslamic = {};
  String _language = 'ar';
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _onboardingComplete = false;
  int _accentColor = 0xFF2D7D5F;
  double _fontScale = 1.0;
  int _hijriOffset = 0;
  String _region = 'global';
  String _profileName = '';
  CalendarView _view = CalendarView.monthly;
  CalendarView _defaultView = CalendarView.monthly;
  CalendarDensity _density = CalendarDensity.normal;

  bool _showAyyamBid = true;
  bool _showRamadan = true;
  bool _showGregorianInCell = true;
  bool _showDualHeader = true;
  bool _showGregorianMonths = false;
  bool _highlightFriday = true;

  bool _enable29thReminder = true;
  TimeOfDay _time29th = const TimeOfDay(hour: 21, minute: 0);
  bool _enableDailySummary = false;
  TimeOfDay _dailySummaryTime = const TimeOfDay(hour: 7, minute: 0);
  int _ramadanReminderDays = 0; // Removed from UI; disabled by default.

  HijriDate _focusedHijri = HijriDate.now();
  DateTime _focusedGregorian = DateTime.now();

  // Getters
  List<AppEvent> get events => _events;
  Set<String> get enabledIslamic => _enabledIslamic;
  String get language => _language;
  AppThemeMode get themeMode => _themeMode;
  bool get onboardingComplete => _onboardingComplete;
  int get accentColor => _accentColor;
  double get fontScale => _fontScale;
  int get hijriOffset => _hijriOffset;
  String get region => _region;
  String get profileName => _profileName;
  CalendarView get view => _view;
  CalendarView get defaultView => _defaultView;
  CalendarDensity get density => _density;
  bool get showAyyamBid => _showAyyamBid;
  bool get showRamadan => _showRamadan;
  bool get showGregorianInCell => _showGregorianInCell;
  bool get showDualHeader => _showDualHeader;
  bool get showGregorianMonths => _showGregorianMonths;
  bool get highlightFriday => _highlightFriday;
  bool get enable29thReminder => _enable29thReminder;
  TimeOfDay get time29th => _time29th;
  bool get enableDailySummary => _enableDailySummary;
  TimeOfDay get dailySummaryTime => _dailySummaryTime;
  int get ramadanReminderDays => _ramadanReminderDays;
  HijriDate get focusedHijri => _focusedHijri;
  DateTime get focusedGregorian => _focusedGregorian;
  bool get isRtl => _language == 'ar';

  Locale get locale => Locale(_language);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString(_kLanguageKey) ?? 'ar';
    _themeMode = AppThemeMode.values[prefs.getInt(_kThemeKey) ?? AppThemeMode.system.index];
    _onboardingComplete = prefs.getBool(_kOnboardingKey) ?? false;
    _accentColor = prefs.getInt(_kAccentColorKey) ?? 0xFF2D7D5F;
    _fontScale = prefs.getDouble(_kFontScaleKey) ?? 1.0;
    _hijriOffset = prefs.getInt(_kHijriOffsetKey) ?? 0;
    _region = prefs.getString(_kRegionKey) ?? 'global';
    _profileName = prefs.getString(_kProfileNameKey) ?? '';
    _defaultView = CalendarView.values[prefs.getInt(_kDefaultViewKey) ?? 0];
    _view = _defaultView;
    _density = CalendarDensity.values[prefs.getInt(_kDensityKey) ?? 1];
    _showAyyamBid = prefs.getBool(_kShowAyyamBidKey) ?? true;
    _showRamadan = prefs.getBool(_kShowRamadanKey) ?? true;
    _showGregorianInCell = prefs.getBool(_kShowGregorianInCellKey) ?? true;
    _showDualHeader = prefs.getBool(_kShowDualHeaderKey) ?? true;
    _showGregorianMonths = prefs.getBool(_kShowGregorianMonthsKey) ?? false;
    _highlightFriday = prefs.getBool(_kHighlightFridayKey) ?? true;
    _enable29thReminder = prefs.getBool(_k29thReminderKey) ?? true;
    _time29th = _decodeTime(prefs.getString(_k29thTimeKey)) ?? const TimeOfDay(hour: 21, minute: 0);
    _enableDailySummary = prefs.getBool(_kDailySummaryKey) ?? false;
    _dailySummaryTime = _decodeTime(prefs.getString(_kDailySummaryTimeKey)) ?? const TimeOfDay(hour: 7, minute: 0);
    _ramadanReminderDays = prefs.getInt(_kRamadanReminderDaysKey) ?? 0;

    final eventsJson = prefs.getString(_kEventsKey);
    if (eventsJson != null) {
      try {
        final List list = jsonDecode(eventsJson);
        _events = list.map((e) => AppEvent.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) { _events = []; }
    }

    final enabled = prefs.getStringList(_kEnabledIslamicKey);
    if (enabled != null) {
      _enabledIslamic = enabled.toSet();
    } else {
      _enabledIslamic = IslamicEventsData.all
          .where((e) => e.defaultEnabled)
          .map((e) => e.key)
          .toSet();
    }
    // Initialize the focus pair using the regional source, so the calendar
    // header opens on the correct Hijri month for the chosen region.
    _focusedGregorian = DateTime.now();
    _focusedHijri = RegionalHijri.fromGregorian(_focusedGregorian,
        region: _region, userOffset: _hijriOffset);
    notifyListeners();
  }

  TimeOfDay? _decodeTime(String? s) {
    if (s == null) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0,
                     minute: int.tryParse(parts[1]) ?? 0);
  }

  String _encodeTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';

  String label(String key) {
    final m = _labels[key] ?? const {};
    return m[_language] ?? m['en'] ?? key;
  }

  // ===== persistence =====
  Future<void> _persistEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEventsKey, jsonEncode(_events.map((e) => e.toJson()).toList()));
  }

  Future<void> _persistEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kEnabledIslamicKey, _enabledIslamic.toList());
  }

  Future<void> _refreshNotifications() async {
    await NotificationService.instance.rescheduleAll(
      personalEvents: _events,
      enabledIslamic: _enabledIslamic,
      enable29th: _enable29thReminder,
      time29th: _time29th,
      enableDailySummary: _enableDailySummary,
      dailySummaryTime: _dailySummaryTime,
      ramadanReminderDays: _ramadanReminderDays,
      language: _language,
      region: _region,
      userOffset: _hijriOffset,
      accentColor: _accentColor,
    );
  }

  // ===== regional Hijri helpers (single source of truth) =====
  HijriDate today() =>
      RegionalHijri.today(region: _region, userOffset: _hijriOffset);

  HijriDate hijriFromGregorian(DateTime g) =>
      RegionalHijri.fromGregorian(g, region: _region, userOffset: _hijriOffset);

  DateTime gregorianFromHijri(HijriDate h) =>
      RegionalHijri.toGregorian(h, region: _region, userOffset: _hijriOffset);

  String hijriSourceLabel() => RegionalHijri.sourceLabel(_region, _language);

  // ===== events =====
  Future<void> addEvent(AppEvent e) async {
    e.id = e.id.isEmpty ? _uuid.v4() : e.id;
    _events.add(e);
    await _persistEvents();
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> updateEvent(AppEvent e) async {
    final i = _events.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      _events[i] = e;
      await _persistEvents();
      await _refreshNotifications();
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    await _persistEvents();
    await _refreshNotifications();
    notifyListeners();
  }

  List<AppEvent> eventsForHijri(HijriDate h) {
    final greg = gregorianFromHijri(h);
    final personal = _events.where((e) {
      if (e.isRecurring && e.hijriYear == 0) {
        return e.hijriDay == h.day && e.hijriMonth == h.month;
      }
      return e.hijriDay == h.day && e.hijriMonth == h.month && e.hijriYear == h.year;
    }).toList();
    final islamic = IslamicEventsData.eventsForDate(
      h.day, h.month, h.year, _enabledIslamic, greg);
    return [...islamic, ...personal];
  }

  /// Days from today until the next occurrence of an Islamic event,
  /// looking up to [maxDays] ahead. Returns null if no occurrence.
  int? daysUntilIslamic(IslamicEventConfig cfg, {int maxDays = 365}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 0; i <= maxDays; i++) {
      final g = today.add(Duration(days: i));
      final h = HijriDate.fromGregorian(g);
      bool occurs = false;
      switch (cfg.frequency) {
        case IslamicFrequency.daily:
          occurs = true; break;
        case IslamicFrequency.weekly:
          if (cfg.key == 'fast_mon_thu') {
            occurs = g.weekday == DateTime.monday || g.weekday == DateTime.thursday;
          } else {
            occurs = g.weekday == cfg.weekday;
          }
          break;
        case IslamicFrequency.monthly:
          occurs = cfg.days.contains(h.day); break;
        case IslamicFrequency.annual:
          occurs = cfg.month == h.month && cfg.days.contains(h.day); break;
      }
      if (occurs) return i;
    }
    return null;
  }

  // ===== islamic toggles =====
  Future<void> toggleIslamic(String key) async {
    final cfg = IslamicEventsData.byKey(key);
    if (cfg != null && cfg.alwaysOn) return;
    if (_enabledIslamic.contains(key)) {
      _enabledIslamic.remove(key);
    } else {
      _enabledIslamic.add(key);
    }
    await _persistEnabled();
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> enableAllIslamic() async {
    _enabledIslamic = IslamicEventsData.all.map((e) => e.key).toSet();
    await _persistEnabled();
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> disableAllIslamic() async {
    _enabledIslamic = IslamicEventsData.all
        .where((e) => e.alwaysOn).map((e) => e.key).toSet();
    await _persistEnabled();
    await _refreshNotifications();
    notifyListeners();
  }

  // ===== generic settings =====
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await (await SharedPreferences.getInstance()).setString(_kLanguageKey, lang);
    // Notifications must be re-issued so titles/bodies match the new language.
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await (await SharedPreferences.getInstance()).setInt(_kThemeKey, mode.index);
    notifyListeners();
  }

  Future<void> setAccentColor(int c) async {
    _accentColor = c;
    await (await SharedPreferences.getInstance()).setInt(_kAccentColorKey, c);
    notifyListeners();
  }

  Future<void> setFontScale(double s) async {
    _fontScale = s;
    await (await SharedPreferences.getInstance()).setDouble(_kFontScaleKey, s);
    notifyListeners();
  }

  Future<void> setHijriOffset(int o) async {
    _hijriOffset = o;
    await (await SharedPreferences.getInstance()).setInt(_kHijriOffsetKey, o);
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> setRegion(String r) async {
    _region = r;
    int offset = 0;
    switch (r) {
      case 'morocco': offset = 0; break;
      case 'algeria': offset = 0; break;
      case 'tunisia': offset = 0; break;
      case 'saudi': offset = 0; break;
      case 'turkey': offset = 0; break;
      case 'indonesia': offset = 0; break;
      default: offset = 0;
    }
    await (await SharedPreferences.getInstance()).setString(_kRegionKey, r);
    if (offset != _hijriOffset) {
      _hijriOffset = offset;
      await (await SharedPreferences.getInstance()).setInt(_kHijriOffsetKey, offset);
    }
    // Region change affects every Hijri computation -> re-plan notifications.
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> setProfileName(String n) async {
    _profileName = n;
    await (await SharedPreferences.getInstance()).setString(_kProfileNameKey, n);
    notifyListeners();
  }

  Future<void> setDefaultView(CalendarView v) async {
    _defaultView = v;
    _view = v;
    await (await SharedPreferences.getInstance()).setInt(_kDefaultViewKey, v.index);
    notifyListeners();
  }

  Future<void> setDensity(CalendarDensity d) async {
    _density = d;
    await (await SharedPreferences.getInstance()).setInt(_kDensityKey, d.index);
    notifyListeners();
  }

  Future<void> setShowAyyamBid(bool v) async {
    _showAyyamBid = v;
    await (await SharedPreferences.getInstance()).setBool(_kShowAyyamBidKey, v);
    notifyListeners();
  }
  Future<void> setShowRamadan(bool v) async {
    _showRamadan = v;
    await (await SharedPreferences.getInstance()).setBool(_kShowRamadanKey, v);
    notifyListeners();
  }
  Future<void> setShowGregorianInCell(bool v) async {
    _showGregorianInCell = v;
    await (await SharedPreferences.getInstance()).setBool(_kShowGregorianInCellKey, v);
    notifyListeners();
  }
  Future<void> setShowDualHeader(bool v) async {
    _showDualHeader = v;
    await (await SharedPreferences.getInstance()).setBool(_kShowDualHeaderKey, v);
    notifyListeners();
  }
  Future<void> setShowGregorianMonths(bool v) async {
    _showGregorianMonths = v;
    await (await SharedPreferences.getInstance()).setBool(_kShowGregorianMonthsKey, v);
    notifyListeners();
  }
  Future<void> setHighlightFriday(bool v) async {
    _highlightFriday = v;
    await (await SharedPreferences.getInstance()).setBool(_kHighlightFridayKey, v);
    notifyListeners();
  }

  Future<void> setEnable29thReminder(bool v) async {
    _enable29thReminder = v;
    await (await SharedPreferences.getInstance()).setBool(_k29thReminderKey, v);
    await _refreshNotifications();
    notifyListeners();
  }
  Future<void> setTime29th(TimeOfDay t) async {
    _time29th = t;
    await (await SharedPreferences.getInstance()).setString(_k29thTimeKey, _encodeTime(t));
    await _refreshNotifications();
    notifyListeners();
  }
  Future<void> setEnableDailySummary(bool v) async {
    _enableDailySummary = v;
    await (await SharedPreferences.getInstance()).setBool(_kDailySummaryKey, v);
    await _refreshNotifications();
    notifyListeners();
  }
  Future<void> setDailySummaryTime(TimeOfDay t) async {
    _dailySummaryTime = t;
    await (await SharedPreferences.getInstance()).setString(_kDailySummaryTimeKey, _encodeTime(t));
    await _refreshNotifications();
    notifyListeners();
  }
  Future<void> setRamadanReminderDays(int d) async {
    _ramadanReminderDays = d;
    await (await SharedPreferences.getInstance()).setInt(_kRamadanReminderDaysKey, d);
    await _refreshNotifications();
    notifyListeners();
  }

  // ===== 29th-day per-month choice =====
  Future<void> set29thChoice(int hijriYear, int hijriMonth, String choice) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('$_k29thChoicePrefix${hijriYear}_$hijriMonth', choice);
  }
  Future<String?> get29thChoice(int hijriYear, int hijriMonth) async {
    final p = await SharedPreferences.getInstance();
    return p.getString('$_k29thChoicePrefix${hijriYear}_$hijriMonth');
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    await (await SharedPreferences.getInstance()).setBool(_kOnboardingKey, true);
    notifyListeners();
  }

  void setView(CalendarView v) { _view = v; notifyListeners(); }

  void setFocusedHijri(HijriDate h) {
    _focusedHijri = h;
    _focusedGregorian = gregorianFromHijri(h);
    notifyListeners();
  }

  void setFocusedGregorian(DateTime d) {
    _focusedGregorian = d;
    _focusedHijri = hijriFromGregorian(d);
    notifyListeners();
  }

  // ===== labels =====
  static const Map<String, Map<String, String>> _labels = {
    'app_name': {'ar': 'بدر', 'fr': 'Badr', 'en': 'Badr', 'es': 'Badr'},
    'tab_calendar': {'ar': 'التقويم', 'fr': 'Calendrier', 'en': 'Calendar', 'es': 'Calendario'},
    'tab_bank': {'ar': 'فضائل إسلامية', 'fr': 'Vertus islamiques', 'en': 'Islamic Virtues', 'es': 'Virtudes islámicas'},
    'tab_converter': {'ar': 'محوّل', 'fr': 'Convertir', 'en': 'Convert', 'es': 'Convertir'},
    'tab_settings': {'ar': 'الإعدادات', 'fr': 'Paramètres', 'en': 'Settings', 'es': 'Ajustes'},
    'new_event': {'ar': 'حدث جديد', 'fr': 'Nouvel événement', 'en': 'New event', 'es': 'Nuevo evento'},
    'edit_event': {'ar': 'تعديل الحدث', 'fr': 'Modifier', 'en': 'Edit event', 'es': 'Editar'},
    'save': {'ar': 'حفظ', 'fr': 'Enregistrer', 'en': 'Save', 'es': 'Guardar'},
    'cancel': {'ar': 'إلغاء', 'fr': 'Annuler', 'en': 'Cancel', 'es': 'Cancelar'},
    'delete': {'ar': 'حذف', 'fr': 'Supprimer', 'en': 'Delete', 'es': 'Eliminar'},
    'title': {'ar': 'العنوان', 'fr': 'Titre', 'en': 'Title', 'es': 'Título'},
    'description': {'ar': 'الوصف', 'fr': 'Description', 'en': 'Description', 'es': 'Descripción'},
    'date': {'ar': 'التاريخ', 'fr': 'Date', 'en': 'Date', 'es': 'Fecha'},
    'time': {'ar': 'الوقت', 'fr': 'Heure', 'en': 'Time', 'es': 'Hora'},
    'all_day': {'ar': 'طوال اليوم', 'fr': 'Toute la journée', 'en': 'All day', 'es': 'Todo el día'},
    'location': {'ar': 'الموقع', 'fr': 'Lieu', 'en': 'Location', 'es': 'Ubicación'},
    'notifications': {'ar': 'الإشعارات', 'fr': 'Notifications', 'en': 'Notifications', 'es': 'Notificaciones'},
    'reminders': {'ar': 'التذكيرات', 'fr': 'Rappels', 'en': 'Reminders', 'es': 'Recordatorios'},
    'category': {'ar': 'الفئة', 'fr': 'Catégorie', 'en': 'Category', 'es': 'Categoría'},
    'priority': {'ar': 'الأولوية', 'fr': 'Priorité', 'en': 'Priority', 'es': 'Prioridad'},
    'color': {'ar': 'اللون', 'fr': 'Couleur', 'en': 'Color', 'es': 'Color'},
    'today': {'ar': 'اليوم', 'fr': "Aujourd'hui", 'en': 'Today', 'es': 'Hoy'},
    'no_events': {'ar': 'لا توجد أحداث', 'fr': 'Aucun événement', 'en': 'No events', 'es': 'Sin eventos'},
    'language': {'ar': 'اللغة', 'fr': 'Langue', 'en': 'Language', 'es': 'Idioma'},
    'theme': {'ar': 'المظهر', 'fr': 'Thème', 'en': 'Theme', 'es': 'Tema'},
    'theme_light': {'ar': 'فاتح', 'fr': 'Clair', 'en': 'Light', 'es': 'Claro'},
    'theme_dark': {'ar': 'داكن', 'fr': 'Sombre', 'en': 'Dark', 'es': 'Oscuro'},
    'theme_system': {'ar': 'تلقائي', 'fr': 'Auto', 'en': 'System', 'es': 'Sistema'},
    'enable_all': {'ar': 'تفعيل الكل', 'fr': 'Tout activer', 'en': 'Enable all', 'es': 'Activar todo'},
    'disable_all': {'ar': 'إلغاء الكل', 'fr': 'Tout désactiver', 'en': 'Disable all', 'es': 'Desactivar todo'},
    'view_monthly': {'ar': 'شهري', 'fr': 'Mois', 'en': 'Month', 'es': 'Mes'},
    'view_weekly': {'ar': 'أسبوعي', 'fr': 'Semaine', 'en': 'Week', 'es': 'Semana'},
    'view_agenda': {'ar': 'أجندة', 'fr': 'Agenda', 'en': 'Agenda', 'es': 'Agenda'},
    'badge_islamic': {'ar': 'إسلامي', 'fr': 'Islamique', 'en': 'Islamic', 'es': 'Islámico'},
    'badge_personal': {'ar': 'شخصي', 'fr': 'Personnel', 'en': 'Personal', 'es': 'Personal'},
    'hijri_to_greg': {'ar': 'هجري إلى ميلادي', 'fr': 'Hijri vers Grégorien', 'en': 'Hijri to Gregorian', 'es': 'Hijri a Gregoriano'},
    'greg_to_hijri': {'ar': 'ميلادي إلى هجري', 'fr': 'Grégorien vers Hijri', 'en': 'Gregorian to Hijri', 'es': 'Gregoriano a Hijri'},
    'corresponds_to': {'ar': 'الموافق', 'fr': 'Correspond à', 'en': 'Corresponds to', 'es': 'Corresponde a'},
    'welcome': {'ar': 'مرحباً', 'fr': 'Bienvenue', 'en': 'Welcome', 'es': 'Bienvenido'},
    'get_started': {'ar': 'ابدأ', 'fr': 'Commencer', 'en': 'Get started', 'es': 'Empezar'},
    'next': {'ar': 'التالي', 'fr': 'Suivant', 'en': 'Next', 'es': 'Siguiente'},
    'choose_language': {'ar': 'اختر لغتك', 'fr': 'Choisissez votre langue', 'en': 'Choose your language', 'es': 'Elige tu idioma'},
    'enable_islamic_events': {'ar': 'فعّل الفضائل الإسلامية', 'fr': 'Activez les vertus islamiques', 'en': 'Enable Islamic virtues', 'es': 'Activa virtudes islámicas'},
    'share': {'ar': 'مشاركة', 'fr': 'Partager', 'en': 'Share', 'es': 'Compartir'},
    'cat_personal': {'ar': 'شخصي', 'fr': 'Personnel', 'en': 'Personal', 'es': 'Personal'},
    'cat_religious': {'ar': 'ديني', 'fr': 'Religieux', 'en': 'Religious', 'es': 'Religioso'},
    'cat_family': {'ar': 'عائلي', 'fr': 'Famille', 'en': 'Family', 'es': 'Familia'},
    'cat_work': {'ar': 'عمل', 'fr': 'Travail', 'en': 'Work', 'es': 'Trabajo'},
    'cat_health': {'ar': 'صحة', 'fr': 'Santé', 'en': 'Health', 'es': 'Salud'},
    'cat_social': {'ar': 'اجتماعي', 'fr': 'Social', 'en': 'Social', 'es': 'Social'},
    'priority_low': {'ar': 'منخفض', 'fr': 'Basse', 'en': 'Low', 'es': 'Baja'},
    'priority_medium': {'ar': 'متوسط', 'fr': 'Moyenne', 'en': 'Medium', 'es': 'Media'},
    'priority_high': {'ar': 'عالي', 'fr': 'Haute', 'en': 'High', 'es': 'Alta'},
    'add_reminder': {'ar': 'إضافة تذكير', 'fr': 'Ajouter un rappel', 'en': 'Add reminder', 'es': 'Añadir recordatorio'},
    'at_event': {'ar': 'عند الحدث', 'fr': "À l'heure", 'en': 'At time of event', 'es': 'A la hora'},
    'min_before': {'ar': 'دقائق قبل', 'fr': 'min avant', 'en': 'min before', 'es': 'min antes'},
    'hour_before': {'ar': 'ساعة قبل', 'fr': 'heure avant', 'en': 'hour before', 'es': 'hora antes'},
    'day_before': {'ar': 'يوم قبل', 'fr': 'jour avant', 'en': 'day before', 'es': 'día antes'},
    // ── Notification screen / agenda notifications (translated) ─────────
    'notif_title_screen': {'ar': 'إشعارات الأجندة', 'fr': "Notifications d'agenda", 'en': 'Agenda notifications', 'es': 'Notificaciones de agenda'},
    'notif_authorization': {'ar': 'السماح بالإشعارات', 'fr': 'Autorisation des notifications', 'en': 'Allow notifications', 'es': 'Permitir notificaciones'},
    'notif_mode_alert': {'ar': 'تنبيه', 'fr': 'Alerte', 'en': 'Alert', 'es': 'Alerta'},
    'notif_mode_silent': {'ar': 'هادئ', 'fr': 'Discret', 'en': 'Silent', 'es': 'Silencioso'},
    'notif_popup': {'ar': 'العرض كنافذة منبثقة', 'fr': 'Affichage sous forme de pop-up', 'en': 'Show as pop-up', 'es': 'Mostrar como pop-up'},
    'notif_sound': {'ar': 'الصوت', 'fr': 'Son', 'en': 'Sound', 'es': 'Sonido'},
    'notif_sound_picker': {'ar': 'صوت الإشعار', 'fr': 'Son de notification', 'en': 'Notification sound', 'es': 'Sonido'},
    'notif_vibration': {'ar': 'الاهتزاز', 'fr': 'Vibreur', 'en': 'Vibration', 'es': 'Vibración'},
    'notif_lock_screen': {'ar': 'شاشة القفل', 'fr': 'Écran de verrouillage', 'en': 'Lock screen', 'es': 'Pantalla de bloqueo'},
    'notif_lock_hide_content': {'ar': 'إخفاء المحتوى', 'fr': 'Masquer le contenu', 'en': 'Hide content', 'es': 'Ocultar contenido'},
    'notif_lock_hide_all': {'ar': 'عدم عرض الإشعارات', 'fr': 'Ne pas afficher les notifications', 'en': "Don't show notifications", 'es': 'No mostrar notificaciones'},
    'notif_lock_show_all': {'ar': 'إظهار كل المحتوى', 'fr': 'Afficher tout le contenu', 'en': 'Show all content', 'es': 'Mostrar todo'},
    'notif_volume': {'ar': 'مستوى الصوت', 'fr': 'Volume des notifications', 'en': 'Notification volume', 'es': 'Volumen'},
    'notif_test': {'ar': 'اختبار الآن', 'fr': 'Tester maintenant', 'en': 'Test now', 'es': 'Probar ahora'},
    'notif_test_sent': {'ar': '🔔 تم إرسال إشعار تجريبي', 'fr': '🔔 Test envoyé', 'en': '🔔 Test sent', 'es': '🔔 Prueba enviada'},
    'notif_personalize': {'ar': 'تخصيص', 'fr': 'Personnaliser', 'en': 'Customize', 'es': 'Personalizar'},
    'notif_subtitle': {'ar': 'الأصوات، الاهتزاز، شاشة القفل…', 'fr': 'Sons, vibrations, écran de verrouillage…', 'en': 'Sounds, vibration, lock screen…', 'es': 'Sonidos, vibración, pantalla de bloqueo…'},
    // ── Notification BODY translations (used by NotificationService) ─────
    'notif_body_now': {'ar': 'الآن', 'fr': 'Maintenant', 'en': 'Now', 'es': 'Ahora'},
    'notif_body_today': {'ar': 'اليوم', 'fr': "Aujourd'hui", 'en': 'Today', 'es': 'Hoy'},
    'notif_body_tomorrow': {'ar': 'غداً', 'fr': 'Demain', 'en': 'Tomorrow', 'es': 'Mañana'},
    'notif_body_in_min': {'ar': 'بعد {n} دقيقة', 'fr': 'Dans {n} min', 'en': 'In {n} min', 'es': 'En {n} min'},
    'notif_body_in_hour': {'ar': 'بعد {n} ساعة', 'fr': 'Dans {n} h', 'en': 'In {n} h', 'es': 'En {n} h'},
    'notif_body_in_days': {'ar': 'بعد {n} أيام', 'fr': 'Dans {n} jours', 'en': 'In {n} days', 'es': 'En {n} días'},
    'notif_body_in_week': {'ar': 'بعد أسبوع', 'fr': 'Dans une semaine', 'en': 'In one week', 'es': 'En una semana'},
    'notif_event_default': {'ar': 'حدث', 'fr': 'Événement', 'en': 'Event', 'es': 'Evento'},
    'notif_29th_title': {'ar': '🌙 اليوم 29', 'fr': '🌙 29e jour', 'en': '🌙 29th day', 'es': '🌙 Día 29'},
    'notif_29th_body': {'ar': 'تحرَّ هلال الشهر القادم.', 'fr': 'Vérifiez le croissant lunaire pour le mois prochain.', 'en': 'Check the new moon for next month.', 'es': 'Comprueba la luna nueva del próximo mes.'},
    'notif_summary_body': {'ar': 'يوم سعيد — أحداثك بانتظارك.', 'fr': 'Bonne journée — vos événements vous attendent.', 'en': 'Have a great day — your events are waiting.', 'es': 'Buen día — tus eventos te esperan.'},
    'notif_ramadan_title': {'ar': '🌙 رمضان قريباً', 'fr': '🌙 Ramadan approche', 'en': '🌙 Ramadan approaching', 'es': '🌙 Ramadán se acerca'},
    'notif_ramadan_body': {'ar': 'استعد قلبك للشهر المبارك.', 'fr': 'Préparez votre cœur pour le mois béni.', 'en': 'Prepare your heart for the blessed month.', 'es': 'Prepara tu corazón para el mes bendito.'},
    'notif_test_body': {'ar': 'إذا رأيت هذا الإشعار فالنظام يعمل بشكل صحيح.', 'fr': 'Si vous voyez ce message, les notifications fonctionnent.', 'en': 'If you see this, notifications are working.', 'es': 'Si ves esto, las notificaciones funcionan.'},
    'hijri_source': {'ar': 'مصدر التاريخ الهجري', 'fr': 'Source Hijri', 'en': 'Hijri source', 'es': 'Fuente Hijri'},
    'search': {'ar': 'بحث', 'fr': 'Rechercher', 'en': 'Search', 'es': 'Buscar'},
    'about': {'ar': 'حول', 'fr': 'À propos', 'en': 'About', 'es': 'Acerca de'},
    'region': {'ar': 'المنطقة', 'fr': 'Région', 'en': 'Region', 'es': 'Región'},
    'font_size': {'ar': 'حجم الخط', 'fr': 'Taille du texte', 'en': 'Font size', 'es': 'Tamaño'},
    'accent_color': {'ar': 'لون التطبيق', 'fr': 'Couleur principale', 'en': 'Accent color', 'es': 'Color principal'},
    'export': {'ar': 'تصدير', 'fr': 'Exporter', 'en': 'Export', 'es': 'Exportar'},
    'clear_all': {'ar': 'حذف جميع الأحداث', 'fr': 'Effacer tout', 'en': 'Clear all events', 'es': 'Borrar todo'},
    'confirm': {'ar': 'تأكيد', 'fr': 'Confirmer', 'en': 'Confirm', 'es': 'Confirmar'},
    'profile': {'ar': 'الملف الشخصي', 'fr': 'Profil', 'en': 'Profile', 'es': 'Perfil'},
    'name': {'ar': 'الاسم', 'fr': 'Nom', 'en': 'Name', 'es': 'Nombre'},
    'stats_total': {'ar': 'مجموع الأحداث', 'fr': 'Total événements', 'en': 'Total events', 'es': 'Total eventos'},
    'stats_islamic': {'ar': 'الفضائل الإسلامية', 'fr': 'Vertus islamiques', 'en': 'Islamic virtues', 'es': 'Virtudes islámicas'},
    'stats_next': {'ar': 'الحدث القادم', 'fr': 'Prochain événement', 'en': 'Next event', 'es': 'Próximo evento'},
    'appearance': {'ar': 'المظهر', 'fr': 'Apparence', 'en': 'Appearance', 'es': 'Apariencia'},
    'calendar_section': {'ar': 'التقويم', 'fr': 'Calendrier', 'en': 'Calendar', 'es': 'Calendario'},
    'data_section': {'ar': 'البيانات', 'fr': 'Données', 'en': 'Data', 'es': 'Datos'},
    'default_view': {'ar': 'العرض الافتراضي', 'fr': 'Vue par défaut', 'en': 'Default view', 'es': 'Vista por defecto'},
    'density': {'ar': 'كثافة العرض', 'fr': 'Densité', 'en': 'Density', 'es': 'Densidad'},
    'density_compact': {'ar': 'مضغوط', 'fr': 'Compact', 'en': 'Compact', 'es': 'Compacto'},
    'density_normal': {'ar': 'عادي', 'fr': 'Normal', 'en': 'Normal', 'es': 'Normal'},
    'density_expanded': {'ar': 'موسّع', 'fr': 'Étendu', 'en': 'Expanded', 'es': 'Extendido'},
    'show_ayyam_bid': {'ar': 'إبراز الأيام البيض', 'fr': 'Mettre en valeur Ayyam Al-Bid', 'en': 'Highlight White Days', 'es': 'Destacar Días Blancos'},
    'show_ramadan': {'ar': 'إبراز أيام رمضان', 'fr': 'Mettre en valeur le Ramadan', 'en': 'Highlight Ramadan days', 'es': 'Destacar días de Ramadán'},
    'show_greg_in_cell': {'ar': 'التاريخ الميلادي في الخلية', 'fr': 'Date grégorienne dans la cellule', 'en': 'Gregorian date in cell', 'es': 'Fecha gregoriana en la celda'},
    'show_dual_header': {'ar': 'الهجري والميلادي معاً', 'fr': 'Hijri & Grégorien dans le titre', 'en': 'Both dates in header', 'es': 'Ambas fechas en cabecera'},
    'show_greg_months': {'ar': 'أسماء الأشهر الميلادية', 'fr': 'Noms des mois grégoriens', 'en': 'Gregorian month names', 'es': 'Nombres meses gregorianos'},
    'highlight_friday': {'ar': 'تمييز الجمعة', 'fr': 'Mettre en valeur le vendredi', 'en': 'Highlight Friday', 'es': 'Destacar viernes'},
    'enable_notifications': {'ar': 'تفعيل الإشعارات', 'fr': 'Activer les notifications', 'en': 'Enable notifications', 'es': 'Activar notificaciones'},
    '29th_reminder': {'ar': 'تذكير اليوم 29', 'fr': 'Rappel du 29e jour', 'en': '29th day reminder', 'es': 'Recordatorio día 29'},
    'default_time': {'ar': 'الوقت الافتراضي', 'fr': 'Heure par défaut', 'en': 'Default time', 'es': 'Hora por defecto'},
    'daily_summary': {'ar': 'الملخص اليومي', 'fr': 'Résumé quotidien', 'en': 'Daily summary', 'es': 'Resumen diario'},
    'ramadan_reminder': {'ar': 'تذكير قبل رمضان', 'fr': 'Rappel avant Ramadan', 'en': 'Ramadan reminder', 'es': 'Recordatorio antes del Ramadán'},
    'days_before': {'ar': 'أيام قبل', 'fr': 'jours avant', 'en': 'days before', 'es': 'días antes'},
    'sound': {'ar': 'الصوت', 'fr': 'Son', 'en': 'Sound', 'es': 'Sonido'},
    'rate_app': {'ar': 'قيّم التطبيق', 'fr': "Noter l'application", 'en': 'Rate the app', 'es': 'Calificar app'},
    'privacy': {'ar': 'سياسة الخصوصية', 'fr': 'Politique de confidentialité', 'en': 'Privacy Policy', 'es': 'Privacidad'},
    'contact': {'ar': 'اتصل بنا', 'fr': 'Contact', 'en': 'Contact', 'es': 'Contacto'},
    'version': {'ar': 'النسخة', 'fr': 'Version', 'en': 'Version', 'es': 'Versión'},
    'virtue': {'ar': 'الفضل', 'fr': 'Vertu', 'en': 'Virtue', 'es': 'Virtud'},
    'in_days': {'ar': 'بعد', 'fr': 'Dans', 'en': 'In', 'es': 'En'},
    'days_unit': {'ar': 'يوماً', 'fr': 'jours', 'en': 'days', 'es': 'días'},
    'today_word': {'ar': 'اليوم', 'fr': "aujourd'hui", 'en': 'today', 'es': 'hoy'},
    'tomorrow_word': {'ar': 'غداً', 'fr': 'demain', 'en': 'tomorrow', 'es': 'mañana'},
    'frequency_daily': {'ar': 'يومي', 'fr': 'Journalier', 'en': 'Daily', 'es': 'Diario'},
    'frequency_weekly': {'ar': 'أسبوعي', 'fr': 'Hebdomadaire', 'en': 'Weekly', 'es': 'Semanal'},
    'frequency_monthly': {'ar': 'شهري', 'fr': 'Mensuel', 'en': 'Monthly', 'es': 'Mensual'},
    'frequency_annual': {'ar': 'سنوي', 'fr': 'Annuel', 'en': 'Annual', 'es': 'Anual'},
    'next_month_reminder': {'ar': 'تذكير الشهر القادم', 'fr': 'Rappel du mois prochain', 'en': 'Next month reminder', 'es': 'Recordatorio próximo mes'},
    // Google Calendar style event/reminder labels
    'starts': {'ar': 'يبدأ', 'fr': 'Début', 'en': 'Starts', 'es': 'Inicio'},
    'ends': {'ar': 'ينتهي', 'fr': 'Fin', 'en': 'Ends', 'es': 'Fin'},
    'time_zone': {'ar': 'المنطقة الزمنية', 'fr': 'Fuseau horaire', 'en': 'Time zone', 'es': 'Zona horaria'},
    'repeat': {'ar': 'التكرار', 'fr': 'Récurrence', 'en': 'Repeat', 'es': 'Repetir'},
    'repeat_none': {'ar': 'بدون تكرار', 'fr': 'Ne pas répéter', 'en': 'Does not repeat', 'es': 'No repetir'},
    'repeat_daily': {'ar': 'يوميًا', 'fr': 'Tous les jours', 'en': 'Daily', 'es': 'Diariamente'},
    'repeat_weekly': {'ar': 'أسبوعيًا', 'fr': 'Toutes les semaines', 'en': 'Weekly', 'es': 'Semanalmente'},
    'repeat_monthly': {'ar': 'شهريًا', 'fr': 'Tous les mois', 'en': 'Monthly', 'es': 'Mensualmente'},
    'repeat_yearly': {'ar': 'سنويًا', 'fr': 'Tous les ans', 'en': 'Yearly', 'es': 'Anualmente'},
    'add_notification': {'ar': 'إضافة إشعار', 'fr': 'Ajouter une notification', 'en': 'Add notification', 'es': 'Añadir notificación'},
    'remove': {'ar': 'إزالة', 'fr': 'Supprimer', 'en': 'Remove', 'es': 'Quitar'},
    'on_day_at_9': {'ar': 'في اليوم نفسه الساعة 9:00', 'fr': 'Le jour même à 9:00', 'en': 'On day at 9:00', 'es': 'El mismo día a las 9:00'},
    'day_before_at_9': {'ar': 'قبل يوم الساعة 9:00', 'fr': 'La veille à 9:00', 'en': 'Day before at 9:00', 'es': 'El día anterior a las 9:00'},
    'day_before_at_11': {'ar': 'قبل يوم الساعة 11:00', 'fr': 'La veille à 11:00', 'en': 'Day before at 11:00', 'es': 'El día anterior a las 11:00'},
    'day_before_at_17': {'ar': 'قبل يوم الساعة 17:00', 'fr': 'La veille à 17:00', 'en': 'Day before at 17:00', 'es': 'El día anterior a las 17:00'},
    'two_days_before': {'ar': 'قبل يومين الساعة 9:00', 'fr': '2 jours avant à 9:00', 'en': '2 days before at 9:00', 'es': '2 días antes a las 9:00'},
    'one_week_before': {'ar': 'قبل أسبوع الساعة 9:00', 'fr': '1 semaine avant à 9:00', 'en': '1 week before at 9:00', 'es': '1 semana antes a las 9:00'},
    'minutes_before_n': {'ar': 'دقيقة قبل', 'fr': 'minutes avant', 'en': 'minutes before', 'es': 'minutos antes'},
    'two_min_before': {'ar': 'قبل دقيقتين', 'fr': '2 minutes avant', 'en': '2 minutes before', 'es': '2 minutos antes'},
    'five_min_before': {'ar': 'قبل 5 دقائق', 'fr': '5 minutes avant', 'en': '5 minutes before', 'es': '5 minutos antes'},
    'ten_min_before': {'ar': 'قبل 10 دقائق', 'fr': '10 minutes avant', 'en': '10 minutes before', 'es': '10 minutos antes'},
    'fifteen_min_before': {'ar': 'قبل 15 دقيقة', 'fr': '15 minutes avant', 'en': '15 minutes before', 'es': '15 minutos antes'},
    'thirty_min_before': {'ar': 'قبل 30 دقيقة', 'fr': '30 minutes avant', 'en': '30 minutes before', 'es': '30 minutos antes'},
    'one_hour_before': {'ar': 'قبل ساعة', 'fr': '1 heure avant', 'en': '1 hour before', 'es': '1 hora antes'},
    'one_day_before': {'ar': 'قبل يوم', 'fr': '1 jour avant', 'en': '1 day before', 'es': '1 día antes'},
    'custom': {'ar': 'مخصص', 'fr': 'Personnaliser', 'en': 'Custom', 'es': 'Personalizado'},
    'event_type': {'ar': 'النوع', 'fr': 'Type', 'en': 'Type', 'es': 'Tipo'},
    'type_event': {'ar': 'حدث', 'fr': 'Événement', 'en': 'Event', 'es': 'Evento'},
    'type_task': {'ar': 'مهمة', 'fr': 'Tâche', 'en': 'Task', 'es': 'Tarea'},
    'type_birthday': {'ar': 'عيد ميلاد', 'fr': 'Anniversaire', 'en': 'Birthday', 'es': 'Cumpleaños'},
    'end_before_start_error': {'ar': 'الفترة غير صالحة: النهاية قبل البداية', 'fr': 'Période invalide : la fin est avant le début', 'en': 'Invalid range: end is before start', 'es': 'Rango inválido: fin antes del inicio'},
    'title_required': {'ar': 'العنوان مطلوب', 'fr': 'Le titre est requis', 'en': 'Title is required', 'es': 'El título es obligatorio'},
  };
}
