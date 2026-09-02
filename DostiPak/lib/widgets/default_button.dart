import 'package:flutter/material.dart';

/// The app-wide primary button.
/// Rose background + white label (owner rule: NEVER black buttons).
class DefaultButton extends StatelessWidget {
  // Variables
  final Widget child;
  final VoidCallback onPressed;
  final double? width;
  final double? height;

  DefaultButton(
      {required this.child, required this.onPressed, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 45,
      child: ElevatedButton(
        child: child,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              Theme.of(context).primaryColor.withOpacity(0.45),
          disabledForegroundColor: Colors.white,
          textStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
