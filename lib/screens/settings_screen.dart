import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/islamic_events.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../utils/hijri_utils.dart';
import 'notification_settings_screen.dart';
import '../services/regional_hijri_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _languages = [
    {'code': 'ar', 'flag': '🇸🇦', 'name': 'العربية'},
    {'code': 'fr', 'flag': '🇫🇷', 'name': 'Français'},
    {'code': 'en', 'flag': '🇬🇧', 'name': 'English'},
    {'code': 'es', 'flag': '🇪🇸', 'name': 'Español'},
  ];

  static const _regions = [
    {'code': 'global',    'flag': '🌍', 'name': 'Global (Umm al-Qura)'},
    {'code': 'morocco',   'flag': '🇲🇦', 'name': 'Maroc'},
    {'code': 'algeria',   'flag': '🇩🇿', 'name': 'Algérie'},
    {'code': 'tunisia',   'flag': '🇹🇳', 'name': 'Tunisie'},
    {'code': 'saudi',     'flag': '🇸🇦', 'name': 'Arabie Saoudite'},
    {'code': 'turkey',    'flag': '🇹🇷', 'name': 'Turquie (Diyanet)'},
    {'code': 'indonesia', 'flag': '🇮🇩', 'name': 'Indonésie'},
  ];

  static const _accentColors = AppColors.palette;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final today = p.today();
    final greg = DateTime.now();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(p.label('tab_settings'),
              style: Theme.of(context).textTheme.headlineMedium),
        ),

        // ───── PROFILE ─────
        _section(p.label('profile')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.green,
                  child: Text(_initials(p.profileName),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: p.profileName,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: p.label('name'),
                          border: InputBorder.none),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        onChanged: (v) => p.setProfileName(v),
                      ),
                      const SizedBox(height: 4),
                      Text('${today.day} ${today.monthName(p.language)} ${today.year}',
                          style: const TextStyle(color: AppColors.text2, fontSize: 12)),
                      Text('${greg.day}/${greg.month}/${greg.year}',
                          style: const TextStyle(color: AppColors.text3, fontSize: 11)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _stat(p.label('stats_total'), '${p.events.length}', AppColors.green),
                const SizedBox(width: 8),
                _stat(p.label('stats_islamic'), '${p.enabledIslamic.length}', AppColors.gold),
                const SizedBox(width: 8),
                _stat(p.label("stats_next"), _nextDays(p), AppColors.gold),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ───── LANGUAGE ─────
        _section('${p.label('language')} & ${p.label('region')}'),
        Card(
          child: Column(children: _languages.map((l) => RadioListTile<String>(
            value: l['code']!,
            groupValue: p.language,
            activeColor: AppColors.green,
            onChanged: (v) => p.setLanguage(v!),
            title: Text('${l['flag']}  ${l['name']}'),
          )).toList()),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(children: [
            for (final r in _regions)
              RadioListTile<String>(
                value: r['code']!,
                groupValue: p.region,
                activeColor: AppColors.green,
                onChanged: (v) => p.setRegion(v!),
                title: Text('${r['flag']}  ${r['name']}'),
              ),
            const Divider(height: 1),
            ListTile(
              title: Text('${p.language == "ar" ? "إزاحة" : "Offset"}: ${p.hijriOffset >= 0 ? "+" : ""}${p.hijriOffset}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.remove),
                    onPressed: p.hijriOffset > -2 ? () => p.setHijriOffset(p.hijriOffset - 1) : null),
                IconButton(icon: const Icon(Icons.add),
                    onPressed: p.hijriOffset < 2 ? () => p.setHijriOffset(p.hijriOffset + 1) : null),
              ]),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 16, color: AppColors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.label('hijri_source'),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.text3,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          RegionalHijri.sourceLabel(p.region, p.language),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.text2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ───── APPEARANCE ─────
        _section(p.label('appearance')),
        Card(
          child: Column(children: [
            RadioListTile<AppThemeMode>(
              value: AppThemeMode.light, groupValue: p.themeMode,
              activeColor: AppColors.green,
              onChanged: (v) => p.setThemeMode(v!),
              title: Text('☀️  ${p.label('theme_light')}')),
            RadioListTile<AppThemeMode>(
              value: AppThemeMode.dark, groupValue: p.themeMode,
              activeColor: AppColors.green,
              onChanged: (v) => p.setThemeMode(v!),
              title: Text('🌙  ${p.label('theme_dark')}')),
            RadioListTile<AppThemeMode>(
              value: AppThemeMode.system, groupValue: p.themeMode,
              activeColor: AppColors.green,
              onChanged: (v) => p.setThemeMode(v!),
              title: Text('⚙️  ${p.label('theme_system')}')),
          ]),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.label('accent_color'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: _accentColors.map((c) {
                // ignore: deprecated_member_use
                final selected = p.accentColor == c.value;
                return GestureDetector(
                  // ignore: deprecated_member_use
                  onTap: () => p.setAccentColor(c.value),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: c, shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                        width: 3),
                    ),
                  ),
                );
              }).toList()),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.label('font_size'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: p.fontScale,
                min: 0.85, max: 1.30, divisions: 3,
                activeColor: AppColors.green,
                label: _fontLabel(p.fontScale),
                onChanged: (v) => p.setFontScale(v),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('S', style: TextStyle(color: AppColors.text3)),
                  Text('M', style: TextStyle(color: AppColors.text3)),
                  Text('L', style: TextStyle(color: AppColors.text3)),
                  Text('XL', style: TextStyle(color: AppColors.text3)),
                ]),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            title: Text(p.label('density'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: SegmentedButton<CalendarDensity>(
              segments: [
                ButtonSegment(value: CalendarDensity.compact,  label: Text(p.label('density_compact'))),
                ButtonSegment(value: CalendarDensity.normal,   label: Text(p.label('density_normal'))),
                ButtonSegment(value: CalendarDensity.expanded, label: Text(p.label('density_expanded'))),
              ],
              selected: {p.density},
              onSelectionChanged: (s) => p.setDensity(s.first),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ───── CALENDAR ─────
        _section(p.label('calendar_section')),
        Card(
          child: Column(children: [
            ListTile(
              title: Text(p.label('default_view')),
              subtitle: SegmentedButton<CalendarView>(
                segments: [
                  ButtonSegment(value: CalendarView.monthly, label: Text(p.label('view_monthly'))),
                  ButtonSegment(value: CalendarView.weekly,  label: Text(p.label('view_weekly'))),
                  ButtonSegment(value: CalendarView.agenda,  label: Text(p.label('view_agenda'))),
                ],
                selected: {p.defaultView},
                onSelectionChanged: (s) => p.setDefaultView(s.first),
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              value: p.showAyyamBid, activeColor: AppColors.green,
              onChanged: p.setShowAyyamBid, title: Text(p.label('show_ayyam_bid'))),
            SwitchListTile(
              value: p.showRamadan, activeColor: AppColors.green,
              onChanged: p.setShowRamadan, title: Text(p.label('show_ramadan'))),
            SwitchListTile(
              value: p.showGregorianInCell, activeColor: AppColors.green,
              onChanged: p.setShowGregorianInCell, title: Text(p.label('show_greg_in_cell'))),
            SwitchListTile(
              value: p.showDualHeader, activeColor: AppColors.green,
              onChanged: p.setShowDualHeader, title: Text(p.label('show_dual_header'))),
            SwitchListTile(
              value: p.showGregorianMonths, activeColor: AppColors.green,
              onChanged: p.setShowGregorianMonths, title: Text(p.label('show_greg_months'))),
            SwitchListTile(
              value: p.highlightFriday, activeColor: AppColors.green,
              onChanged: p.setHighlightFriday, title: Text(p.label('highlight_friday'))),
          ]),
        ),
        const SizedBox(height: 16),

        // ───── NOTIFICATIONS ─────
        _section('🔔  ${p.label('notifications')}'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined, color: AppColors.green),
              title: Text(p.label('notifications')),
              subtitle: Text(p.language == 'fr'
                  ? 'Sons, vibrations, écran de verrouillage…'
                  : (p.language == 'ar'
                      ? 'الأصوات، الاهتزاز، شاشة القفل…'
                      : 'Sounds, vibration, lock screen…')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen())),
            ),
            const Divider(height: 1),
            SwitchListTile(
              value: p.enable29thReminder, activeColor: AppColors.green,
              onChanged: p.setEnable29thReminder,
              title: Text(p.label('29th_reminder')),
              subtitle: Text(_fmtTime(p.time29th)),
            ),
            ListTile(
              leading: const SizedBox(width: 40),
              title: Text(p.label('default_time')),
              trailing: TextButton(
                onPressed: () async {
                  final t = await showTimePicker(context: context, initialTime: p.time29th);
                  if (t != null) p.setTime29th(t);
                },
                child: Text(_fmtTime(p.time29th)),
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              value: p.enableDailySummary, activeColor: AppColors.green,
              onChanged: p.setEnableDailySummary,
              title: Text(p.label('daily_summary')),
              subtitle: Text(_fmtTime(p.dailySummaryTime)),
            ),
            ListTile(
              leading: const SizedBox(width: 40),
              title: Text(p.label('default_time')),
              trailing: TextButton(
                onPressed: () async {
                  final t = await showTimePicker(context: context, initialTime: p.dailySummaryTime);
                  if (t != null) p.setDailySummaryTime(t);
                },
                child: Text(_fmtTime(p.dailySummaryTime)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ───── DATA & ABOUT ─────
        _section(p.label('about')),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(p.label('version')),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.star_outline, color: AppColors.gold),
              title: Text(p.label('rate_app')),
              onTap: () => _openUrl('https://play.google.com/store/apps/'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: AppColors.green),
              title: Text(p.label('share')),
              onTap: () => Share.share('Hijri Calendar — ${p.label('app_name')}'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(p.label('privacy')),
              onTap: () => _openUrl('https://example.com/privacy'),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: Text(p.label('contact')),
              onTap: () => _openUrl('mailto:contact@example.com'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.red),
              title: Text(p.label('clear_all'),
                  style: const TextStyle(color: AppColors.red)),
              onTap: () async {
                final ok = await showDialog<bool>(context: context, builder: (_) =>
                  AlertDialog(
                    title: Text(p.label('confirm')),
                    content: Text(p.label('clear_all')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false),
                          child: Text(p.label('cancel'))),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(p.label('delete'))),
                    ],
                  ));
                if (ok == true) {
                  for (final e in [...p.events]) {
                    await p.deleteEvent(e.id);
                  }
                }
              },
            ),
          ]),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ───── helpers ─────
  Widget _section(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Text(t.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w800, fontSize: 12,
          letterSpacing: 1.2, color: AppColors.text3)),
  );

  Widget _stat(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 18, color: color)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppColors.text2)),
      ]),
    ),
  );

  String _initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return '👤';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fontLabel(double v) {
    if (v <= 0.9) return 'S';
    if (v <= 1.05) return 'M';
    if (v <= 1.18) return 'L';
    return 'XL';
  }

  String _nextDays(AppProvider p) {
    int? best;
    for (final cfg in IslamicEventsData.all) {
      if (cfg.frequency == IslamicFrequency.daily) continue;
      if (!(cfg.alwaysOn || p.enabledIslamic.contains(cfg.key))) continue;
      final d = p.daysUntilIslamic(cfg, maxDays: 365);
      if (d != null && (best == null || d < best)) best = d;
    }
    return best == null ? '—' : '$best';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
