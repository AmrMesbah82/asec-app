# ASEC — setup

Videos and timed quizzes. One admin (`adminamr@gmail.com`), everybody else is a
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
adminamr@gmail.com
```

The role follows the email in two places that must stay in step:

* `AppConstants.adminEmail` — what the app believes,
* `isAdmin()` in `firestore.rules` and `storage.rules` — the boundary that
  actually enforces it.

Anybody else who registers becomes a member. Nobody can promote themselves:
the rules refuse a `role: "admin"` profile written by any other email.

To change the admin address later, change it in **all three** files and
redeploy the rules.

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
five videos (one still a draft), five quizzes (timed, untimed, inside a
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
