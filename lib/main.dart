import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState, User;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'domain/entities/user.dart';
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
import 'presentation/blocs/local_auth/local_auth_event.dart';
import 'presentation/blocs/local_auth/local_auth_state.dart';
import 'presentation/blocs/sync/sync_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/pages/shared/home_page.dart';
import 'presentation/pages/shared/initial_sync_page.dart';
import 'presentation/pages/shared/login_page.dart';
import 'presentation/pages/shared/pin_setup_page.dart';
import 'presentation/pages/shared/pin_verify_page.dart';
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

class _PinGate extends StatefulWidget {
  final User user;
  const _PinGate({required this.user});

  @override
  State<_PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<_PinGate> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    context.read<LocalAuthBloc>().add(CheckPinEvent(widget.user.id!));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocalAuthBloc, LocalAuthState>(
      listenWhen: (prev, curr) => curr is PinReady || curr is PinNotSet || curr is PinError || curr is PinVerified,
      listener: (context, state) {
        if (!_hasChecked && (state is PinReady || state is PinNotSet || state is PinError)) {
          setState(() => _hasChecked = true);
        }
      },
      builder: (context, state) {
        if (!_hasChecked) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is PinNotSet) {
          return PinSetupPage(userId: widget.user.id!);
        }

        return PinVerifyPage(
          userId: widget.user.id!,
          onVerified: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          },
          onSkip: () {
            context.read<AuthBloc>().add(LogoutEvent());
          },
        );
      },
    );
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
                    home: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthInitial ||
                            state is AuthLoading &&
                                state is! Authenticated &&
                                state is! Unauthenticated) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (state is Authenticated) {
                          return _PinGate(user: state.user);
                        }
                        return const LoginPage();
                      },
                    ),
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
