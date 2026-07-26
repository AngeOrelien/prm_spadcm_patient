import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/alerte/presentation/pages/sos_page.dart';
import '../features/auth/presentation/pages/inscription_page.dart';
import '../features/auth/presentation/pages/login_email_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/documents/presentation/pages/documents_page.dart';
import '../features/dossier/presentation/pages/dossier_page.dart';
import '../features/messagerie/presentation/pages/messagerie_page.dart';
import '../features/profil/presentation/pages/profil_page.dart';
import '../features/soins/presentation/pages/soin_detail_page.dart';
import '../features/soins/presentation/pages/soins_page.dart';
import '../features/soins/presentation/pages/souscription_infos_page.dart';
import '../features/soins/presentation/providers/soins_providers.dart';
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
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Chemins accessibles sans être connecté (README frontend §2). Toute autre
/// route redirige vers `/vitrine` si l'utilisateur n'est pas connecté —
/// c'est ce nouvel accueil public qui remplace `/login` comme point
/// d'atterrissage par défaut.
bool _estRoutePublique(String matchedLocation) {
  const prefixesPublics = ['/vitrine', '/soins-public', '/login', '/inscription'];
  return prefixesPublics.any(
    (prefixe) => matchedLocation == prefixe || matchedLocation.startsWith('$prefixe/'),
  );
}

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

      final matchedLocation = state.matchedLocation;
      final surSplash = matchedLocation == '/';
      // `/login` et `/inscription` sont les deux écrans "point d'entrée" de
      // connexion : une fois connecté depuis l'un ou l'autre, même logique
      // de redirection (accueil, ou souscription en attente ci-dessous).
      final surEcranConnexion = matchedLocation == '/login' || matchedLocation == '/inscription';

      if (estEnChargement) return surSplash ? null : '/';

      if (!estConnecte) {
        return _estRoutePublique(matchedLocation) ? null : '/vitrine';
      }

      if (estConnecte && (surEcranConnexion || surSplash)) {
        // Un visiteur non connecté qui voulait souscrire à un soin est
        // envoyé ici juste après confirmation de connexion/inscription,
        // plutôt que vers l'accueil générique (README frontend §5/§7.2).
        final soinIdEnAttente = ref.read(pendingSoinIdProvider);
        if (soinIdEnAttente != null) {
          ref.read(pendingSoinIdProvider.notifier).state = null;
          return '/souscrire/$soinIdEnAttente';
        }
        return '/accueil';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginEmailPage()),
      GoRoute(path: '/inscription', builder: (context, state) => const InscriptionPage()),

      // --- Vitrine publique (README frontend §3) ---
      // Accueil des visiteurs non connectés : présentation SPAD, images,
      // vidéos, catalogue de services, contact. Aucune bottom navigation ici
      // (page défilante simple), d'où le rattachement au navigateur racine.
      GoRoute(
        path: '/vitrine',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VitrinePage(),
      ),
      GoRoute(
        path: '/soins-public/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SoinDetailPage(soinId: state.pathParameters['id']!),
      ),

      // --- Écrans plein écran hors bottom navigation ---
      // Poussés par-dessus le shell (via _rootNavigatorKey) plutôt que
      // nichés dans un onglet : SOS doit rester atteignable depuis
      // n'importe quel onglet, Documents est une consultation ponctuelle.
      GoRoute(
        path: '/sos',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SosPage(),
      ),
      GoRoute(
        path: '/documents',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DocumentsPage(),
      ),

      // Formulaire patientInfo + paiement (README frontend §7). Réservé aux
      // utilisateurs connectés : un accès direct sans connexion est
      // renvoyé vers `/vitrine` par le `redirect` ci-dessus.
      GoRoute(
        path: '/souscrire/:soinId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SouscriptionInfosPage(soinId: state.pathParameters['soinId']!),
      ),

      // --- Bottom navigation persistante du patient (5 onglets, README 7.1) ---
      // Accueil / Soins / Dossier / Messages / Profil. Chaque branche garde
      // sa propre pile de navigation (utile pour les écrans de détail
      // poussés depuis une liste, ex: le chat depuis Messages, ou le détail
      // d'un soin depuis l'onglet Soins).
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
              GoRoute(
                path: '/soins',
                builder: (context, state) => const SoinsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => SoinDetailPage(soinId: state.pathParameters['id']!),
                  ),
                ],
              ),
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
