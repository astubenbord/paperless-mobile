import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as im;

typedef ImageOperationCallback = im.Image Function(im.Image);

class DecodeParam {
  final File file;
  final SendPort sendPort;
  final im.Image Function(im.Image) imageOperation;
  DecodeParam(this.file, this.sendPort, this.imageOperation);
}

void decodeIsolate(DecodeParam param) {
  // Read an image from file (webp in this case).
  // decodeImage will identify the format of the image and use the appropriate
  // decoder.
  var image = im.decodeImage(param.file.readAsBytesSync())!;
  // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
  var processed = param.imageOperation(image);
  param.sendPort.send(processed);
}

// Decode and process an image file in a separate thread (isolate) to avoid
// stalling the main UI thread.
Future<File> processImage(
  File file,
  ImageOperationCallback imageOperation,
) async {
  var receivePort = ReceivePort();

  await Isolate.spawn(
      decodeIsolate,
      DecodeParam(
        file,
        receivePort.sendPort,
        imageOperation,
      ));

  var image = await receivePort.first as im.Image;

  return file.writeAsBytes(im.encodePng(image));
}
