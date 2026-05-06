# v9 — Hotfix build

## Correction
- **converter_screen.dart** : suppression de l'erreur de compilation
  `Undefined name 'context'` à la ligne 14.
  Le champ `_hijri` ne peut pas être initialisé directement avec
  `context.read<AppProvider>().today()` car `context` n'est pas
  disponible dans l'initialiseur d'une variable de classe.
  → Déclaré comme `late HijriDate _hijri;` et initialisé dans
  `initState()`, qui a accès au `context`.

Le build APK via GitHub Actions doit maintenant réussir.
