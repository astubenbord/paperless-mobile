#!/usr/bin/env bash
set -Eeuo pipefail

__script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

readonly __script_dir

pushd "$__script_dir/../"

pushd packages/paperless_api
$FLUTTER_ROOT/flutter packages pub get
$FLUTTER_ROOT/dart run build_runner build --delete-conflicting-outputs
popd

pushd packages/mock_server
$FLUTTER_ROOT/flutter packages pub get
popd

$FLUTTER_ROOT/flutter packages pub get
$FLUTTER_ROOT/dart run build_runner build --delete-conflicting-outputs
$FLUTTER_ROOT/flutter gen-l10n
popd
