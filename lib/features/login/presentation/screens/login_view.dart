import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_design_system.dart';
import '../widgets/google_mark.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          color: AppColors.primaryMain,
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    SizedBox(
                      height: constraints.maxHeight * 0.42,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/login_image.png',
                            fit: BoxFit.cover,
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.primaryMain40,
                                  AppColors.primaryMain,
                                ],
                                stops: [0.42, 0.74, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 72),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          Text(
                            'Explora los campus',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: AppTypography.weightBold,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Universidad Nacional Sede Medellin',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: AppTypography.weightMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 56),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: _GoogleContinueButton(
                        fontSize: constraints.maxWidth < 420 ? 18 : 23,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Usa tu cuenta institucional',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: AppTypography.weightRegular,
                      ),
                    ),
                    const Spacer(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleContinueButton extends StatefulWidget {
  const _GoogleContinueButton({required this.fontSize});

  final double fontSize;

  @override
  State<_GoogleContinueButton> createState() => _GoogleContinueButtonState();
}

class _GoogleContinueButtonState extends State<_GoogleContinueButton> {
  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  bool _loading = false;
  bool _pressed = false;

  Future<void> _signIn() async {
    if (_loading) return;

    if (_supabaseUrl.isEmpty) {
      _showMessage(
        'Falta la URL de Supabase. Detén la app y vuelve a ejecutarla con --dart-define-from-file=.env',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final opened = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? Uri.base.origin
            : 'io.supabase.minasgo://login-callback/',
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showMessage('No se pudo abrir el inicio de sesión de Google.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo abrir Google. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);

    return AnimatedScale(
      scale: _pressed && !_loading ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: _pressed ? const Color(0xFFE4E7FF) : AppColors.surface,
        elevation: _pressed ? 10 : 3,
        shadowColor: const Color(0x66000000),
        borderRadius: radius,
        child: InkWell(
          onTap: _loading ? null : _signIn,
          onHighlightChanged: (value) {
            if (_pressed == value) return;
            setState(() => _pressed = value);
          },
          borderRadius: radius,
          splashColor: AppColors.primaryMain.withValues(alpha: 0.28),
          highlightColor: AppColors.primaryMain.withValues(alpha: 0.14),
          child: Ink(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: _pressed ? AppColors.primaryLight : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primaryMain,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const GoogleMark(),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Text(
                              'Continuar con google',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: widget.fontSize,
                                fontWeight: AppTypography.weightMedium,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
