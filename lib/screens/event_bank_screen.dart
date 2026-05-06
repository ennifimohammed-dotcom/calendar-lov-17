import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/islamic_events.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class EventBankScreen extends StatefulWidget {
  const EventBankScreen({super.key});
  @override State<EventBankScreen> createState() => _EventBankScreenState();
}

class _EventBankScreenState extends State<EventBankScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final filtered = IslamicEventsData.all.where((e) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.titles.values.any((v) => v.toLowerCase().contains(q)) ||
             e.descriptions.values.any((v) => v.toLowerCase().contains(q));
    }).toList();

    final groups = <IslamicFrequency, List<IslamicEventConfig>>{
      IslamicFrequency.daily: [],
      IslamicFrequency.weekly: [],
      IslamicFrequency.monthly: [],
      IslamicFrequency.annual: [],
    };
    for (final e in filtered) {
      groups[e.frequency]!.add(e);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.label('tab_bank'),
                  style: const TextStyle(color: Colors.white,
                    fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${IslamicEventsData.all.length} ${p.language == "ar" ? "فضيلة" : "virtues"}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                    onPressed: () => p.enableAllIslamic(),
                    child: Text(p.label('enable_all')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                    onPressed: () => p.disableAllIslamic(),
                    child: Text(p.label('disable_all')),
                  ),
                ),
              ]),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: p.label('search'),
              filled: true,
              fillColor: Theme.of(context).cardTheme.color,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final freq in IslamicFrequency.values)
                if ((groups[freq]?.isNotEmpty ?? false))
                  ..._buildSection(p, freq, groups[freq]!),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSection(AppProvider p, IslamicFrequency freq, List<IslamicEventConfig> items) {
    String label;
    switch (freq) {
      case IslamicFrequency.daily:   label = p.label('frequency_daily'); break;
      case IslamicFrequency.weekly:  label = p.label('frequency_weekly'); break;
      case IslamicFrequency.monthly: label = p.label('frequency_monthly'); break;
      case IslamicFrequency.annual:  label = p.label('frequency_annual'); break;
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Text(label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13, letterSpacing: 1.1,
              color: AppColors.text3)),
      ),
      for (final e in items) _row(p, e),
    ];
  }

  Widget _row(AppProvider p, IslamicEventConfig e) {
    final enabled = e.alwaysOn || p.enabledIslamic.contains(e.key);
    final daysUntil = p.daysUntilIslamic(e, maxDays: 30);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(e),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: e.color.withOpacity(0.15),
                  shape: BoxShape.circle),
                child: Center(
                  child: Text(e.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 8),
              // color dot
              Container(
                width: 6, height: 36,
                decoration: BoxDecoration(
                  color: e.color,
                  borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(e.titles[p.language] ?? e.titles['en']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      if (daysUntil != null && daysUntil <= 30)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(left: 4, right: 4),
                          decoration: BoxDecoration(
                            color: e.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10)),
                          child: Text(_daysBadge(p, daysUntil),
                              style: TextStyle(color: e.color,
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      if (e.alwaysOn)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4)),
                          child: const Text('★', style: TextStyle(fontSize: 11, color: AppColors.gold)),
                        ),
                    ]),
                    const SizedBox(height: 2),
                    Text(e.descriptions[p.language] ?? '',
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeColor: AppColors.green,
                onChanged: e.alwaysOn ? null : (_) => p.toggleIslamic(e.key),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _daysBadge(AppProvider p, int days) {
    if (days == 0) return p.label('today_word');
    if (days == 1) return p.label('tomorrow_word');
    return '${p.label('in_days')} $days ${p.label('days_unit')}';
  }

  void _openDetail(IslamicEventConfig cfg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailSheet(cfg: cfg),
    );
  }
}

class _EventDetailSheet extends StatelessWidget {
  final IslamicEventConfig cfg;
  const _EventDetailSheet({required this.cfg});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final enabled = cfg.alwaysOn || p.enabledIslamic.contains(cfg.key);
    final daysUntil = p.daysUntilIslamic(cfg, maxDays: 365);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: cfg.color.withOpacity(0.15),
                shape: BoxShape.circle),
              child: Center(
                child: Text(cfg.emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cfg.titles[p.language] ?? cfg.titles['en']!,
                      style: Theme.of(context).textTheme.titleLarge),
                  if (daysUntil != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        daysUntil == 0
                            ? p.label('today_word')
                            : (daysUntil == 1
                                ? p.label('tomorrow_word')
                                : '${p.label('in_days')} $daysUntil ${p.label('days_unit')}'),
                        style: TextStyle(color: cfg.color, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Text(cfg.descriptions[p.language] ?? '',
              style: const TextStyle(fontSize: 14, height: 1.5)),
          if ((cfg.virtues[p.language] ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldPale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withOpacity(0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppColors.gold),
                    const SizedBox(width: 6),
                    Text(p.label('virtue'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.gold)),
                  ]),
                  const SizedBox(height: 6),
                  Text(cfg.virtues[p.language] ?? '',
                      style: const TextStyle(fontSize: 13, height: 1.5,
                          color: AppColors.text)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: enabled,
                activeColor: AppColors.green,
                onChanged: cfg.alwaysOn ? null : (_) {
                  p.toggleIslamic(cfg.key);
                  Navigator.pop(context);
                },
                title: Text(p.label('notifications'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(cfg.alwaysOn
                  ? (p.language == 'ar' ? 'مفعّل دائماً' : 'Toujours activé')
                  : (p.language == 'ar' ? 'تفعيل/إلغاء' : 'Activer / désactiver')),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
