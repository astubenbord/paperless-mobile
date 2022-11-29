import 'package:flutter/material.dart';

enum AssetImages {
  headacheDocuments("images/documents_headache.png"),
  organizeDocuments("images/organize_documents.png"),
  secureDocuments("images/secure_documents.png"),
  success("images/success.png"),
  emptyInbox("images/empty_inbox.png");

  final String relativePath;
  const AssetImages(String relativePath)
      : relativePath = "assets/$relativePath";

  AssetImage get image => AssetImage(relativePath);

  void load(context) => precacheImage(image, context);
}

late Image emptyInboxImage;
