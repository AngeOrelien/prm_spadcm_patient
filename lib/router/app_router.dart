import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/alerte/presentation/pages/sos_page.dart';
import '../features/auth/presentation/pages/login_email_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/documents/presentation/pages/documents_page.dart';
import '../features/messagerie/presentation/pages/messagerie_page.dart';
import '../features/profil/presentation/pages/profil_page.dart';
import '../features/rendezvous/presentation/pages/rendezvous_page.dart';
import '../features/soins/presentation/pages/journal_soins_page.dart';
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

      final surSplash = state.matchedLocation == '/';
      final surLogin = state.matchedLocation == '/login';

      if (estEnChargement) return surSplash ? null : '/';
      if (!estConnecte) return surLogin ? null : '/login';
      if (estConnecte && (surLogin || surSplash)) return '/accueil';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginEmailPage()),

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

      // --- Bottom navigation persistante du patient ---
      // Chaque branche garde sa propre pile de navigation (utile dès que
      // "Soins" ou "Rendez-vous" auront des écrans de détail poussés
      // depuis leur liste).
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
              GoRoute(path: '/soins', builder: (context, state) => const JournalSoinsPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/rendez-vous', builder: (context, state) => const RendezVousPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/messagerie', builder: (context, state) => const MessageriePage()),
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
