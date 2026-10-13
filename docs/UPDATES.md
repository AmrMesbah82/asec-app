# Updating the Android app

Code: `lib/core/settings/app_update.dart` (runs once per launch, after the splash).

## 1. Shorebird — push fixes without a Play release

One-time setup (on the Mac):

```bash
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
shorebird login
cd ~/Desktop/ASEC
shorebird init            # creates shorebird.yaml and adds it to pubspec assets
```

Then open `shorebird.yaml` and set:

```yaml
auto_update: false        # app_update.dart downloads the patch and tells the user
```

Every NEW version on Play (version bump in pubspec, e.g. 1.0.1+5):

```bash
shorebird release android         # builds the .aab → upload it to Play Console as usual
```

A fix for a version already on Play (Dart code / assets only):

```bash
shorebird patch android           # users get it in the background, applied on next open
```

Patches CANNOT change: native Android code, new/updated plugins, AndroidManifest,
or the version number. Those need a new `shorebird release android` + Play upload.
Only builds made with `shorebird release` receive patches (not `flutter build`).

## 2. Google Play update dialog

Shown automatically when Play has a newer version (app must be installed from Play —
use an internal-testing track to try it).

Control it from Firestore → `settings/app_update` (all optional):

| field          | type   | effect |
|----------------|--------|--------|
| `min_build`    | number | builds **below** this MUST update (dialog can't be closed) |
| `latest_build` | number | builds below this get the optional "New version" dialog |
| `notes_en`     | string | "What's new" text, English |
| `notes_ar`     | string | "What's new" text, Arabic |

The build number is the part after `+` in `pubspec.yaml` → `version: 1.0.0+4` = **4**.
Set `min_build` only AFTER the new version is live on Play.
