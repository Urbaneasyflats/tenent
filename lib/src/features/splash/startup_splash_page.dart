import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';

enum StartupStep {
  initializing,
  checkingInternet,
  requestingDeviceId,
  fetchingVendorConfig,
  authenticatingUser,
  ready,
  noInternet,
  timeout,
  failed,
}

extension StartupStepX on StartupStep {
  String get message {
    return switch (this) {
      StartupStep.initializing => 'Setting things up...',
      StartupStep.checkingInternet => 'Checking connection...',
      StartupStep.requestingDeviceId => 'Preparing your device...',
      StartupStep.fetchingVendorConfig => 'Preparing your experience...',
      StartupStep.authenticatingUser => 'Almost ready...',
      StartupStep.ready => 'Ready',
      StartupStep.noInternet => ApiClient.offlineMessage,
      StartupStep.timeout => 'This is taking longer than expected.',
      StartupStep.failed => 'Unable to start the app right now.',
    };
  }

  bool get isError {
    return switch (this) {
      StartupStep.noInternet || StartupStep.timeout || StartupStep.failed =>
        true,
      _ => false,
    };
  }
}

class StartupSplashPage extends StatefulWidget {
  const StartupSplashPage({
    super.key,
    required this.step,
    required this.onRetry,
  });

  final StartupStep step;
  final VoidCallback onRetry;

  @override
  State<StartupSplashPage> createState() => _StartupSplashPageState();
}

class _StartupSplashPageState extends State<StartupSplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool error = widget.step.isError;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 108,
                      height: 108,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color:
                                const Color(0xFF0284C7).withValues(alpha: 0.14),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/tenenet_logo.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      error
                          ? widget.step.message
                          : 'Urban EasyFlats',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 26,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      error
                          ? 'Please check your connection and try again.'
                          : widget.step.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (error)
                      _RetryButton(onPressed: widget.onRetry)
                    else
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Color(0xFF0284C7),
                          strokeWidth: 2.8,
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

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF38BDF8), Color(0xFF0284C7)],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: const Center(
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
