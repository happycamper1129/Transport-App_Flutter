// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:

// Project imports:

class ActionAppBar extends StatefulWidget with PreferredSizeWidget {
  const ActionAppBar({
    required this.title,
    required this.isActive,
    required this.onStartPressed,
    required this.onStopPressed,
    Key? key,
  }) : super(key: key);

  final String title;
  final bool isActive;
  final VoidCallback onStartPressed;
  final VoidCallback onStopPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<ActionAppBar> createState() => _ActionAppBarState();
}

class _ActionAppBarState extends State<ActionAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool isAnimating = false;
  bool isStartActionActive = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      iconTheme: Theme.of(context).iconTheme,
      actions: [
        IconButton(
          splashRadius: 25.0,
          icon: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            size: 35.0,
            progress: _controller,
          ),
          onPressed: () async {
            isStartActionActive
                ? widget.onStartPressed()
                : widget.onStopPressed();
            isStartActionActive = !isStartActionActive;

            toggleAnimation();
          },
        )
      ],
    );
  }

  void toggleAnimation() {
    isAnimating = !isAnimating;
    isAnimating ? _controller.forward() : _controller.reverse();
  }
}
