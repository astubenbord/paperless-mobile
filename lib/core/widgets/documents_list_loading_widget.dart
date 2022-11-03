import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DocumentsListLoadingWidget extends StatelessWidget {
  static const tags = ["    ", "            ", "      "];
  static const titleLengths = <double>[double.infinity, 150.0, 200.0];
  static const correspondentLengths = <double>[200.0, 300.0, 150.0];
  static const fontSize = 16.0;

  const DocumentsListLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[300]!
                  : Colors.grey[900]!,
              highlightColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[100]!
                  : Colors.grey[600]!,
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final r = Random(index);
                  final tagCount = r.nextInt(tags.length + 1);
                  final correspondentLength = correspondentLengths[
                      r.nextInt(correspondentLengths.length - 1)];
                  final titleLength =
                      titleLengths[r.nextInt(titleLengths.length - 1)];
                  return ListTile(
                    isThreeLine: true,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: Colors.white,
                        height: 50,
                        width: 35,
                      ),
                    ),
                    title: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      width: correspondentLength,
                      height: fontSize,
                      color: Colors.white,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            height: fontSize,
                            width: titleLength,
                            color: Colors.white,
                          ),
                          Wrap(
                            spacing: 2.0,
                            children: List.generate(
                              tagCount,
                              (index) => InputChip(
                                label: Text(tags[r.nextInt(tags.length)]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
