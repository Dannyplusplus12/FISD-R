import 'package:flutter/material.dart';

import '../theme.dart';

/// Bọc quanh 1 icon/tab: vẽ chấm đỏ khi [coThongBao]. Nếu người dùng chưa
/// từng xem mục này ([daXem] == false), chấm đỏ nhấp nháy scale liên tục mỗi
/// giây để liên tục nhắc; sau khi xem rồi, chấm đỏ đứng yên (vẫn hiện nếu
/// còn việc chưa xử lý).
class NutThongBao extends StatefulWidget {
  final bool coThongBao;
  final bool daXem;
  final Widget child;

  const NutThongBao({
    super.key,
    required this.coThongBao,
    required this.daXem,
    required this.child,
  });

  @override
  State<NutThongBao> createState() => _NutThongBaoState();
}

class _NutThongBaoState extends State<NutThongBao> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  bool get _canRung => widget.coThongBao && !widget.daXem;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_ctrl);
    if (_canRung) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant NutThongBao old) {
    super.didUpdateWidget(old);
    if (_canRung && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!_canRung && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      widget.child,
      if (widget.coThongBao)
        Positioned(
          right: -2,
          top: -2,
          child: AnimatedBuilder(
            animation: _scale,
            builder: (_, child) => Transform.scale(
              scale: _canRung ? _scale.value : 1.0,
              child: child,
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
            ),
          ),
        ),
    ]);
  }
}
