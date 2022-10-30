import 'package:flutter/material.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Coming Soon\u2122",
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
