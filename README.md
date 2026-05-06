# 📿 Hijri Calendar — Application Mobile Professionnelle

> Application Flutter complète : calendrier Hijri, gestion d'événements, banque d'événements islamiques, multilingue (AR/FR/EN/ES) avec support RTL.

---

## ✨ Fonctionnalités

- 📅 **Calendrier Hijri** — vues mensuelle, hebdomadaire, agenda
- 🕌 **Banque d'événements islamiques** — 16+ événements (Ramadan, Aïds, Arafat, Ayyam Al-Bid, Laylat al-Qadr, Achoura, Mawlid, etc.)
- ✏️ **Gestion d'événements** — création, édition, catégories, couleurs, emojis, priorités, lieu
- 🔄 **Convertisseur Hijri ↔ Grégorien** intégré
- 🌍 **4 langues** : Arabe (RTL), Français, Anglais, Espagnol
- 🎨 **Mode clair/sombre** + couleur d'accent personnalisable
- 🔔 **Notifications locales** programmables
- 💾 **Stockage local** (SharedPreferences) — fonctionne hors-ligne
- 🎯 **Onboarding** en 3 écrans à la première ouverture

---

## 🚀 Construire l'APK avec GitHub Actions (sans installer Flutter)

C'est la méthode recommandée. **Aucun outil à installer sur votre ordinateur.**

### Étape 1 — Créer un dépôt GitHub
1. Allez sur https://github.com/new
2. Créez un dépôt (par exemple `hijri-calendar`), **vide** (pas de README, pas de `.gitignore`).

### Étape 2 — Pousser le code
Décompressez le ZIP, ouvrez un terminal dans le dossier, puis :

```bash
git init
git add .
git commit -m "Initial commit: Hijri Calendar"
git branch -M main
git remote add origin https://github.com/VOTRE-NOM/hijri-calendar.git
git push -u origin main
```

### Étape 3 — Récupérer l'APK
1. Sur GitHub, ouvrez l'onglet **Actions**.
2. Le workflow **"Build Android APK"** se lance automatiquement (~5 min).
3. Une fois terminé (✅), cliquez dessus → section **Artifacts** en bas.
4. Téléchargez **`hijri-calendar-release-apk`** (APK universel) ou **`hijri-calendar-split-apks`** (APKs plus légers par architecture).
5. Transférez le `.apk` sur votre téléphone Android et installez-le (autorisez les "sources inconnues").

---

## 🛠 Construire en local (optionnel)

Si vous voulez compiler localement :

```bash
# Installer Flutter : https://docs.flutter.dev/get-started/install
flutter --version    # 3.19+
flutter pub get
flutter run          # lance sur émulateur/appareil branché
flutter build apk --release
# APK produit : build/app/outputs/flutter-apk/app-release.apk
```

---

## 📁 Structure du projet

```
lib/
├── main.dart                          # entrée
├── theme.dart                         # design system (couleurs, fonts)
├── models/event_model.dart            # AppEvent, ReminderConfig
├── data/islamic_events.dart           # 16+ événements islamiques
├── utils/hijri_utils.dart             # conversion Hijri ↔ Grégorien
├── providers/app_provider.dart        # state + persistance + i18n
├── services/notification_service.dart # notifications locales
└── screens/
    ├── onboarding_screen.dart
    ├── home_screen.dart               # bottom nav 4 tabs + FAB
    ├── calendar_screen.dart           # mois / semaine / agenda
    ├── event_bank_screen.dart         # banque islamique
    ├── add_event_screen.dart          # formulaire complet
    ├── event_detail_sheet.dart
    ├── converter_screen.dart
    └── settings_screen.dart

android/                  # config Gradle, AndroidManifest, icônes
.github/workflows/build.yml  # CI qui produit l'APK
```

---

## ⚠️ Notes importantes

- **Algorithme Hijri** : tabular (Umm al-Qura). Précision ±1 jour vs observation astronomique. Un offset (-2 à +2) est paramétrable.
- **Notifications** : nécessitent l'autorisation au premier lancement (Android 13+).
- **Mawlid** : désactivé par défaut (sujet juridique parmi les écoles).
- Le projet utilise **Flutter 3.24+ / Dart 3.3+**. Le workflow GitHub Actions épingle Flutter 3.24.3.

---

## 🔧 Personnalisation rapide

| Quoi | Où |
|------|----|
| Nom de l'app | `android/app/src/main/AndroidManifest.xml` → `android:label` |
| Package ID | `android/app/build.gradle` → `applicationId` |
| Icône | `android/app/src/main/res/mipmap-*/ic_launcher.png` |
| Couleurs | `lib/theme.dart` |
| Ajouter un événement islamique | `lib/data/islamic_events.dart` |
| Ajouter une langue | `lib/providers/app_provider.dart` (dictionnaire `_labels`) |

---

## 📜 Licence

Code source libre — utilisez-le comme vous voulez. Bonne route inchaAllah 🌙
