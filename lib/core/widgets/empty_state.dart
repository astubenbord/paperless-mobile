import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? bottomChild;

  const EmptyState({
    Key? key,
    required this.title,
    required this.subtitle,
    this.bottomChild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: size.height / 3,
          width: size.width / 3,
          child: SvgPicture.asset("assets/images/empty-state.svg"),
        ),
        Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        if (bottomChild != null) ...[bottomChild!] else ...[]
      ],
    );
  }
}
