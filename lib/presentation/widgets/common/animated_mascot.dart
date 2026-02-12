import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Cute bouncing animated mascot that floats around.
/// Shows Stitch or Angel image based on role.
class AnimatedMascot extends StatefulWidget {
  final String? imagePath;
  final String? emoji;
  final double size;
  final Color glowColor;

  const AnimatedMascot({
    super.key,
    this.imagePath,
    this.emoji,
    this.size = 60,
    required this.glowColor,
  }) : assert(imagePath != null || emoji != null);

  @override
  State<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends State<AnimatedMascot>
    with TickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _rotateCtrl;
  late final Animation<double> _bounceAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();

    _bounceCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(
      begin: 0,
      end: -12,
    ).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _rotateCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _rotateAnim = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _rotateCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _floatCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceAnim, _floatAnim, _rotateAnim]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_floatAnim.value, _bounceAnim.value),
          child: Transform.rotate(angle: _rotateAnim.value, child: child),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: widget.imagePath != null
              ? widget.imagePath!.endsWith('.svg')
                    ? SvgPicture.asset(
                        widget.imagePath!,
                        height: widget.size * 0.8,
                        fit: BoxFit.contain,
                      )
                    : Image.asset(
                        widget.imagePath!,
                        height: widget.size * 0.8,
                        fit: BoxFit.contain,
                      )
              : Text(
                  widget.emoji!,
                  style: TextStyle(fontSize: widget.size * 0.7),
                ),
        ),
      ),
    );
  }
}

/// Smaller bouncing mascot for compact areas
class MiniMascot extends StatefulWidget {
  final String? imagePath;
  final String? emoji;
  final double size;

  const MiniMascot({super.key, this.imagePath, this.emoji, this.size = 28})
    : assert(imagePath != null || emoji != null);

  @override
  State<MiniMascot> createState() => _MiniMascotState();
}

class _MiniMascotState extends State<MiniMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0,
      end: -4,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _anim.value),
          child: child,
        );
      },
      child: widget.imagePath != null
          ? widget.imagePath!.endsWith('.svg')
                ? SvgPicture.asset(
                    widget.imagePath!,
                    height: widget.size,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    widget.imagePath!,
                    height: widget.size,
                    fit: BoxFit.contain,
                  )
          : Text(widget.emoji!, style: TextStyle(fontSize: widget.size)),
    );
  }
}
