# Hijri Calendar v8 — Changelog

## Corrections critiques
- **Notifications nouveaux événements** : liaison directe avec les paramètres
  généraux. Si la notification globale est OFF, aucun rappel n'est planifié.
  Settings rechargés depuis le disque avant CHAQUE planification.
- **Synchronisation Hijri ↔ Grégorien régionale** : nouveau service
  `RegionalHijri` utilisé par tous les écrans et le moteur de notifications.
- **Région Maroc** : table d'ancrages officiels basée sur les annonces du
  Ministère des Habous (habous.gov.ma) — ex. 1 Ramadan 1447 = jeudi
  19 février 2026.
- **Traductions** des notifications d'agenda en AR / FR / EN / ES (titres,
  corps, écran de paramètres, bouton de test, source Hijri).
- **Changement de langue / région** déclenche automatiquement un re-schedule
  complet pour que les notifications futures sortent dans la nouvelle langue.

## Fichiers modifiés / ajoutés
- + lib/services/regional_hijri_service.dart  (NEW)
- ~ lib/services/notification_service.dart    (i18n + region-aware)
- ~ lib/providers/app_provider.dart           (helpers today/source + labels)
- ~ lib/screens/notification_settings_screen.dart  (libellés traduits)
- ~ lib/screens/settings_screen.dart          (source Hijri officielle)
- ~ lib/screens/add_event_screen.dart         (date par défaut régionale)
- ~ lib/screens/calendar_screen.dart          (dates régionales)
- ~ lib/screens/converter_screen.dart         (conversion régionale)
- ~ lib/main.dart                             (passe lang/région au service)

## Build APK
Pousser sur GitHub — le workflow `.github/workflows/build.yml` produit l'APK.
