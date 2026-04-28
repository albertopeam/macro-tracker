import 'dart:math';
import 'package:flutter/material.dart';

class WaveformWidget extends StatefulWidget {
  final double soundLevel; // -2.0 to 10.0 (from speech_to_text)
  final bool isListening;
  final Color color;

  const WaveformWidget({
    super.key,
    required this.soundLevel,
    required this.isListening,
    this.color = Colors.green,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const barCount = 20;
    final normalizedLevel =
        ((widget.soundLevel + 2) / 12).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              final base = 0.1 + (normalizedLevel * 0.8);
              final noise = widget.isListening
                  ? (_random.nextDouble() * 0.3 * base)
                  : 0.02;
              final height = (base + noise).clamp(0.05, 1.0) * 50;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 3,
                  height: height,
                  decoration: BoxDecoration(
                    color: widget.isListening
                        ? widget.color.withValues(alpha: (0.7 + noise).clamp(0.0, 1.0))
                        : Colors.grey.shade400.withValues(alpha: 1.0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
