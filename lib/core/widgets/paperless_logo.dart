import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PaperlessLogo extends StatelessWidget {
  final double? height;
  final double? width;
  final String _path;

  const PaperlessLogo.white({super.key, this.height, this.width})
      : _path = "assets/logos/paperless_logo_white.svg";

  const PaperlessLogo.green({super.key, this.height, this.width})
      : _path = "assets/logos/paperless_logo_green.svg";

  const PaperlessLogo.black({super.key, this.height, this.width})
      : _path = "assets/logos/paperless_logo_black.svg";

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: height ?? Theme.of(context).iconTheme.size ?? 32,
        maxWidth: width ?? Theme.of(context).iconTheme.size ?? 32,
      ),
      padding: const EdgeInsets.only(right: 8),
      child: SvgPicture.asset(
        _path,
      ),
    );
  }
}
