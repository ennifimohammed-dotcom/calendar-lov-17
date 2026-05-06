import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = AppProvider();
  await provider.init();
  await NotificationService.instance.init();
  // Smart scheduling: refresh the 30-day notification window on every launch
  // (covers post-reboot, settings changes, app updates).
  await NotificationService.instance.rescheduleAll(
    personalEvents: provider.events,
    enabledIslamic: provider.enabledIslamic,
    enable29th: provider.enable29thReminder,
    time29th: provider.time29th,
    enableDailySummary: provider.enableDailySummary,
    dailySummaryTime: provider.dailySummaryTime,
    ramadanReminderDays: provider.ramadanReminderDays,
    language: provider.language,
    region: provider.region,
    userOffset: provider.hijriOffset,
    accentColor: provider.accentColor,
  );
  runApp(MyApp(provider: provider));
}

class MyApp extends StatelessWidget {
  final AppProvider provider;
  const MyApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<AppProvider>(
        builder: (context, p, _) {
          ThemeMode mode;
          switch (p.themeMode) {
            case AppThemeMode.light: mode = ThemeMode.light; break;
            case AppThemeMode.dark: mode = ThemeMode.dark; break;
            case AppThemeMode.system: mode = ThemeMode.system; break;
          }
          return MaterialApp(
            title: 'بدر',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(accent: Color(p.accentColor)),
            darkTheme: AppTheme.dark(accent: Color(p.accentColor)),
            themeMode: mode,
            locale: p.locale,
            supportedLocales: const [
              Locale('ar'), Locale('fr'), Locale('en'), Locale('es'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return Directionality(
                textDirection: p.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: MediaQuery(
                  data: mq.copyWith(textScaler: TextScaler.linear(p.fontScale)),
                  child: child!,
                ),
              );
            },
            home: p.onboardingComplete ? const HomeScreen() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
