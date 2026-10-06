import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/bus_tracker_provider.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  final List<String> _loadingMessages = [
    'Iniciando sistema de rastreo Campus Sur...',
    'Cargando mapas y mosaicos offline...',
    'Sincronizando paradas y tiempos de caseta...',
    'Calculando estimación en tiempo real...',
    '¡Listo! Conectando al circuito UAT...',
  ];

  int _messageIndex = 0;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Pulso constante para anillos de radar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );

    // Animación de barra de progreso (2.4 segundos para una experiencia fluida)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.addListener(() {
      final progress = _progressController.value;
      final newIndex = (progress * (_loadingMessages.length - 1))
          .floor()
          .clamp(0, _loadingMessages.length - 1);
      if (newIndex != _messageIndex) {
        setState(() {
          _messageIndex = newIndex;
        });
      }
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToHome();
      }
    });

    // Iniciar carga del provider en paralelo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusTrackerProvider>().initialize();
      _progressController.forward();
    });
  }

  void _goToHome() {
    if (_navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A111C),
      body: Stack(
        children: [
          // Fondo con sutil degradado radial
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF132238),
                    Color(0xFF090E17),
                  ],
                ),
              ),
            ),
          ),

          // Botón saltar en esquina superior derecha
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton.icon(
                  onPressed: _goToHome,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text(
                    'Entrar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),

          // Contenido principal centrado
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── ANIMACIÓN CENTRAL DEL AUTOBÚS Y RADARES ──
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _RadarPulsePainter(
                                pulseValue: _pulseAnimation.value,
                              ),
                              child: Center(
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF0288D1),
                                        Color(0xFF01579B),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0288D1)
                                            .withOpacity(0.4),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: const Color(0xFF4FC3F7),
                                      width: 2.5,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.directions_bus_rounded,
                                      color: Colors.white,
                                      size: 46,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Títulos con identidad UAT
                      const Text(
                        'BUS TRACKER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.uatOrange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.uatOrange.withOpacity(0.5),
                              ),
                            ),
                            child: const Text(
                              'CAMPUS SUR',
                              style: TextStyle(
                                color: AppColors.uatOrangeLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF00E676).withOpacity(0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.offline_pin_rounded,
                                  color: Color(0xFF00E676),
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '100% OFFLINE',
                                  style: TextStyle(
                                    color: Color(0xFF00E676),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ── BARRA DE PROGRESO ANIMADA ──
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          final value = _progressAnimation.value;
                          final percentage = (value * 100).toInt();

                          return Column(
                            children: [
                              // Barra con gradiente
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 8,
                                  width: double.infinity,
                                  color: Colors.white.withOpacity(0.1),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: value.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0288D1),
                                              Color(0xFF26C6DA),
                                              Color(0xFFFFB300),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0288D1)
                                                  .withOpacity(0.8),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Mensaje de estado dinámico y porcentaje
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Text(
                                        _loadingMessages[_messageIndex],
                                        key: ValueKey<int>(_messageIndex),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$percentage%',
                                    style: const TextStyle(
                                      color: Color(0xFF4FC3F7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Pie de página de información
                      Text(
                        'Ruta Oficial Circuito Universitario · Versión 2.2',
                        style: TextStyle(
                          color: AppColors.textMuted.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja ondas de radar concéntricas que emanan del autobús
class _RadarPulsePainter extends CustomPainter {
  final double pulseValue;

  _RadarPulsePainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (pulseValue + (i * 0.33)) % 1.0;
      final radius = 48.0 + (maxRadius - 48.0) * waveProgress;
      final opacity = (1.0 - waveProgress).clamp(0.0, 1.0) * 0.45;

      final paint = Paint()
        ..color = const Color(0xFF0288D1).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + (1.0 - waveProgress) * 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
