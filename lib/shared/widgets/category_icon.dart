import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String icon;
  final Color color;
  final double size;
  final double iconSize;

  const CategoryIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.35),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        icon,
        style: TextStyle(fontSize: iconSize),
      ),
    );
  }
}
