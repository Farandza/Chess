import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'models/game.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/find_opponent_screen.dart';
import 'screens/invitations_screen.dart';
import 'screens/new_game_screen.dart';
import 'screens/chess_game_screen.dart';
import 'screens/play_bot_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/forgot_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.restoreSession();
  await SettingsService.instance.load();
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
          title: 'Chess',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff315d8d),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xfff6f8fc),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              backgroundColor: Color(0xfff6f8fc),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: Color(0xff18202a),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xffe5eaf2)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xffd7dfeb)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xffd7dfeb)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xff315d8d), width: 2),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                // A finite width keeps inline buttons (such as invitation
                // actions) valid inside Rows while still giving all buttons
                // a comfortable tap height.
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 72,
              indicatorColor: const Color(0xffd8e9ff),
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          initialRoute: '/',
          onGenerateRoute: (settings) {
            if (settings.name == '/game') {
              return MaterialPageRoute(
                  builder: (_) =>
                      ChessGameScreen(gameData: settings.arguments as Game?));
            }
            return null;
          },
          routes: {
            '/': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/verify-email': (_) => const VerifyEmailScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/home': (_) => const HomeScreen(),
            '/find': (_) => const FindOpponentScreen(),
            '/invitations': (_) => const InvitationsScreen(),
            '/new-game': (_) => const NewGameScreen(),
            '/bot': (_) => const PlayBotScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/settings': (_) => const SettingsScreen()
          });
}
