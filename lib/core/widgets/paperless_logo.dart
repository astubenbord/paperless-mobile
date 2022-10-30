import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PaperlessLogo extends StatelessWidget {
  final double? height;
  final double? width;
  const PaperlessLogo({Key? key, this.height, this.width}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: height ?? Theme.of(context).iconTheme.size ?? 32,
        maxWidth: width ?? Theme.of(context).iconTheme.size ?? 32,
      ),
      padding: const EdgeInsets.only(right: 8),
      child: SvgPicture.asset(
        "assets/logo/paperless_ng_logo_light.svg",
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
