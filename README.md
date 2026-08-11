# Flutter Create PowerShell

An interactive PowerShell wrapper around Flutter's `flutter create` command.

Instead of remembering and typing a long list of Flutter CLI flags, Flutter Create PowerShell provides an interactive terminal UI for configuring a new Flutter project — including its name, location, template, platforms, Android language, and advanced creation options.

The project is intentionally lightweight and is designed primarily for local use on Windows.

## How It Works

Flutter Create PowerShell does not replace or reimplement Flutter's project generation logic.

It acts as a user-friendly layer on top of the existing Flutter CLI.

The workflow is roughly:

```text
                  Flutter Create TUI
                           │
                           ▼
                 Project configuration
                           │
                           ▼
                  Build flutter arguments
                           │
                           ▼
                Run flutter create <options>
                           │
                           ▼
                   New Flutter project
```

For example, instead of manually writing:

```powershell
flutter create `
    --project-name my_app `
    --org com.example `
    --template app `
    --platforms android,ios,web `
    --android-language kotlin `
    my_app
```

The wizard lets you select these options interactively and constructs the corresponding Flutter command for you.

The actual project is still created by Flutter itself.

---

## Requirements

Before using the tool, make sure you have:

* Windows
* PowerShell
* Flutter SDK installed
* `flutter` available in your system `PATH`

You can verify your Flutter installation with:

```powershell
flutter --version
```

---

## Download and Use

The easiest way to use the tool is to download the latest standalone script from the [releases page](https://github.com/jydv402/flutter_create_powershell/releases).

Download:

```text
flutter-create.ps1
```

Run it from PowerShell:

```powershell
.\flutter-create.ps1
```

---

## Or Build It Yourself

If you want to build the standalone script yourself, clone the repository:

```powershell
git clone <repository-url>
cd flutter-create-powershell
```

The source is organized as:

```text
flutter-create-powershell/
│
├── src/
│   ├── main.ps1
│   └── parts/
│       ├── config.ps1
│       ├── ui.ps1
│       ├── menus.ps1
│       └── flutter.ps1
│
├── build/
│   └── build.ps1
│
└── .github/
    └── workflows/
        └── release.yml
```

Run the build script:

```powershell
.\build\build.ps1
```

The resulting standalone script will be generated at:

```text
dist/flutter-create.ps1
```
You can freely copy the `flutter_create.ps1` and run it inside the powershell.

---

## License

This project is licensed under the [MIT License](LICENSE).
