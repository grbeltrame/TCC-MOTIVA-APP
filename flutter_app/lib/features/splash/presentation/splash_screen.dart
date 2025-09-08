import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/features/auth/presentation/login_screen.dart';

/// SplashScreen com animação de expansão lenta da mancha vermelha
/// e flip vertical do logo,  atrasando o inicio.
class SplashScreen extends StatefulWidget {
  static const String routeName = '/';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _blobPercent;
  late final Animation<double> _rotateX;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // duração mais longa
    );
    _blobPercent = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _rotateX = Tween(
      begin: 0.0,
      end: pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (_, animation, __, child) {
              // Fade in + deslizamento suave de baixo pra cima
              final slide = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
          ),
        );
      }
    });

    // Atraso antes de iniciar a animação
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxDiameter =
        sqrt(size.width * size.width + size.height * size.height) * 2;

    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final blobSize = _blobPercent.value * maxDiameter;
          return Stack(
            children: [
              // Mancha vermelha expandindo da base da tela
              Positioned(
                bottom: -(maxDiameter - blobSize) / 2,
                left: (size.width - blobSize) / 2,
                width: blobSize,
                height: blobSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.ellipseGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowPink,
                        offset: const Offset(100, 100),
                        blurRadius: 300,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 300,
                        sigmaY: 300,
                      ), // blur mais forte
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),

              // Logo central com flip vertical e sumindo ao passar de 90°
              Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: _rotateX.value <= pi / 2 ? 1.0 : 0.0,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateX(_rotateX.value),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 180,
                      height: 180,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
