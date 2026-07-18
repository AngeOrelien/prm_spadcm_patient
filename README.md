# mobile-app-patient

App Flutter **Patients/Familles** du projet PRM — SPAD Cameroun.

Ce projet reprend **exactement** l'architecture posée dans `mobile-app-personnel`
(feature-first : `core`, `features/<nom>/{data,domain,presentation}`, `shared`,
`router`, `screens`) pour que les deux apps restent cohérentes et faciles à
maintenir en parallèle. Deux ajouts propres à cette app : une **bottom
navigation persistante** (`StatefulShellRoute`) et une entité de session
adaptée (`Patient` au lieu de `Personnel`).

---

## 1. Ce qui est fonctionnel maintenant

### Authentification (identique au flux de l'app Personnel)

Même backend unique, mêmes endpoints, même stockage sécurisé des tokens :

1. Saisie email + mot de passe → `POST /api/auth/request-otp`.
2. Saisie du code reçu par email → `POST /api/auth/verify-login-otp` → tokens
   stockés dans `flutter_secure_storage`.
3. Au démarrage suivant, `GET /api/auth/me` restaure automatiquement la
   session ; sinon tentative silencieuse de `POST /api/auth/refresh-token`.
4. Le `GoRouter` redirige automatiquement selon l'état de session (voir
   `router/app_router.dart`) : session inconnue → splash, non connecté →
   login, connecté → shell principal.

Pas encore d'écran d'inscription (le compte est aujourd'hui provisionné côté
SPAD Cameroun) — voir "Prochaines étapes".

### Navigation du patient (bottom navigation)

`router/app_router.dart` définit un `StatefulShellRoute.indexedStack` avec
**5 onglets**, chacun conservant sa propre pile de navigation :

| Onglet | Route | Cas d'utilisation | Écran |
|---|---|---|---|
| Accueil | `/accueil` | UC2 — Consulter tableau de bord santé | `DashboardPage` |
| Soins | `/soins` | UC3 — Consulter journal de soins | `JournalSoinsPage` |
| Rendez-vous | `/rendez-vous` | UC6 — Consulter calendrier RDV | `RendezVousPage` |
| Messagerie | `/messagerie` | UC8 — Utiliser messagerie interne | `MessageriePage` |
| Profil | `/profil` | UC7 — Gérer profil & sécurité | `ProfilPage` |

Deux cas d'utilisation restants sont **volontairement hors bottom nav** :

- **UC4 — Déclencher alerte SOS** (`/sos`) : bouton flottant rouge
  (`FloatingActionButton.extended`, `centerFloat`) toujours visible dans
  `PatientShell`, quel que soit l'onglet actif. C'est l'action la plus
  critique de l'app (urgence), elle ne doit pas se disputer l'attention avec
  le reste de la navigation ni être à un tap de plus derrière un onglet.
- **UC5 — Consulter documents médicaux** (`/documents`) : consultation
  ponctuelle plutôt qu'usage quotidien, accessible en push depuis l'icône
  de l'app bar sur l'Accueil (et bientôt depuis le Profil).

Toutes les pages de contenu métier sont créées et routées, mais **vides**
pour l'instant (widget partagé `PageEnConstruction`) : le contenu réel
arrivera feature par feature en Phase 2+ de la feuille de route, une fois
les endpoints backend correspondants disponibles.

### Fichiers clés

```
lib/
├── core/
│   ├── constants/api_constants.dart      # URL du backend + endpoints
│   ├── errors/app_exception.dart
│   ├── extensions/context_extensions.dart
│   ├── theme/                            # même design system que l'app Personnel
│   └── utils/validators.dart
├── features/
│   ├── auth/                             # data / domain / presentation (entité Patient)
│   ├── dashboard/presentation/pages/dashboard_page.dart
│   ├── soins/presentation/pages/journal_soins_page.dart
│   ├── rendezvous/presentation/pages/rendezvous_page.dart
│   ├── messagerie/presentation/pages/messagerie_page.dart
│   ├── profil/presentation/pages/profil_page.dart
│   ├── documents/presentation/pages/documents_page.dart   # hors bottom nav
│   └── alerte/presentation/pages/sos_page.dart             # hors bottom nav
├── router/app_router.dart                # redirection + StatefulShellRoute
├── screens/splash_screen.dart
└── shared/
    ├── services/                         # api_client.dart, secure_storage_service.dart
    └── widgets/
        ├── navigation/patient_shell.dart # bottom nav + FAB SOS
        └── misc/page_en_construction.dart
```

## 2. Pourquoi cette architecture

- Même découpage `data / domain / presentation` que l'app Personnel : un
  développeur qui connaît l'une connaît l'autre.
- Pas de `usecases/` remplis pour l'instant, pour la même raison que côté
  Personnel : un seul flux (login OTP) ne justifie pas encore cette couche.
- `PageEnConstruction` mutualise uniquement le *contenu visuel* des écrans
  vides — chaque feature garde son propre fichier/classe de page, donc le
  passage au vrai contenu (Phase 2) ne touchera que ce fichier, jamais le
  router ni le shell.
- `StatefulShellRoute` (plutôt que de simples `GoRoute`) parce que chaque
  onglet doit garder son état/sa pile de navigation en arrière-plan quand on
  bascule dessus — indispensable dès que "Soins" ou "Rendez-vous" auront des
  écrans de détail.

## 3. Lancer le projet

Ce dossier contient uniquement `lib/`, `pubspec.yaml` et ce README — pas les
fichiers générés par `flutter create` (android/, ios/, etc.).

```bash
# Nouveau projet Flutter, puis on copie lib/ et pubspec.yaml par-dessus
flutter create mobile_app_patient
cd mobile_app_patient
# copie le contenu de ce dossier (lib/, pubspec.yaml) en écrasant les fichiers générés
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
```

`API_BASE_URL` par défaut pointe vers `http://localhost:4000/api`. Sur
émulateur Android, utilise `10.0.2.2` ; sur appareil physique, l'IP locale
de ta machine sur le même réseau Wi-Fi.

## 4. Prochaines étapes suggérées

- Écran d'inscription / rattachement d'un compte famille à un patient
  existant (si ce parcours est retenu côté produit).
- Contenu réel de chaque onglet à mesure que les endpoints backend
  correspondants arrivent (Phase 2 : dossier patient & documents ; Phase 3 :
  messagerie temps réel + alertes SOS avec Socket.io/FCM).
- Écrans de détail nichés dans les branches `soins` et `rendez-vous`
  (ex: détail d'un rapport journalier, détail d'un rendez-vous).
- Authentification biométrique, une fois la session JWT en place — simple
  ajout dans `AuthRepositoryImpl` + `local_auth`, pas de refonte nécessaire.
