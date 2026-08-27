import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/features/arena/games/penalty/pages/penalty_result_page.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_game.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_game_page.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_cubit.dart';
import 'package:goias_app/features/arena/games/career_path/pages/career_path_page.dart';
import 'package:goias_app/features/arena/games/guess_player/cubit/guess_player_cubit.dart';
import 'package:goias_app/features/arena/games/guess_player/pages/guess_player_page.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_cubit.dart';
import 'package:goias_app/features/arena/games/lineup/pages/lineup_page.dart';
import 'package:goias_app/features/arena/games/quiz/cubit/quiz_cubit.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_progress_repository.dart';
import 'package:goias_app/features/arena/games/quiz/pages/quiz_level_page.dart';
import 'package:goias_app/features/arena/games/quiz/pages/quiz_page.dart';
import 'package:goias_app/features/arena/games/quiz/pages/quiz_result_page.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/ranking/presentation/cubit/ranking_cubit.dart';
import 'package:goias_app/features/arena/ranking/presentation/pages/ranking_page.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/features/auth/presentation/pages/check_your_email_page.dart';
import 'package:goias_app/features/auth/presentation/pages/login_page.dart';
import 'package:goias_app/features/auth/presentation/pages/register_page.dart';
import 'package:goias_app/features/auth/presentation/pages/reset_password_page.dart';
import 'package:goias_app/features/club/domain/entities/club_song.dart';
import 'package:goias_app/features/club/presentation/pages/club_history_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_song_details_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_songs_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_titles_page.dart';
import 'package:goias_app/features/home/presentation/pages/home_shell_page.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/crowd_lineup/presentation/pages/crowd_lineup_page.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_cubit.dart';
import 'package:goias_app/features/match/presentation/pages/match_details_page.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/presentation/pages/find_zip_code_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_faq_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_plan_details_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_plans_catalog_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_regulation_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_registration_page.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/presentation/pages/news_article_page.dart';
import 'package:goias_app/features/news/presentation/pages/news_list_page.dart';
import 'package:goias_app/features/partners/presentation/pages/partners_page.dart';
import 'package:goias_app/features/membership/presentation/pages/my_membership_page.dart';
import 'package:goias_app/features/profile/presentation/cubit/address_cubit.dart';
import 'package:goias_app/features/profile/presentation/pages/address_page.dart';
import 'package:goias_app/features/profile/data/legal_documents_data.dart';
import 'package:goias_app/features/profile/presentation/pages/legal_document_page.dart';
import 'package:goias_app/features/profile/presentation/pages/personal_data_page.dart';
import 'package:goias_app/features/profile/presentation/pages/profile_page.dart';
import 'package:goias_app/features/profile/presentation/pages/delete_account_page.dart';
import 'package:goias_app/features/profile/presentation/pages/security_page.dart';
import 'package:goias_app/features/profile/presentation/pages/language_settings_page.dart';
import 'package:goias_app/features/profile/presentation/pages/theme_settings_page.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_cubit.dart';
import 'package:goias_app/features/squad/presentation/pages/squad_list_page.dart';
import 'package:goias_app/features/squad/presentation/pages/squad_member_detail_page.dart';
import 'package:goias_app/features/ticket/domain/entities/match_sales_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/presentation/cubit/purchase_cubit.dart';
import 'package:goias_app/features/ticket/presentation/pages/check_in_confirmation_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/match_info_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/my_orders_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/my_tickets_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/purchase_match_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/purchase_summary_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/ticket_view_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/tickets_page.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/router/splash_gate.dart';
import 'package:goias_app/features/home/presentation/widgets/desktop_shell_frame.dart';
import 'package:goias_app/features/splash/presentation/pages/splash_video_page.dart';
import 'package:goias_app/shared/widgets/coming_soon_page.dart';

const _authArea = {'/login', '/register', '/check-email'};

/// Acessíveis logado OU deslogado — os links de Termos/Privacidade da tela
/// de cadastro precisam abrir sem o usuário estar autenticado.
const _publicRoutes = {'/profile/terms', '/profile/privacy'};

GoRouter createAppRouter(AuthCubit authCubit, SplashGate splashGate) {
  return GoRouter(
    initialLocation: '/',
    observers: [appRouteObserver],
    refreshListenable: Listenable.merge([
      _AuthRefresh(authCubit.stream),
      splashGate,
    ]),
    redirect: (context, state) {
      final authState = authCubit.state;
      final location = state.matchedLocation;

      if (authState is AuthPasswordRecovery) {
        return location == '/reset-password' ? null : '/reset-password';
      }

      if (!splashGate.done) {
        return location == '/splash' ? null : '/splash';
      }

      if (_publicRoutes.contains(location)) return null;

      final loggedIn = authState is AuthAuthenticated;
      final onAuthArea = _authArea.contains(location);

      if (location == '/splash') return loggedIn ? '/' : '/login';
      if (!loggedIn && !onAuthArea) return '/login';
      if (loggedIn && (onAuthArea || location == '/reset-password')) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashVideoPage(),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(
                begin: 1,
                end: 0,
              ).animate(secondaryAnimation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeShellPage()),
      // Fora do shell de propósito: acessíveis sem estar logado (Termos e
      // Privacidade linkados no cadastro) ou imersivo por natureza (o
      // gameplay do Pênalti é um `GameWidget` em tela cheia).
      GoRoute(
        path: '/profile/terms',
        builder: (context, state) =>
            const LegalDocumentPage(document: LegalDocumentsData.termsOfUse),
      ),
      GoRoute(
        path: '/profile/privacy',
        builder: (context, state) =>
            const LegalDocumentPage(document: LegalDocumentsData.privacyPolicy),
      ),
      GoRoute(
        path: '/arena/penalty',
        builder: (context, state) => const PenaltyGamePage(),
      ),
      // Todas as demais rotas internas — no desktop, permanecem dentro do
      // mesmo rail lateral da Home (`DesktopShellFrame`) em vez de abrir
      // como uma página solta sem navegação; no mobile é um no-op, cada
      // rota continua abrindo em tela cheia como sempre abriu.
      ShellRoute(
        builder: (context, state, child) => DesktopShellFrame(
          tabIndex: tabIndexForLocation(state.matchedLocation),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/match/:fixtureId',
            builder: (context, state) => MatchDetailsPage(
              fixtureId: state.pathParameters['fixtureId']!,
              cubit: state.extra as MatchDetailsCubit?,
            ),
          ),
          GoRoute(
            path: '/crowd-lineup',
            builder: (context, state) {
              final args =
                  state.extra! as ({Match match, CrowdLineupCubit cubit});
              return CrowdLineupPage(match: args.match, cubit: args.cubit);
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/squad',
            builder: (context, state) =>
                SquadListPage(cubit: state.extra as SquadCubit?),
          ),
          GoRoute(
            path: '/squad/:memberId',
            builder: (context, state) =>
                SquadMemberDetailPage(member: state.extra! as SquadMember),
          ),
          GoRoute(
            path: '/tickets',
            builder: (context, state) => const TicketsPage(),
          ),
          GoRoute(
            path: '/tickets/my',
            builder: (context, state) => const MyTicketsPage(),
          ),
          GoRoute(
            path: '/tickets/orders',
            builder: (context, state) => const MyOrdersPage(),
          ),
          GoRoute(
            path: '/tickets/checkin',
            builder: (context, state) =>
                CheckInConfirmationPage(args: state.extra! as CheckInArgs),
          ),
          GoRoute(
            path: '/tickets/view',
            builder: (context, state) =>
                TicketViewPage(ticket: state.extra! as Ticket),
          ),
          GoRoute(
            path: '/tickets/purchase',
            builder: (context, state) {
              final args =
                  state.extra! as ({PurchaseCubit cubit, Profile profile});
              return PurchaseMatchPage(
                cubit: args.cubit,
                profile: args.profile,
              );
            },
          ),
          GoRoute(
            path: '/tickets/purchase/summary',
            builder: (context, state) =>
                PurchaseSummaryPage(args: state.extra! as PurchaseSummaryArgs),
          ),
          GoRoute(
            path: '/tickets/purchase/info',
            builder: (context, state) =>
                MatchInfoPage(info: state.extra! as MatchSalesInfo),
          ),
          GoRoute(
            path: '/profile/personal',
            builder: (context, state) => const PersonalDataPage(),
          ),
          GoRoute(
            path: '/profile/address',
            builder: (context, state) =>
                AddressPage(cubit: state.extra as AddressCubit?),
          ),
          GoRoute(
            path: '/profile/security',
            builder: (context, state) => const SecurityPage(),
          ),
          GoRoute(
            path: '/profile/delete-account',
            builder: (context, state) => const DeleteAccountPage(),
          ),
          GoRoute(
            path: '/profile/theme',
            builder: (context, state) => const ThemeSettingsPage(),
          ),
          GoRoute(
            path: '/profile/language',
            builder: (context, state) => const LanguageSettingsPage(),
          ),
          GoRoute(
            path: '/coming-soon',
            builder: (context, state) {
              final args = state.extra as ({String title, String? message})?;
              return ComingSoonPage(
                title:
                    args?.title ?? context.l10n.commonComingSoon.toUpperCase(),
                message: args?.message,
              );
            },
          ),
          GoRoute(
            path: '/arena/penalty/result',
            builder: (context, state) =>
                PenaltyResultPage(data: state.extra! as PenaltyEndData),
          ),
          GoRoute(
            path: '/arena/ranking',
            builder: (context, state) =>
                RankingPage(cubit: state.extra as RankingCubit?),
          ),
          GoRoute(
            path: '/arena/quiz',
            builder: (context, state) => QuizLevelPage(
              initialSummaries:
                  state.extra as Map<QuizDifficulty, QuizLevelSummary>?,
            ),
          ),
          GoRoute(
            path: '/arena/quiz/play',
            builder: (context, state) {
              final args =
                  state.extra!
                      as ({
                        QuizDifficulty difficulty,
                        bool isReview,
                        QuizCubit? cubit,
                      });
              return QuizPlayPage(
                difficulty: args.difficulty,
                isReview: args.isReview,
                cubit: args.cubit,
              );
            },
          ),
          GoRoute(
            path: '/arena/quiz/result',
            builder: (context, state) =>
                QuizResultPage(data: state.extra! as QuizEndData),
          ),
          GoRoute(
            path: '/arena/lineup',
            builder: (context, state) =>
                LineupPage(cubit: state.extra as LineupCubit?),
          ),
          GoRoute(
            path: '/arena/career-path',
            builder: (context, state) =>
                CareerPathPage(cubit: state.extra as CareerPathCubit?),
          ),
          GoRoute(
            path: '/arena/guess-player',
            builder: (context, state) =>
                GuessPlayerPage(cubit: state.extra as GuessPlayerCubit?),
          ),
          GoRoute(
            path: '/partners',
            builder: (context, state) => const PartnersPage(),
          ),
          GoRoute(
            path: '/clube',
            builder: (context, state) => const ClubPage(),
          ),
          GoRoute(
            path: '/clube/historia',
            builder: (context, state) => const ClubHistoryPage(),
          ),
          GoRoute(
            path: '/clube/titulos',
            builder: (context, state) => const ClubTitlesPage(),
          ),
          GoRoute(
            path: '/clube/hino',
            builder: (context, state) => const ClubSongsPage(),
          ),
          GoRoute(
            path: '/clube/hino/letra',
            builder: (context, state) =>
                ClubSongDetailsPage(song: state.extra! as ClubSong),
          ),
          GoRoute(
            path: '/news',
            builder: (context, state) => const NewsListPage(),
          ),
          GoRoute(
            path: '/news/article',
            builder: (context, state) =>
                NewsArticlePage(article: state.extra! as NewsArticle),
          ),
          GoRoute(
            path: '/membership/plans',
            builder: (context, state) => const MembershipPlansCatalogPage(),
          ),
          GoRoute(
            path: '/membership/plans/:planId',
            builder: (context, state) => MembershipPlanDetailsPage(
              planId: state.pathParameters['planId']!,
            ),
          ),
          GoRoute(
            path: '/membership/register',
            builder: (context, state) {
              final args = state.extra! as MembershipRegistrationArgs;
              return MembershipRegistrationPage(
                plan: args.plan,
                price: args.price,
              );
            },
          ),
          GoRoute(
            path: '/membership/regulation',
            builder: (context, state) => const MembershipRegulationPage(),
          ),
          GoRoute(
            path: '/membership/find-zip-code',
            builder: (context, state) => const FindZipCodePage(),
          ),
          GoRoute(
            path: '/membership/faq',
            builder: (context, state) {
              final args =
                  state.extra
                      as ({String? initialCategoryId, String? initialQuery})?;
              return MembershipFaqPage(
                initialCategoryId: args?.initialCategoryId,
                initialQuery: args?.initialQuery,
              );
            },
          ),
          GoRoute(
            path: '/membership/my',
            builder: (context, state) =>
                MyMembershipPage(membership: state.extra! as Membership),
          ),
          GoRoute(
            path: '/membership/coming-soon',
            builder: (context, state) {
              final args = state.extra as ({String title, String message})?;
              return ComingSoonPage(
                title:
                    args?.title ?? context.l10n.commonComingSoon.toUpperCase(),
                message: args?.message,
              );
            },
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/check-email',
        builder: (context, state) =>
            CheckYourEmailPage(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
    ],
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
