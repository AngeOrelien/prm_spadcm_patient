import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/inscription_page.dart';
import '../features/auth/presentation/pages/login_email_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/documents/presentation/pages/documents_page.dart';
import '../features/dossier/presentation/pages/dossier_onboarding_personnel_page.dart';
import '../features/dossier/presentation/pages/dossier_page.dart';
import '../features/dossier/presentation/providers/dossier_providers.dart';
import '../features/messagerie/presentation/pages/messagerie_page.dart';
import '../features/profil/presentation/pages/profil_page.dart';
import '../features/soins/presentation/pages/onboarding_souscription_prompt_page.dart';
import '../features/soins/presentation/pages/soin_detail_page.dart';
import '../features/soins/presentation/pages/soins_page.dart';
import '../features/soins/presentation/pages/souscription_infos_page.dart';
import '../features/vitrine/presentation/pages/vitrine_page.dart';
import '../screens/splash_screen.dart';
import '../shared/widgets/navigation/patient_shell.dart';

/// Pont entre le AsyncNotifierProvider de Riverpod et `refreshListenable` de
/// go_router, pour que le router recalcule ses redirections à chaque
/// changement d'état d'authentification.
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      notifyListeners();
    });
    // Le check "dossier créé ?" (README onboarding) doit lui aussi
    // déclencher un recalcul du redirect dès qu'il se résout, sinon un
    // patient nouvellement inscrit resterait bloqué sur l'écran affiché au
    // moment de la connexion jusqu'au prochain changement de route.
    ref.listen(monDossierExisteProvider, (previous, next) {
      notifyListeners();
    });
  }
}

/// Routes accessibles sans être connecté (README section 2). Toute route
/// hors de cette liste redirige un visiteur non connecté vers `/vitrine`
/// (nouveau point d'atterrissage par défaut, à la place de `/login`).
///
/// `/inscription/otp` n'apparaît pas ici : comme `otp_verification_page`
/// pour la connexion, cet écran est poussé via `Navigator.push` directement
/// depuis `/inscription`, pas via go_router — il ne devient donc jamais
/// `state.matchedLocation`.
bool _estRoutePublique(String location) {
  if (location == '/vitrine' || location == '/login' || location == '/inscription') {
    return true;
  }
  if (location.startsWith('/soins-public/')) return true;
  return false;
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final estEnChargement = authState.isLoading;
      final estConnecte = authState.value != null;

      final location = state.matchedLocation;
      final surSplash = location == '/';
      final surRoutePublique = _estRoutePublique(location);
      final surOnboarding = location.startsWith('/onboarding');

      if (estEnChargement) return surSplash ? null : '/';
      if (!estConnecte) return surRoutePublique ? null : '/vitrine';

      // Onboarding obligatoire "Créer mon dossier" (README) : tant que
      // `GET /patients/moi` renvoie 404, on bloque l'accès au reste de
      // l'app pour éviter les erreurs "compte non relié à une fiche
      // patient" sur le dashboard/dossier/soins/messagerie. Le check est
      // volontairement permissif tant qu'il n'a pas encore de valeur
      // (chargement/erreur réseau) pour ne pas bloquer l'app hors-ligne.
      final dossierExiste = ref.read(monDossierExisteProvider).value;
      if (dossierExiste == false && !surOnboarding) {
        return '/onboarding/dossier';
      }
      if (dossierExiste == true && surOnboarding) {
        return '/accueil';
      }

      // Connecté : les écrans "pré-connexion" ne doivent plus s'afficher.
      if (surSplash || location == '/login' || location == '/vitrine' || location == '/inscription') {
        return dossierExiste == false ? '/onboarding/dossier' : '/accueil';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginEmailPage()),

      // --- Vitrine publique et parcours d'inscription/souscription non
      // connecté (README section 1 et 2) : en dehors du
      // StatefulShellRoute, pas de bottom navigation pour un visiteur non
      // connecté. ---
      GoRoute(
        path: '/vitrine',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VitrinePage(),
      ),
      GoRoute(
        path: '/soins-public/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SoinDetailPage(
          soinId: state.pathParameters['id']!,
          estContextePublic: true,
        ),
      ),
      GoRoute(
        path: '/inscription',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final soinId = extra is Map ? extra['soinId'] as String? : null;
          return InscriptionPage(soinId: soinId);
        },
      ),

      // --- Onboarding obligatoire après inscription (README) : créer son
      // dossier (personnel + médical) avant tout accès au reste de l'app,
      // puis proposition (facultative) de souscription à un suivi SPAD.
      // Hors StatefulShellRoute : pas de bottom navigation pendant ce
      // parcours, comme `/inscription`.
      GoRoute(
        path: '/onboarding/dossier',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => DossierOnboardingPersonnelPage(
          soinId: state.uri.queryParameters['soinId'],
        ),
      ),
      GoRoute(
        path: '/onboarding/souscription',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingSouscriptionPromptPage(),
      ),

      // --- Écrans plein écran hors bottom navigation ---
      // Poussé par-dessus le shell (via _rootNavigatorKey) plutôt que niché
      // dans un onglet : Documents est une consultation ponctuelle. (Le
      // bouton SOS a été retiré du shell : "Signaler une urgence" vit
      // maintenant dans l'espace Messagerie, voir `messagerie_page.dart`.)
      GoRoute(
        path: '/documents',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DocumentsPage(),
      ),

      // --- Détail d'un soin authentifié + formulaire de souscription ---
      // Poussés au-dessus du shell (README section 6.2/7.1) : ce sont des
      // écrans de consultation/action ponctuels, pas des onglets.
      // `souscrire/:id` déclaré avant `:id` pour être prioritaire sur ce
      // segment statique.
      GoRoute(
        path: '/soins/souscrire/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SouscriptionInfosPage(soinId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/soins/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SoinDetailPage(
          soinId: state.pathParameters['id']!,
          estContextePublic: false,
        ),
      ),

      // --- Bottom navigation persistante du patient (5 onglets, README 7.1) ---
      // Accueil / Soins / Dossier / Messages / Profil. Chaque branche garde
      // sa propre pile de navigation (utile pour les écrans de détail
      // poussés depuis une liste, ex: le chat depuis Messages).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return PatientShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(path: '/accueil', builder: (context, state) => const DashboardPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/soins', builder: (context, state) => const SoinsPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/dossier', builder: (context, state) => const DossierPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/messages', builder: (context, state) => const MessageriePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profil', builder: (context, state) => const ProfilPage()),
            ],
          ),
        ],
      ),
    ],
  );
});
