import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Bascule locale <-> Vercel pour l'app Patients/Familles.
///
/// Toute la config d'environnement vit dans le fichier `.env` à la racine du
/// projet (à côté de `pubspec.yaml`) — même mécanisme que côté app
/// Personnel (`prm_spadcm_personnel/lib/core/config/env_config.dart`), pour
/// que les deux apps se pilotent de la même façon. Pour changer de backend,
/// il suffit de modifier la ligne `APP_ENV` dans `.env` — aucun changement
/// de code requis :
///
///   APP_ENV=local   -> utilise API_BASE_URL_LOCAL (backend Node en local,
///                       typiquement joint via `adb reverse tcp:4000 tcp:4000`)
///   APP_ENV=vercel  -> utilise API_BASE_URL_VERCEL (backend déployé sur
///                       Vercel + MongoDB Atlas)
///
/// `EnvConfig.init()` doit être appelé une seule fois, avant `runApp()`
/// (voir `main.dart`).
class EnvConfig {
  EnvConfig._();

  static bool _loaded = false;

  /// Charge `.env`. Idempotent : un second appel ne recharge rien.
  static Future<void> init() async {
    if (_loaded) return;
    await dotenv.load(fileName: '.env');
    _loaded = true;
  }

  static String get _appEnv =>
      dotenv.env['APP_ENV']?.trim().toLowerCase() ?? 'local';

  static bool get isVercel => _appEnv == 'vercel';

  /// URL de base de l'API à utiliser pour toute la durée de vie de l'app,
  /// choisie selon `APP_ENV`.
  ///
  /// Une surcharge ponctuelle reste possible sans toucher à `.env`, via :
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000/api
  /// (utile pour un appareil physique sur le même réseau Wi-Fi, sans adb reverse).
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    final url = isVercel
        ? dotenv.env['API_BASE_URL_VERCEL']
        : dotenv.env['API_BASE_URL_LOCAL'];

    return url ?? 'http://localhost:4000/api';
  }

  /// ⚠️ TEMPORAIRE — bypass de la vérification OTP à la connexion (appelle
  /// directement `POST /auth/test/login` au lieu du flux OTP à 2 facteurs).
  ///
  /// Piloté par `.env` : `BYPASS_OTP=true`. Ne s'active **que** si
  /// `APP_ENV=local`, même si `BYPASS_OTP=true` — la route `/auth/test/login`
  /// est volontairement désactivée en production côté backend (voir
  /// `routes/authRoutes.js` du backend), donc impossible de se retrouver
  /// avec un bypass actif contre Vercel qui échouerait silencieusement (404).
  static bool get otpBypassActive =>
      !isVercel && (dotenv.env['BYPASS_OTP']?.trim().toLowerCase() == 'true');
}
