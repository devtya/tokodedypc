import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState, User;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config.dart';
import 'core/di/injection.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_theme.dart';
import 'i18n/strings.g.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/local_auth/local_auth_bloc.dart';
import 'presentation/blocs/sync/sync_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/pages/shared/home_page.dart';
import 'presentation/pages/shared/login_page.dart';
import 'presentation/pages/shared/pin_gate.dart';
import 'presentation/pages/shared/reset_password_page.dart';

Future<void> _checkUpdate() async {
  try {
    final updateService = sl<UpdateService>();
    final info = await updateService.checkForUpdate();
    if (info != null && info.url.isNotEmpty) {
      // Update tersedia — dialog akan muncul di HomePage
    }
  } catch (_) {}
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  late final StreamSubscription<AuthState> _sub;
  AuthState _state = AuthInitial();
  bool _pinVerified = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<AuthBloc>();
    _state = bloc.state;
    debugPrint('${DateTime.now()} [AppShell] initState: initial state=${_state.runtimeType}');
    _sub = bloc.stream.listen((newState) {
      debugPrint('${DateTime.now()} [AppShell] stream received: ${newState.runtimeType}');
      if (!mounted) return;
      if (newState is! Authenticated) {
        _pinVerified = false;
      }
      setState(() => _state = newState);
    });
  }

  void _onPinVerified() {
    debugPrint('${DateTime.now()} [AppShell] _onPinVerified');
    setState(() => _pinVerified = true);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('${DateTime.now()} [AppShell] AuthState: ${_state.runtimeType}, _pinVerified=$_pinVerified');
    if (_state is AuthInitial) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_state is Authenticated) {
      final user = (_state as Authenticated).user;
      if (_pinVerified) {
        debugPrint('${DateTime.now()} [AppShell] Rendering HomePage');
        return const HomePage();
      }
      debugPrint('${DateTime.now()} [AppShell] Rendering PinGate for user.id=${user.id}');
      return PinGate(user: user, onVerified: _onPinVerified);
    }
    debugPrint('${DateTime.now()} [AppShell] Rendering LoginPage');
    return const LoginPage();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  LocaleSettings.useDeviceLocale();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await initDependencies();

  _checkUpdate();
  runApp(const TokodedyApp());
}

class TokodedyApp extends StatefulWidget {
  const TokodedyApp({super.key});

  @override
  State<TokodedyApp> createState() => _TokodedyAppState();
}

class _TokodedyAppState extends State<TokodedyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // Listen untuk Supabase auth events — handle password recovery deep link
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => sl<AuthBloc>()..add(CheckAuthStatus()),
              ),
              BlocProvider(create: (context) => sl<SyncBloc>()),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => sl<LocalAuthBloc>(),
                ),
              ],
              child: TranslationProvider(
                child: Builder(builder: (context) {
                  return MaterialApp(
                    navigatorKey: _navigatorKey,
                    title: 'Tokodedy',
                    debugShowCheckedModeBanner: false,
                    themeMode: themeMode,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    locale: TranslationProvider.of(context).flutterLocale,
                    supportedLocales: AppLocaleUtils.supportedLocales,
                    localizationsDelegates: GlobalMaterialLocalizations.delegates,
                    home: const _AppShell(),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}
