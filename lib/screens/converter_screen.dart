import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../services/regional_hijri_service.dart';
import '../utils/hijri_utils.dart';
import '../theme.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});
  @override State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  late HijriDate _hijri;
  DateTime _greg = DateTime.now();
  bool _hijriToGreg = true;

  @override
  void initState() {
    super.initState();
    _hijri = context.read<AppProvider>().today();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(p.label('tab_converter'),
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(p.label('hijri_to_greg'))),
              ButtonSegment(value: false, label: Text(p.label('greg_to_hijri'))),
            ],
            selected: {_hijriToGreg},
            onSelectionChanged: (s) => setState(() => _hijriToGreg = s.first),
          ),
          const SizedBox(height: 24),
          if (_hijriToGreg) _hijriPicker(p) else _gregPicker(p),
          const SizedBox(height: 24),
          const Center(child: Icon(Icons.arrow_downward, size: 32, color: AppColors.green)),
          const SizedBox(height: 16),
          _resultCard(p),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.today),
                label: Text(p.label('today')),
                onPressed: () => setState(() {
                  _hijri = context.read<AppProvider>().today();
                  _greg = DateTime.now();
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.green),
                icon: const Icon(Icons.share),
                label: Text(p.label('share')),
                onPressed: () {
                  final h = _hijriToGreg ? _hijri : context.read<AppProvider>().hijriFromGregorian(_greg);
                  final g = _hijriToGreg
                      ? context.read<AppProvider>().gregorianFromHijri(_hijri)
                      : _greg;
                  Share.share('${h.day} ${h.monthName(p.language)} ${h.year} = ${g.day}/${g.month}/${g.year}');
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _hijriPicker(AppProvider p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_hijri.monthName(p.language),
                style: Theme.of(context).textTheme.titleLarge),
            Text('${_hijri.day} • ${_hijri.year}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                  color: AppColors.green)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
              _btn('-1d', () => setState(() => _hijri = RegionalHijri.addDays(_hijri, -1, region: p.region, userOffset: p.hijriOffset))),
              _btn('+1d', () => setState(() => _hijri = RegionalHijri.addDays(_hijri, 1, region: p.region, userOffset: p.hijriOffset))),
              _btn('-1m', () => setState(() => _hijri = RegionalHijri.addMonths(_hijri, -1, region: p.region, userOffset: p.hijriOffset))),
              _btn('+1m', () => setState(() => _hijri = RegionalHijri.addMonths(_hijri, 1, region: p.region, userOffset: p.hijriOffset))),
              _btn('-1y', () => setState(() => _hijri = HijriDate(_hijri.year - 1, _hijri.month, _hijri.day))),
              _btn('+1y', () => setState(() => _hijri = HijriDate(_hijri.year + 1, _hijri.month, _hijri.day))),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              icon: const Icon(Icons.event),
              label: Text(p.label('date')),
              onPressed: () async {
                // Pick a Gregorian date and convert via the active region.
                final picked = await showDatePicker(
                  context: context,
                  initialDate: context.read<AppProvider>().gregorianFromHijri(_hijri),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null && mounted) {
                  setState(() {
                    _hijri = context.read<AppProvider>().hijriFromGregorian(picked);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _gregPicker(AppProvider p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${_greg.day}/${_greg.month}/${_greg.year}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                  color: AppColors.green)),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              icon: const Icon(Icons.calendar_today),
              label: Text(p.label('date')),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _greg,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _greg = picked);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(AppProvider p) {
    if (_hijriToGreg) {
      final g = p.gregorianFromHijri(_hijri);
      return Card(
        color: AppColors.greenPale,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(p.label('corresponds_to'),
                style: const TextStyle(color: AppColors.text2)),
            const SizedBox(height: 8),
            Text('${g.day} / ${g.month} / ${g.year}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                  color: AppColors.green)),
          ]),
        ),
      );
    } else {
      final h = context.read<AppProvider>().hijriFromGregorian(_greg);
      return Card(
        color: AppColors.greenPale,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(p.label('corresponds_to'),
                style: const TextStyle(color: AppColors.text2)),
            const SizedBox(height: 8),
            Text('${h.day} ${h.monthName(p.language)} ${h.year}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                  color: AppColors.green)),
          ]),
        ),
      );
    }
  }

  Widget _btn(String l, VoidCallback f) => OutlinedButton(
    onPressed: f,
    style: OutlinedButton.styleFrom(minimumSize: const Size(60, 36)),
    child: Text(l),
  );
}
