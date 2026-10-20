# Releasing the E-LIKAS Android app

The app updates itself: on launch (and when resumed after 6 h or more) it
fetches a small static file, `version.json`, and offers the new APK if the
build number is higher. There is no backend involved — you upload two files
to the website by hand.

## One-time prerequisites

- `android/key.properties` with the **release** keystore (never committed;
  `android/.gitignore` already excludes it and `*.jks`/`*.keystore`):

  ```properties
  storeFile=<path to the .jks file>
  storePassword=<store password>
  keyAlias=<key alias>
  keyPassword=<key password>
  ```

- Android SDK build-tools (for `apksigner`) and a JDK on `PATH`.
- Android only updates an app when the new APK is signed with **the same
  key** as the installed one and has a **higher `versionCode`** (the number
  after `+` in `pubspec.yaml`). A phone that has a debug-signed or
  differently-signed copy must uninstall it once before the first
  release-signed install. The first build that contains the updater
  (0.2.0+3) must itself be installed by hand; every later one can arrive
  in-app.

## Steps

1. **Bump the version** in `pubspec.yaml`, e.g. `version: 0.2.1+4`. The
   number after `+` must be higher than the last release.
2. **Build** (smaller than the fat APK; do *not* use `--split-per-abi`):

   ```powershell
   flutter build apk --release --target-platform android-arm,android-arm64
   ```

   If Gradle prints the "key.properties is missing / DEBUG key" warning,
   stop: that APK must not be distributed.
3. **Verify the signer** — the certificate must *not* be "Android Debug":

   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\build-tools\<version>\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-release.apk
   ```

4. **Compute SHA-256 and size**:

   ```powershell
   Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256
   (Get-Item build\app\outputs\flutter-apk\app-release.apk).Length
   ```

5. **Write `version.json`** (only `latest_build` and `apk_url` are
   mandatory; `sha256` must be exactly 64 hex characters if present):

   ```json
   {
     "latest_build": 4,
     "latest_version": "0.2.1",
     "min_build": 1,
     "apk_url": "https://e-likasligao.online/downloads/E-LIKAS-Mobile.apk",
     "sha256": "<64 hex characters>",
     "size_bytes": 50000000,
     "notes": { "en": "...", "fil": "...", "bcl": "..." }
   }
   ```

   - `apk_url` must be `https` and on the **same host** as `version.json`.
   - `min_build`: any installed build below it sees an "Update required"
     dialog on every launch (still dismissible with *Later*). Leave it at
     the oldest build you still support.
   - `notes` may also be a plain string (shown in every language).
6. **Upload with WinSCP** to `public/downloads/` on the VPS: the **APK
   first**, `version.json` **last**. Residents only see the update once
   `version.json` points at it, so the APK must already be in place.
7. **Smoke test**: open `https://e-likasligao.online/downloads/version.json`
   in a browser, then on a phone with the previous build use
   *Settings → Check for updates*.

## Helper script

`tool\release.ps1` does steps 2–5 (build, signer check, copy, hash, JSON)
and writes `dist\E-LIKAS-Mobile.apk` and `dist\version.json` (`dist/` is
git-ignored). It refuses to run without `android\key.properties` and fails
if the APK is signed with the Android Debug certificate:

```powershell
.\tool\release.ps1 -NotesEn "What changed" -NotesFil "Ano ang nagbago" -MinBuild 1
```

Then upload as in step 6.

## Testing the updater without touching production

Point a debug/profile or release build at a test manifest (same host as the
APK URL, `https` only):

```powershell
flutter run --dart-define=UPDATE_MANIFEST_URL=https://e-likasligao.online/downloads/test/version.json
```

Remember that Android will only install an APK signed with the same key as
the one on the phone.
