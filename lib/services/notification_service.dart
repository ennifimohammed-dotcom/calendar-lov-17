import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_settings.dart';
import '../models/event_model.dart';
import '../data/islamic_events.dart';
import '../utils/hijri_utils.dart';
import 'regional_hijri_service.dart';

/// Production-grade notification engine inspired by Google Calendar.
///
/// v8 fixes:
///   • Reloads NotificationSettings from disk before EVERY reschedule (no
///     stale in-memory state from a prior run).
///   • Honors the global [enabled] switch — even if an event has its own
///     "notifications" toggle on, no notification is scheduled when global
///     is off (mirrors Google Agenda behaviour).
///   • All titles and bodies are now LOCALIZED (ar/fr/en/es) instead of
///     hard-coded French. The active language is passed in by AppProvider.
///   • Hijri dates used by Islamic / 29th / daily / Ramadan reminders go
///     through RegionalHijri so they match the user's region (e.g. Maroc =
///     Ministère des Habous).
///   • For personal events: planned occurrences and "minutes-before" rules
///     now use the regional Gregorian conversion of the Hijri start date,
///     so "5 minutes before" really fires 5 minutes before the moment the
///     user expects in their region.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _exactAlarmGranted = false;
  NotificationSettings _settings = NotificationSettings();
  String? _activeChannelId;
  String _channelLanguage = 'ar';
  int _channelAccentColor = 0xFF2D7D5F;

  NotificationSettings get settings => _settings;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final localName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localName));
        debugPrint('NotificationService: local tz = $localName');
      } catch (e) {
        debugPrint('NotificationService: tz fallback to UTC ($e)');
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _plugin.initialize(initSettings);

      _settings = await NotificationSettings.load();

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final notifGranted = await android.requestNotificationsPermission();
        debugPrint('NotificationService: POST_NOTIFICATIONS = $notifGranted');
        try {
          final exact = await android.requestExactAlarmsPermission();
          _exactAlarmGranted = exact ?? false;
          debugPrint('NotificationService: SCHEDULE_EXACT_ALARM = $_exactAlarmGranted');
        } catch (e) {
          _exactAlarmGranted = false;
          debugPrint('NotificationService: exact alarm request failed: $e');
        }
        await _ensureChannel(android);
      }

      _initialized = true;
    } catch (e, st) {
      debugPrint('Notification init failed: $e\n$st');
    }
  }

  Future<void> updateSettings(NotificationSettings s,
      {String? language, int? accentColor}) async {
    _settings = s;
    await s.save();
    if (language != null) _channelLanguage = language;
    if (accentColor != null) _channelAccentColor = accentColor;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await _ensureChannel(android);
    }
  }

  /// Re-loads the latest settings from disk. Called automatically before
  /// every reschedule so that any change made elsewhere is picked up.
  Future<void> _reloadSettings() async {
    try {
      _settings = await NotificationSettings.load();
    } catch (_) {}
  }

  Future<void> _ensureChannel(AndroidFlutterLocalNotificationsPlugin android) async {
    final s = _settings;
    final lang = _channelLanguage;
    final id = '${s.channelId}_$lang';
    final isAlert = s.mode == NotificationMode.alert;
    final soundRes = s.androidSoundResource;
    final chName = isAlert
        ? _t('channel_alert_name', lang)
        : _t('channel_silent_name', lang);
    final chDesc = isAlert
        ? _t('channel_alert_desc', lang)
        : _t('channel_silent_desc', lang);
    final channel = AndroidNotificationChannel(
      id,
      chName,
      description: chDesc,
      importance: isAlert ? Importance.max : Importance.low,
      playSound: isAlert,
      sound: (isAlert && soundRes != null)
          ? RawResourceAndroidNotificationSound(soundRes)
          : null,
      enableVibration: s.vibrationEnabled,
      vibrationPattern: s.vibrationEnabled
          ? Int64List.fromList([0, 250, 250, 250])
          : null,
      enableLights: isAlert,
      ledColor: Color(_channelAccentColor),
      showBadge: true,
    );
    try {
      await android.createNotificationChannel(channel);
      _activeChannelId = id;
      debugPrint('NotificationService: channel ready = $id');
    } catch (e) {
      debugPrint('NotificationService: createNotificationChannel failed: $e');
    }
  }

  AndroidNotificationDetails _androidDetails() {
    final s = _settings;
    final lang = _channelLanguage;
    final isAlert = s.mode == NotificationMode.alert;
    final soundRes = s.androidSoundResource;
    return AndroidNotificationDetails(
      '${s.channelId}_$lang',
      isAlert
          ? _t('channel_alert_name', lang)
          : _t('channel_silent_name', lang),
      channelDescription: isAlert
          ? _t('channel_alert_desc', lang)
          : _t('channel_silent_desc', lang),
      importance: isAlert ? Importance.max : Importance.low,
      priority: isAlert ? Priority.max : Priority.low,
      playSound: isAlert,
      sound: (isAlert && soundRes != null)
          ? RawResourceAndroidNotificationSound(soundRes)
          : null,
      enableVibration: s.vibrationEnabled,
      vibrationPattern: s.vibrationEnabled
          ? Int64List.fromList([0, 250, 250, 250])
          : null,
      visibility: _mapVisibility(s.lockScreenVisibility),
      ticker: _t('app_name', lang),
      color: Color(_channelAccentColor),
      colorized: isAlert,
      ledColor: Color(_channelAccentColor),
      ledOnMs: 1000,
      ledOffMs: 500,
      audioAttributesUsage: AudioAttributesUsage.notification,
      fullScreenIntent: isAlert && s.popupEnabled,
      category: AndroidNotificationCategory.reminder,
      autoCancel: true,
    );
  }

  AndroidNotificationDetails _androidDetailsBig(String body, String? title) {
    final base = _androidDetails();
    return AndroidNotificationDetails(
      base.channelId,
      base.channelName,
      channelDescription: base.channelDescription,
      importance: base.importance,
      priority: base.priority,
      playSound: base.playSound,
      sound: base.sound,
      enableVibration: base.enableVibration,
      vibrationPattern: base.vibrationPattern,
      visibility: base.visibility,
      ticker: base.ticker,
      color: base.color,
      colorized: base.colorized,
      ledColor: base.ledColor,
      ledOnMs: base.ledOnMs,
      ledOffMs: base.ledOffMs,
      audioAttributesUsage: base.audioAttributesUsage,
      fullScreenIntent: base.fullScreenIntent,
      category: base.category,
      autoCancel: base.autoCancel,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: null,
      ),
    );
  }

  NotificationVisibility _mapVisibility(LockScreenVisibility v) {
    switch (v) {
      case LockScreenVisibility.hideContent:
        return NotificationVisibility.private;
      case LockScreenVisibility.hideNotifications:
        return NotificationVisibility.secret;
      case LockScreenVisibility.showAll:
        return NotificationVisibility.public;
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_initialized) await init();
    if (!_settings.enabled) {
      debugPrint('schedule skipped — global notifications disabled');
      return;
    }
    if (when.isBefore(DateTime.now())) {
      debugPrint('schedule skipped (past): $when');
      return;
    }
    try {
      final tzWhen = tz.TZDateTime.from(when, tz.local);
      final mode = _exactAlarmGranted
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        NotificationDetails(android: _androidDetailsBig(body, title)),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('scheduled #$id @ $tzWhen ($title)');
    } catch (e) {
      debugPrint('schedule failed for $title @ $when: $e');
      if (_exactAlarmGranted) {
        try {
          await _plugin.zonedSchedule(
            id, title, body,
            tz.TZDateTime.from(when, tz.local),
            NotificationDetails(android: _androidDetails()),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          debugPrint('scheduled #$id (inexact fallback)');
        } catch (e2) {
          debugPrint('inexact fallback also failed: $e2');
        }
      }
    }
  }

  /// Show an immediate test notification using the latest settings.
  Future<void> showTestNow({String language = 'ar', int? accentColor}) async {
    if (!_initialized) await init();
    await _reloadSettings();
    _channelLanguage = language;
    if (accentColor != null) _channelAccentColor = accentColor;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) await _ensureChannel(android);
    try {
      final title = '🔔 ${_t('notif_test', language)} — ${_t('app_name', language)}';
      final body = _t('notif_test_body', language);
      await _plugin.show(
        999001,
        title,
        body,
        NotificationDetails(android: _androidDetailsBig(body, title)),
      );
      debugPrint('test notification shown ($language)');
    } catch (e) {
      debugPrint('test notification failed: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Re-schedule everything for the next 30 days.
  Future<void> rescheduleAll({
    required List<AppEvent> personalEvents,
    Set<String> enabledIslamic = const {},
    bool enable29th = true,
    TimeOfDay time29th = const TimeOfDay(hour: 21, minute: 0),
    bool enableDailySummary = false,
    TimeOfDay dailySummaryTime = const TimeOfDay(hour: 7, minute: 0),
    int ramadanReminderDays = 7,
    String language = 'ar',
    String region = 'global',
    int userOffset = 0,
    int? accentColor,
  }) async {
    if (!_initialized) await init();
    await _reloadSettings();
    _channelLanguage = language;
    if (accentColor != null) _channelAccentColor = accentColor;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) await _ensureChannel(android);
    await cancelAll();
    if (!_settings.enabled) {
      debugPrint('rescheduleAll: notifications globally disabled — skipping');
      return;
    }

    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 30));
    int counter = 1;

    debugPrint('rescheduleAll v8: lang=$language region=$region '
        'events=${personalEvents.length} islamic=${enabledIslamic.length}');

    // 1) Personal events
    for (final e in personalEvents) {
      if (!e.notificationsEnabled) continue;
      final occurrences =
          _expandPersonal(e, now, horizon, region, userOffset);
      for (final occ in occurrences) {
        final reminders = e.reminders.isEmpty
            ? [
                e.isAllDay
                    ? _encodeAllDay(daysBefore: 0, hour: 9)
                    : 10
              ]
            : e.reminders.map((r) => r.minutesBefore).toList();

        for (final m in reminders) {
          final fireAt = e.isAllDay
              ? _allDayFireTime(occ, m)
              : occ.subtract(Duration(minutes: m));
          if (fireAt.isBefore(now) || fireAt.isAfter(horizon)) continue;
          counter++;
          final id = (e.id.hashCode ^
                  fireAt.millisecondsSinceEpoch.hashCode ^
                  counter)
              .toUnsigned(31);
          await _scheduleOne(
            id: id,
            title: _titleForPersonal(e, language),
            body: _bodyForPersonal(e, m, language),
            when: fireAt,
          );
        }
      }
    }

    // 2) Islamic enabled events
    final enabledKeys = {...enabledIslamic};
    for (final cfg in IslamicEventsData.all) {
      if (cfg.alwaysOn) enabledKeys.add(cfg.key);
    }
    for (int dayOffset = 0; dayOffset <= 30; dayOffset++) {
      final g =
          DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
      final h = RegionalHijri.fromGregorian(g,
          region: region, userOffset: userOffset);
      final occs = IslamicEventsData.eventsForDate(
          h.day, h.month, h.year, enabledKeys, g);
      for (final ev in occs) {
        final fireAt = DateTime(
            g.year, g.month, g.day, ev.hour ?? 8, ev.minute ?? 0);
        if (fireAt.isBefore(now) || fireAt.isAfter(horizon)) continue;
        counter++;
        final id = ('${ev.id}_$dayOffset'.hashCode ^ counter).toUnsigned(31);
        await _scheduleOne(
          id: id,
          title: _titleForIslamic(ev, language),
          body: _bodyForIslamic(ev, language),
          when: fireAt,
        );
      }
    }

    // 3) 29th of every Hijri month
    if (enable29th) {
      for (int dayOffset = 0; dayOffset <= 30; dayOffset++) {
        final g = DateTime(now.year, now.month, now.day)
            .add(Duration(days: dayOffset));
        final h = RegionalHijri.fromGregorian(g,
            region: region, userOffset: userOffset);
        if (h.day != 29) continue;
        final fireAt = DateTime(
            g.year, g.month, g.day, time29th.hour, time29th.minute);
        if (fireAt.isBefore(now) || fireAt.isAfter(horizon)) continue;
        counter++;
        final id = ('29th_${g.year}_${g.month}_${g.day}'.hashCode ^ counter)
            .toUnsigned(31);
        await _scheduleOne(
          id: id,
          title: '${_t('notif_29th_title', language)} — '
              '${h.monthName(language)}',
          body: _t('notif_29th_body', language),
          when: fireAt,
        );
      }
    }

    // 4) Daily summary
    if (enableDailySummary) {
      for (int dayOffset = 0; dayOffset <= 30; dayOffset++) {
        final g = DateTime(now.year, now.month, now.day)
            .add(Duration(days: dayOffset));
        final fireAt = DateTime(g.year, g.month, g.day,
            dailySummaryTime.hour, dailySummaryTime.minute);
        if (fireAt.isBefore(now) || fireAt.isAfter(horizon)) continue;
        final h = RegionalHijri.fromGregorian(g,
            region: region, userOffset: userOffset);
        counter++;
        final id =
            ('summary_${g.year}_${g.month}_${g.day}'.hashCode ^ counter)
                .toUnsigned(31);
        await _scheduleOne(
          id: id,
          title: '📅 ${h.day} ${h.monthName(language)} ${h.year}',
          body: _t('notif_summary_body', language),
          when: fireAt,
        );
      }
    }

    // 5) Ramadan pre-reminder
    if (ramadanReminderDays > 0) {
      for (int dayOffset = 0; dayOffset <= 30; dayOffset++) {
        final g = DateTime(now.year, now.month, now.day)
            .add(Duration(days: dayOffset));
        final h = RegionalHijri.fromGregorian(g,
            region: region, userOffset: userOffset);
        try {
          final ramadanG = RegionalHijri.toGregorian(
              HijriDate(h.month <= 9 ? h.year : h.year + 1, 9, 1),
              region: region, userOffset: userOffset);
          final diff =
              ramadanG.difference(DateTime(g.year, g.month, g.day)).inDays;
          if (diff == ramadanReminderDays) {
            final fireAt = DateTime(g.year, g.month, g.day, 9, 0);
            if (fireAt.isBefore(now) || fireAt.isAfter(horizon)) continue;
            counter++;
            final id = ('ramadan_pre_${g.year}'.hashCode ^ counter)
                .toUnsigned(31);
            await _scheduleOne(
              id: id,
              title: _t('notif_ramadan_title', language),
              body: _t('notif_ramadan_body', language),
              when: fireAt,
            );
          }
        } catch (_) {}
      }
    }

    debugPrint('rescheduleAll: done.');
  }

  // ───────── encoding / labels helpers ─────────

  int _encodeAllDay({required int daysBefore, required int hour}) =>
      daysBefore * 1440 + (1440 - hour * 60);

  DateTime _allDayFireTime(DateTime occ, int encoded) {
    final daysBefore = encoded ~/ 1440;
    final hour = 24 - ((encoded % 1440) ~/ 60);
    final base = DateTime(occ.year, occ.month, occ.day);
    return base.subtract(Duration(days: daysBefore)).add(Duration(hours: hour));
  }

  String _titleForPersonal(AppEvent e, String lang) {
    final t = e.titles[lang] ??
        e.titles['en'] ??
        e.titles['fr'] ??
        e.titles['ar'] ??
        _t('notif_event_default', lang);
    return e.emoji.isNotEmpty ? '${e.emoji}  $t' : t;
  }

  String _titleForIslamic(AppEvent e, String lang) {
    final t = e.titles[lang] ??
        e.titles['en'] ??
        e.titles['ar'] ??
        _t('notif_event_default', lang);
    return e.emoji.isNotEmpty ? '${e.emoji}  $t' : t;
  }

  /// Body for Islamic events: full localized description + complete virtue
  /// (e.g. full hadith) so the user sees the entire reward in the pop-up.
  String _bodyForIslamic(AppEvent e, String lang) {
    final desc = e.getDescription(lang);
    final virtue = e.getVirtue(lang);
    if (desc.isNotEmpty && virtue.isNotEmpty) {
      return '$desc\n\n✨ $virtue';
    }
    if (virtue.isNotEmpty) return '✨ $virtue';
    return desc;
  }

  String _bodyForPersonal(AppEvent e, int minutes, String lang) {
    if (e.isAllDay) {
      final daysBefore = minutes ~/ 1440;
      if (daysBefore == 0) {
        return e.description.isNotEmpty
            ? e.description
            : _t('notif_body_today', lang);
      }
      if (daysBefore == 1) return _t('notif_body_tomorrow', lang);
      if (daysBefore == 7) return _t('notif_body_in_week', lang);
      return _t('notif_body_in_days', lang)
          .replaceAll('{n}', '$daysBefore');
    }
    if (minutes == 0) {
      return e.description.isNotEmpty
          ? e.description
          : _t('notif_body_now', lang);
    }
    if (minutes < 60) {
      return _t('notif_body_in_min', lang).replaceAll('{n}', '$minutes');
    }
    if (minutes < 1440) {
      return _t('notif_body_in_hour', lang)
          .replaceAll('{n}', '${minutes ~/ 60}');
    }
    return _t('notif_body_in_days', lang)
        .replaceAll('{n}', '${minutes ~/ 1440}');
  }

  /// Translate a label key. Mirrors a tiny subset of AppProvider._labels so
  /// the service stays self-contained (no circular import).
  String _t(String key, String lang) {
    final m = _strings[key];
    if (m == null) return key;
    return m[lang] ?? m['en'] ?? m['fr'] ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    'app_name': {
      'ar': 'بدر', 'fr': 'Badr', 'en': 'Badr', 'es': 'Badr'
    },
    'channel_alert_name': {
      'ar': 'تنبيهات بدر', 'fr': 'Alertes Badr',
      'en': 'Badr alerts', 'es': 'Alertas Badr'
    },
    'channel_alert_desc': {
      'ar': 'تنبيهات تقويم بدر (صوت، اهتزاز، نافذة منبثقة)',
      'fr': 'Alertes Badr (sons, vibration, pop-up)',
      'en': 'Badr Calendar alerts (sound, vibration, pop-up)',
      'es': 'Alertas Badr (sonido, vibración, ventana)'
    },
    'channel_silent_name': {
      'ar': 'إشعارات صامتة', 'fr': 'Notifications discrètes',
      'en': 'Silent notifications', 'es': 'Notificaciones discretas'
    },
    'channel_silent_desc': {
      'ar': 'إشعارات صامتة لتقويم بدر',
      'fr': 'Notifications discrètes Badr',
      'en': 'Silent Badr Calendar notifications',
      'es': 'Notificaciones discretas Badr'
    },
    'notif_test': {
      'ar': 'اختبار', 'fr': 'Test', 'en': 'Test', 'es': 'Prueba'
    },
    'notif_test_body': {
      'ar': 'إذا رأيت هذا الإشعار فالنظام يعمل بشكل صحيح.',
      'fr': 'Si vous voyez ce message, les notifications fonctionnent.',
      'en': 'If you see this, notifications are working.',
      'es': 'Si ves esto, las notificaciones funcionan.'
    },
    'notif_event_default': {
      'ar': 'حدث', 'fr': 'Événement', 'en': 'Event', 'es': 'Evento'
    },
    'notif_body_now': {
      'ar': 'الآن', 'fr': 'Maintenant', 'en': 'Now', 'es': 'Ahora'
    },
    'notif_body_today': {
      'ar': 'اليوم', 'fr': "Aujourd'hui", 'en': 'Today', 'es': 'Hoy'
    },
    'notif_body_tomorrow': {
      'ar': 'غداً', 'fr': 'Demain', 'en': 'Tomorrow', 'es': 'Mañana'
    },
    'notif_body_in_min': {
      'ar': 'بعد {n} دقيقة', 'fr': 'Dans {n} min',
      'en': 'In {n} min', 'es': 'En {n} min'
    },
    'notif_body_in_hour': {
      'ar': 'بعد {n} ساعة', 'fr': 'Dans {n} h',
      'en': 'In {n} h', 'es': 'En {n} h'
    },
    'notif_body_in_days': {
      'ar': 'بعد {n} أيام', 'fr': 'Dans {n} jours',
      'en': 'In {n} days', 'es': 'En {n} días'
    },
    'notif_body_in_week': {
      'ar': 'بعد أسبوع', 'fr': 'Dans une semaine',
      'en': 'In one week', 'es': 'En una semana'
    },
    'notif_29th_title': {
      'ar': '🌙 اليوم 29', 'fr': '🌙 29e jour',
      'en': '🌙 29th day', 'es': '🌙 Día 29'
    },
    'notif_29th_body': {
      'ar': 'تحرَّ هلال الشهر القادم.',
      'fr': 'Vérifiez le croissant lunaire pour le mois prochain.',
      'en': 'Check the new moon for next month.',
      'es': 'Comprueba la luna nueva del próximo mes.'
    },
    'notif_summary_body': {
      'ar': 'يوم سعيد — أحداثك بانتظارك.',
      'fr': 'Bonne journée — vos événements vous attendent.',
      'en': 'Have a great day — your events are waiting.',
      'es': 'Buen día — tus eventos te esperan.'
    },
    'notif_ramadan_title': {
      'ar': '🌙 رمضان قريباً', 'fr': '🌙 Ramadan approche',
      'en': '🌙 Ramadan approaching', 'es': '🌙 Ramadán se acerca'
    },
    'notif_ramadan_body': {
      'ar': 'استعد قلبك للشهر المبارك.',
      'fr': 'Préparez votre cœur pour le mois béni.',
      'en': 'Prepare your heart for the blessed month.',
      'es': 'Prepara tu corazón para el mes bendito.'
    },
  };

  /// Expand personal event into concrete occurrences within [from..to],
  /// using the regional Hijri→Gregorian conversion.
  List<DateTime> _expandPersonal(
    AppEvent e,
    DateTime from,
    DateTime to,
    String region,
    int userOffset,
  ) {
    final result = <DateTime>[];
    DateTime base;
    try {
      final anchorYear = e.hijriYear == 0
          ? RegionalHijri.fromGregorian(from,
                  region: region, userOffset: userOffset)
              .year
          : e.hijriYear;
      final g = RegionalHijri.toGregorian(
          HijriDate(anchorYear, e.hijriMonth, e.hijriDay),
          region: region,
          userOffset: userOffset);
      base = DateTime(g.year, g.month, g.day, e.hour ?? 9, e.minute ?? 0);
    } catch (_) {
      return result;
    }

    bool inRange(DateTime d) =>
        !d.isBefore(from.subtract(const Duration(days: 1))) &&
        !d.isAfter(to.add(const Duration(days: 1)));

    switch (e.repeat) {
      case EventRepeat.daily:
        var cur = base;
        while (cur.isAfter(from)) cur = cur.subtract(const Duration(days: 1));
        while (cur.isBefore(from)) cur = cur.add(const Duration(days: 1));
        while (!cur.isAfter(to)) {
          if (inRange(cur)) result.add(cur);
          cur = cur.add(const Duration(days: 1));
        }
        break;
      case EventRepeat.weekly:
      case EventRepeat.biweekly:
        final step = e.repeat == EventRepeat.weekly ? 7 : 14;
        var cur = base;
        while (cur.isAfter(from)) cur = cur.subtract(Duration(days: step));
        while (cur.isBefore(from)) cur = cur.add(Duration(days: step));
        while (!cur.isAfter(to)) {
          if (inRange(cur)) result.add(cur);
          cur = cur.add(Duration(days: step));
        }
        break;
      case EventRepeat.weekdays:
        var cur = DateTime(
            from.year, from.month, from.day, e.hour ?? 9, e.minute ?? 0);
        while (!cur.isAfter(to)) {
          if (cur.weekday >= DateTime.monday &&
              cur.weekday <= DateTime.friday) {
            result.add(cur);
          }
          cur = cur.add(const Duration(days: 1));
        }
        break;
      case EventRepeat.monthly:
      case EventRepeat.monthlyByDay:
        var cur = base;
        while (cur.isAfter(from)) {
          cur = DateTime(cur.year, cur.month - 1, cur.day, cur.hour, cur.minute);
        }
        while (cur.isBefore(from)) {
          cur = DateTime(cur.year, cur.month + 1, cur.day, cur.hour, cur.minute);
        }
        while (!cur.isAfter(to)) {
          if (inRange(cur)) result.add(cur);
          cur = DateTime(cur.year, cur.month + 1, cur.day, cur.hour, cur.minute);
        }
        break;
      case EventRepeat.yearly:
        for (final y in [
          RegionalHijri.fromGregorian(from,
                  region: region, userOffset: userOffset)
              .year,
          RegionalHijri.fromGregorian(from,
                      region: region, userOffset: userOffset)
                  .year +
              1
        ]) {
          try {
            final g = RegionalHijri.toGregorian(
                HijriDate(y, e.hijriMonth, e.hijriDay),
                region: region, userOffset: userOffset);
            final occ = DateTime(
                g.year, g.month, g.day, e.hour ?? 9, e.minute ?? 0);
            if (inRange(occ)) result.add(occ);
          } catch (_) {}
        }
        break;
      case EventRepeat.none:
      case EventRepeat.custom:
        if (e.hijriYear == 0) {
          for (final y in [
            RegionalHijri.fromGregorian(from,
                    region: region, userOffset: userOffset)
                .year,
            RegionalHijri.fromGregorian(from,
                        region: region, userOffset: userOffset)
                    .year +
                1
          ]) {
            try {
              final g = RegionalHijri.toGregorian(
                  HijriDate(y, e.hijriMonth, e.hijriDay),
                  region: region, userOffset: userOffset);
              final occ = DateTime(
                  g.year, g.month, g.day, e.hour ?? 9, e.minute ?? 0);
              if (inRange(occ)) result.add(occ);
            } catch (_) {}
          }
        } else {
          if (inRange(base)) result.add(base);
        }
        break;
    }
    return result;
  }
}
