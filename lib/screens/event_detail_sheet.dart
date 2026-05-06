import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event_model.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class EventDetailSheet extends StatelessWidget {
  final AppEvent event;
  final VoidCallback? onEdit;
  const EventDetailSheet({super.key, required this.event, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
          Row(
            children: [
              Container(width: 6, height: 32,
                decoration: BoxDecoration(color: event.color,
                  borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 12),
              if (event.emoji.isNotEmpty)
                Text('${event.emoji} ', style: const TextStyle(fontSize: 24)),
              Expanded(
                child: Text(event.getTitle(p.language),
                  style: Theme.of(context).textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(builder: (_) {
            final desc = event.getDescription(p.language);
            if (desc.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(desc,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
            );
          }),
          Builder(builder: (_) {
            final virtue = event.getVirtue(p.language);
            if (virtue.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldPale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome,
                        size: 16, color: AppColors.gold),
                    const SizedBox(width: 6),
                    Text(p.label('virtue'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold)),
                  ]),
                  const SizedBox(height: 6),
                  Text(virtue,
                      style: const TextStyle(
                          fontSize: 13, height: 1.6, color: AppColors.text)),
                ],
              ),
            );
          }),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.text3),
              const SizedBox(width: 8),
              Text('${event.hijriDay}/${event.hijriMonth}'
                + (event.hijriYear > 0 ? '/${event.hijriYear}' : ''),
                style: const TextStyle(color: AppColors.text2)),
            ],
          ),
          if (event.hour != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.text3),
              const SizedBox(width: 8),
              Text('${event.hour!.toString().padLeft(2, '0')}:${(event.minute ?? 0).toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.text2)),
            ]),
          ],
          if (event.location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.text3),
              const SizedBox(width: 8),
              Expanded(child: Text(event.location,
                  style: const TextStyle(color: AppColors.text2))),
            ]),
          ],
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share, size: 18),
                label: Text(p.label('share')),
                onPressed: () {
                  Share.share('${event.getTitle(p.language)} • ${event.hijriDay}/${event.hijriMonth}');
                },
              ),
            ),
            if (!event.isIslamic) ...[
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.green),
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(p.label('edit_event')),
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
                onPressed: () async {
                  await context.read<AppProvider>().deleteEvent(event.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ]),
        ],
      ),
    );
  }
}
