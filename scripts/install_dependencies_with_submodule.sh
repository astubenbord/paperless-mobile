#!/usr/bin/env bash
set -Eeuo pipefail

__script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

readonly __script_dir

cd "$__script_dir/../"

$FLUTTER_ROOT/flutter pub get
$FLUTTER_ROOT/flutter run build_runner build --delete-conflicting-outputs
$FLUTTER_ROOT/flutter gen-l10n

