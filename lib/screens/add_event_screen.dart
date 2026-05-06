import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/app_provider.dart';
import '../utils/hijri_utils.dart';
import '../theme.dart';

/// Google Calendar–style "New Event" screen.
///
/// Strict business rules:
///  - allDay = true  => no time fields, reminders are FIXED-HOUR presets
///                      (on day 9:00, day before 9:00 / 11:00 / 17:00,
///                       2 days before 9:00, 1 week before 9:00, custom).
///  - allDay = false => start AND end with date+time, reminders are RELATIVE
///                      offsets in minutes (2/5/10/15/30 min, 1 h, 1 day, custom).
///  - Recurrence (none/daily/weekly/monthly/yearly) is preserved by the
///    notification engine (each occurrence inherits the same reminders).
///  - End must be strictly after Start when not allDay.
class AddEventScreen extends StatefulWidget {
  final AppEvent? existing;
  /// When opening the screen from a specific calendar day (e.g. double-tap
  /// in the monthly view), this Hijri date pre-fills both start AND end.
  final HijriDate? initialDate;
  const AddEventScreen({super.key, this.existing, this.initialDate});
  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

/// Sentinel value (in minutes) representing the all-day "preset" anchored
/// to a specific hour-of-day relative to the event date. We encode the rule
/// as a *negative* number that the engine knows how to interpret. To stay
/// fully backward-compatible with the existing ReminderConfig (positive
/// "minutesBefore" for timed events), we also store the same information
/// directly into a list of plain DateTime offsets when needed.
///
/// Encoding for all-day reminders, stored in `minutesBefore`:
///   onDayAt9        =>  0 * 1440 + (24*60 - 9*60) = 0 day before, fires 9:00
///   dayBeforeAt9    =>  1 day before, fires 9:00
///   dayBeforeAt11   =>  1 day before, fires 11:00
///   dayBeforeAt17   =>  1 day before, fires 17:00
///   twoDaysBeforeAt9 => 2 days before, fires 9:00
///   oneWeekBeforeAt9 => 7 days before, fires 9:00
///
/// We use the convention: minutesBefore = daysBefore * 1440 + (1440 - hour*60)
/// i.e. "minutes between fire time and start-of-day-OF-event".
class _AllDayPreset {
  final String labelKey;
  final int daysBefore;
  final int hour;
  const _AllDayPreset(this.labelKey, this.daysBefore, this.hour);

  int get encoded => daysBefore * 1440 + (1440 - hour * 60);
}

const _allDayPresets = <_AllDayPreset>[
  _AllDayPreset('on_day_at_9', 0, 9),
  _AllDayPreset('day_before_at_9', 1, 9),
  _AllDayPreset('day_before_at_11', 1, 11),
  _AllDayPreset('day_before_at_17', 1, 17),
  _AllDayPreset('two_days_before', 2, 9),
  _AllDayPreset('one_week_before', 7, 9),
];

class _TimedPreset {
  final String labelKey;
  final int minutesBefore;
  const _TimedPreset(this.labelKey, this.minutesBefore);
}

const _timedPresets = <_TimedPreset>[
  _TimedPreset('two_min_before', 2),
  _TimedPreset('five_min_before', 5),
  _TimedPreset('ten_min_before', 10),
  _TimedPreset('fifteen_min_before', 15),
  _TimedPreset('thirty_min_before', 30),
  _TimedPreset('one_hour_before', 60),
  _TimedPreset('one_day_before', 1440),
];

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  // Start / End — Google Calendar separates date AND time.
  late HijriDate _startDate;
  late HijriDate _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  bool _allDay = true;
  bool _notif = true;

  Color _color = AppColors.green;
  String _category = 'personal';
  String _emoji = '';
  EventPriority _priority = EventPriority.medium;
  EventRepeat _repeat = EventRepeat.none;

  // List of reminders. The MEANING of each int depends on _allDay:
  //  - allDay = true  => encoded preset (see _AllDayPreset.encoded)
  //  - allDay = false => positive minutes-before-start
  List<int> _reminders = [];

  static const _colors = [
    AppColors.green, AppColors.gold, AppColors.blue, AppColors.red,
    Color(0xFF8E44AD), Color(0xFF16A085), Color(0xFFE67E22), Color(0xFF2C3E50),
  ];

  static const _categories = [
    {'key': 'religious', 'emoji': '🕌'},
    {'key': 'personal', 'emoji': '🙂'},
    {'key': 'family', 'emoji': '👨‍👩‍👧'},
    {'key': 'work', 'emoji': '💼'},
    {'key': 'health', 'emoji': '🏥'},
    {'key': 'social', 'emoji': '🎉'},
  ];

  static const _emojis = [
    '🌙','🕌','📿','🤲','✨','🌕','🎉','🎊','📅','🏔','🗓','🕯',
    '🌹','🌸','💼','📚','🏥','👨‍👩‍👧','🍽','✈️','🎂',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text =
          e.titles[context.read<AppProvider>().language] ?? e.titles.values.first;
      _descCtrl.text = e.description;
      _locationCtrl.text = e.location;
      _startDate = HijriDate(
        e.hijriYear == 0
            ? context.read<AppProvider>().today().year
            : e.hijriYear,
        e.hijriMonth,
        e.hijriDay,
      );
      _endDate = HijriDate(
        (e.endHijriYear ?? e.hijriYear) == 0
            ? _startDate.year
            : (e.endHijriYear ?? e.hijriYear),
        e.endHijriMonth ?? e.hijriMonth,
        e.endHijriDay ?? e.hijriDay,
      );
      _allDay = e.isAllDay;
      if (e.hour != null) {
        _startTime = TimeOfDay(hour: e.hour!, minute: e.minute ?? 0);
      }
      if (e.endHour != null) {
        _endTime = TimeOfDay(hour: e.endHour!, minute: e.endMinute ?? 0);
      } else if (e.hour != null) {
        _endTime = TimeOfDay(hour: (e.hour! + 1) % 24, minute: e.minute ?? 0);
      }
      _color = e.color;
      _category = e.category;
      _emoji = e.emoji;
      _priority = e.priority;
      _notif = e.notificationsEnabled;
      _repeat = e.repeat;
      _reminders = e.reminders.map((r) => r.minutesBefore).toList();
    } else {
      final t = widget.initialDate ?? context.read<AppProvider>().today();
      _startDate = t;
      _endDate = t;
      // Sensible defaults — match Google Calendar's default reminder.
      _reminders = _allDay ? [_allDayPresets[0].encoded] : [10];
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existing == null ? p.label('new_event') : p.label('edit_event'),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              p.label('save'),
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Title ──────────────────────────────────────
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: p.label('title'),
              border: InputBorder.none,
            ),
          ),
          const Divider(),

          // ── All-day toggle ─────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(p.label('all_day')),
            value: _allDay,
            activeColor: AppColors.green,
            onChanged: (v) => setState(() {
              _allDay = v;
              // Re-seed default reminders to match the new mode.
              _reminders = v ? [_allDayPresets[0].encoded] : [10];
              // Make sure end >= start when switching to timed.
              if (!v && !_endStrictlyAfterStart()) {
                _endTime = TimeOfDay(
                  hour: (_startTime.hour + 1) % 24,
                  minute: _startTime.minute,
                );
              }
            }),
          ),

          // ── Start ──────────────────────────────────────
          _section(p.label('starts')),
          _dateTimeRow(
            p,
            date: _startDate,
            time: _allDay ? null : _startTime,
            onDate: (d) => setState(() {
              _startDate = d;
              if (_endDate.toGregorian().isBefore(_startDate.toGregorian())) {
                _endDate = d;
              }
            }),
            onTime: (t) => setState(() {
              _startTime = t;
              if (!_endStrictlyAfterStart()) {
                _endTime = TimeOfDay(
                  hour: (t.hour + 1) % 24,
                  minute: t.minute,
                );
              }
            }),
          ),

          const SizedBox(height: 12),

          // ── End ────────────────────────────────────────
          _section(p.label('ends')),
          _dateTimeRow(
            p,
            date: _endDate,
            time: _allDay ? null : _endTime,
            onDate: (d) => setState(() => _endDate = d),
            onTime: (t) => setState(() => _endTime = t),
          ),

          const Divider(height: 32),

          // ── Repeat ─────────────────────────────────────
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.repeat, color: AppColors.green),
            title: Text(p.label('repeat')),
            subtitle: Text(_repeatLabel(p, _repeat)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickRepeat,
          ),

          const Divider(),

          // ── Reminders / Notifications ──────────────────
          _section(p.label('reminders')),
          ..._reminders.asMap().entries.map((e) {
            final idx = e.key;
            final value = e.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_active_outlined,
                  color: AppColors.green),
              title: Text(_reminderLabel(p, value)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _reminders.removeAt(idx)),
              ),
              onTap: () => _pickReminder(replaceIndex: idx),
            );
          }),
          TextButton.icon(
            onPressed: () => _pickReminder(),
            icon: const Icon(Icons.add, color: AppColors.green),
            label: Text(
              p.label('add_notification'),
              style: const TextStyle(color: AppColors.green),
            ),
          ),

          const Divider(),

          // ── Description ────────────────────────────────
          _section(p.label('description')),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: p.label('description'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // ── Location ───────────────────────────────────
          _section(p.label('location')),
          TextField(
            controller: _locationCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.location_on_outlined),
              hintText: p.label('location'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 16),

          // ── Category ───────────────────────────────────
          _section(p.label('category')),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((c) {
                final selected = _category == c['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${c['emoji']} ${p.label('cat_${c['key']}')}'),
                    selected: selected,
                    selectedColor: AppColors.greenPale,
                    onSelected: (_) => setState(() => _category = c['key']!),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ── Color ──────────────────────────────────────
          _section(p.label('color')),
          Wrap(
            spacing: 12,
            children: _colors.map((c) => GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == c ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                )).toList(),
          ),

          const SizedBox(height: 16),

          // ── Emoji ──────────────────────────────────────
          _section('Emoji'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis.map((e) => GestureDetector(
                  onTap: () => setState(() => _emoji = _emoji == e ? '' : e),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _emoji == e ? AppColors.greenPale : null,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                )).toList(),
          ),

          const SizedBox(height: 16),

          // ── Priority ───────────────────────────────────
          _section(p.label('priority')),
          SegmentedButton<EventPriority>(
            segments: [
              ButtonSegment(
                  value: EventPriority.low,
                  label: Text(p.label('priority_low'))),
              ButtonSegment(
                  value: EventPriority.medium,
                  label: Text(p.label('priority_medium'))),
              ButtonSegment(
                  value: EventPriority.high,
                  label: Text(p.label('priority_high'))),
            ],
            selected: {_priority},
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),

          const SizedBox(height: 16),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(p.label('notifications')),
            value: _notif,
            activeColor: AppColors.green,
            onChanged: (v) => setState(() => _notif = v),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ───────────────────────────── helpers ─────────────────────────────

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      );

  Widget _dateTimeRow(
    AppProvider p, {
    required HijriDate date,
    required TimeOfDay? time,
    required ValueChanged<HijriDate> onDate,
    required ValueChanged<TimeOfDay> onTime,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              '${date.day} ${date.monthName(p.language)} ${date.year}',
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () async {
              final picked = await _showHijriDatePicker(date);
              if (picked != null) onDate(picked);
            },
          ),
        ),
        if (time != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.access_time, size: 18),
              label: Text(_fmtTime(time)),
              onPressed: () async {
                final t = await showTimePicker(
                    context: context, initialTime: time);
                if (t != null) onTime(t);
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<HijriDate?> _showHijriDatePicker(HijriDate initial) async {
    HijriDate temp = initial;
    return showModalBottomSheet<HijriDate>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${temp.day} ${temp.monthName(context.read<AppProvider>().language)} ${temp.year}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(spacing: 8, children: [
                _navBtn('-1d', () => setS(() => temp = temp.addDays(-1))),
                _navBtn('+1d', () => setS(() => temp = temp.addDays(1))),
                _navBtn('-1m', () => setS(() => temp = temp.addMonths(-1))),
                _navBtn('+1m', () => setS(() => temp = temp.addMonths(1))),
              ]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                          context.read<AppProvider>().label('cancel')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx, temp),
                      child:
                          Text(context.read<AppProvider>().label('save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(String label, VoidCallback onTap) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(56, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: onTap,
        child: Text(label),
      );

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _repeatLabel(AppProvider p, EventRepeat r) {
    switch (r) {
      case EventRepeat.daily: return p.label('repeat_daily');
      case EventRepeat.weekly: return p.label('repeat_weekly');
      case EventRepeat.monthly: return p.label('repeat_monthly');
      case EventRepeat.yearly: return p.label('repeat_yearly');
      default: return p.label('repeat_none');
    }
  }

  Future<void> _pickRepeat() async {
    final p = context.read<AppProvider>();
    final choice = await showModalBottomSheet<EventRepeat>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in const [
              EventRepeat.none,
              EventRepeat.daily,
              EventRepeat.weekly,
              EventRepeat.monthly,
              EventRepeat.yearly,
            ])
              ListTile(
                title: Text(_repeatLabel(p, r)),
                trailing: _repeat == r
                    ? const Icon(Icons.check, color: AppColors.green)
                    : null,
                onTap: () => Navigator.pop(context, r),
              ),
          ],
        ),
      ),
    );
    if (choice != null) setState(() => _repeat = choice);
  }

  String _reminderLabel(AppProvider p, int value) {
    if (_allDay) {
      // Try to match a known preset.
      for (final preset in _allDayPresets) {
        if (preset.encoded == value) return p.label(preset.labelKey);
      }
      // Custom all-day fallback: decode days/hour.
      final daysBefore = value ~/ 1440;
      final hour = 24 - ((value % 1440) ~/ 60);
      return '$daysBefore × 24h • ${hour.toString().padLeft(2, '0')}:00';
    } else {
      for (final preset in _timedPresets) {
        if (preset.minutesBefore == value) return p.label(preset.labelKey);
      }
      if (value == 0) return p.label('at_event');
      if (value < 60) return '$value ${p.label('minutes_before_n')}';
      if (value < 1440) return '${value ~/ 60} ${p.label('hour_before')}';
      return '${value ~/ 1440} ${p.label('day_before')}';
    }
  }

  Future<void> _pickReminder({int? replaceIndex}) async {
    final p = context.read<AppProvider>();
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        if (_allDay) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final preset in _allDayPresets)
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(p.label(preset.labelKey)),
                    onTap: () => Navigator.pop(context, preset.encoded),
                  ),
              ],
            ),
          );
        }
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final preset in _timedPresets)
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(p.label(preset.labelKey)),
                  onTap: () => Navigator.pop(context, preset.minutesBefore),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (replaceIndex != null) {
        _reminders[replaceIndex] = picked;
      } else if (!_reminders.contains(picked)) {
        _reminders.add(picked);
      }
    });
  }

  bool _endStrictlyAfterStart() {
    if (_allDay) {
      return !_endDate.toGregorian().isBefore(_startDate.toGregorian());
    }
    final s = DateTime(0, 1, 1, _startTime.hour, _startTime.minute);
    final e = DateTime(0, 1, 1, _endTime.hour, _endTime.minute);
    final sameDay = _startDate.day == _endDate.day &&
        _startDate.month == _endDate.month &&
        _startDate.year == _endDate.year;
    if (sameDay) return e.isAfter(s);
    return _endDate.toGregorian().isAfter(_startDate.toGregorian());
  }

  Future<void> _save() async {
    final p = context.read<AppProvider>();
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(p.label('title_required'))),
      );
      return;
    }
    if (!_allDay && !_endStrictlyAfterStart()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(p.label('end_before_start_error'))),
      );
      return;
    }

    final titles = <String, String>{p.language: _titleCtrl.text.trim()};
    final reminders = _reminders
        .map((m) => ReminderConfig(minutesBefore: m))
        .toList();

    final ev = AppEvent(
      id: widget.existing?.id ?? '',
      titles: titles,
      description: _descCtrl.text.trim(),
      hijriDay: _startDate.day,
      hijriMonth: _startDate.month,
      hijriYear: _repeat == EventRepeat.yearly ? 0 : _startDate.year,
      hour: _allDay ? null : _startTime.hour,
      minute: _allDay ? null : _startTime.minute,
      endHour: _allDay ? null : _endTime.hour,
      endMinute: _allDay ? null : _endTime.minute,
      endHijriDay: _endDate.day,
      endHijriMonth: _endDate.month,
      endHijriYear: _endDate.year,
      color: _color,
      notificationsEnabled: _notif,
      isAllDay: _allDay,
      location: _locationCtrl.text.trim(),
      category: _category,
      emoji: _emoji,
      priority: _priority,
      repeat: _repeat,
      reminders: reminders,
      isRecurring: _repeat != EventRepeat.none,
    );
    if (widget.existing == null) {
      await p.addEvent(ev);
    } else {
      await p.updateEvent(ev);
    }
    if (mounted) Navigator.pop(context);
  }
}
