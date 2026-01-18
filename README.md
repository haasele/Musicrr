# Musicrr

A highly customizable, power-user focused music player application.

## Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Generate code (for freezed models):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Run the app:
```bash
flutter run
```

## Project Structure

- `lib/core/` - Core business logic (audio, providers, models, storage)
- `lib/features/` - Feature modules (home, library, now_playing, settings, mini_player, remote)
- `lib/shared/` - Shared utilities, widgets, and theme
- `android/` - Native Android implementation (ExoPlayer, DSP, visualizer, web server)

## Features

- Material 3 UI with customizable themes
- Multi-provider support (Local, HTTP, WebDAV, SMB, Subsonic, Jellyfin)
- Advanced audio processing (EQ, ReplayGain, Crossfade)
- Gapless playback
- Local-only recommendations
- Customizable Now Playing screen
- Remote control via embedded web server
