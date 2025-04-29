import 'package:flutter/material.dart';

// Reusable CompactIconButton widget
class ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  final double iconSize;
  final double padding;

  const ActionIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
    this.iconSize = 20.0,
    this.padding = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Tooltip(
          message: tooltip,
          child: Icon(
            icon,
            size: iconSize,
            color: color,
          ),
        ),
      ),
    );
  }
}
