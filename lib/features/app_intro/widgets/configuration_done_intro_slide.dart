import 'package:flutter/material.dart';

class ConfigurationDoneIntroSlide extends StatelessWidget {
  const ConfigurationDoneIntroSlide({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      //TODO: INTL
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          "All set up!",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Icon(
          Icons.emoji_emotions_outlined,
          size: 64,
        ),
        Text(
          "You've successfully configured Paperless Mobile! Press 'GO' to get started managing your documents.",
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
