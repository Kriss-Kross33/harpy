import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:harpy/components/components.dart';
import 'package:harpy/core/core.dart';

/// Paths that an unauthenticated user can access,
const _unprotectedRoutes = [SplashPage.path, LoginPage.path];

// - when navigating to the splash page don't redirect
// - when not initialized, redirect to the splash page and then go to the
//   expected location after initialization
// - when not authenticated, redirect to the login page
// - when the location doesn't exist, redirect to the home page
// - otherwise don't redirect
String? handleRedirect(Reader read, GoRouterState state) {
  if (state.subloc == SplashPage.path) return null;

  // handle redirect when uninitialized
  final coldDeeplink = _handleColdDeeplink(read, state);
  if (coldDeeplink != null) return coldDeeplink;

  // handle redirect when unauthenticated
  final unauthenticated = _handleUnauthenticated(read, state);
  if (unauthenticated != null) return unauthenticated;

  if (!locationHasRouteMatch(
    location: state.location,
    routes: read(routesProvider),
  )) {
    // handle the location if it's a twitter path that can be mapped to a harpy
    // path
    final mappedLocation = _mapTwitterPath(state);
    if (mappedLocation != null) return mappedLocation;

    // if the location doesn't exist navigate to home instead
    return '/';
  }

  return null;
}

/// Returns the [SplashPage.path] with the target location as a redirect if the
/// app is not initialized.
String? _handleColdDeeplink(Reader read, GoRouterState state) {
  final isInitialized =
      read(applicationStateProvider) == ApplicationState.initialized;

  return !isInitialized
      // TODO: add origin here before the redirect to change animation?
      ? '${SplashPage.path}?redirect=${state.location}'
      : null;
}

/// Returns the [LoginPage.path] if the user is not authenticated and tried to
/// navigate to a protected route.
String? _handleUnauthenticated(Reader read, GoRouterState state) {
  final isAuthenticated = read(authenticationStateProvider).isAuthenticated;

  return !isAuthenticated && !_unprotectedRoutes.contains(state.subloc)
      // TODO: maybe add a redirect after successful login?
      ? LoginPage.path
      : null;
}

/// Maps a twitter url path to the harpy equivalent path or returns `null` if
/// there is no matching location.
///
/// Same as harpy (no need to map):
/// - /i/lists/$id: list timeline
/// - /i/lists/$id/members: list members
/// - /compose/tweet: tweet compose
///
/// Mapped:
/// - /home:          home
/// - /i/trends:      home with trends tab
/// - /explore:       home with trends tab
/// - /notifications: home with mentions tab
///
/// - /search?q=test:         search with query
/// - /search?q=harpy&f=user: search user with query
///
/// - /$handle:           user profile
/// - /$handle/followers: followers page
/// - /$handle/following: following page
/// - /$handle/lists:     lists show page
///
/// - /$handle/status/$id:          tweet detail page
/// - /$handle/status/$id/retweets: tweet retweeters
String? _mapTwitterPath(GoRouterState state) {
  final uri = Uri.tryParse(state.location);

  if (uri == null) return null;

  switch (uri.path) {
    case '/home':
      return '/';
    case '/notifications':
      // TODO: go to mentions tab in home page if it exists
      return '/';
    case '/explore':
    case '/i/trends':
      // TODO: go to search tab in home page if it exists
      return '/';
    case '/search':
      // TODO: user search if `f=user`
      return Uri(
        path: '/harpy_search/tweets',
        queryParameters: {
          if (uri.queryParameters['q'] != null)
            'query': uri.queryParameters['q'],
        },
      ).toString();
  }

  final userProfileMatch = userProfilePathRegex.firstMatch(uri.path);
  if (userProfileMatch?.group(1) != null) {
    return '/user/${userProfileMatch!.group(1)}';
  }

  final userFollowersMatch = userFollowersPathRegex.firstMatch(uri.path);
  if (userFollowersMatch?.group(1) != null) {
    return '/user/${userFollowersMatch!.group(1)}/followers';
  }

  final userFollowingMatch = userFollowingPathRegex.firstMatch(uri.path);
  if (userFollowingMatch?.group(1) != null) {
    return '/user/${userFollowingMatch!.group(1)}/following';
  }

  final userListsMatch = userListsPathRegex.firstMatch(uri.path);
  if (userListsMatch?.group(1) != null) {
    return '/user/${userListsMatch!.group(1)}/lists';
  }

  final statusMatch = statusPathRegex.firstMatch(uri.path);
  if (statusMatch?.group(1) != null && statusMatch?.group(2) != null) {
    return '/user/${statusMatch!.group(1)}'
        '/status/${statusMatch.group(2)}';
  }

  return null;
}
