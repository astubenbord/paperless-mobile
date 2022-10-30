import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';

class WelcomeIntroSlide extends StatelessWidget {
  const WelcomeIntroSlide({super.key});

  @override
  Widget build(BuildContext context) {
    //TODO: INTL
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Welcome to Paperless Mobile!",
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        Text(
          "Manage and add your documents on the go!",
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
