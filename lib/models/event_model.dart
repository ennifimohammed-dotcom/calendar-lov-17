import 'package:flutter/material.dart';

enum EventRepeat {
  none, daily, weekdays, weekly, biweekly,
  monthly, monthlyByDay, yearly, custom,
}

enum EventPriority { low, medium, high }
enum ReminderType { notification, alarm }

class ReminderConfig {
  final ReminderType type;
  final int minutesBefore;
  final bool vibrate;

  const ReminderConfig({
    this.type = ReminderType.notification,
    required this.minutesBefore,
    this.vibrate = true,
  });

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'minutesBefore': minutesBefore,
    'vibrate': vibrate,
  };

  factory ReminderConfig.fromJson(Map<String, dynamic> j) => ReminderConfig(
    type: ReminderType.values[j['type'] ?? 0],
    minutesBefore: j['minutesBefore'] ?? 0,
    vibrate: j['vibrate'] ?? true,
  );
}

class AppEvent {
  String id;
  Map<String, String> titles; // {ar, fr, en, es}
  String description;
  Map<String, String> descriptions; // localized full description (optional)
  Map<String, String> virtues;      // localized virtue / hadith (optional)
  int hijriDay, hijriMonth, hijriYear; // 0 year = recurring yearly
  int? hour, minute;
  int? endHour, endMinute;
  Color color;
  bool notificationsEnabled;
  bool isIslamic;
  bool isRecurring;

  // Extended
  String location;
  String url;
  EventRepeat repeat;
  List<ReminderConfig> reminders;
  String category;
  bool isAllDay;
  int? endHijriDay, endHijriMonth, endHijriYear;
  String emoji;
  EventPriority priority;
  bool isPrivate;

  AppEvent({
    required this.id,
    required this.titles,
    this.description = '',
    this.descriptions = const {},
    this.virtues = const {},
    required this.hijriDay,
    required this.hijriMonth,
    this.hijriYear = 0,
    this.hour,
    this.minute,
    this.endHour,
    this.endMinute,
    this.color = const Color(0xFF2D7D5F),
    this.notificationsEnabled = true,
    this.isIslamic = false,
    this.isRecurring = false,
    this.location = '',
    this.url = '',
    this.repeat = EventRepeat.none,
    this.reminders = const [],
    this.category = 'personal',
    this.isAllDay = false,
    this.endHijriDay,
    this.endHijriMonth,
    this.endHijriYear,
    this.emoji = '',
    this.priority = EventPriority.medium,
    this.isPrivate = false,
  });

  String getTitle(String lang) =>
      titles[lang] ?? titles['en'] ?? titles['ar'] ?? 'Event';

  String getDescription(String lang) {
    if (descriptions.isNotEmpty) {
      return descriptions[lang] ??
          descriptions['en'] ??
          descriptions['ar'] ??
          description;
    }
    return description;
  }

  String getVirtue(String lang) {
    if (virtues.isEmpty) return '';
    return virtues[lang] ?? virtues['en'] ?? virtues['ar'] ?? '';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titles': titles,
    'description': description,
    'descriptions': descriptions,
    'virtues': virtues,
    'hijriDay': hijriDay,
    'hijriMonth': hijriMonth,
    'hijriYear': hijriYear,
    'hour': hour,
    'minute': minute,
    'endHour': endHour,
    'endMinute': endMinute,
    // ignore: deprecated_member_use
    'color': color.value,
    'notificationsEnabled': notificationsEnabled,
    'isIslamic': isIslamic,
    'isRecurring': isRecurring,
    'location': location,
    'url': url,
    'repeat': repeat.index,
    'reminders': reminders.map((r) => r.toJson()).toList(),
    'category': category,
    'isAllDay': isAllDay,
    'endHijriDay': endHijriDay,
    'endHijriMonth': endHijriMonth,
    'endHijriYear': endHijriYear,
    'emoji': emoji,
    'priority': priority.index,
    'isPrivate': isPrivate,
  };

  factory AppEvent.fromJson(Map<String, dynamic> j) => AppEvent(
    id: j['id'],
    titles: Map<String, String>.from(j['titles'] ?? {}),
    description: j['description'] ?? '',
    descriptions: Map<String, String>.from(j['descriptions'] ?? const {}),
    virtues: Map<String, String>.from(j['virtues'] ?? const {}),
    hijriDay: j['hijriDay'],
    hijriMonth: j['hijriMonth'],
    hijriYear: j['hijriYear'] ?? 0,
    hour: j['hour'],
    minute: j['minute'],
    endHour: j['endHour'],
    endMinute: j['endMinute'],
    color: Color(j['color'] ?? 0xFF2D7D5F),
    notificationsEnabled: j['notificationsEnabled'] ?? true,
    isIslamic: j['isIslamic'] ?? false,
    isRecurring: j['isRecurring'] ?? false,
    location: j['location'] ?? '',
    url: j['url'] ?? '',
    repeat: EventRepeat.values[j['repeat'] ?? 0],
    reminders: (j['reminders'] as List? ?? [])
        .map((r) => ReminderConfig.fromJson(Map<String, dynamic>.from(r)))
        .toList(),
    category: j['category'] ?? 'personal',
    isAllDay: j['isAllDay'] ?? false,
    endHijriDay: j['endHijriDay'],
    endHijriMonth: j['endHijriMonth'],
    endHijriYear: j['endHijriYear'],
    emoji: j['emoji'] ?? '',
    priority: EventPriority.values[j['priority'] ?? 1],
    isPrivate: j['isPrivate'] ?? false,
  );
}
