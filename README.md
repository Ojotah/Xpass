# XPass Vault

Offline-first, multi-vault password manager built with Flutter and Riverpod using Clean Architecture.

## Production release commands

```bash
flutter clean
flutter pub get
flutter test
flutter build linux --release
```

Release bundle output:

```text
build/linux/x64/release/bundle/
```

## Linux packaging

### 1) AppImage (portable)

```bash
sudo apt-get install -y appimagetool
flutter build linux --release
mkdir -p dist/AppDir
cp -r build/linux/x64/release/bundle/* dist/AppDir/
cp linux/packaging/xpass.desktop dist/AppDir/
cp linux/runner/resources/xpass_icon.png dist/AppDir/xpass.png
appimagetool dist/AppDir dist/xpass-vault.AppImage
```

### 2) .deb package

```bash
flutter build linux --release
mkdir -p dist/deb/DEBIAN
mkdir -p dist/deb/usr/local/bin
mkdir -p dist/deb/usr/share/applications
mkdir -p dist/deb/usr/share/icons/hicolor/256x256/apps
cp build/linux/x64/release/bundle/xpass dist/deb/usr/local/bin/xpass
cp linux/packaging/xpass.desktop dist/deb/usr/share/applications/xpass.desktop
cp linux/runner/resources/xpass_icon.png dist/deb/usr/share/icons/hicolor/256x256/apps/xpass.png
cat > dist/deb/DEBIAN/control <<'CONTROL'
Package: xpass-vault
Version: 0.1.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: XPass Team
Description: Offline encrypted password vault
CONTROL

dpkg-deb --build dist/deb dist/xpass-vault_0.1.0_amd64.deb
```

## Runtime configuration

Use compile-time defines for environment-specific settings:

```bash
flutter run -d linux \
  --dart-define=BREACH_API_BASE_URL=https://api.pwnedpasswords.com/range/ \
  --dart-define=FEATURE_BREACH_DETECTION=true
```

## Security notes

- Vault files are always encrypted before save (AES-256-GCM + PBKDF2).
- Wrong-password and corruption errors are mapped to user-safe messages.
- Logger only records non-sensitive events/errors.
- In-memory session password is cleared on lock.

## Key production files

- `lib/core/error/error_handler.dart`
- `lib/core/logging/app_logger.dart`
- `lib/core/config/app_config.dart`
- `linux/packaging/xpass.desktop`
- `linux/runner/resources/xpass_icon.png`

## Project structure

```text
lib/
  core/
    config/
    error/
    logging/
    security/
    utils/
    widgets/
  features/
    settings/
    security/
    theme/
    vault/
    vault_switching/
test/
  core/security/
  features/vault/data/repositories/
  features/vault/domain/usecases/
linux/
  packaging/
  runner/resources/
```
