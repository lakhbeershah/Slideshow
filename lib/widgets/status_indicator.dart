import 'package:flutter/material.dart';
import '../constants/colors.dart';

class StatusIndicator extends StatelessWidget {
  final bool isOpen;
  final double size;
  final bool showText;

  const StatusIndicator({
    super.key,
    required this.isOpen,
    this.size = 12,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Dot
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isOpen ? AppColors.openGreen : AppColors.closedRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isOpen ? AppColors.openGreen : AppColors.closedRed)
                    .withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        
        // Optional Text
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            isOpen ? 'OPEN' : 'CLOSED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOpen ? AppColors.openGreen : AppColors.closedRed,
            ),
          ),
        ],
      ],
    );
  }
}

class AnimatedStatusIndicator extends StatefulWidget {
  final bool isOpen;
  final double size;
  final bool showText;
  final Duration animationDuration;

  const AnimatedStatusIndicator({
    super.key,
    required this.isOpen,
    this.size = 12,
    this.showText = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedStatusIndicator> createState() => _AnimatedStatusIndicatorState();
}

class _AnimatedStatusIndicatorState extends State<AnimatedStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: widget.isOpen ? AppColors.closedRed : AppColors.openGreen,
      end: widget.isOpen ? AppColors.openGreen : AppColors.closedRed,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(AnimatedStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Status Dot
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: _colorAnimation.value,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_colorAnimation.value ?? AppColors.primary)
                          .withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            
            // Optional Text
            if (widget.showText) ...[
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: widget.animationDuration,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _colorAnimation.value,
                ),
                child: Text(
                  widget.isOpen ? 'OPEN' : 'CLOSED',
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class StatusBadge extends StatelessWidget {
  final bool isOpen;
  final String? text;
  final Color? backgroundColor;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.isOpen,
    this.text,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = text ?? (isOpen ? 'OPEN' : 'CLOSED');
    final bgColor = backgroundColor ?? 
        (isOpen ? AppColors.openGreen : AppColors.closedRed);
    final txtColor = textColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          
          const SizedBox(width: 6),
          
          // Status Text
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: txtColor,
            ),
          ),
        ],
      ),
    );
  }
}