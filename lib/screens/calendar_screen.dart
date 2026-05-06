import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/regional_hijri_service.dart';
import '../utils/hijri_utils.dart';
import '../models/event_model.dart';
import '../theme.dart';
import 'add_event_screen.dart';
import 'event_detail_sheet.dart';

/// Helper: weekday index 0..6 with MONDAY = 0 (the whole app starts the
/// week on Monday, as required).
int _mondayIndex(DateTime d) => (d.weekday + 6) % 7; // Mon=1 -> 0, Sun=7 -> 6

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // _selected is stored as Gregorian to keep a single source of truth for
  // synchronization. The Hijri value is derived via the regional service.
  DateTime _selected = DateTime.now();
  final ScrollController _timelineCtrl = ScrollController();

  // Weekly view paging — ±5000 weeks ≈ ±96 years, effectively "infinite".
  static const int _weekEpoch = 5000;
  late final PageController _weekPager =
      PageController(initialPage: _weekEpoch);

  bool _initFromRegion = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initFromRegion) {
      _selected = _stripTime(DateTime.now());
      _initFromRegion = true;
    }
  }

  @override
  void dispose() {
    _timelineCtrl.dispose();
    _weekPager.dispose();
    super.dispose();
  }

  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Column(
      children: [
        _header(p),
        _viewSwitcher(p),
        Expanded(child: _buildView(p)),
      ],
    );
  }

  Widget _header(AppProvider p) {
    final selectedHijri = p.hijriFromGregorian(_selected);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  p.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.focusedHijri.monthName(p.language)} ${p.focusedHijri.year}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${_gregMonth(p.focusedGregorian.month, p.language)} ${p.focusedGregorian.year} • '
                  '${selectedHijri.day} ${selectedHijri.monthName(p.language)}',
                  style: const TextStyle(color: AppColors.text3, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.today, size: 18),
            label: Text(p.label('today')),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () {
              final today = _stripTime(DateTime.now());
              setState(() => _selected = today);
              p.setFocusedGregorian(today);
              if (p.view == CalendarView.weekly) {
                _weekPager.jumpToPage(_weekEpoch);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _viewSwitcher(AppProvider p) {
    final views = [
      CalendarView.monthly,
      CalendarView.weekly,
      CalendarView.agenda,
    ];
    final labels = ['view_monthly', 'view_weekly', 'view_agenda'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: List.generate(3, (i) {
            final selected = p.view == views[i];
            return Expanded(
              child: InkWell(
                onTap: () => p.setView(views[i]),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.green : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.label(labels[i]),
                    style: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildView(AppProvider p) {
    switch (p.view) {
      case CalendarView.monthly:
        return _monthlyView(p);
      case CalendarView.weekly:
        return _weeklyView(p);
      case CalendarView.agenda:
        return _agendaView(p);
    }
  }

  // ============================================================
  // MONTHLY VIEW — full 6×7 grid (no vertical scroll, only swipe LR).
  // Cells from prev/next month are rendered faded so the grid is always
  // complete (Google Agenda style).
  // ============================================================
  Widget _monthlyView(AppProvider p) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // ONLY horizontal navigation. Vertical drag explicitly absorbed.
      onVerticalDragStart: (_) {},
      onVerticalDragUpdate: (_) {},
      onVerticalDragEnd: (_) {},
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity == null) return;
        final dir = d.primaryVelocity! < 0 ? 1 : -1;
        final next = RegionalHijri.addMonths(
          p.focusedHijri, p.isRtl ? -dir : dir,
          region: p.region, userOffset: p.hijriOffset);
        p.setFocusedHijri(next);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Allocate ~60% of the available height to the full 6×7 grid
          // and ~40% to the selected day's events list below it.
          final headerH = 32.0;
          final available = constraints.maxHeight - headerH;
          final gridH = (available * 0.62).clamp(260.0, available - 120.0);
          return Column(
            children: [
              _weekdayHeader(p),
              SizedBox(height: gridH, child: _monthGrid(p)),
              const Divider(height: 1),
              Expanded(child: _selectedDayEventsList(p)),
            ],
          );
        },
      ),
    );
  }

  // Events list for the currently selected day, shown under the monthly grid.
  Widget _selectedDayEventsList(AppProvider p) {
    final selectedHijri = p.hijriFromGregorian(_selected);
    final events = p.eventsForHijri(selectedHijri);
    final dateLabel =
        '${selectedHijri.day} ${selectedHijri.monthName(p.language)} ${selectedHijri.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(Icons.event_note,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Text('${events.length}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.text3)),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Text(
                    p.label('no_events'),
                    style: const TextStyle(color: AppColors.text3),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: events.length,
                  itemBuilder: (_, i) => _eventTile(p, events[i]),
                ),
        ),
      ],
    );
  }

  Widget _monthGrid(AppProvider p) {
    final h = p.focusedHijri;
    // First gregorian day of the focused Hijri month, region-aware.
    final firstGreg = p.gregorianFromHijri(HijriDate(h.year, h.month, 1));
    // Monday-first offset for the first cell.
    final leadingBlanks = _mondayIndex(firstGreg);
    final dim = RegionalHijri.daysInMonth(h.year, h.month,
        region: p.region, userOffset: p.hijriOffset);
    final today = _stripTime(DateTime.now());

    // 42 cells (6 rows × 7 cols) — always a complete grid.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.85,
        ),
        itemCount: 42,
        itemBuilder: (_, i) {
          final dayOffset = i - leadingBlanks; // 0-based offset from day 1
          final cellGreg = firstGreg.add(Duration(days: dayOffset));
          final cellHijri = p.hijriFromGregorian(cellGreg);
          final inMonth = dayOffset >= 0 && dayOffset < dim;
          final isToday = _stripTime(cellGreg).isAtSameMomentAs(today);
          final isSelected = _stripTime(cellGreg)
              .isAtSameMomentAs(_stripTime(_selected));
          final isWhiteDay =
              inMonth && [13, 14, 15].contains(cellHijri.day);
          final isRamadan = inMonth && cellHijri.month == 9;

          Color? bg;
          if (isWhiteDay) bg = AppColors.greenPale.withOpacity(0.4);
          if (isRamadan) bg = AppColors.goldPale.withOpacity(0.5);
          if (isToday)   bg = Theme.of(context).colorScheme.primary;

          final dimText = !inMonth;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _selected = cellGreg);
              p.setFocusedGregorian(cellGreg);
            },
            // DOUBLE TAP — open "New event" pre-filled with the tapped day.
            onDoubleTap: () {
              setState(() => _selected = cellGreg);
              p.setFocusedGregorian(cellGreg);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEventScreen(initialDate: cellHijri),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected && !isToday
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${cellHijri.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? Colors.white
                          : (dimText ? AppColors.text3.withOpacity(0.5) : null),
                    ),
                  ),
                  Text(
                    '${cellGreg.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday
                          ? Colors.white70
                          : (dimText
                              ? AppColors.text3.withOpacity(0.5)
                              : AppColors.text3),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Monday-first weekday header.
  Widget _weekdayHeader(AppProvider p) {
    final names = p.language == 'ar'
        ? ['إثن', 'ثلا', 'أرب', 'خمس', 'جمعة', 'سبت', 'أحد']
        : (p.language == 'fr'
            ? ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
            : (p.language == 'es'
                ? ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']
                : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: List.generate(
          7,
          (i) => Expanded(
            child: Center(
              child: Text(
                names[i],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WEEKLY VIEW — infinite horizontal paging, full weekday names.
  // ============================================================
  Widget _weeklyView(AppProvider p) {
    return PageView.builder(
      controller: _weekPager,
      reverse: p.isRtl,
      onPageChanged: (page) {
        final delta = page - _weekEpoch;
        final today = _stripTime(DateTime.now());
        // Anchor each page on the Monday of its week.
        final monday = today.add(Duration(days: delta * 7));
        final mondayOfWeek =
            monday.subtract(Duration(days: _mondayIndex(monday)));
        setState(() => _selected = mondayOfWeek);
        p.setFocusedGregorian(mondayOfWeek);
      },
      itemBuilder: (_, page) {
        final delta = page - _weekEpoch;
        final base = _stripTime(DateTime.now()).add(Duration(days: delta * 7));
        final monday = base.subtract(Duration(days: _mondayIndex(base)));
        return _weekPage(p, monday);
      },
    );
  }

  Widget _weekPage(AppProvider p, DateTime monday) {
    return Column(
      children: [
        SizedBox(
          height: 96,
          child: Row(
            children: List.generate(7, (i) {
              final d = monday.add(Duration(days: i));
              final hijri = p.hijriFromGregorian(d);
              final selected = _stripTime(d)
                  .isAtSameMomentAs(_stripTime(_selected));
              final today = _stripTime(d)
                  .isAtSameMomentAs(_stripTime(DateTime.now()));
              final dayName = _weekdayFullName(d.weekday, p.language);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selected = d);
                    p.setFocusedGregorian(d);
                  },
                  onDoubleTap: () {
                    setState(() => _selected = d);
                    p.setFocusedGregorian(d);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEventScreen(initialDate: hijri),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 3, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.green
                          : (today ? AppColors.greenPale : null),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white70
                                : AppColors.text3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${hijri.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : null,
                          ),
                        ),
                        Text(
                          '${d.day}/${d.month}',
                          style: TextStyle(
                            fontSize: 10,
                            color: selected
                                ? Colors.white70
                                : AppColors.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _timeline(p)),
      ],
    );
  }

  String _weekdayFullName(int weekday, String lang) {
    // weekday: Mon=1 ... Sun=7
    const ar = ['الإثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'];
    const fr = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
    const en = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const es = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    final i = (weekday - 1).clamp(0, 6);
    switch (lang) {
      case 'ar': return ar[i];
      case 'fr': return fr[i];
      case 'es': return es[i];
      default:   return en[i];
    }
  }

  Widget _eventTile(AppProvider p, AppEvent e) {
    final timeStr = e.hour != null
        ? '${e.hour!.toString().padLeft(2, '0')}:${(e.minute ?? 0).toString().padLeft(2, '0')}'
        : null;
    return Card(
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: e.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Row(
          children: [
            if (e.emoji.isNotEmpty)
              Text('${e.emoji} ', style: const TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                e.getTitle(p.language),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: e.isIslamic ? AppColors.greenPale : AppColors.goldPale,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e.isIslamic
                    ? p.label('badge_islamic')
                    : p.label('badge_personal'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: e.isIslamic ? AppColors.green : AppColors.gold,
                ),
              ),
            ),
          ],
        ),
        subtitle: timeStr != null
            ? Text(timeStr)
            : (e.description.isNotEmpty
                ? Text(e.description,
                    maxLines: 1, overflow: TextOverflow.ellipsis)
                : null),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EventDetailSheet(
            event: e,
            onEdit: () {
              if (!e.isIslamic) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEventScreen(existing: e),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _timeline(AppProvider p) {
    final selectedHijri = p.hijriFromGregorian(_selected);
    final events = p.eventsForHijri(selectedHijri);
    final timed = events.where((e) => e.hour != null).toList();
    final allDay = events.where((e) => e.hour == null).toList();
    final now = TimeOfDay.now();
    final isToday = _stripTime(_selected)
        .isAtSameMomentAs(_stripTime(DateTime.now()));
    const slotHeight = 60.0;

    return SingleChildScrollView(
      controller: _timelineCtrl,
      child: Column(
        children: [
          if (allDay.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: AppColors.greenPale.withOpacity(0.3),
              child: Column(
                children: allDay
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(width: 4, height: 20, color: e.color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${e.emoji} ${e.getTitle(p.language)}'.trim(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          SizedBox(
            height: slotHeight * 24,
            child: Stack(
              children: [
                Column(
                  children: List.generate(24, (h) {
                    return SizedBox(
                      height: slotHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 50,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 4, right: 6),
                              child: Text(
                                '${h.toString().padLeft(2, '0')}:00',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.text3),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: AppColors.border.withOpacity(0.5)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                ...timed.map((e) {
                  final top =
                      (e.hour! + (e.minute ?? 0) / 60.0) * slotHeight;
                  final endH = e.endHour ?? (e.hour! + 1);
                  final endM = e.endMinute ?? (e.minute ?? 0);
                  final dur = ((endH + endM / 60.0) -
                          (e.hour! + (e.minute ?? 0) / 60.0))
                      .clamp(0.5, 24.0);
                  return Positioned(
                    top: top,
                    left: 54,
                    right: 8,
                    height: dur * slotHeight - 4,
                    child: GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            EventDetailSheet(event: e, onEdit: () {}),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: e.color.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(color: e.color, width: 4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.emoji} ${e.getTitle(p.language)}'.trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${e.hour!.toString().padLeft(2, '0')}:${(e.minute ?? 0).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (isToday)
                  Positioned(
                    top: (now.hour + now.minute / 60.0) * slotHeight,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                            child: Container(height: 2, color: AppColors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AGENDA — chronological list grouped by date
  // ============================================================
  Widget _agendaView(AppProvider p) {
    final today = _stripTime(DateTime.now());
    final upcomingDays = <DateTime>[];
    for (int i = 0; i < 60; i++) {
      final g = today.add(Duration(days: i));
      final h = p.hijriFromGregorian(g);
      if (p.eventsForHijri(h).isNotEmpty) upcomingDays.add(g);
    }
    if (upcomingDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: AppColors.text3),
            const SizedBox(height: 12),
            Text(p.label('no_events'),
                style: const TextStyle(color: AppColors.text3)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: upcomingDays.length,
        itemBuilder: (_, i) {
          final g = upcomingDays[i];
          final d = p.hijriFromGregorian(g);
          final events = p.eventsForHijri(d);
          final isToday = _stripTime(g).isAtSameMomentAs(today);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.green : AppColors.greenPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${d.day} ${d.monthName(p.language)} ${d.year} • ${g.day}/${g.month}/${g.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : AppColors.green,
                  ),
                ),
              ),
              ...events.map((e) => _eventTile(p, e)),
            ],
          );
        },
      ),
    );
  }

  String _gregMonth(int m, String lang) {
    const en = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const fr = ['Jan','Fév','Mar','Avr','Mai','Juin','Juil','Août','Sep','Oct','Nov','Déc'];
    const ar = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    const es = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    switch (lang) {
      case 'ar': return ar[m - 1];
      case 'fr': return fr[m - 1];
      case 'es': return es[m - 1];
      default:   return en[m - 1];
    }
  }
}
