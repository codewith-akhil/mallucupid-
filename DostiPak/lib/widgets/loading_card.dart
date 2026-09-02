import 'package:flutter/material.dart';
import 'package:rishtpak/widgets/default_card_border.dart';

class LoadingCard extends StatelessWidget {
  final double? iconSize;

  const LoadingCard({this.iconSize, super.key});

  @override
  Widget build(BuildContext context) {
    // shimmer removed: static grey placeholder instead
    return Card(
      color: Colors.grey[200],
      clipBehavior: Clip.antiAlias,
      shape: defaultCardBorder(),
      child: Center(
        child: Icon(
          Icons.favorite_border,
          size: iconSize ?? 150,
          color: Colors.grey[350],
        ),
      ),
    );
  }
}
