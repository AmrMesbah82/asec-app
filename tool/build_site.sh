#!/usr/bin/env bash
# Builds the public asecbim website (lib/features/web/web_main.dart) for
# Firebase Hosting, using web_site/ (Arabic, RTL, the site's title, icons and
# boot logo) as the host page instead of the app's web/ folder.
#
#   ./tool/build_site.sh
#   firebase deploy --only hosting:web
#
# web/ is put back exactly as it was afterwards, even if the build fails.
set -euo pipefail
cd "$(dirname "$0")/.."

backup="$(mktemp -d)"
cp -R web/. "$backup/"
restore() { rm -rf web && mkdir web && cp -R "$backup/." web/ && rm -rf "$backup"; }
trap restore EXIT

cp -R web_site/. web/
flutter build web --release -t lib/features/web/web_main.dart "$@"
echo "Built build/web — deploy with: firebase deploy --only hosting:web"
