# Journal — retrait des mocks, persistance auth, branchement backend réel

## 1. Suppression des mock data

Supprimés (plus aucune référence dans le code) :
- `core/mock/mock_backend.dart`
- `shared/mock/mock_api.dart`
- `shared/mock/mock_db.dart`
- `features/auth/data/repositories/auth_mock_repository.dart` (mort : jamais
  branché dans les providers réels)
- `features/dashboard/data/datasources/dashboard_mock_datasource.dart` (mort)
- `features/profil/presentation/providers/famille_providers.dart` (mort,
  doublon de `profil_providers.dart` qui est le seul réellement utilisé par
  `profil_page.dart`)

## 2. Switch d'environnement — une seule ligne à changer

`core/config/app_config.dart` :

```dart
static const AppEnvironment environment = AppEnvironment.vercel;
// static const AppEnvironment environment = AppEnvironment.local;
```

- `AppEnvironment.local` → `http://localhost:4000/api` (utilise `adb reverse
  tcp:4000 tcp:4000` comme tu le fais déjà).
- `AppEnvironment.vercel` → `https://prmspadcmbackend.vercel.app/api`.

Toutes les datasources lisent `ApiConstants.baseUrl`, qui suit ce switch
automatiquement. Une surcharge ponctuelle reste possible sans recompiler :
```
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000/api
```
(utile pour un appareil physique sur le même Wi-Fi que ton PC, sans adb reverse)

Je n'ai pas utilisé `flutter_dotenv` (fichier `.env` texte + asset déclaré
dans `pubspec.yaml`) car ce zip ne contenait que `lib/` — pas le
`pubspec.yaml` du projet. Si tu préfères un vrai fichier `.env`, envoie-moi
ton `pubspec.yaml` et je bascule dessus ; le switch actuel remplit la même
promesse ("une ligne à changer") sans dépendance supplémentaire.

## 3. Vérification OTP "commentée"

`core/config/app_config.dart` :
```dart
static const bool bypassOtpVerification = true;
static bool get otpBypassActive =>
    bypassOtpVerification && environment == AppEnvironment.local;
```

Important : le bypass ne s'active **que** si `environment == local`, même si
`bypassOtpVerification` reste à `true`. Raison : `/auth/test/login` est
désormais bloqué en production côté backend (voir le changelog backend,
section 2) — donc si tu mets `environment = vercel` avec le bypass à `true`,
l'app basculera automatiquement sur le flux OTP complet plutôt que d'appeler
une route qui répondrait 404. Pas de configuration incohérente possible.

`features/auth/presentation/pages/login_email_page.dart` a été mis à jour
pour utiliser `AppConfig.otpBypassActive` au lieu de `kDebugMode` (qui suit
le mode de compilation Flutter, pas un choix explicite). Le flux OTP complet
(`demanderCode` / `OtpVerificationPage` / `verifierCode`) reste écrit tel
quel dans `auth_providers.dart` et `otp_verification_page.dart` — rien
supprimé, juste non utilisé tant que le bypass est actif. Pour réactiver
plus tard : repasser `bypassOtpVerification` à `false`.

## 4. Persistance de l'auth

Déjà bien implémentée avant mon passage, je n'ai rien changé ici :
`secure_storage_service.dart` (flutter_secure_storage) + `AuthController.build()`
qui appelle `restaurerSession()` au démarrage + `ApiClient` qui rafraîchit le
token automatiquement sur 401. Fonctionne pareil en local et en Vercel.

## 5. Correctifs de branchement au vrai backend (datasources)

Le format réel des réponses du backend diffère de ce que les datasources
mock laissaient supposer. Corrigé dans **toutes** les datasources :

| Avant (attendu) | Réel (backend) |
|---|---|
| `response.data` = tableau JSON brut | `{ success, resultats, <clé>: [...] }` |
| `GET /patients/moi/traitements` | `GET /traitements` (auto-filtré patient) |
| `GET /patients/moi/rapports` | `GET /rapports` (auto-filtré patient) |
| `GET /patients/moi/documents` | `GET /documents` (auto-filtré patient) |
| `GET /patients/moi/rendezvous` | `GET /rendezvous`, clé `rendezVous` (V majuscule) |
| `GET /souscriptions` (patient) | `GET /souscriptions/moi` (patient) — `/souscriptions` seul est 403 pour un patient |
| `POST /conversations/:id/lu` | `PATCH /conversations/:id/marquer-lu` |
| `ResumePatientModel.fromJson(response.data)` | `ResumePatientModel.fromJson(response.data['patient'])` |

Fichiers réécrits : `auth_remote_datasource.dart`,
`dashboard_remote_datasource.dart` (déjà correct, juste mock retiré),
`dossier_remote_datasource.dart`, `profil_remote_datasource.dart`,
`messagerie_remote_datasource.dart`, `soins_remote_datasource.dart`,
`alerte_providers.dart`.

Nouvelle constante ajoutée : `ApiConstants.mesSouscriptions = '/souscriptions/moi'`
(distincte de `souscriptions = '/souscriptions'`, utilisée pour le `POST` de
souscription).

## 6. Petits correctifs backend nécessaires pour que ça marche vraiment

Voir `CHANGELOG-FUSION.md` du backend, sections 6 et 7, pour le détail :
- `PATCH /api/auth/me` ajouté (toggle biométrie).
- Bouton SOS débloqué (validation `patientId` trop stricte).
- `GET /traitements` auto-filtré pour un patient (bloquait + faille d'accès).
- `GET /patients/moi/membres-famille` ajouté (liste avec détails).

## 7. Non connecté / limitation assumée : invitation d'un membre famille

`ProfilRemoteDataSource.inviterMembreFamille(...)` lève désormais une
`AppException` explicite ("pas encore disponible") au lieu de simuler un
succès : le backend ne sait lier qu'un compte **déjà existant** par son ID,
pas inviter quelqu'un par email pour lui créer un compte. Voir le changelog
backend section 7 pour les deux options si tu veux compléter cette
fonctionnalité.

## 8. Ce qui n'a pas été touché

Tout le reste de l'app (thème, navigation, formulaires, widgets partagés,
UI) est resté intact — seuls les fichiers listés ci-dessus ont été modifiés.

## 9. Alignement sur le système de config de l'app Personnel (`.env` / flutter_dotenv)

Le zip contenait encore les fichiers mocks censés être supprimés (section 1)
ainsi que deux fichiers morts qui les référençaient encore
(`dashboard_mock_datasource.dart`, `famille_providers.dart`) — supprimés
maintenant pour de bon, vérifié qu'aucun autre fichier ne les importait.

`core/config/app_config.dart` (switch `enum` codé en dur) remplacé par
`core/config/env_config.dart`, calqué sur
`prm_spadcm_personnel/lib/core/config/env_config.dart` : la config
d'environnement vit désormais dans un fichier `.env` à la racine du projet,
au lieu d'une ligne de code à changer et recompiler. Les deux apps se
pilotent maintenant de la même façon.

`.env` attendu à la racine (voir `.env.example` fourni) :
```
APP_ENV=local
API_BASE_URL_LOCAL=http://localhost:4000/api
API_BASE_URL_VERCEL=https://prmspadcmbackend.vercel.app/api
BYPASS_OTP=true
```

- `APP_ENV=local` ou `vercel` remplace l'ancien enum `AppEnvironment`.
- `BYPASS_OTP=true` remplace l'ancienne constante
  `bypassOtpVerification`. Comme avant, le bypass ne s'active que si
  `APP_ENV=local` (voir `EnvConfig.otpBypassActive`) : impossible de se
  retrouver avec un bypass actif contre Vercel qui échouerait
  silencieusement (404), même en oubliant de retirer `BYPASS_OTP` du
  `.env`.
- La surcharge `--dart-define=API_BASE_URL=...` fonctionne toujours pareil.

Fichiers modifiés : `core/constants/api_constants.dart` (pointe vers
`EnvConfig.apiBaseUrl` au lieu de `AppConfig.apiBaseUrl`),
`main.dart` (appelle `EnvConfig.init()` avant `runApp`, comme l'app
Personnel), `login_email_page.dart` et `auth_remote_datasource.dart`
(commentaires/références `AppConfig` → `EnvConfig`).

**À faire côté projet (pas inclus dans ce zip qui ne contient que `lib/`)** :
1. Ajouter `flutter_dotenv` à `pubspec.yaml` (même version que côté
   Personnel) :
   ```yaml
   dependencies:
     flutter_dotenv: ^5.1.0
   ```
2. Déclarer `.env` comme asset dans `pubspec.yaml` :
   ```yaml
   flutter:
     assets:
       - .env
   ```
3. Créer le fichier `.env` à la racine du projet (à côté de
   `pubspec.yaml`) à partir de `.env.example`, et l'ajouter à
   `.gitignore` s'il ne l'est pas déjà (ne pas committer de secrets/URLs
   d'environnement).
4. `flutter pub get`.
