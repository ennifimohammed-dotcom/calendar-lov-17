# v17 — تنسيق إشعارات الأجندة

- توطين قنوات الإشعارات (اسم/وصف القناة) حسب اللغة المختارة → تختفي الكلمات الفرنسية من شاشة القفل ولوحة الصوت.
- تطبيق لون التطبيق (accent) على الإشعار: `color`, `colorized`, `ledColor`.
- استخدام BigTextStyle في إشعار الاختبار أيضاً.
- تمرير `language` و `accentColor` إلى NotificationService من main, AppProvider, و notification_settings_screen.
- اسم القناة يصبح "بدر" بالعربية بدل "Hijri Calendar".
