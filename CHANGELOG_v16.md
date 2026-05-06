# v16

* Renamed "المناسبات الإسلامية / Islamic Events" → "فضائل إسلامية / Islamic Virtues" everywhere (tab, settings stats, onboarding).
* Event detail pop-up for Islamic events now displays:
  - Full localized description (ar/fr/en/es)
  - The COMPLETE virtue (full hadith / reward) — not truncated.
* Notification body for Islamic events now contains the full description + complete virtue, expanded with Android BigTextStyle so the full text is readable in the notification shade and pop-up.
* AppEvent model gained `descriptions` and `virtues` multilingual maps (with backward-compatible JSON).
