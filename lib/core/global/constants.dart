import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

const supportedFileExtensions = [
  '.pdf',
  '.png',
  '.tiff',
  '.gif',
  '.jpg',
  '.jpeg'
];

// Globally accessible variables which are definitely initialized after main().
late final PackageInfo packageInfo;
late final AndroidDeviceInfo? androidInfo;
late final IosDeviceInfo? iosInfo;

const latestSupportedApiVersion = 3;
