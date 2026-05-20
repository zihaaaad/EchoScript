import 'package:flutter/material.dart';

/// A sleek glassmorphic container card for holding dashboard items.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.06),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A custom button that glows and pulses when active.
class PulseRecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const PulseRecordButton({
    super.key,
    required this.isRecording,
    required this.onTap,
  });

  @override
  State<PulseRecordButton> createState() => _PulseRecordButtonState();
}

class _PulseRecordButtonState extends State<PulseRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isRecording) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PulseRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    const size = 120.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Center(
        child: SizedBox(
          width: size * 1.6,
          height: size * 1.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse waves
              if (widget.isRecording)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: size * _pulseAnimation.value,
                          height: size * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(1.0 - (_controller.value)),
                          ),
                        ),
                        Container(
                          width: size * (1.0 + (_pulseAnimation.value - 1.0) * 0.5),
                          height: size * (1.0 + (_pulseAnimation.value - 1.0) * 0.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.4 * (1.0 - _controller.value)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              // Base button
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: widget.isRecording
                        ? [Colors.redAccent, Colors.red.shade900]
                        : [primaryColor, Theme.of(context).colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isRecording ? Colors.red : primaryColor)
                          .withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 44,
                  color: widget.isRecording ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A styled chip to display task processing status.
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color textColor;
    String label = status;

    switch (status.toUpperCase()) {
      case 'DONE':
        color = Colors.green.withOpacity(0.12);
        textColor = Colors.greenAccent;
        label = 'Completed';
        break;
      case 'PROCESSING':
        color = Colors.blue.withOpacity(0.12);
        textColor = Colors.blueAccent;
        label = 'Processing';
        break;
      case 'PENDING':
        color = Colors.amber.withOpacity(0.12);
        textColor = Colors.amberAccent;
        label = 'Pending';
        break;
      case 'FAILED':
      default:
        color = Colors.red.withOpacity(0.12);
        textColor = Colors.redAccent;
        label = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// A simple shimmering loader.
class ShimmerLoader extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
    );
  }
}
