# Running Finsor (DEV vs PROD)

## Environment Selection

Finsor uses `--dart-define=ENV=dev` or `--dart-define=ENV=prod` to select which `.env` file to load.

| ENV value | File loaded  | Supabase project |
|-----------|-------------|------------------|
| `dev`     | `.env.dev`  | finsor-dev       |
| `prod`    | `.env.prod` | finsor-prod      |

If no `--dart-define=ENV` is provided, defaults to `dev`.

## Command Line

### Windows

```bash
flutter run -d windows --dart-define=ENV=dev
flutter run -d windows --dart-define=ENV=prod
```

### Web (Chrome)

    ```bash
    flutter run -d chrome --dart-define=ENV=dev
    flutter run -d chrome --dart-define=ENV=prod
    ```

### Android / iOS

```bash
flutter run --dart-define=ENV=dev
flutter run --dart-define=ENV=prod
```

(Flutter will prompt you to select a device if `-d` is omitted and multiple are connected.)

## VS Code / Cursor

Use the pre-configured launch configurations in `.vscode/launch.json`:

- **Finsor (dev) - Windows**
- **Finsor (dev) - Web**
- **Finsor (prod) - Windows**
- **Finsor (prod) - Web**

## Offline Mode

If `.env.dev` / `.env.prod` is missing or contains placeholder values, the app runs in **offline mode**:

- All local features work (transactions, budgets, analytics, goals)
- A banner shows "Offline mode (Supabase not configured)"
- No crash, no login required

## Build for Release

```bash
flutter build web --dart-define=ENV=prod
flutter build windows --dart-define=ENV=prod
flutter build apk --dart-define=ENV=prod
```
