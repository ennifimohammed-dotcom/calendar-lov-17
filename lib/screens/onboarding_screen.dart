import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _languages = [
    {'code': 'ar', 'flag': '🇸🇦', 'name': 'العربية'},
    {'code': 'fr', 'flag': '🇫🇷', 'name': 'Français'},
    {'code': 'en', 'flag': '🇬🇧', 'name': 'English'},
    {'code': 'es', 'flag': '🇪🇸', 'name': 'Español'},
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _welcome(p),
                  _languagePage(p),
                  _islamicPage(p),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.all(4),
                width: i == _page ? 24 : 8, height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.green : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity, height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () async {
                    if (_page < 2) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut);
                    } else {
                      await p.completeOnboarding();
                      if (!mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()));
                    }
                  },
                  child: Text(
                    _page < 2 ? p.label('next') : p.label('get_started'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcome(AppProvider p) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160, height: 160,
            decoration: const BoxDecoration(
              color: AppColors.greenPale,
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🌙', style: TextStyle(fontSize: 80))),
          ),
          const SizedBox(height: 32),
          Text(p.label('welcome'),
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Text(p.label('app_name'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.green)),
        ],
      ),
    );
  }

  Widget _languagePage(AppProvider p) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(p.label('choose_language'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12, crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: _languages.map((l) {
                final selected = p.language == l['code'];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => p.setLanguage(l['code']!),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? AppColors.greenPale : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? AppColors.green : AppColors.border,
                        width: selected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l['flag']!, style: const TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text(l['name']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? AppColors.green : null)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _islamicPage(AppProvider p) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text('🕌', textAlign: TextAlign.center, style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(p.label('enable_islamic_events'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _quick(p, 'ramadan_start', '🌙'),
                  _quick(p, 'eid_fitr', '🎉'),
                  _quick(p, 'eid_adha', '🎊'),
                  _quick(p, 'arafat', '🏔'),
                  _quick(p, 'ayyam_albid', '🌕'),
                  _quick(p, 'jumua', '🕌'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quick(AppProvider p, String key, String emoji) {
    final enabled = p.enabledIslamic.contains(key);
    final cfg = _findCfg(key);
    final title = cfg?[p.language] ?? key;
    return Card(
      child: SwitchListTile(
        value: enabled,
        onChanged: (_) => p.toggleIslamic(key),
        activeColor: AppColors.green,
        secondary: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Map<String, String>? _findCfg(String key) {
    try {
      // Avoid heavy import here — just static labels mapping
      const titles = {
        'ramadan_start': {'ar': 'بداية رمضان', 'fr': 'Début Ramadan', 'en': 'Start of Ramadan', 'es': 'Inicio Ramadán'},
        'eid_fitr': {'ar': 'عيد الفطر', 'fr': 'Aïd al-Fitr', 'en': 'Eid al-Fitr', 'es': 'Eid al-Fitr'},
        'eid_adha': {'ar': 'عيد الأضحى', 'fr': 'Aïd al-Adha', 'en': 'Eid al-Adha', 'es': 'Eid al-Adha'},
        'arafat': {'ar': 'يوم عرفة', 'fr': 'Jour de Arafat', 'en': 'Day of Arafat', 'es': 'Día de Arafat'},
        'ayyam_albid': {'ar': 'الأيام البيض', 'fr': 'Ayyam Al-Bid', 'en': 'White Days', 'es': 'Días Blancos'},
        'jumua': {'ar': 'الجمعة', 'fr': 'Joumoua', 'en': 'Jumu\'ah', 'es': 'Yumu\'ah'},
      };
      return titles[key];
    } catch (_) { return null; }
  }
}
