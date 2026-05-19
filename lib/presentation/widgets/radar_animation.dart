import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A premium, highly polished radar scanning animation.
/// Features a rotating sweep gradient beam, expanding concentric waves,
/// and a pulsing glowing center.
class RadarAnimation extends StatefulWidget {
  final double size;
  final bool isScanning;
  final Widget? centerWidget;

  const RadarAnimation({
    super.key,
    this.size = 200.0,
    this.isScanning = true,
    this.centerWidget,
  });

  @override
  State<RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.isScanning) {
      _rotationController.repeat();
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RadarAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _rotationController.repeat();
        _pulseController.repeat();
      } else {
        _rotationController.stop();
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding background pulse waves
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(3, (index) {
                  // Offset each pulse wave
                  final value = (_pulseController.value + (index / 3.0)) % 1.0;
                  final scale = value * 0.95 + 0.05;
                  final opacity = (1.0 - value) * 0.35;

                  return Container(
                    width: widget.size * scale,
                    height: widget.size * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.electricBlue.withOpacity(opacity),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricBlue.withOpacity(opacity * 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),

          // Static structural grid circles
          ...List.generate(3, (index) {
            final double circleSize = widget.size * ((index + 1) / 3);
            return Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.02),
                  width: 1.0,
                ),
              ),
            );
          }),

          // Diagonal cross lines of the radar
          Container(
            width: widget.size,
            height: 1.0,
            color: Colors.white.withOpacity(0.03),
          ),
          Container(
            height: widget.size,
            width: 1.0,
            color: Colors.white.withOpacity(0.03),
          ),

          // The rotating sweep beam
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      center: Alignment.center,
                      startAngle: 0.0,
                      endAngle: 2 * math.pi,
                      colors: [
                        AppColors.electricBlue.withOpacity(0.25),
                        AppColors.electricBlue.withOpacity(0.08),
                        Colors.transparent,
                        Colors.transparent,
                        AppColors.electricBlue.withOpacity(0.25),
                      ],
                      stops: const [0.0, 0.15, 0.16, 0.99, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Central glowing node
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final sizePercent = 0.8 + 0.2 * math.sin(_pulseController.value * math.pi);
              return Container(
                width: 32 * sizePercent,
                height: 32 * sizePercent,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.electricBlue,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricBlue.withOpacity(0.6),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: AppColors.neonPurple.withOpacity(0.4),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: widget.centerWidget ??
                    const Icon(
                      Icons.cleaning_services,
                      color: AppColors.obsidian,
                      size: 16,
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
