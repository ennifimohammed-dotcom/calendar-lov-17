import 'package:shared_preferences/shared_preferences.dart';

enum NotificationMode { alert, discret }
enum LockScreenVisibility { hideContent, hideNotifications, showAll }

class NotificationSettings {
  bool enabled;
  NotificationMode mode;
  bool popupEnabled;
  bool vibrationEnabled;
  String sound; // 'brightline' | 'alpha' | 'arrow' | 'custom:<uri>'
  double volume; // 0.0..1.0
  LockScreenVisibility lockScreenVisibility;

  NotificationSettings({
    this.enabled = true,
    this.mode = NotificationMode.alert,
    this.popupEnabled = true,
    this.vibrationEnabled = true,
    this.sound = 'brightline',
    this.volume = 0.8,
    this.lockScreenVisibility = LockScreenVisibility.hideContent,
  });

  static const _kEnabled = 'notif_enabled_v1';
  static const _kMode = 'notif_mode_v1';
  static const _kPopup = 'notif_popup_v1';
  static const _kVibrate = 'notif_vibrate_v1';
  static const _kSound = 'notif_sound_v1';
  static const _kVolume = 'notif_volume_v1';
  static const _kLock = 'notif_lock_v1';

  static Future<NotificationSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return NotificationSettings(
      enabled: p.getBool(_kEnabled) ?? true,
      mode: NotificationMode.values[p.getInt(_kMode) ?? 0],
      popupEnabled: p.getBool(_kPopup) ?? true,
      vibrationEnabled: p.getBool(_kVibrate) ?? true,
      sound: p.getString(_kSound) ?? 'brightline',
      volume: p.getDouble(_kVolume) ?? 0.8,
      lockScreenVisibility:
          LockScreenVisibility.values[p.getInt(_kLock) ?? 0],
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, enabled);
    await p.setInt(_kMode, mode.index);
    await p.setBool(_kPopup, popupEnabled);
    await p.setBool(_kVibrate, vibrationEnabled);
    await p.setString(_kSound, sound);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kLock, lockScreenVisibility.index);
  }

  String get soundLabel {
    if (sound.startsWith('custom:')) return 'Personnalisé';
    switch (sound) {
      case 'alpha': return 'Alpha';
      case 'arrow': return 'Arrow';
      case 'brightline':
      default: return 'Brightline';
    }
  }

  /// Maps logical sound key to a raw resource name (without extension).
  /// Custom sounds fall back to the default channel sound.
  String? get androidSoundResource {
    if (sound == 'brightline') return 'brightline';
    if (sound == 'alpha') return 'alpha';
    if (sound == 'arrow') return 'arrow';
    return null; // custom -> use default
  }

  /// Channel id changes with sound + mode + vibration so Android picks up changes.
  String get channelId {
    final m = mode == NotificationMode.alert ? 'alert' : 'discret';
    final s = sound.startsWith('custom:') ? 'custom' : sound;
    final v = vibrationEnabled ? 'v1' : 'v0';
    return 'hijri_${m}_${s}_$v';
  }
}
