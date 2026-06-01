import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_map_background.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_shared_widgets.dart';

/// Map + bottom sheet kéo được — kéo xuống gần hết chỉ còn tay cầm.
class MechanicMapDraggableSheet extends StatefulWidget {
  const MechanicMapDraggableSheet({
    super.key,
    required this.map,
    required this.sheetContent,
    this.pinnedFooter,
    this.initialSize = 0.30,
    this.minSize = 0.06,
    this.maxSize = 0.92,
  });

  final MechanicOrderMapBackground map;
  final Widget sheetContent;
  final Widget? pinnedFooter;
  final double initialSize;
  final double minSize;
  final double maxSize;

  @override
  State<MechanicMapDraggableSheet> createState() => _MechanicMapDraggableSheetState();
}

class _MechanicMapDraggableSheetState extends State<MechanicMapDraggableSheet> {
  late final DraggableScrollableController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _collapseSheet() {
    if (!_controller.isAttached) return;
    _controller.animateTo(
      widget.minSize,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: widget.map),
        DraggableScrollableSheet(
          controller: _controller,
          initialChildSize: widget.initialSize,
          minChildSize: widget.minSize,
          maxChildSize: widget.maxSize,
          snap: true,
          snapSizes: [widget.minSize, widget.initialSize, widget.maxSize],
          builder: (context, scrollController) {
            return MechanicOrderBottomSheet(
              scrollController: scrollController,
              onDoubleTapCollapse: _collapseSheet,
              pinnedFooter: widget.pinnedFooter,
              child: widget.sheetContent,
            );
          },
        ),
      ],
    );
  }
}
