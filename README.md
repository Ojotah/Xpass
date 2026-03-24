# XPass - Phase 1 MVP

Cross-platform offline password manager starter (Linux desktop first) built with Flutter + Riverpod using Clean Architecture.

## Implemented in this phase

- Unlock vault screen (mock unlock)
- Home screen listing accounts from local JSON-backed repository
- Add account flow that persists to local file
- Clean architecture layering for future encryption support

## Architecture

```text
lib/
  core/
    error/
    utils/
  features/
    vault/
      domain/
        entities/
        repositories/
        usecases/
      data/
        models/
        repositories/
        datasources/
      presentation/
        screens/
        widgets/
        providers/
```

## Local storage behavior

Vault data is written to the app support directory in `vault.json` with a schema designed for future encryption metadata:

```json
{
  "version": 1,
  "encryption": "none",
  "accounts": []
}
```

## Run (native environment)

```bash
flutter pub get
flutter run -d linux
```

## Dockerized dev environment

Build image:

```bash
docker build -t xpass-dev .
```

Run container with repo mounted:

```bash
docker run --rm -it \
  -v "$(pwd)":/workspace/Xpass \
  -w /workspace/Xpass \
  xpass-dev bash
```

Then inside container:

```bash
flutter pub get
flutter run -d linux
```

> Note: GUI forwarding for running Linux desktop apps depends on host display configuration.
