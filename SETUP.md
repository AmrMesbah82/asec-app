# ASEC — setup

Videos and timed quizzes. One admin (`amrmesbah33@gmail.com`), everybody else is a
member. Same architecture, core widgets and theme as **manger_plus**.

## 1. First run

```bash
flutter pub get          # also runs gen-l10n -> lib/generated/l10n.dart
flutter run              # -d macos | chrome | <device id>
```

`lib/generated/` does not exist until the first `pub get` / build. Until then
every `S.of(context)` looks unresolved in the IDE — that is expected, not a
broken import.

## 2. Firebase

The project is already wired to **asec-a811b** (`lib/firebase_options.dart`,
`firebase.json`). In the Firebase console, switch on:

* **Authentication → Email/Password**
* **Firestore Database** (production mode)
* **Storage**

Then deploy the rules — the app will not work without them:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## 3. The admin account

There is no special setup screen. Open the app, tap **Create account**, and
register with:

```
amrmesbah33@gmail.com
```

The role follows the email in two places that must stay in step:

* `AppConstants.adminEmail` — what the app believes,
* `isAdmin()` in `firestore.rules` and `storage.rules` — the boundary that
  actually enforces it.

Anybody else who registers becomes a member. Nobody can promote themselves:
the rules refuse a `role: "admin"` profile written by any other email.

To change the admin address later, change it in **all three** files and
redeploy the rules.

## 3b. Admins and the control centre

`amrmesbah33@gmail.com` is the **super admin**. In **Settings** it gets two extra
cards:

* **Admins** — *Add admin* creates a login (name, email, password) and picks
  what they may manage: Dashboard, Videos, Quizzes, Results, Members, CVs.
  Each admin only sees the menu items they are allowed, and
  `firestore.rules` / `storage.rules` enforce the same list. Admins can be
  switched off, have their permissions edited, or be removed.
* **Control centre** — switches, saved live in Firestore `settings/app`, that
  turn parts of the app on or off for everybody: the member menu items,
  every video option (lock order, block skipping, autoplay, up next, options
  bar, speed, resume, search, progress bar), animations, new sign-ups, and
  the dashboard charts / table.

Deploy the rules after updating:

    firebase deploy --only firestore:rules,storage

## 3c. The website and its control panel (lib/features/web/)

The asecbim website (a copy of asecbim.com whose content lives in this same
Firebase project) and its control panel are now **part of this app** — the
separate `asec_web/` project is gone (its old copy is in
`Claude outputs/_to_delete/asec_web`).

```
lib/features/web/
  web_control_page.dart   the "Website" tab of the admin drawer
  web_main.dart           second entry point: the public site + /admin on the web
  admin/                  panel: session, menu, fields, pages, panel_nav.dart
  core/                   Doc, L (ar/en), WebColors/WebTheme, router, widgets
  data/                   SiteRepo (site_* collections), WordPress importers
  site/                   the public site's pages and widgets
assets/web/               logo + starter content (site_seed.json)
web_site/                 host page (index.html, icons) for the site build
tool/build_site.sh        builds the site with web_site/ as its host page
```

**In the app.** An admin with the **Website** permission
(`AdminPermission.website`, Settings → Admins) — and the super admin — gets a
**Website** item in the drawer. It opens the whole panel beside the drawer:
Dashboard, Inbox, Site settings, Services, Why us, Projects, Articles,
Partners, Testimonials, Control centre, Admins (super admin), Import content.
Its own menu is a side list on a wide screen and a row of chips on a narrow
one; editors open inside the page. It follows the app's language switch
(Arabic / English) and its light / dark switch — its neutral colours are the
app's own (`WebPalette`, `lib/features/web/core/theme.dart`). Every icon is an
SVG: `AppIcon` draws the file mapped in `AppSvgIcons` (core/custom/
111-app_svg_icon.dart); the website's own icons are in
`assets/icons_assets/web_assets/`. A new icon in the web code needs a line
there too.

**The public site** is still its own web build, served on a subdomain (e.g.
`app.asecbim.com`); the WordPress site on the root domain is untouched:

    flutter run -d chrome -t lib/features/web/web_main.dart   # try it locally
    ./tool/build_site.sh                                      # build
    firebase deploy --only hosting:web                        # publish

`firebase.json` has the `web` hosting target and `.firebaserc` maps it to the
`asecbim-web` site. Rules for the `site_*` collections and `site/` images are
at the bottom of `firestore.rules` / `storage.rules`:

    firebase deploy --only firestore:rules,storage

If Storage images do not show in the browser, apply CORS once:

    gsutil cors set storage.cors.json gs://asec-a811b.firebasestorage.app

"View site" in the app's Website tab opens a **preview of the site inside
the app** (`site_preview_page.dart`) — the real pages with the live content,
so it works before the site is published. Its "Open live link" button opens
`kWebsiteUrl` (`lib/features/web/admin/panel_nav.dart`), which shows
Firebase's "Site Not Found" page until the site has been deployed once:

    firebase hosting:sites:create asecbim-web   # only the first time
    ./tool/build_site.sh
    firebase deploy --only hosting:web

Change `kWebsiteUrl` to your domain once it is live. A switch added to `AppFeature` must also be added to `kAppSwitches`
in `lib/features/web/admin/pages/control_page.dart`.

## 4. Data

```
users/{uid}                 full_name, email, phone, role, active
videos/{id}                 title, description, url, storage_path, published
quizzes/{id}                title, duration_minutes, opens_at, closes_at,
                            published, questions[]
attempts/{quizId}_{uid}     answers, score, total_points, submitted_at
Storage: videos/{adminUid}/{timestamp}_{name}
```

No composite indexes are needed: every query filters on one field and sorts on
the client.

## 4b. Demo data

Signed in as the admin, **Settings → Demo data → Fill demo data** writes a
complete sample set: six members (one switched off, one without CV rights),
eleven videos (ten published, one still a draft), five quizzes (timed, untimed, inside a
window, already closed, and an unpublished draft), fourteen attempts and four
CVs — one in each review state. Every screen in both the admin and the member
side then has something real to draw.

* Every document it writes carries `demo: true`. **Remove demo data** deletes
  exactly those, and nothing you or your members made.
* Each demo member also gets a Firebase Auth account on `@demo.asec.app`, a
  domain that receives no mail, with the password `Asec12345`. Sign out and
  sign in as one of them to see the member side.
* `firestore.rules` lets the admin write a member's profile, attempt or CV
  **only** while the document carries `demo: true`, so the button cannot be
  used to forge a real record. Deploy the rules before pressing it:

      firebase deploy --only firestore:rules

* Pressing Fill twice refreshes the same documents — the ids are fixed
  (`demo_q_safety`, `demo_v_boq`, …), so nothing is duplicated.

## 4c. Screen capture protection

Screenshots and screen recordings are blocked app-wide, in native code:

| Platform | Where | What happens |
|---|---|---|
| Android | `MainActivity.kt` — `FLAG_SECURE` | Screenshot refused; recordings / casting show black |
| iOS | `SceneDelegate.swift` — secure-field layer + `isCaptured` cover | Screenshots and recordings come out black |
| macOS | `MainFlutterWindow.swift` — `sharingType = .none` | Window left out of screenshots / recordings |
| Windows | `flutter_window.cpp` — `WDA_EXCLUDEFROMCAPTURE` | Window captured as black |
| Web | — | Not possible in a browser |

Nothing stops a second phone filming the screen.

**Switch.** Settings → Control centre → *Block screenshots* (also in the
website panel's Control centre). On by default; switched off, every open app
lifts the block within a second (`lib/core/settings/screen_protection.dart`
→ channel `asec/screen_protection` → the native files above). Apps always
start protected and lift it once the setting has loaded.

## 5. The two times on a quiz

They are different things and the UI keeps them apart:

* **Time limit** (`duration_minutes`) — the countdown that starts when a member
  presses Start. `0` = untimed. It is recomputed from the start time on every
  tick, so backgrounding the app buys nobody extra time, and the quiz submits
  itself at zero.
* **When it is open** (`opens_at` / `closes_at`) — the window the quiz can be
  taken in at all. Either end may be left empty. **The window caps the
  countdown**: a 30-minute quiz started 10 minutes before it closes gets 10.

One attempt per member per quiz — the document id is `{quizId}_{uid}` and the
rules allow create but not update.

## 6. Platforms

Every screen has a layout for its width, so both roles run on phone, tablet,
desktop, macOS and the web: a side rail with labels ≥ 1100, an icon rail
≥ 600, a bottom bar below that.

* macOS entitlements include `network.client` (Firebase),
  `files.user-selected.read-only` (picking a video) and
  **`keychain-access-groups`**.

  That last one is not optional: a sandboxed macOS app can only touch the
  Keychain through an access group, and firebase_auth stores its session token
  there — without it every sign-in and registration fails with
  `[firebase_auth/keychain-error]` AFTER Firebase has already done the work,
  so an account gets created while the app says it failed.

  `$(AppIdentifierPrefix)` only resolves when the target is signed, so the
  macOS Runner target has `DEVELOPMENT_TEAM = 6PN5F8N7MA` (the same team
  manger_plus uses). If you sign with a different Apple ID, change it in
  `macos/Runner.xcodeproj/project.pbxproj` and change the group in both
  `macos/Runner/*.entitlements` to match the bundle id. Check the certificate
  is there with:

  ```bash
  security find-identity -v -p codesigning
  ```

  After changing entitlements or signing, rebuild from clean:
  `flutter clean && flutter run -d macos`.
* Android: `INTERNET`, `minSdk 23` (firebase_auth 5.x).
* Windows and Linux have no `video_player` implementation — the player detects
  it and offers **Open in another app** instead.

## 7. Where things are

```
lib/core/                     ported from manger_plus, package renamed
lib/features/
  onboarding/o1_splash        splash + AppRouter (the one routing rule)
  onboarding/o2_authentication sign in, register, session
  video/v1_videos             upload, list, player
  quiz/q1_quizzes             editor, attempt (timer), results
  admin/a1_shell              the responsive shell both roles use
  admin/a2_members            members, and the on/off switch
  admin/a3_dashboard          counts at a glance
  user/u1_shell               member navigation
  settings/se1_settings       theme, language, haptics, sign out
```
