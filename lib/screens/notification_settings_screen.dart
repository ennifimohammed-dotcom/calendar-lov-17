import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/notification_settings.dart';
import '../services/notification_service.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

/// Pixel-perfect Notification Settings screen matching the provided screenshots.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationSettings _s;
  // Short label getter, captured in build so card builders can reach it.
  String Function(String) _l = (k) => k;

  // iOS-like blue used in the mockups.
  static const _blue = Color(0xFF1F7AFE);
  static const _bgGroup = Color(0xFFF2F2F7);
  static const _cardBg = Colors.white;
  static const _divider = Color(0xFFE5E5EA);
  static const _muted = Color(0xFF8E8E93);

  @override
  void initState() {
    super.initState();
    _s = NotificationService.instance.settings;
  }

  Future<void> _save() async {
    if (!mounted) return;
    final p0 = context.read<AppProvider>();
    await NotificationService.instance.updateSettings(_s,
        language: p0.language, accentColor: p0.accentColor);
    if (!mounted) return;
    final p = context.read<AppProvider>();
    await NotificationService.instance.rescheduleAll(
      personalEvents: p.events,
      enabledIslamic: p.enabledIslamic,
      enable29th: p.enable29thReminder,
      time29th: p.time29th,
      enableDailySummary: p.enableDailySummary,
      dailySummaryTime: p.dailySummaryTime,
      ramadanReminderDays: p.ramadanReminderDays,
      language: p.language,
      region: p.region,
      userOffset: p.hijriOffset,
      accentColor: p.accentColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    _l = p.label;
    return Scaffold(
      backgroundColor: _bgGroup,
      appBar: AppBar(
        backgroundColor: _bgGroup,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          p.label('notif_title_screen'),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _authorizationCard(),
          const SizedBox(height: 24),
          _modeCard(),
          const SizedBox(height: 0),
          _popupCard(),
          const SizedBox(height: 0),
          _soundCard(),
          const SizedBox(height: 0),
          _vibrationCard(),
          const SizedBox(height: 0),
          _lockScreenCard(),
          const SizedBox(height: 24),
          _volumeCard(),
          const SizedBox(height: 32),
          _testButton(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _testButton(BuildContext context) {
    final p = context.read<AppProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            await NotificationService.instance.updateSettings(_s,
                language: p.language, accentColor: p.accentColor);
            await NotificationService.instance.showTestNow(
                language: p.language, accentColor: p.accentColor);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(p.label('notif_test_sent')),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          icon: const Icon(Icons.notifications_active),
          label: Text(p.label('notif_test'),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  // === Authorization toggle (top blue card) ===
  Widget _authorizationCard() {
    final l = _l;
    return _GroupedCard(
      child: SwitchListTile.adaptive(
        value: _s.enabled,
        activeColor: _blue,
        title: Text(
          l('notif_authorization'),
          style: const TextStyle(
            color: _blue,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onChanged: (v) {
          setState(() => _s.enabled = v);
          _save();
        },
      ),
    );
  }

  Widget _modeCard() {
    final l = _l;
    return _GroupedCard(
      topRadius: true,
      bottomRadius: false,
      child: Column(
        children: [
          _radioTile(
            label: l('notif_mode_alert'),
            selected: _s.mode == NotificationMode.alert,
            onTap: () {
              setState(() => _s.mode = NotificationMode.alert);
              _save();
            },
          ),
          const Divider(height: 1, indent: 56, color: _divider),
          _radioTile(
            label: l('notif_mode_silent'),
            selected: _s.mode == NotificationMode.discret,
            onTap: () {
              setState(() => _s.mode = NotificationMode.discret);
              _save();
            },
          ),
        ],
      ),
    );
  }

  Widget _popupCard() {
    final l = _l;
    return _GroupedCard(
      topRadius: false,
      bottomRadius: false,
      child: SwitchListTile.adaptive(
        value: _s.popupEnabled,
        activeColor: _blue,
        title: Text(
          l('notif_popup'),
          style: const TextStyle(fontSize: 15, color: Colors.black),
        ),
        onChanged: (v) {
          setState(() => _s.popupEnabled = v);
          _save();
        },
      ),
    );
  }

  Widget _soundCard() {
    final l = _l;
    return _GroupedCard(
      topRadius: false,
      bottomRadius: false,
      child: ListTile(
        title: Text(l('notif_sound'),
            style: const TextStyle(fontSize: 15, color: Colors.black)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _s.soundLabel,
            style: const TextStyle(color: _blue, fontSize: 14),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: _muted),
        onTap: _openSoundPicker,
      ),
    );
  }

  Widget _vibrationCard() {
    final l = _l;
    return _GroupedCard(
      topRadius: false,
      bottomRadius: false,
      child: SwitchListTile.adaptive(
        value: _s.vibrationEnabled,
        activeColor: _blue,
        title: Text(l('notif_vibration'),
            style: const TextStyle(fontSize: 15, color: Colors.black)),
        onChanged: (v) {
          setState(() => _s.vibrationEnabled = v);
          _save();
        },
      ),
    );
  }

  Widget _lockScreenCard() {
    final l = _l;
    return _GroupedCard(
      topRadius: false,
      bottomRadius: true,
      child: ListTile(
        title: Text(l('notif_lock_screen'),
            style: const TextStyle(fontSize: 15, color: Colors.black)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _lockLabel(_s.lockScreenVisibility),
            style: const TextStyle(color: _blue, fontSize: 14),
          ),
        ),
        onTap: _openLockSheet,
      ),
    );
  }

  Widget _volumeCard() {
    final l = _l;
    return _GroupedCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.volume_up_rounded, color: _blue, size: 20),
                const SizedBox(width: 8),
                Text(l('notif_volume'),
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('${(_s.volume * 100).round()}%',
                    style: const TextStyle(color: _muted, fontSize: 13)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _blue,
                thumbColor: _blue,
                inactiveTrackColor: _divider,
                trackHeight: 4,
              ),
              child: Slider(
                value: _s.volume,
                onChanged: (v) {
                  setState(() => _s.volume = v);
                },
                onChangeEnd: (_) => _save(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === helpers ===
  Widget _radioTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _RadioDot(selected: selected, color: _blue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 15, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  String _lockLabel(LockScreenVisibility v) {
    final l = _l;
    switch (v) {
      case LockScreenVisibility.hideContent:
        return l('notif_lock_hide_content');
      case LockScreenVisibility.hideNotifications:
        return l('notif_lock_hide_all');
      case LockScreenVisibility.showAll:
        return l('notif_lock_show_all');
    }
  }

  Future<void> _openSoundPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SoundSheet(current: _s.sound),
    );
    if (result != null) {
      setState(() => _s.sound = result);
      await _save();
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _openLockSheet() async {
    final result = await showModalBottomSheet<LockScreenVisibility>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LockSheet(current: _s.lockScreenVisibility),
    );
    if (result != null) {
      setState(() => _s.lockScreenVisibility = result);
      await _save();
    }
  }
}

class _GroupedCard extends StatelessWidget {
  final Widget child;
  final bool topRadius;
  final bool bottomRadius;
  const _GroupedCard({
    required this.child,
    this.topRadius = true,
    this.bottomRadius = true,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(topRadius ? 14 : 0),
          bottom: Radius.circular(bottomRadius ? 14 : 0),
        ),
        child: Container(color: Colors.white, child: child),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  final Color color;
  const _RadioDot({required this.selected, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? color : const Color(0xFFC7C7CC),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}

// === Lock screen sheet (matches second screenshot) ===
class _LockSheet extends StatelessWidget {
  final LockScreenVisibility current;
  const _LockSheet({required this.current});

  static const _blue = Color(0xFF1F7AFE);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Écran de verrouillage',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
              _option(context, 'Masquer le contenu',
                  LockScreenVisibility.hideContent),
              const Divider(height: 1, color: Color(0xFFE5E5EA), indent: 48),
              _option(context, 'Ne pas afficher les notifications',
                  LockScreenVisibility.hideNotifications),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Annuler',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(
      BuildContext context, String label, LockScreenVisibility v) {
    final selected = v == current;
    return InkWell(
      onTap: () => Navigator.pop(context, v),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _RadioDot(selected: selected, color: _blue),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 15, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

// === Sound picker sheet ===
class _SoundSheet extends StatelessWidget {
  final String current;
  const _SoundSheet({required this.current});

  static const _blue = Color(0xFF1F7AFE);
  static const _options = [
    {'k': 'brightline', 'l': 'Brightline'},
    {'k': 'alpha', 'l': 'Alpha'},
    {'k': 'arrow', 'l': 'Arrow'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Son de notification',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
              ..._options.map((o) {
                final selected = current == o['k'];
                return Column(children: [
                  InkWell(
                    onTap: () => Navigator.pop(context, o['k']),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(children: [
                        _RadioDot(selected: selected, color: _blue),
                        const SizedBox(width: 14),
                        Expanded(child: Text(o['l']!,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black))),
                      ]),
                    ),
                  ),
                  const Divider(
                      height: 1, color: Color(0xFFE5E5EA), indent: 48),
                ]);
              }),
              InkWell(
                onTap: () => Navigator.pop(context, 'custom:user'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(children: [
                    _RadioDot(
                        selected: current.startsWith('custom:'), color: _blue),
                    const SizedBox(width: 14),
                    const Expanded(
                        child: Text('Personnaliser',
                            style: TextStyle(
                                fontSize: 15, color: Colors.black))),
                    const Icon(Icons.folder_open, color: _blue, size: 20),
                  ]),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Annuler',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
