import 'package:flutter/material.dart';

enum AssetImages {
  headacheDocuments("images/documents_headache.png"),
  organizeDocuments("images/organize_documents.png"),
  secureDocuments("images/secure_documents.png"),
  success("images/success.png");

  final String relativePath;
  const AssetImages(String relativePath)
      : relativePath = "assets/$relativePath";

  Image get image => Image.asset(
        relativePath,
        key: ObjectKey("assetimage_$relativePath"),
      );

  void load(context) => precacheImage(image.image, context);
}
