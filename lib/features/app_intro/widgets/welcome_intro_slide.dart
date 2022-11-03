import 'package:flutter/material.dart';

class WelcomeIntroSlide extends StatelessWidget {
  const WelcomeIntroSlide({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Welcome to Paperless Mobile!",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Manage, share and create documents on the go without any compromises!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ),
        Align(child: Image.asset("assets/logos/paperless_logo_green.png")),
      ],
    );
  }
}
