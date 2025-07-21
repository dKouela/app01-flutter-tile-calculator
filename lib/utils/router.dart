import 'package:go_router/go_router.dart';
import '../screens/registration_screen.dart';
import '../screens/quote_form_screen.dart';
import '../screens/quote_result_screen.dart';
import '../models/quote.dart';
import '../models/user.dart';

final GoRouter router = GoRouter(
  initialLocation: '/registration',
  routes: [
    GoRoute(
      path: '/registration',
      name: 'registration',
      builder: (context, state) => const RegistrationScreen(),
    ),
    GoRoute(
      path: '/quote-form',
      name: 'quote-form',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final userId = extra?['userId'] as String? ?? '';
        final user = extra?['user'] as UserModel?;
        return QuoteFormScreen(userId: userId, user: user);
      },
    ),
    GoRoute(
      path: '/quote-result',
      name: 'quote-result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final quote = extra['quote'] as Quote;
        final user = extra['user'] as UserModel;
        return QuoteResultScreen(quote: quote, user: user);
      },
    ),
  ],
  errorBuilder: (context, state) => const RegistrationScreen(),
);