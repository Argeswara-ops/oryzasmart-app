import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isPulse = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool isPulse;

  @override
  Widget build(BuildContext context) {
    final shouldPulse =
        isPulse ||
        label.toUpperCase() == 'LIVE' ||
        label.toUpperCase() == 'ONLINE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2.5),
      constraints: const BoxConstraints(maxWidth: 96, minHeight: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shouldPulse) ...[
            _PulseDot(color: color),
            const SizedBox(width: 3),
          ] else if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _opacity = Tween<double>(begin: 0.35, end: 1).animate(curve);
    _scale = Tween<double>(begin: 0.82, end: 1.18).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
