# manager-bot

The staff console for the Telegram casino cashier backend. A native Android and
iOS app, written in Flutter, for the people who work the money: reviewing
deposits, watching reconciliation breaks and agent float, keeping payment
destinations correct, and administering the admin users themselves.

It talks to the same REST API the Telegram bot talks to, under `/v1/admin/...`.

**What it is not.** Not Flutter Web. Not a Telegram Mini App. Not a player app.
There is no player surface here at all, and there never should be: this app
holds an admin bearer token, and an admin token on a player screen is how tokens
leak. It is also not a replacement for the server's own checks - every gate in
this code exists to stop an operator pressing a button that will be refused, and
the server is still the only thing that decides.

---

## Read this first

### Build status: compiles clean, tests green

Verified on **Flutter 3.47.0 (stable) / Dart 3.13.0**, 2026-08-16:

| Check | Result |
|---|---|
| `flutter pub get` | resolves |
| `flutter analyze` | **No issues found** — 0 errors, 0 warnings, 0 infos, under the strict `analysis_options.yaml` |
| `flutter test` | **273 passed**, 0 failed |
| `flutter build apk --debug` | **builds** → `build/app/outputs/flutter-apk/app-debug.apk` (~152 MB; debug carries every ABI and no minification) |
| `android/` + `ios/` | generated, `applicationId` `com.managerbot.manager_bot` |

The platform prerequisites are already applied:

| Where | State |
|---|---|
| `minSdk` | Nothing to do. Flutter 3.47's default is **24**, already above the API 23 that `flutter_secure_storage`'s `EncryptedSharedPreferences` needs (`lib/core/auth/token_store.dart`). Do not pin it lower. |
| `android/app/src/debug/res/xml/network_security_config.xml` | Written, and referenced from the **debug** `AndroidManifest.xml`. Permits cleartext to `10.0.2.2`, `localhost`, `127.0.0.1` for dev only — `src/debug` never merges into a release build. |
| `ios/Runner/Info.plist` | `NSAppTransportSecurity` → `NSAllowsLocalNetworking` = `true`. Local cleartext only; real hosts keep full ATS. |

Two standing rules:

- **Do not weaken `analysis_options.yaml`.** It is clean today. Keep it that way.
- **Do not create a `web/` directory.** The target is native only.

### Toolchain

Installed and verified on this machine, without Android Studio — Flutter needs
only the SDK, and the command-line tools are scriptable where Studio's
first-launch wizard is not:

| Piece | Where |
|---|---|
| Flutter 3.47.0 stable | `C:\Users\Mustafa\flutter` (on the user PATH) |
| JDK 17 (Microsoft OpenJDK) | `C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot`, `JAVA_HOME` set. AGP 8.x requires 17. |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk`, `ANDROID_HOME` set — platform-tools, platform 36, build-tools 36.0.0, plus NDK 28.2 / CMake / platforms 34-35 that Gradle pulled in on the first build |

`flutter doctor` is green for Flutter, Windows, **Android toolchain**, Chrome,
devices and network. The one remaining ✗ is **Visual Studio**, which is only for
building Windows *desktop* apps — irrelevant to this project.

To run it:

```bash
flutter run --dart-define=USE_FAKE_AUTH=true
```

iOS needs macOS + Xcode; the `ios/` folder is generated here but cannot be built
on Windows.

Before any release build, change `applicationId` in
`android/app/build.gradle.kts` — `com.managerbot.manager_bot` is a placeholder —
and replace the debug signing config, which currently signs release builds.

### The backend blocker: no admin login endpoint

There is no way for this app to obtain a real admin token today.

- `issueAdminAccessToken` exists in `src/core/auth/services/session.service.ts`
  and has **zero callers**. Nothing in the HTTP layer reaches it.
- The only token-minting route that is wired is the player one,
  `POST /v1/auth/telegram`, which takes Telegram `initData`. A native app cannot
  produce valid `initData` - only a Mini App webview can.
- `POST /v1/auth/refresh` exists, but admin sessions are never issued a refresh
  token, so it is not usable here.

So until `POST /v1/admin/auth/bot-code` (or an equivalent) ships, run with the
fake auth adapter. `FakeAdminAuthApi` mints an in-memory session so every screen
is usable and reviewable; it contacts no server and it says so, loudly, in the
startup log and on the login screen.

`HttpAdminAuthApi.backendEndpointImplemented` is `false`. While it is false the
real adapter refuses to send the request at all and explains why, rather than
firing at a route that answers 404 and reads like a wrong code. Flip it to
`true` in the same commit the endpoint lands.

**Run it with the fake adapter (the default in dev):**

```bash
flutter run \
  --dart-define=MB_ENV=dev \
  --dart-define=MB_API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=MB_USE_FAKE_AUTH=true
```

Accepted codes on the login screen (case-insensitive, `-` works instead of `_`):

| Code | Session |
|---|---|
| `DEV-SUPER_ADMIN` | 8 h, SUPER_ADMIN |
| `DEV-FINANCE_ADMIN` | 8 h, FINANCE_ADMIN |
| `DEV-REVIEWER` | 8 h, REVIEWER |
| `DEV-SUPPORT` | 8 h, SUPPORT |
| `DEV-VIEWER` | 8 h, VIEWER |
| `DEV-REVIEWER:SHORT` | **2 minutes** - use this to exercise expiry and re-login |
| `DEV-SUPPORT:Layla` | 8 h, display name `Layla` |
| `DEV-DENY` | always rejected - use this to exercise the error path |

**Run it against a real server (only once the endpoint exists):**

```bash
flutter run \
  --dart-define=MB_ENV=dev \
  --dart-define=MB_API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=MB_USE_FAKE_AUTH=false
```

A release build for production:

```bash
flutter build apk --release \
  --dart-define=MB_ENV=prod \
  --dart-define=MB_API_BASE_URL=https://api.example.com \
  --dart-define=MB_USE_FAKE_AUTH=false
```

`MB_ENV=prod` forces `useFakeAuth` to false whatever the define says, so a
mis-set flag can never ship a login bypass.

---

## What the backend must add

Two things, in this order.

**1. A bot-code login endpoint.** The bot DMs an admin a one-time code; the app
exchanges it for an access token. The client is already written against this
exact shape (`lib/core/auth/http_admin_auth_api.dart`,
`AdminSession.fromJson`):

```
POST /v1/admin/auth/bot-code        @Public()  - no Authorization header
body:    { "code": "<one-time code the bot DM'd to the admin>" }
success: 200/201 envelope, data = {
           "accessToken": "<jwt>",
           "expiresAt":   "2026-08-16T18:04:11.512Z",   // ISO-8601, REQUIRED
           "admin": {
             "id":             "<uuid>",
             "telegramUserId": "7123456789",   // decimal STRING, 64-bit
             "role":           "FINANCE_ADMIN",
             "displayName":    "Layla"
           }
         }
failure: 401 { code: "BOT_CODE_INVALID" | "BOT_CODE_EXPIRED" }
         403 { code: "ADMIN_INACTIVE" }
         429 { code: "RATE_LIMITED" }
```

`expiresAt` is not optional. The app refuses to parse a session without it -
every expiry decision reads that field, and a guessed expiry keeps a dead token
looking alive right up to the surprise 401.

**2. Something to do about session length.** Admin tokens have **no refresh
token**. When the token dies, the operator has to go back to the bot, get a new
code, and type it in - in the middle of a review queue. The app is honest about
this (`AuthExpired` names who you were and why it ended, and `refresh()` throws
`AuthUnsupportedError` rather than pretending), but it is not pleasant to use
day to day. Either an admin refresh path or a long-lived device token is needed
before this is a tool somebody works an eight-hour shift in.

Also worth fixing, both reproducible 500s the app now names instead of blaming
on the operator:

- **`POST /v1/admin/deposits/:id/claim` cannot succeed.** The service asks for
  `[SUBMITTED, UNDER_REVIEW] -> UNDER_REVIEW`, and `DepositStateMachine`
  asserts every candidate before touching the row, but
  `ALLOWED_TRANSITIONS[UNDER_REVIEW]` has no `UNDER_REVIEW` self-edge. Add it.
  The claim is advisory, so approve and reject still work without it.
- **`POST /v1/admin/deposits/:id/retry-credit` cannot succeed.** Same shape:
  `[CREDIT_FAILED, NEEDS_RECONCILIATION] -> APPROVED`, and
  `ALLOWED_TRANSITIONS[NEEDS_RECONCILIATION]` does not contain `APPROVED`.

Both throw `IllegalDepositTransitionError`, which is a plain `Error` and not an
`AppException`, so they arrive as 500 `INTERNAL_ERROR` rather than a 422.

---

## Pointing the app at a local API

Everything comes from `--dart-define`. Nothing is baked into source control.

| Define | Default | Meaning |
|---|---|---|
| `MB_ENV` | `dev` | `dev` or `prod`. `prod` forces real auth. |
| `MB_API_BASE_URL` | `http://10.0.2.2:3000` | Origin only. No trailing slash, no `/v1`. |
| `MB_USE_FAKE_AUTH` | `true` in dev | Bind `FakeAdminAuthApi` instead of HTTP. Ignored in prod. |
| `MB_PAGE_SIZE` | `20` | `limit` on list endpoints. Server caps at 100. |
| `MB_CONNECT_TIMEOUT_MS` | `10000` | |
| `MB_SEND_TIMEOUT_MS` | `20000` | |
| `MB_RECEIVE_TIMEOUT_MS` | `20000` | |
| `MB_VERBOSE_HTTP` | on in dev | Log method, path, status, correlation id. |

**The 10.0.2.2 rule.** Inside an Android emulator, `localhost` means the
emulator, not your machine. The emulator reaches your host loopback through the
alias `10.0.2.2`, which is why that is the default.

| Target | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:3000` (the default) |
| iOS simulator | `http://localhost:3000` |
| Physical handset | `http://<your-LAN-ip>:3000`, and the API must bind `0.0.0.0` |

Cleartext HTTP needs the debug exemptions listed in Build status, which are
already applied. Production is
HTTPS and needs none of them.

---

## Screens

| Route | Screen | Who can open it |
|---|---|---|
| `/` | `SplashScreen` | everyone (keystore read only) |
| `/login` | `LoginScreen` | everyone |
| `/deposits` | `DepositQueueScreen` | all five roles |
| `/deposits/:shortId` | `DepositDetailScreen` | all five roles |
| `/reconciliation` | `ReconciliationScreen` | all five roles (resolving a break: SUPER_ADMIN, FINANCE_ADMIN) |
| `/payment-methods` | `PaymentMethodsScreen` | all five roles (writing: SUPER_ADMIN, FINANCE_ADMIN) |
| `/admin-users` | `AdminUsersScreen` | SUPER_ADMIN, FINANCE_ADMIN read; SUPER_ADMIN writes |
| `/settings` | `SettingsScreen` | everyone signed in |

The five tabs live in a `StatefulShellRoute`, so each keeps its own navigation
stack. Tabs a role cannot use are hidden, and the router guards the routes
themselves - the guards only avoid dead ends, the server still decides.

Navigate by NAME, never by literal path:

```dart
context.goNamed(AppRoute.depositQueue);
context.pushNamed(
  AppRoute.depositDetail,
  pathParameters: <String, String>{AppRoute.shortIdParam: deposit.shortId},
);
```

---

## Architecture

```
lib/
  core/          shared foundation, owned by nobody in particular
    api/         ApiClient (the ONE http entry point), envelope, Json helpers
    auth/        AdminSession, the AdminAuthApi port + 2 adapters, roles
    config/      AppConfig from --dart-define
    errors/      the sealed ApiError hierarchy + stable error codes
    money/       Money: BigInt minor units, scale 2
    theme/       semantic colours (approve / reject / pending / failed)
    widgets/     AsyncValueView, ErrorStateView, MoneyText, StatusChip
  features/
    <feature>/
      data/         wire models with hand-written fromJson, and the repository
      application/  Riverpod controllers, policies, pure decision code
      presentation/ screens and widgets
  router/        go_router config, the tab shell, the splash
```

Three rules keep it navigable:

1. **`data/` never imports `presentation/`.** A repository knows nothing about a
   screen. `application/` is the only thing that sees both.
2. **One HTTP entry point.** Everything goes through `ApiClient`. A
   `DioException` never escapes it, and neither does a parse failure - a
   hand-written `fromJson` runs inside the client's guard, so a contract change
   arrives as a typed `ApiError`, not as a raw throw in a widget.
3. **Pure decisions live in `application/` and are unit tested.** The action
   matrices (`DepositActionPolicy`, `AdminUserPolicy`, the role sets) are plain
   functions with no Flutter in them, which is why `test/` can cover them
   without a device.

## Rules this code follows

- **No code generation.** No freezed, no json_serializable, no build_runner, no
  retrofit. Every model has a hand-written `fromJson`, and a `toJson` where a
  request body needs one. A missing `.g.dart` must never be able to break the
  build.
- **The dependency set is fixed**: `flutter_riverpod`, `dio`,
  `flutter_secure_storage`, `go_router`, `intl`, plus `flutter_test` and
  `flutter_lints`. Adding a package is a decision, not a convenience.
- **Money is `BigInt` minor units, end to end, scale 2.** Never `double`, never
  `num`. Parsing happens once, formatting happens only at the render edge. An
  amount that cannot be read exactly is reported as an error rather than
  rounded into view.
- **Telegram ids are 64-bit.** They arrive as decimal strings and are parsed as
  `BigInt`. Never `int`.
- **Strict null safety.** No `late` on anything that can arrive absent from
  JSON, no `dynamic` escaping a parser, sealed hierarchies for anything that
  gets switched on.

## Backend docs

This app is a client. The contract, the state machines and the operational
story all live in the backend repository:

- `docs/STATUS.md` - what is actually built and what is not
- `docs/ARCHITECTURE.md` - modules, layering, the envelope
- `docs/DECISIONS.md` - why things are the way they are
- `docs/RUNBOOK.md` - running it, and what to do when it breaks
