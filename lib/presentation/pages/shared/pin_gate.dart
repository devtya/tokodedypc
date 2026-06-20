import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/local_auth/local_auth_bloc.dart';
import '../../blocs/local_auth/local_auth_event.dart';
import '../../blocs/local_auth/local_auth_state.dart';
import 'pin_setup_page.dart';
import 'pin_verify_page.dart';

class PinGate extends StatefulWidget {
  final User user;
  final VoidCallback? onVerified;
  const PinGate({super.key, required this.user, this.onVerified});

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    debugPrint('${DateTime.now()} [PinGate] initState: userId=${widget.user.id}, LocalAuthBloc state=${context.read<LocalAuthBloc>().state.runtimeType}');
    context.read<LocalAuthBloc>().add(CheckPinEvent(widget.user.id!));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocalAuthBloc, LocalAuthState>(
      listenWhen: (prev, curr) => curr is PinReady || curr is PinNotSet || curr is PinError || curr is PinVerified,
      listener: (context, state) {
        debugPrint('${DateTime.now()} [PinGate] listener: state=${state.runtimeType}, _hasChecked=$_hasChecked');
        if (!_hasChecked && (state is PinReady || state is PinNotSet || state is PinError)) {
          debugPrint('${DateTime.now()} [PinGate] listener: setting _hasChecked=true');
          setState(() => _hasChecked = true);
        }
      },
      builder: (context, state) {
        debugPrint('${DateTime.now()} [PinGate] builder: state=${state.runtimeType}, _hasChecked=$_hasChecked');
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
          onVerified: () => widget.onVerified?.call(),
          onSkip: () {
            context.read<AuthBloc>().add(LogoutEvent());
          },
        );
      },
    );
  }
}
