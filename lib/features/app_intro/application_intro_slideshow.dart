import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/app_intro/widgets/biometric_authentication_intro_slide.dart';
import 'package:paperless_mobile/features/app_intro/widgets/configuration_done_intro_slide.dart';
import 'package:paperless_mobile/features/app_intro/widgets/welcome_intro_slide.dart';
import 'package:paperless_mobile/features/home/view/home_page.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:intro_slider/intro_slider.dart';

class ApplicationIntroSlideshow extends StatelessWidget {
  const ApplicationIntroSlideshow({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: IntroSlider(
        renderDoneBtn: TextButton(
          child: Text("GO"), //TODO: INTL
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColorAllTabs: Theme.of(context).canvasColor,
        onDonePress: () => Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) => const HomePage())),
        listCustomTabs: [
          const WelcomeIntroSlide(),
          BlocProvider.value(
            value: getIt<ApplicationSettingsCubit>(),
            child: const BiometricAuthenticationIntroSlide(),
          ),
          const ConfigurationDoneIntroSlide(),
        ].padded(const EdgeInsets.all(16.0)),
      ),
    );
  }
}
