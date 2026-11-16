import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Globally accessible variables which are definitely initialized after main().
late final PackageInfo packageInfo;
late final AndroidDeviceInfo? androidInfo;
late final IosDeviceInfo? iosInfo;

const minSupportedApiVersion = 10;
const latestSupportedApiVersion = 10;
