# v15 — Hotfix build
- Corrigé l'erreur de compilation: `p.t('no_events')` → `p.label('no_events')` dans `lib/screens/calendar_screen.dart` (la méthode du provider s'appelle `label`, pas `t`).
- Version bump: 1.0.15+15.
- Workflow `.github/workflows/build.yml` inchangé (JDK 17 + Build-Tools 34.0.0 + Flutter 3.24.5).
