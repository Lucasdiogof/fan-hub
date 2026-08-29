import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/router/app_page.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
import 'package:goias_app/features/club/domain/entities/club_transparency_topic.dart';
import 'package:goias_app/features/club/presentation/pages/club_diretoria_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_history_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_transparency_document_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_transparency_page.dart';
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
import 'package:goias_app/features/passport/presentation/pages/passport_page.dart';
import 'package:goias_app/features/passport/presentation/pages/passport_ranking_page.dart';
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
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/presentation/pages/cart_page.dart';
import 'package:goias_app/features/store/presentation/pages/checkout_page.dart';
import 'package:goias_app/features/store/presentation/pages/product_detail_page.dart';
import 'package:goias_app/features/store/presentation/pages/store_addresses_page.dart';
import 'package:goias_app/features/store/presentation/pages/store_home_page.dart';
import 'package:goias_app/features/store/presentation/pages/store_listing_page.dart';
import 'package:goias_app/features/store/presentation/pages/store_order_detail_page.dart';
import 'package:goias_app/features/store/presentation/pages/store_orders_page.dart';
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
import 'package:goias_app/core/router/root_navigator_key.dart';
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
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    // `SentryNavigatorObserver` deixa cada troca de tela como breadcrumb no
    // Sentry — sem isso, um erro só mostra a exceção, nunca em QUAL tela o
    // usuário estava quando ela aconteceu.
    observers: [appRouteObserver, SentryNavigatorObserver()],
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
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => appPage(state, const HomeShellPage()),
      ),
      // Fora do shell de propósito: acessíveis sem estar logado (Termos e
      // Privacidade linkados no cadastro) ou imersivo por natureza (o
      // gameplay do Pênalti é um `GameWidget` em tela cheia).
      GoRoute(
        path: '/profile/terms',
        pageBuilder: (context, state) => appPage(
          state,
          const LegalDocumentPage(document: LegalDocumentsData.termsOfUse),
        ),
      ),
      GoRoute(
        path: '/profile/privacy',
        pageBuilder: (context, state) => appPage(
          state,
          const LegalDocumentPage(document: LegalDocumentsData.privacyPolicy),
        ),
      ),
      GoRoute(
        path: '/arena/penalty',
        pageBuilder: (context, state) =>
            appPage(state, const PenaltyGamePage()),
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
            pageBuilder: (context, state) => appPage(
              state,
              MatchDetailsPage(
                fixtureId: state.pathParameters['fixtureId']!,
                cubit: state.extra as MatchDetailsCubit?,
              ),
            ),
          ),
          GoRoute(
            path: '/crowd-lineup',
            pageBuilder: (context, state) {
              final args =
                  state.extra! as ({Match match, CrowdLineupCubit cubit});
              return appPage(
                state,
                CrowdLineupPage(match: args.match, cubit: args.cubit),
              );
            },
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                appPage(state, const ProfilePage()),
          ),
          GoRoute(
            path: '/squad',
            pageBuilder: (context, state) => appPage(
              state,
              SquadListPage(cubit: state.extra as SquadCubit?),
            ),
          ),
          GoRoute(
            path: '/squad/:memberId',
            pageBuilder: (context, state) => appPage(
              state,
              SquadMemberDetailPage(member: state.extra! as SquadMember),
            ),
          ),
          GoRoute(
            path: '/tickets',
            pageBuilder: (context, state) =>
                appPage(state, const TicketsPage()),
          ),
          GoRoute(
            path: '/tickets/my',
            pageBuilder: (context, state) =>
                appPage(state, const MyTicketsPage()),
          ),
          GoRoute(
            path: '/tickets/orders',
            pageBuilder: (context, state) =>
                appPage(state, const MyOrdersPage()),
          ),
          GoRoute(
            path: '/tickets/checkin',
            pageBuilder: (context, state) => appPage(
              state,
              CheckInConfirmationPage(args: state.extra! as CheckInArgs),
            ),
          ),
          GoRoute(
            path: '/tickets/view',
            pageBuilder: (context, state) =>
                appPage(state, TicketViewPage(ticket: state.extra! as Ticket)),
          ),
          GoRoute(
            path: '/tickets/purchase',
            pageBuilder: (context, state) {
              final args =
                  state.extra! as ({PurchaseCubit cubit, Profile profile});
              return appPage(
                state,
                PurchaseMatchPage(cubit: args.cubit, profile: args.profile),
              );
            },
          ),
          GoRoute(
            path: '/tickets/purchase/summary',
            pageBuilder: (context, state) => appPage(
              state,
              PurchaseSummaryPage(args: state.extra! as PurchaseSummaryArgs),
            ),
          ),
          GoRoute(
            path: '/tickets/purchase/info',
            pageBuilder: (context, state) => appPage(
              state,
              MatchInfoPage(info: state.extra! as MatchSalesInfo),
            ),
          ),
          GoRoute(
            path: '/profile/personal',
            pageBuilder: (context, state) =>
                appPage(state, const PersonalDataPage()),
          ),
          GoRoute(
            path: '/profile/address',
            pageBuilder: (context, state) => appPage(
              state,
              AddressPage(cubit: state.extra as AddressCubit?),
            ),
          ),
          GoRoute(
            path: '/profile/security',
            pageBuilder: (context, state) =>
                appPage(state, const SecurityPage()),
          ),
          GoRoute(
            path: '/profile/delete-account',
            pageBuilder: (context, state) =>
                appPage(state, const DeleteAccountPage()),
          ),
          GoRoute(
            path: '/profile/theme',
            pageBuilder: (context, state) =>
                appPage(state, const ThemeSettingsPage()),
          ),
          GoRoute(
            path: '/profile/language',
            pageBuilder: (context, state) =>
                appPage(state, const LanguageSettingsPage()),
          ),
          GoRoute(
            path: '/coming-soon',
            pageBuilder: (context, state) {
              final args = state.extra as ({String title, String? message})?;
              return appPage(
                state,
                ComingSoonPage(
                  title:
                      args?.title ??
                      context.l10n.commonComingSoon.toUpperCase(),
                  message: args?.message,
                ),
              );
            },
          ),
          GoRoute(
            path: '/arena/penalty/result',
            pageBuilder: (context, state) => appPage(
              state,
              PenaltyResultPage(data: state.extra! as PenaltyEndData),
            ),
          ),
          GoRoute(
            path: '/arena/ranking',
            pageBuilder: (context, state) => appPage(
              state,
              RankingPage(cubit: state.extra as RankingCubit?),
            ),
          ),
          GoRoute(
            path: '/arena/quiz',
            pageBuilder: (context, state) => appPage(
              state,
              QuizLevelPage(
                initialSummaries:
                    state.extra as Map<QuizDifficulty, QuizLevelSummary>?,
              ),
            ),
          ),
          GoRoute(
            path: '/arena/quiz/play',
            pageBuilder: (context, state) {
              final args =
                  state.extra!
                      as ({
                        QuizDifficulty difficulty,
                        bool isReview,
                        QuizCubit? cubit,
                      });
              return appPage(
                state,
                QuizPlayPage(
                  difficulty: args.difficulty,
                  isReview: args.isReview,
                  cubit: args.cubit,
                ),
              );
            },
          ),
          GoRoute(
            path: '/arena/quiz/result',
            pageBuilder: (context, state) => appPage(
              state,
              QuizResultPage(data: state.extra! as QuizEndData),
            ),
          ),
          GoRoute(
            path: '/arena/lineup',
            pageBuilder: (context, state) =>
                appPage(state, LineupPage(cubit: state.extra as LineupCubit?)),
          ),
          GoRoute(
            path: '/arena/career-path',
            pageBuilder: (context, state) => appPage(
              state,
              CareerPathPage(cubit: state.extra as CareerPathCubit?),
            ),
          ),
          GoRoute(
            path: '/arena/guess-player',
            pageBuilder: (context, state) => appPage(
              state,
              GuessPlayerPage(cubit: state.extra as GuessPlayerCubit?),
            ),
          ),
          GoRoute(
            path: '/arena/passport',
            pageBuilder: (context, state) =>
                appPage(state, const PassportPage()),
          ),
          GoRoute(
            path: '/arena/passport/ranking',
            pageBuilder: (context, state) =>
                appPage(state, const PassportRankingPage()),
          ),
          GoRoute(
            path: '/partners',
            pageBuilder: (context, state) =>
                appPage(state, const PartnersPage()),
          ),
          GoRoute(
            path: '/clube',
            pageBuilder: (context, state) => appPage(state, const ClubPage()),
          ),
          GoRoute(
            path: '/clube/historia',
            pageBuilder: (context, state) =>
                appPage(state, const ClubHistoryPage()),
          ),
          GoRoute(
            path: '/clube/titulos',
            pageBuilder: (context, state) =>
                appPage(state, const ClubTitlesPage()),
          ),
          GoRoute(
            path: '/clube/diretoria',
            pageBuilder: (context, state) =>
                appPage(state, const ClubDiretoriaPage()),
          ),
          GoRoute(
            path: '/clube/transparencia',
            pageBuilder: (context, state) =>
                appPage(state, const ClubTransparencyPage()),
          ),
          GoRoute(
            path: '/clube/transparencia/documento',
            pageBuilder: (context, state) => appPage(
              state,
              ClubTransparencyDocumentPage(
                document: state.extra! as ClubTransparencyDocument,
              ),
            ),
          ),
          GoRoute(
            path: '/clube/hino',
            pageBuilder: (context, state) =>
                appPage(state, const ClubSongsPage()),
          ),
          GoRoute(
            path: '/clube/hino/letra',
            pageBuilder: (context, state) => appPage(
              state,
              ClubSongDetailsPage(song: state.extra! as ClubSong),
            ),
          ),
          GoRoute(
            path: '/news',
            pageBuilder: (context, state) =>
                appPage(state, const NewsListPage()),
          ),
          GoRoute(
            path: '/news/article',
            pageBuilder: (context, state) => appPage(
              state,
              NewsArticlePage(article: state.extra! as NewsArticle),
            ),
          ),
          GoRoute(
            path: '/membership/plans',
            pageBuilder: (context, state) =>
                appPage(state, const MembershipPlansCatalogPage()),
          ),
          GoRoute(
            path: '/membership/plans/:planId',
            pageBuilder: (context, state) => appPage(
              state,
              MembershipPlanDetailsPage(
                planId: state.pathParameters['planId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/membership/register',
            pageBuilder: (context, state) {
              final args = state.extra! as MembershipRegistrationArgs;
              return appPage(
                state,
                MembershipRegistrationPage(plan: args.plan, price: args.price),
              );
            },
          ),
          GoRoute(
            path: '/membership/regulation',
            pageBuilder: (context, state) =>
                appPage(state, const MembershipRegulationPage()),
          ),
          GoRoute(
            path: '/membership/find-zip-code',
            pageBuilder: (context, state) =>
                appPage(state, const FindZipCodePage()),
          ),
          GoRoute(
            path: '/membership/faq',
            pageBuilder: (context, state) {
              final args =
                  state.extra
                      as ({String? initialCategoryId, String? initialQuery})?;
              return appPage(
                state,
                MembershipFaqPage(
                  initialCategoryId: args?.initialCategoryId,
                  initialQuery: args?.initialQuery,
                ),
              );
            },
          ),
          GoRoute(
            path: '/membership/my',
            pageBuilder: (context, state) => appPage(
              state,
              MyMembershipPage(membership: state.extra! as Membership),
            ),
          ),
          GoRoute(
            path: '/store',
            pageBuilder: (context, state) =>
                appPage(state, const StoreHomePage()),
          ),
          GoRoute(
            path: '/store/search',
            pageBuilder: (context, state) =>
                appPage(state, const StoreListingPage()),
          ),
          GoRoute(
            path: '/store/category/:categoryId',
            pageBuilder: (context, state) => appPage(
              state,
              StoreListingPage(categoryId: state.pathParameters['categoryId']),
            ),
          ),
          GoRoute(
            path: '/store/product/:id',
            pageBuilder: (context, state) => appPage(
              state,
              ProductDetailPage(productId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/store/cart',
            pageBuilder: (context, state) => appPage(state, const CartPage()),
          ),
          GoRoute(
            path: '/store/checkout',
            pageBuilder: (context, state) =>
                appPage(state, const CheckoutPage()),
          ),
          GoRoute(
            path: '/store/orders',
            pageBuilder: (context, state) =>
                appPage(state, const StoreOrdersPage()),
          ),
          GoRoute(
            path: '/store/orders/:id',
            pageBuilder: (context, state) => appPage(
              state,
              StoreOrderDetailPage(order: state.extra! as StoreOrder),
            ),
          ),
          GoRoute(
            path: '/store/addresses',
            pageBuilder: (context, state) =>
                appPage(state, const StoreAddressesPage()),
          ),
          GoRoute(
            path: '/membership/coming-soon',
            pageBuilder: (context, state) {
              final args = state.extra as ({String title, String message})?;
              return appPage(
                state,
                ComingSoonPage(
                  title:
                      args?.title ??
                      context.l10n.commonComingSoon.toUpperCase(),
                  message: args?.message,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => appPage(state, const LoginPage()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => appPage(state, const RegisterPage()),
      ),
      GoRoute(
        path: '/check-email',
        pageBuilder: (context, state) => appPage(
          state,
          CheckYourEmailPage(email: state.extra as String? ?? ''),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) =>
            appPage(state, const ResetPasswordPage()),
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
