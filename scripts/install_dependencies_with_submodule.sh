#!/usr/bin/env bash
set -Eeuo pipefail

__script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

readonly __script_dir

pushd "$__script_dir/../"

pushd packages/paperless_api
flutter packages pub get
dart run build_runner build --delete-conflicting-outputs
popd

pushd packages/mock_server
flutter packages pub get
popd

flutter packages pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
popd

