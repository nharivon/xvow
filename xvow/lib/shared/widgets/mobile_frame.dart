import 'package:flutter/material.dart';

class MobileFrame extends StatelessWidget {
  const MobileFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: child,
          ),
        ),
      ),
    );
  }
}