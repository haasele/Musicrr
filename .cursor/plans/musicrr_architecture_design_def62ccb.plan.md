---
name: Musicrr Architecture Design
overview: Design a comprehensive architecture for a highly customizable, power-user focused music player with Flutter UI, native audio engine, unified media providers, local recommendations, and embedded web server for remote control.
todos:
  - id: setup-project
    content: Set up Flutter project structure with proper folder organization and dependencies
    status: completed
  - id: platform-channels
    content: Define and implement platform channel interfaces (MethodChannel/EventChannel) for audio engine communication
    status: completed
    dependencies:
      - setup-project
  - id: exoplayer-integration
    content: Integrate ExoPlayer with basic playback functionality (play, pause, seek) and format support
    status: completed
    dependencies:
      - platform-channels
  - id: provider-abstraction
    content: Create unified MediaProvider interface and implement LocalProvider as first provider
    status: completed
    dependencies:
      - setup-project
  - id: basic-ui
    content: Build basic Flutter UI with Material 3, bottom navigation, and mini-player bar
    status: completed
    dependencies:
      - setup-project
  - id: library-browser
    content: Implement library browser with artists, albums, and songs views
    status: completed
    dependencies:
      - provider-abstraction
      - basic-ui
  - id: now-playing-basic
    content: Create basic Now Playing screen with cover art, progress bar, and controls
    status: completed
    dependencies:
      - exoplayer-integration
      - basic-ui
  - id: settings-foundation
    content: Build settings screen foundation with theme and basic audio settings
    status: completed
    dependencies:
      - basic-ui
---

# Musicrr Architecture Design

## System Architecture Overview

The application follows a layered architecture with clear separation between UI, business logic, and platform-specific audio engine.

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                      │
│  (Material 3, Navigation, State Management)              │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              Business Logic Layer                        │
│  (Providers, Services, State Management)                 │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│            Platform Channel Layer                        │
│  (MethodChannel, EventChannel)                           │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│          Native Android Layer                            │
│  (ExoPlayer, Audio Engine, DSP, Visualizer)              │
└──────────────────────────────────────────────────────────┘
```

## Detailed System Architecture

### Module Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FLUTTER UI LAYER                                   │
│                                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   Home       │  │   Library    │  │  Now Playing │  │  Settings    │   │
│  │   Screen     │  │   Screen     │  │  Screen      │  │  Screen      │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         │                  │                  │                  │          │
│         └──────────────────┴──────────────────┴──────────────────┘          │
│                              │                                               │
│                    ┌─────────▼─────────┐                                     │
│                    │  Mini Player Bar  │                                     │
│                    │  (Persistent)    │                                     │
│                    └─────────┬─────────┘                                     │
│                              │                                               │
│  ┌───────────────────────────▼───────────────────────────┐                 │
│  │              State Management (Riverpod)                │                 │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐        │                 │
│  │  │Playback    │ │Library     │ │Settings    │        │                 │
│  │  │State       │ │State       │ │State       │        │                 │
│  │  └────────────┘ └────────────┘ └────────────┘        │                 │
│  └───────────────────────────┬───────────────────────────┘                 │
└───────────────────────────────┼───────────────────────────────────────────┘
                                │
┌───────────────────────────────▼───────────────────────────────────────────┐
│                      BUSINESS LOGIC LAYER                                   │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                    Audio Service Layer                              │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │    │
│  │  │AudioEngine   │  │PlaybackQueue │  │AudioEffects  │            │    │
│  │  │(Facade)      │  │(Queue Mgmt)  │  │(EQ/ReplayGain)│            │    │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │    │
│  │         │                  │                  │                      │    │
│  │  ┌──────▼──────────────────▼──────────────────▼──────┐             │    │
│  │  │         Platform Channel Bridge                    │             │    │
│  │  │  (MethodChannel + EventChannel)                    │             │    │
│  │  └────────────────────────────────────────────────────┘             │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                    Provider System                                  │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │    │
│  │  │MediaProvider │  │Provider      │  │Cache         │            │    │
│  │  │(Interface)   │  │Repository    │  │Manager       │            │    │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │    │
│  │         │                  │                  │                      │    │
│  │  ┌──────▼──────────────────▼──────────────────▼──────┐             │    │
│  │  │  Local  │  HTTP  │  WebDAV  │  SMB  │  Subsonic  │             │    │
│  │  │Provider │Provider│ Provider │Provider│  Provider  │             │    │
│  │  └────────────────────────────────────────────────────┘             │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │              Supporting Services                                    │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │    │
│  │  │Recommendation│  │Lyrics        │  │Visualizer    │            │    │
│  │  │Engine        │  │Service       │  │Service       │            │    │
│  │  └──────────────┘  └──────────────┘  └──────┬───────┘            │    │
│  │                                               │                      │    │
│  │  ┌───────────────────────────────────────────▼──────┐             │    │
│  │  │         Analytics Service                         │             │    │
│  │  │  (Play frequency, recency, skip rate)             │             │    │
│  │  └───────────────────────────────────────────────────┘             │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                    Remote Control Service                           │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │    │
│  │  │WebServer     │  │REST API      │  │WebSocket     │            │    │
│  │  │(Embedded)    │  │Handler       │  │Handler       │            │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘            │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└───────────────────────────────┬───────────────────────────────────────────┘
                                │
┌───────────────────────────────▼───────────────────────────────────────────┐
│                    PLATFORM CHANNEL LAYER                                   │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │              MethodChannel Handlers                                 │    │
│  │  - play(String uri)                                                │    │
│  │  - pause() / resume()                                              │    │
│  │  - seek(int positionMs)                                            │    │
│  │  - setEQ(List<EQBand>)                                             │    │
│  │  - setReplayGain(double gain)                                      │    │
│  │  - enableCrossfade(bool, int durationMs)                          │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │              EventChannel Streams                                   │    │
│  │  - playbackState (playing, paused, stopped, error)                │    │
│  │  - position (current position in ms)                               │    │
│  │  - audioSessionId (for visualizer)                                  │    │
│  │  - audioData (FFT data for visualizer)                              │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└───────────────────────────────┬───────────────────────────────────────────┘
                                │
┌───────────────────────────────▼───────────────────────────────────────────┐
│                      NATIVE ANDROID LAYER                                   │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                    Audio Engine (ExoPlayer)                          │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │    │
│  │  │ExoPlayer     │  │GaplessPlayer │  │AudioSession  │            │    │
│  │  │Instance      │  │(Dual Player) │  │Manager       │            │    │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │    │
│  │         │                  │                  │                      │    │
│  │  ┌──────▼──────────────────▼──────────────────▼──────┐             │    │
│  │  │         Audio Processing Pipeline                  │             │    │
│  │  │  ┌──────────────┐  ┌──────────────┐              │             │    │
│  │  │  │ReplayGain    │  │Parametric EQ │              │             │    │
│  │  │  │Processor     │  │(DSP)         │              │             │    │
│  │  │  └──────┬───────┘  └──────┬───────┘              │             │    │
│  │  │         │                  │                        │             │    │
│  │  │  ┌──────▼──────────────────▼──────┐                │             │    │
│  │  │  │    Crossfade Mixer             │                │             │    │
│  │  │  └──────┬─────────────────────────┘                │             │    │
│  │  │         │                                            │             │    │
│  │  │  ┌──────▼─────────────────────────┐                │             │    │
│  │  │  │    Audio Output                │                │             │    │
│  │  │  └────────────────────────────────┘                │             │    │
│  │  └────────────────────────────────────────────────────┘             │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                    Visualizer Engine                                │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │    │
│  │  │MilkPreset    │  │OpenGL ES     │  │FFT Analyzer  │            │    │
│  │  │Parser        │  │Renderer      │  │(Audio Data)  │            │    │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │    │
│  │         │                  │                  │                      │    │
│  │  ┌──────▼──────────────────▼──────────────────▼──────┐             │    │
│  │  │         Visualizer Output (Texture)               │             │    │
│  │  └────────────────────────────────────────────────────┘             │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                    Embedded Web Server                              │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │    │
│  │  │NanoHTTPD     │  │API Router    │  │WebSocket     │            │    │
│  │  │Server        │  │(REST)        │  │Server        │            │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘            │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Module Responsibilities

#### Flutter UI Layer

**Home Screen (`lib/features/home/`)**

- Display recommendation widgets
- Show auto-generated playlists
- Quick access to recently played
- Navigation to library sections
- **State**: Consumes `RecommendationState`, `PlaybackState`

**Library Screen (`lib/features/library/`)**

- Browse artists, albums, songs, playlists
- Provider selection/filtering
- Search functionality
- Playlist management
- **State**: Consumes `LibraryState`, `ProviderState`

**Now Playing Screen (`lib/features/now_playing/`)**

- Modular layout components
- Customizable background modes
- Progress slider variants
- Visualizer display
- Lyrics overlay
- **State**: Consumes `PlaybackState`, `VisualizerState`, `LyricsState`

**Settings Screen (`lib/features/settings/`)**

- Appearance customization
- Audio settings (EQ, ReplayGain, Crossfade)
- Provider configuration
- Cache/download management
- System settings
- **State**: Consumes `SettingsState`, writes to `SettingsRepository`

**Mini Player Bar (`lib/features/mini_player/`)**

- Persistent bottom bar
- Current track info
- Play/pause control
- Progress indicator
- Tap to open Now Playing
- **State**: Consumes `PlaybackState`

#### Business Logic Layer

**Audio Service (`lib/core/audio/`)**

- **AudioEngine**: Facade for all audio operations
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Coordinates playback, queue, effects
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Manages platform channel communication
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Handles state synchronization
- **PlaybackQueue**: Queue management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Add/remove/reorder tracks
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Shuffle/repeat modes
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Gapless preparation
- **AudioEffects**: Effect management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - EQ band configuration
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - ReplayGain application
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Crossfade coordination
- **Threading**: Main isolate (Flutter), communicates via platform channels

**Provider System (`lib/core/providers/`)**

- **MediaProvider**: Abstract interface
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `getArtists()`, `getAlbums()`, `getSongs()`, `getPlaylists()`
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `getAudioStream(String songId)` - returns stream for playback
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `getCoverArtUrl(String albumId)`
- **ProviderRepository**: Multi-provider management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Unified library aggregation
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Provider priority/ordering
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Offline mode filtering
- **Provider Implementations**:
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **LocalProvider**: File system scanning, metadata extraction
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **HttpProvider**: HTTP streaming, basic auth
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **WebDAVProvider**: WebDAV protocol, directory browsing
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **SMBProvider**: SMB/CIFS protocol, network shares
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **SubsonicProvider**: Subsonic API client
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **JellyfinProvider**: Jellyfin API client
- **Threading**: Background isolates for scanning/network operations

**Recommendation Engine (`lib/core/recommendations/`)**

- **AnalyticsService**: Data collection
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Play events (start, pause, skip, completion)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Timestamp tracking
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Duration tracking
- **RecommendationEngine**: Algorithm execution
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Frequency scoring
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Recency scoring
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Skip rate penalty
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Genre/artist similarity
- **PlaylistGenerator**: Auto-playlist creation
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - "Recently Played" (time-based)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - "Most Played" (frequency-based)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - "Discover Weekly" (algorithm-based)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - "On Repeat" (high frequency, low skip rate)
- **Threading**: Background isolate for computation

**Lyrics Service (`lib/core/lyrics/`)**

- **LRCParser**: Parse LRC files
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Synced lyrics (timestamped)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Unsynced lyrics (plain text)
- **LyricsService**: Lyrics management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - File discovery (local, embedded tags)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Search functionality (user-triggered)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Caching
- **Threading**: Background isolate for parsing/searching

**Visualizer Service (`lib/core/visualizer/`)**

- **VisualizerEngine**: Flutter-side coordination
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Preset folder management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Preset selection
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Texture stream management
- **Threading**: Native thread for rendering, texture stream to Flutter

**Remote Control Service (`lib/features/remote/`)**

- **WebServer**: Embedded HTTP server
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Local network binding
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Port management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Security (optional auth)
- **ApiHandler**: REST endpoint handlers
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Playback control
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Queue management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Library browsing
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - EQ preset switching
- **WebSocketHandler**: Real-time updates
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Playback state streaming
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Position updates
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Queue changes
- **Threading**: Native thread for server, communicates via platform channels

#### Platform Channel Layer

**MethodChannel (`android/.../platform_channels/AudioMethodChannel.kt`)**

- **Commands** (Flutter → Native):
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `play(String uri)` - Start playback
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `pause()` - Pause playback
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `resume()` - Resume playback
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `seek(int positionMs)` - Seek to position
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `setVolume(double volume)` - Set volume (0.0-1.0)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `setEQ(List<EQBand> bands)` - Configure EQ
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `setReplayGain(double gainDb)` - Set ReplayGain
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `enableCrossfade(bool enabled, int durationMs)` - Enable/configure crossfade
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `setSampleRate(int sampleRate)` - Set output sample rate
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `loadVisualizerPreset(String presetPath)` - Load .milk preset
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `setVisualizerEnabled(bool enabled)` - Enable/disable visualizer
- **Returns**: Success/error status, current state

**EventChannel (`android/.../platform_channels/AudioEventChannel.kt`)**

- **Streams** (Native → Flutter):
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `playbackState`: `{state: "playing"|"paused"|"stopped"|"error", error?: string}`
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `position`: `{positionMs: int, durationMs: int}`
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `audioSessionId`: `{sessionId: int}` - For visualizer
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `audioData`: `{fftData: List<double>, sampleRate: int}` - FFT data for visualizer

#### Native Android Layer

**Audio Engine (`android/.../audio/ExoPlayerAudioEngine.kt`)**

- **ExoPlayerAudioEngine**: Main audio controller
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - ExoPlayer instance management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Format support (MP3, M4A, FLAC, WAV, Opus, OGG)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Audio session management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Lifecycle handling
- **GaplessPlayer**: Gapless playback handler
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Dual ExoPlayer instances for crossfade
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Pre-buffering next track
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Seamless transition logic
- **AudioSessionManager**: Audio session coordination
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Audio focus handling
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Media session integration
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Visualizer session creation
- **Threading**: Main Android thread (UI thread), ExoPlayer internal threads

**DSP Processing (`android/.../dsp/`)**

- **ParametricEQ**: EQ implementation
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Multiple band support (configurable)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Real-time filtering
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Preset management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Integration via ExoPlayer `AudioProcessor`
- **ReplayGainProcessor**: Gain normalization
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Track-level gain application
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Album-level gain (requires album grouping)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Clipping prevention
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Integration via ExoPlayer `AudioProcessor`
- **CrossfadeMixer**: Crossfade implementation
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Dual audio stream mixing
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Fade curves (linear, exponential)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Timing coordination
- **Threading**: Audio processing thread (ExoPlayer's audio thread)

**Visualizer Engine (`android/.../visualizer/`)**

- **MilkPresetParser**: .milk preset parsing
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - XML-like format parsing
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Variable extraction
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Shader code generation
- **VisualizerRenderer**: OpenGL ES rendering
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - GLSurfaceView/TextureView integration
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Shader compilation
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Real-time rendering loop
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - FFT data consumption
- **FFTAnalyzer**: Audio analysis
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Audio session FFT extraction
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Frequency band calculation
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Data formatting for visualizer
- **Threading**: OpenGL rendering thread, FFT analysis thread

**Web Server (`android/.../webserver/`)**

- **MusicrrWebServer**: NanoHTTPD server
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - HTTP server initialization
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Port binding (configurable, default 8080)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Request routing
- **ApiRouter**: REST API routing
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Endpoint registration
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Request parsing
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Response formatting
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - State access (playback, queue, library)
- **Threading**: Background thread for server

### Data Flow: Source → Playback → UI

#### Complete Playback Flow

```
1. USER ACTION (UI)
   User taps song in Library Screen
   ↓
2. UI LAYER (Flutter)
   LibraryScreen calls: AudioEngine.play(song)
   ↓
3. STATE MANAGEMENT (Riverpod)
   PlaybackStateProvider updates: currentSong = song
   ↓
4. BUSINESS LOGIC (Audio Service)
   AudioEngine.play(song):
     a. Resolve song URI via ProviderRepository
     b. Add to PlaybackQueue
     c. Call platform channel: MethodChannel.invokeMethod('play', uri)
   ↓
5. PLATFORM CHANNEL (MethodChannel)
   AudioMethodChannel.handlePlay(uri):
     - Convert Dart String to Android String
     - Forward to ExoPlayerAudioEngine
   ↓
6. NATIVE AUDIO ENGINE (ExoPlayer)
   ExoPlayerAudioEngine.play(uri):
     a. Create MediaItem from URI
     b. Prepare ExoPlayer with MediaItem
     c. Apply AudioProcessors (EQ, ReplayGain)
     d. Start playback
     e. Begin position updates
   ↓
7. AUDIO PROCESSING PIPELINE
   ExoPlayer → ReplayGainProcessor → ParametricEQ → CrossfadeMixer → Audio Output
   ↓
8. EVENT STREAM (EventChannel)
   ExoPlayerAudioEngine emits:
     - playbackState: "playing"
     - position: {positionMs: 0, durationMs: 240000}
   ↓
9. PLATFORM CHANNEL (EventChannel)
   AudioEventChannel streams events to Flutter
   ↓
10. STATE MANAGEMENT (Riverpod)
    PlaybackStateProvider receives events:
      - Updates isPlaying = true
      - Updates position = 0
      - Updates duration = 240000
   ↓
11. UI LAYER (Flutter)
    All UI components rebuild:
      - Mini Player Bar: Shows current song, play icon
      - Now Playing Screen: Updates if open
      - Library Screen: Highlights current song
```

#### Provider Data Flow

```
1. USER ACTION (UI)
   User opens Library Screen
   ↓
2. UI LAYER (Flutter)
   LibraryScreen builds, calls: LibraryService.getArtists()
   ↓
3. BUSINESS LOGIC (Provider System)
   LibraryService.getArtists():
     a. Query ProviderRepository
     b. ProviderRepository aggregates from all active providers
     c. Each provider executes in background isolate:
        - LocalProvider: File system scan
        - HttpProvider: HTTP request
        - WebDAVProvider: WebDAV PROPFIND
        - etc.
     d. Merge and deduplicate results
     e. Cache in local database
   ↓
4. STATE MANAGEMENT (Riverpod)
   LibraryStateProvider updates: artists = [...]
   ↓
5. UI LAYER (Flutter)
   LibraryScreen rebuilds with artists list
```

#### Visualizer Data Flow

```
1. USER ACTION (UI)
   User enables visualizer in Now Playing screen
   ↓
2. UI LAYER (Flutter)
   NowPlayingScreen calls: VisualizerService.enable()
   ↓
3. BUSINESS LOGIC (Visualizer Service)
   VisualizerService.enable():
     a. Load preset via platform channel
     b. Request audio session ID
   ↓
4. PLATFORM CHANNEL (MethodChannel)
   AudioMethodChannel.handleLoadVisualizerPreset(presetPath)
   ↓
5. NATIVE VISUALIZER ENGINE
   MilkVisualizer.loadPreset(presetPath):
     a. Parse .milk preset file
     b. Generate OpenGL shaders
     c. Initialize renderer
   ↓
6. AUDIO ANALYSIS (Native)
   FFTAnalyzer:
     a. Attach to audio session
     b. Extract FFT data in real-time
     c. Format for visualizer
   ↓
7. VISUALIZER RENDERING (Native)
   VisualizerRenderer:
     a. Receive FFT data
     b. Update shader uniforms
     c. Render frame to OpenGL texture
   ↓
8. EVENT STREAM (EventChannel)
   VisualizerEventChannel streams texture/FFT data
   ↓
9. PLATFORM CHANNEL (EventChannel)
   Streams data to Flutter
   ↓
10. UI LAYER (Flutter)
    VisualizerWidget receives texture stream
    Displays in Now Playing screen
```

#### Remote Control Flow

```
1. EXTERNAL REQUEST
   Web browser sends: POST http://device-ip:8080/api/play
   ↓
2. NATIVE WEB SERVER
   MusicrrWebServer receives request
   Routes to ApiRouter
   ↓
3. API HANDLER (Native)
   ApiRouter.handlePlay():
     a. Parse request body
     b. Extract song ID/URI
     c. Call ExoPlayerAudioEngine.play(uri)
   ↓
4. AUDIO ENGINE (Same as playback flow)
   ExoPlayer starts playback
   ↓
5. EVENT STREAM (EventChannel)
   Playback state changes
   ↓
6. WEB SOCKET (Native)
   WebSocketHandler broadcasts update to connected clients
   ↓
7. EXTERNAL CLIENT
   Web browser receives WebSocket update
   UI updates automatically
```

### Threading and Isolate Considerations

#### Flutter Threading Model

**Main Isolate (UI Thread)**

- All Flutter UI code runs here
- State management (Riverpod) runs here
- Platform channel calls are synchronous from Flutter side
- **Blocking operations**: None allowed (causes UI jank)

**Background Isolates**

1. **Provider Scanning Isolate**

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Purpose**: File system scanning for LocalProvider
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Trigger**: User initiates library scan
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Communication**: SendPort/ReceivePort with main isolate
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Data**: Streams scan progress, final results
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Lifecycle**: Spawned on demand, terminated after completion

2. **Recommendation Computation Isolate**

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Purpose**: Heavy computation for recommendation algorithm
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Trigger**: Periodic (e.g., daily) or on-demand
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Communication**: SendPort/ReceivePort
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Data**: Analytics data input, recommendation results output
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Lifecycle**: Spawned on demand, terminated after completion

3. **Lyrics Processing Isolate**

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Purpose**: LRC file parsing, lyrics search
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Trigger**: User requests lyrics or opens Now Playing
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Communication**: SendPort/ReceivePort
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Data**: LRC file content input, parsed lyrics output
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Lifecycle**: Spawned on demand, terminated after completion

**Isolate Communication Pattern**

```dart
// Example: Provider scanning
final receivePort = ReceivePort();
await Isolate.spawn(scanProviderIsolate, receivePort.sendPort);
receivePort.listen((message) {
  if (message is ScanProgress) {
    // Update UI progress
  } else if (message is ScanComplete) {
    // Update library state
  }
});
```

#### Native Android Threading Model

**Main Thread (UI Thread)**

- Platform channel handlers run here (synchronously)
- Must delegate heavy work to background threads
- **Blocking operations**: None allowed

**Audio Thread (ExoPlayer Internal)**

- ExoPlayer manages its own audio thread
- AudioProcessor callbacks run on audio thread
- **Critical**: Audio processing must be real-time, no blocking
- **DSP Operations**: EQ, ReplayGain run here (must be optimized)

**Background Threads**

1. **Web Server Thread**

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Purpose**: Handle HTTP/WebSocket requests
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Implementation**: NanoHTTPD spawns worker threads
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Communication**: Accesses audio engine via synchronized methods
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Lifecycle**: Spawned on server start, terminated on server stop

2. **Visualizer Rendering Thread**

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Purpose**: OpenGL ES rendering
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Implementation**: GLSurfaceView/Renderer thread
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Communication**: Receives FFT data via shared buffer (synchronized)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Lifecycle**: Spawned when visualizer enabled, terminated when disabled

3. **FFT Analysis Thread**

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Purpose**: Extract FFT data from audio session
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Implementation**: Custom thread with AudioRecord/Visualizer API
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Communication**: Writes to shared buffer for visualizer
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - **Lifecycle**: Spawned when visualizer enabled, terminated when disabled

**Thread Communication Patterns**

```kotlin
// Example: Thread-safe audio engine access
class ExoPlayerAudioEngine {
    private val lock = Any()
    
    fun play(uri: String) {
        synchronized(lock) {
            // Modify ExoPlayer state
        }
    }
    
    // Called from audio thread (AudioProcessor)
    fun processAudio(buffer: ByteBuffer): ByteBuffer {
        // Real-time processing, no blocking
        return applyEQ(buffer)
    }
}
```

#### Critical Threading Considerations

1. **Platform Channel Threading**

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - MethodChannel calls are synchronous from Flutter
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Native handlers run on main thread
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Heavy operations must be delegated to background threads
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - EventChannel streams are asynchronous (native → Flutter)

2. **Audio Thread Constraints**

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Audio processing must complete within buffer time
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - No file I/O, network calls, or heavy computation
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - DSP operations must be optimized (SIMD, native code)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Consider JNI for performance-critical DSP

3. **UI Responsiveness**

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - All Flutter UI operations on main isolate
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Provider operations in background isolates
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Use `compute()` for CPU-intensive tasks
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Stream results for progressive updates

4. **State Synchronization**

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Riverpod state updates on main isolate
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Background isolates communicate via ports
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Native threads communicate via synchronized methods
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - EventChannel provides async native → Flutter communication

5. **Memory Management**

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Isolates have separate memory spaces
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Large data transfers via `SendPort` copy data
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Consider streaming for large datasets
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Native threads share memory (use synchronization)

### State Management Architecture (Riverpod)

#### Provider Hierarchy

```
Global Providers (App-level)
├── SettingsProvider (SettingsRepository)
├── ThemeProvider (ThemeState)
└── ProviderRepositoryProvider (ProviderRepository)

Feature Providers
├── PlaybackStateProvider (PlaybackState)
│   ├── CurrentSongProvider
│   ├── QueueProvider
│   ├── PositionProvider
│   └── IsPlayingProvider
├── LibraryStateProvider (LibraryState)
│   ├── ArtistsProvider
│   ├── AlbumsProvider
│   ├── SongsProvider
│   └── PlaylistsProvider
├── RecommendationStateProvider (RecommendationState)
│   ├── RecentlyPlayedProvider
│   ├── MostPlayedProvider
│   └── DiscoverWeeklyProvider
└── VisualizerStateProvider (VisualizerState)
    ├── IsEnabledProvider
    ├── CurrentPresetProvider
    └── TextureStreamProvider
```

#### State Update Flow

```
1. User Action → UI calls service method
2. Service method → Updates state via Riverpod
3. Riverpod notifies listeners
4. UI widgets rebuild (selective, only affected widgets)
5. Platform channel events → Update state → UI rebuilds
```

## Module Structure

### 1. Core Modules

#### `lib/core/`

- **`audio/`**: Audio engine abstraction, playback state, queue management
- **`providers/`**: Unified provider interface and implementations
- **`models/`**: Data models (Song, Album, Artist, Playlist, etc.)
- **`storage/`**: Local database, cache management, settings
- **`recommendations/`**: Local recommendation algorithm
- **`lyrics/`**: Lyrics parsing and management (LRC support)
- **`visualizer/`**: Visualizer engine and .milk preset compatibility

#### `lib/features/`

- **`home/`**: Home screen with recommendations
- **`library/`**: Library browser (artists, albums, songs, playlists)
- **`now_playing/`**: Customizable Now Playing screen
- **`settings/`**: Settings and customization
- **`mini_player/`**: Persistent mini-player bar
- **`remote/`**: Web server and API for remote control

#### `lib/shared/`

- **`widgets/`**: Reusable UI components
- **`theme/`**: Theme management, Material 3 customization
- **`utils/`**: Utility functions

### 2. Native Android Module

#### `android/app/src/main/java/com/haasele/musicrr/`

- **`audio/`**: ExoPlayer wrapper, audio session management
- **`dsp/`**: Parametric EQ implementation, DSP processing
- **`visualizer/`**: .milk visualizer engine port
- **`webserver/`**: Embedded HTTP server (NanoHTTPD or similar)
- **`platform_channels/`**: MethodChannel/EventChannel handlers

## Technology Stack

### Flutter Layer

- **Framework**: Flutter 3.x+
- **State Management**: Riverpod (recommended) or Provider
- **Navigation**: go_router or Navigator 2.0
- **Local Storage**: 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - SQLite: `drift` or `sqflite` for metadata
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - SharedPreferences: `shared_preferences` for settings
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - File system: `path_provider` for cache/downloads
- **HTTP Client**: `dio` for provider requests
- **WebDAV**: `webdav_client` or custom implementation
- **SMB**: `smbclient` or `libsmbclient` wrapper
- **WebSocket**: `web_socket_channel` for remote control

### Native Android Layer

- **Audio Engine**: ExoPlayer with custom extensions
- **DSP Processing**: 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Option A: Custom JNI library using libavfilter or similar
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Option B: ExoPlayer AudioProcessor interface
- **Visualizer**: Custom OpenGL ES renderer compatible with .milk presets
- **Web Server**: NanoHTTPD or Jetty embedded
- **Format Support**: ExoPlayer extensions for FLAC, Opus, OGG

### Audio Format Support

- **ExoPlayer Extensions**:
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - MP3: Built-in
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - M4A: Built-in
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - FLAC: `extension-flac`
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - WAV: Built-in
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Opus: `extension-opus`
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - OGG: `extension-ogg`

## Data Flow

### Playback Flow

```
User Action (UI)
    ↓
PlaybackService (Business Logic)
    ↓
Platform Channel (MethodChannel)
    ↓
NativeAudioEngine (ExoPlayer)
    ↓
Audio Session → DSP Processing
    ↓
Audio Output
```

### Provider Data Flow

```
Provider Interface
    ↓
[LocalProvider | HttpProvider | WebDAVProvider | SMBProvider | SubsonicProvider | JellyfinProvider]
    ↓
ProviderRepository
    ↓
LibraryService
    ↓
UI (via State Management)
```

### Recommendation Flow

```
PlaybackHistory → AnalyticsService
    ↓
RecommendationEngine
    ↓
[Frequency Analysis | Recency Analysis | Skip Rate Analysis]
    ↓
Generated Playlist
    ↓
UI (Home Screen)
```

## Detailed Module Specifications

### 1. Audio Engine Module (`lib/core/audio/`)

**Key Classes:**

- `AudioEngine`: Main interface for playback control
- `PlaybackQueue`: Queue management with gapless support
- `AudioEffects`: EQ, ReplayGain, Crossfade management
- `GaplessPlayer`: Handles gapless transitions
- `ReplayGainProcessor`: Track/album gain normalization

**Platform Channel Interface:**

```dart
// MethodChannel methods
- play(String uri)
- pause()
- resume()
- seek(int positionMs)
- setVolume(double volume)
- setEQ(List<EQBand> bands)
- setReplayGain(double gain)
- enableCrossfade(bool enabled, int durationMs)
- setSampleRate(int sampleRate)

// EventChannel events
- playbackState (playing, paused, stopped, error)
- position (current position in ms)
- audioSessionId (for visualizer)
- audioData (FFT data for visualizer)
```

**Native Implementation:**

- ExoPlayer with custom `AudioProcessor` for EQ/DSP
- Separate audio session for visualizer
- Crossfade via dual ExoPlayer instances or custom renderer

## Audio Engine - Detailed Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER LAYER                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  AudioEngine (Facade)                                     │   │
│  │  - Playback control                                       │   │
│  │  - Queue management                                       │   │
│  │  - State synchronization                                  │   │
│  └──────────────────┬───────────────────────────────────────┘   │
│                     │ Platform Channel (MethodChannel)            │
└─────────────────────┼─────────────────────────────────────────────┘
                      │
┌─────────────────────▼─────────────────────────────────────────────┐
│                    NATIVE ANDROID LAYER                          │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  ExoPlayerAudioEngine                                      │  │
│  │  - ExoPlayer instance management                           │  │
│  │  - Lifecycle handling                                      │  │
│  │  - Audio session management                                │  │
│  └──────────────────┬───────────────────────────────────────┘  │
│                     │                                            │
│  ┌──────────────────▼───────────────────────────────────────┐  │
│  │  Decoder Pipeline                                          │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                │  │
│  │  │Format    │→ │Decoder   │→ │PCM       │                │  │
│  │  │Detector  │  │(ExoPlayer)│ │Output    │                │  │
│  │  └──────────┘  └──────────┘  └────┬─────┘                │  │
│  └──────────────────────────────────┼───────────────────────┘  │
│                                     │                            │
│  ┌──────────────────────────────────▼───────────────────────┐  │
│  │  DSP Processing Chain (AudioProcessor)                    │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │ReplayGain    │→ │Parametric EQ │→ │Crossfade    │   │  │
│  │  │Processor     │  │(Multi-band)  │  │Mixer        │   │  │
│  │  └──────────────┘  └──────────────┘  └──────┬───────┘   │  │
│  └──────────────────────────────────────────────┼───────────┘  │
│                                                 │                │
│  ┌──────────────────────────────────────────────▼───────────┐  │
│  │  Audio Output                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐                     │  │
│  │  │AudioTrack    │  │Visualizer    │                     │  │
│  │  │(Playback)    │  │Tap (FFT)     │                     │  │
│  │  └──────────────┘  └──────────────┘                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  GaplessPlayer (Dual ExoPlayer)                            │  │
│  │  - Pre-buffering next track                               │  │
│  │  - Seamless transition                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

### Decoder Pipeline

#### Format Detection and Decoding

**Format Support:**

- MP3: Built-in ExoPlayer support
- M4A/AAC: Built-in ExoPlayer support
- FLAC: Via `extension-flac`
- WAV: Built-in ExoPlayer support
- Opus: Via `extension-opus`
- OGG: Via `extension-ogg`

**Pipeline Stages:**

```
1. URI Resolution
   - Input: URI (file://, http://, content://)
   - Resolve to DataSource (FileDataSource, HttpDataSource, etc.)
   ↓
2. Format Detection
   - ExoPlayer MediaMetadataRetriever
   - MIME type detection
   - Container format identification
   ↓
3. Decoder Selection
   - ExoPlayer Renderer selection
   - Audio renderer for audio tracks
   - Format-specific decoder initialization
   ↓
4. Decoding
   - Format decoder extracts PCM samples
   - Sample rate conversion (if needed)
   - Channel configuration (mono, stereo, multi-channel)
   ↓
5. PCM Output
   - 16-bit or 32-bit float PCM
   - Standardized sample rate (configurable)
   - Standardized channel layout
```

#### Decoder Configuration

**Sample Rate Handling:**

- **Input**: Variable (44.1kHz, 48kHz, 96kHz, etc.)
- **Processing**: Standardized to configured rate (default: 48kHz)
- **Output**: Matches processing rate
- **Resampling**: Via ExoPlayer's AudioProcessor (high-quality)

**Channel Handling:**

- **Input**: Variable (mono, stereo, 5.1, etc.)
- **Processing**: Downmix to stereo for DSP
- **Output**: Stereo (Android AudioTrack limitation)

**Bit Depth:**

- **Input**: Variable (16-bit, 24-bit, 32-bit)
- **Processing**: 32-bit float (for DSP precision)
- **Output**: 16-bit (Android AudioTrack standard)

#### Native Implementation

```kotlin
class ExoPlayerAudioEngine {
    private val exoPlayer: ExoPlayer
    
    fun prepareTrack(uri: String) {
        val mediaItem = MediaItem.fromUri(uri)
        
        // Configure renderers
        val renderersFactory = DefaultRenderersFactory(context)
            .setExtensionRendererMode(
                DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER
            )
        
        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.prepare()
    }
    
    // Format detection happens automatically in ExoPlayer
    // Decoder selection based on MIME type
}
```

### DSP Processing Chain

#### Processing Order

The DSP chain processes audio in a specific order to optimize quality and performance:

```
PCM Input (from decoder)
    ↓
1. ReplayGain Processor
   - Apply track/album gain
   - Prevent clipping
   - Normalize volume
    ↓
2. Parametric EQ
   - Multi-band filtering
   - Frequency shaping
   - Preset application
    ↓
3. Crossfade Mixer (if enabled)
   - Mix current and next track
   - Apply fade curves
   - Transition management
    ↓
4. Preamp + Limiter
   - Final gain adjustment
   - Clipping prevention
   - Output level control
    ↓
PCM Output (to AudioTrack)
```

#### AudioProcessor Integration

ExoPlayer's `AudioProcessor` interface allows custom DSP processing:

```kotlin
interface AudioProcessor {
    fun configure(
        inputAudioFormat: AudioFormat
    ): AudioFormat
    
    fun process(inputBuffer: ByteBuffer): Boolean
    
    fun flush()
    
    fun reset()
}
```

**Processing Characteristics:**

- **Thread**: Audio thread (real-time, low latency)
- **Buffer Size**: Variable (typically 1024-4096 samples)
- **Latency**: Must be minimal (< 50ms total)
- **Blocking**: Never block (causes audio dropouts)

### Parametric EQ Implementation Strategy

#### Architecture Options

**Option 1: ExoPlayer AudioProcessor (Recommended for MVP)**

- **Pros**: Native integration, no JNI overhead
- **Cons**: Limited to ExoPlayer's processing model
- **Performance**: Good (Kotlin/Java)
- **Complexity**: Medium

**Option 2: JNI + Native Library (Recommended for Advanced)**

- **Pros**: Maximum performance, SIMD optimization
- **Cons**: Complex, requires C/C++ code
- **Performance**: Excellent (native code)
- **Complexity**: High

**Option 3: Hybrid Approach**

- **Pros**: Best of both worlds
- **Cons**: Most complex
- **Performance**: Excellent
- **Complexity**: Very High

#### Implementation: ExoPlayer AudioProcessor

**EQ Band Structure:**

```kotlin
data class EQBand(
    val frequency: Float,  // Hz (20 - 20000)
    val gain: Float,       // dB (-12 to +12)
    val q: Float           // Quality factor (0.1 - 10.0)
)

class ParametricEQProcessor : AudioProcessor {
    private var bands: List<EQBand> = emptyList()
    private var preamp: Float = 0.0f
    private var limiterEnabled: Boolean = true
    
    // Biquad filter implementation for each band
    private val filters: MutableList<BiquadFilter> = mutableListOf()
    
    override fun process(inputBuffer: ByteBuffer): Boolean {
        // Convert ByteBuffer to float array
        val samples = bufferToFloatArray(inputBuffer)
        
        // Apply each EQ band
        bands.forEachIndexed { index, band ->
            filters[index].process(samples)
        }
        
        // Apply preamp
        samples.forEachIndexed { i, sample ->
            samples[i] = sample * preampGain
        }
        
        // Apply limiter (prevent clipping)
        if (limiterEnabled) {
            limitSamples(samples)
        }
        
        // Convert back to ByteBuffer
        floatArrayToBuffer(samples, inputBuffer)
        
        return true
    }
}
```

**Biquad Filter Implementation:**

```kotlin
class BiquadFilter {
    // Second-order IIR filter
    // Supports: Low-pass, High-pass, Band-pass, Notch, Peak, Shelf
    
    private var b0: Float = 1.0f
    private var b1: Float = 0.0f
    private var b2: Float = 0.0f
    private var a1: Float = 0.0f
    private var a2: Float = 0.0f
    
    // State variables (for filter history)
    private var x1: Float = 0.0f
    private var x2: Float = 0.0f
    private var y1: Float = 0.0f
    private var y2: Float = 0.0f
    
    fun configurePeak(frequency: Float, gain: Float, q: Float, sampleRate: Float) {
        // Calculate filter coefficients
        val w = 2.0 * PI * frequency / sampleRate
        val cosw = cos(w).toFloat()
        val sinw = sin(w).toFloat()
        val alpha = sinw / (2.0 * q).toFloat()
        val A = pow(10.0, gain / 40.0).toFloat()
        val S = 1.0f  // Shelf slope
        val beta = sqrt(A) / q
        
        // ... coefficient calculation ...
    }
    
    fun process(samples: FloatArray) {
        samples.forEachIndexed { i, sample ->
            val output = b0 * sample + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            
            // Update state
            x2 = x1
            x1 = sample
            y2 = y1
            y1 = output
            
            samples[i] = output
        }
    }
}
```

**Performance Optimizations:**

- **SIMD**: Use vectorized operations where possible
- **Caching**: Cache filter coefficients (recalculate only when bands change)
- **Early Exit**: Skip processing if all bands are 0dB
- **Batch Processing**: Process multiple samples in loops

**EQ Preset Management:**

```kotlin
data class EQPreset(
    val id: String,
    val name: String,
    val bands: List<EQBand>,
    val preamp: Float = 0.0f
)

class EQPresetManager {
    fun loadPreset(presetId: String): EQPreset
    fun savePreset(preset: EQPreset)
    fun getDefaultPresets(): List<EQPreset>
}
```

### ReplayGain Processor

#### Implementation

```kotlin
class ReplayGainProcessor : AudioProcessor {
    private var trackGain: Float = 0.0f  // dB
    private var albumGain: Float = 0.0f  // dB
    private var mode: ReplayGainMode = ReplayGainMode.TRACK
    
    enum class ReplayGainMode {
        TRACK,      // Use track gain
        ALBUM,      // Use album gain
        DISABLED    // No gain adjustment
    }
    
    override fun process(inputBuffer: ByteBuffer): Boolean {
        if (mode == ReplayGainMode.DISABLED) return false
        
        val gain = when (mode) {
            ReplayGainMode.TRACK -> trackGain
            ReplayGainMode.ALBUM -> albumGain
            ReplayGainMode.DISABLED -> 0.0f
        }
        
        if (gain == 0.0f) return false
        
        // Convert to linear gain
        val linearGain = pow(10.0, gain / 20.0).toFloat()
        
        // Apply gain to samples
        val samples = bufferToFloatArray(inputBuffer)
        samples.forEachIndexed { i, sample ->
            samples[i] = sample * linearGain
        }
        floatArrayToBuffer(samples, inputBuffer)
        
        return true
    }
}
```

#### Gain Calculation

**Preventing Clipping:**

```kotlin
fun applyReplayGainWithLimiting(
    samples: FloatArray,
    gainDb: Float,
    limiterThreshold: Float = 0.95f
) {
    val linearGain = pow(10.0, gainDb / 20.0).toFloat()
    var maxSample = 0.0f
    
    // First pass: find maximum
    samples.forEach { sample ->
        val amplified = sample * linearGain
        maxSample = maxOf(maxSample, abs(amplified))
    }
    
    // Second pass: apply gain with limiting if needed
    if (maxSample > limiterThreshold) {
        val limitingGain = limiterThreshold / maxSample
        samples.forEachIndexed { i, sample ->
            samples[i] = (sample * linearGain * limitingGain).coerceIn(-1.0f, 1.0f)
        }
    } else {
        samples.forEachIndexed { i, sample ->
            samples[i] = (sample * linearGain).coerceIn(-1.0f, 1.0f)
        }
    }
}
```

#### Metadata Extraction

**Reading ReplayGain Tags:**

```kotlin
class ReplayGainReader {
    fun extractReplayGain(uri: String): ReplayGainInfo {
        // Use ExoPlayer's MetadataRetriever or tag library
        // Extract from:
        // - MP3: ID3v2 tags (TXXX frames)
        // - FLAC: VORBIS_COMMENT blocks
        // - M4A: iTunes tags
        
        return ReplayGainInfo(
            trackGain = extractTag("REPLAYGAIN_TRACK_GAIN"),
            trackPeak = extractTag("REPLAYGAIN_TRACK_PEAK"),
            albumGain = extractTag("REPLAYGAIN_ALBUM_GAIN"),
            albumPeak = extractTag("REPLAYGAIN_ALBUM_PEAK")
        )
    }
}
```

### Crossfade Implementation

#### Dual ExoPlayer Approach

**Architecture:**

```
┌─────────────────┐         ┌─────────────────┐
│  ExoPlayer A    │         │  ExoPlayer B    │
│  (Current Track)│         │  (Next Track)   │
└────────┬────────┘         └────────┬─────────┘
         │                         │
         │                         │
    ┌────▼─────────────────────────▼────┐
    │     Crossfade Mixer               │
    │  - Fade out: Track A               │
    │  - Fade in: Track B                │
    │  - Mix samples                     │
    └────────────┬───────────────────────┘
                 │
         ┌───────▼────────┐
         │  Audio Output  │
         └────────────────┘
```

**Implementation:**

```kotlin
class CrossfadeMixer : AudioProcessor {
    private var enabled: Boolean = false
    private var durationMs: Int = 3000  // 3 seconds
    private var fadePosition: Long = 0   // Current position in fade
    private var nextTrackPlayer: ExoPlayer? = null
    
    override fun process(inputBuffer: ByteBuffer): Boolean {
        if (!enabled || nextTrackPlayer == null) return false
        
        val currentSamples = bufferToFloatArray(inputBuffer)
        val nextSamples = getNextTrackSamples(inputBuffer.remaining())
        
        // Calculate fade curves
        val fadeOut = calculateFadeOut(fadePosition, durationMs)
        val fadeIn = calculateFadeIn(fadePosition, durationMs)
        
        // Mix samples
        currentSamples.forEachIndexed { i, sample ->
            currentSamples[i] = sample * fadeOut + nextSamples[i] * fadeIn
        }
        
        fadePosition += currentSamples.size
        
        floatArrayToBuffer(currentSamples, inputBuffer)
        return true
    }
    
    private fun calculateFadeOut(position: Long, duration: Int): Float {
        val progress = (position / duration.toFloat()).coerceIn(0.0f, 1.0f)
        // Linear fade: 1.0 → 0.0
        return 1.0f - progress
        // Or exponential: smoother
        // return exp(-progress * 5.0f)
    }
    
    private fun calculateFadeIn(position: Long, duration: Int): Float {
        val progress = (position / duration.toFloat()).coerceIn(0.0f, 1.0f)
        // Linear fade: 0.0 → 1.0
        return progress
    }
}
```

**Gapless + Crossfade Coordination:**

```kotlin
class GaplessPlayer {
    private val currentPlayer: ExoPlayer
    private val nextPlayer: ExoPlayer
    private val crossfadeMixer: CrossfadeMixer
    
    fun prepareNextTrack(uri: String) {
        // Pre-buffer next track
        nextPlayer.setMediaItem(MediaItem.fromUri(uri))
        nextPlayer.prepare()
        
        // Wait for buffering to complete
        // Then enable crossfade when current track nears end
    }
    
    fun transition() {
        // Start crossfade
        crossfadeMixer.enable(durationMs = 3000)
        
        // When fade completes:
        // - Swap players (next becomes current)
        // - Reset crossfade mixer
        // - Prepare new next track
    }
}
```

### Visualizer Tap (.milk Preset Integration)

#### Audio Data Extraction

**FFT Analysis:**

```kotlin
class VisualizerTap : AudioProcessor {
    private var fftSize: Int = 2048
    private var fftData: FloatArray = FloatArray(fftSize / 2)
    private var audioSessionId: Int = -1
    private var visualizer: Visualizer? = null
    
    override fun process(inputBuffer: ByteBuffer): Boolean {
        // Extract audio samples
        val samples = bufferToFloatArray(inputBuffer)
        
        // Perform FFT
        val fft = FFT(fftSize)
        val fftResult = fft.forward(samples)
        
        // Convert to magnitude spectrum
        fftData = calculateMagnitudeSpectrum(fftResult)
        
        // Broadcast to visualizer engine
        broadcastFFTData(fftData)
        
        return false  // Don't modify audio
    }
    
    private fun calculateMagnitudeSpectrum(fftResult: ComplexArray): FloatArray {
        val magnitude = FloatArray(fftSize / 2)
        for (i in 0 until fftSize / 2) {
            val real = fftResult.real[i]
            val imag = fftResult.imag[i]
            magnitude[i] = sqrt(real * real + imag * imag).toFloat()
        }
        return magnitude
    }
}
```

**Alternative: Android Visualizer API**

```kotlin
class VisualizerTap {
    private var visualizer: Visualizer? = null
    
    fun attachToAudioSession(sessionId: Int) {
        visualizer = Visualizer(sessionId)
        visualizer?.captureSize = 2048
        visualizer?.setDataCaptureListener(
            object : Visualizer.OnDataCaptureListener {
                override fun onWaveFormDataCapture(
                    visualizer: Visualizer,
                    waveform: ByteArray,
                    samplingRate: Int
                ) {
                    // Waveform data
                }
                
                override fun onFftDataCapture(
                    visualizer: Visualizer,
                    fft: ByteArray,
                    samplingRate: Int
                ) {
                    // FFT data for visualizer
                    processFFTData(fft, samplingRate)
                }
            },
            Visualizer.getMaxCaptureRate() / 2,  // 30 FPS
            true,  // Waveform
            true   // FFT
        )
        visualizer?.enabled = true
    }
    
    fun processFFTData(fft: ByteArray, samplingRate: Int) {
        // Convert to float array
        val fftData = ByteArrayToFloatArray(fft)
        
        // Send to visualizer engine
        visualizerEngine.updateFFT(fftData, samplingRate)
    }
}
```

#### Integration with .milk Visualizer

**Data Flow:**

```
AudioProcessor (FFT) → VisualizerTap → VisualizerEngine → MilkRenderer
```

**VisualizerEngine Interface:**

```kotlin
class VisualizerEngine {
    fun updateFFT(fftData: FloatArray, sampleRate: Int) {
        // Update .milk preset variables
        milkRenderer.updateAudioData(fftData, sampleRate)
    }
}
```

### Gapless Playback Handling

#### ExoPlayer Gapless Support

**Built-in Gapless:**

- ExoPlayer supports gapless playback natively
- Requires proper encoding (no silence at track boundaries)
- Works best with formats that support gapless metadata:
                                - MP3: LAME/Xing headers
                                - FLAC: Padding metadata
                                - M4A: iTunes gapless info

**Implementation:**

```kotlin
class GaplessPlayer {
    private val exoPlayer: ExoPlayer
    
    fun playGapless(tracks: List<String>) {
        val mediaItems = tracks.map { MediaItem.fromUri(it) }
        
        // Use ExoPlayer's ConcatenatingMediaSource for gapless
        val concatenatingSource = ConcatenatingMediaSource(
            *mediaItems.map { 
                ProgressiveMediaSource.Factory(dataSourceFactory)
                    .createMediaSource(it)
            }.toTypedArray()
        )
        
        exoPlayer.setMediaSource(concatenatingSource)
        exoPlayer.prepare()
        exoPlayer.play()
    }
}
```

#### Custom Gapless with Pre-buffering

**Dual Player Approach:**

```kotlin
class GaplessPlayer {
    private val currentPlayer: ExoPlayer
    private val nextPlayer: ExoPlayer
    private var nextTrackUri: String? = null
    
    fun playTrack(uri: String) {
        if (currentPlayer.isPlaying) {
            // Pre-buffer next track
            nextTrackUri = uri
            nextPlayer.setMediaItem(MediaItem.fromUri(uri))
            nextPlayer.prepare()
        } else {
            // Play immediately
            currentPlayer.setMediaItem(MediaItem.fromUri(uri))
            currentPlayer.prepare()
            currentPlayer.play()
        }
    }
    
    fun onTrackEnd() {
        // Swap players
        val temp = currentPlayer
        currentPlayer = nextPlayer
        nextPlayer = temp
        
        // Start next track immediately (already buffered)
        currentPlayer.play()
        
        // Pre-buffer next track in queue
        prepareNextTrack()
    }
}
```

#### Gapless Metadata Detection

**Reading Gapless Info:**

```kotlin
class GaplessMetadataReader {
    data class GaplessInfo(
        val encoderDelay: Int,      // Samples to skip at start
        val encoderPadding: Int     // Samples to skip at end
    )
    
    fun readGaplessInfo(uri: String): GaplessInfo? {
        // MP3: Read LAME/Xing header
        // FLAC: Read PADDING block
        // M4A: Read iTunes gapless atoms
        
        return when (detectFormat(uri)) {
            Format.MP3 -> readMP3Gapless(uri)
            Format.FLAC -> readFLACGapless(uri)
            Format.M4A -> readM4AGapless(uri)
            else -> null
        }
    }
}
```

### Background Playback & Lifecycle Handling

#### Audio Focus Management

```kotlin
class AudioFocusManager {
    private val audioManager: AudioManager
    private var audioFocusRequest: AudioFocusRequest? = null
    
    fun requestAudioFocus(): Boolean {
        val focusRequest = AudioFocusRequest.Builder(AudioFocusRequest.AUDIOFOCUS_GAIN)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setOnAudioFocusChangeListener { focusChange ->
                when (focusChange) {
                    AudioManager.AUDIOFOCUS_LOSS -> {
                        // Pause playback
                        pause()
                    }
                    AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                        // Pause temporarily
                        pause()
                    }
                    AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                        // Lower volume
                        setVolume(0.3f)
                    }
                    AudioManager.AUDIOFOCUS_GAIN -> {
                        // Resume playback
                        resume()
                        setVolume(1.0f)
                    }
                }
            }
            .build()
        
        val result = audioManager.requestAudioFocus(focusRequest)
        return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }
    
    fun abandonAudioFocus() {
        audioFocusRequest?.let {
            audioManager.abandonAudioFocusRequest(it)
        }
    }
}
```

#### Media Session Integration

```kotlin
class MediaSessionManager {
    private var mediaSession: MediaSession? = null
    
    fun initialize(context: Context) {
        mediaSession = MediaSession(context, "Musicrr")
        
        val callback = object : MediaSession.Callback() {
            override fun onPlay() {
                audioEngine.play()
            }
            
            override fun onPause() {
                audioEngine.pause()
            }
            
            override fun onSkipToNext() {
                audioEngine.next()
            }
            
            override fun onSkipToPrevious() {
                audioEngine.previous()
            }
            
            override fun onSeekTo(pos: Long) {
                audioEngine.seekTo(pos.toInt())
            }
        }
        
        mediaSession?.setCallback(callback)
        mediaSession?.isActive = true
    }
    
    fun updateMetadata(track: Track) {
        val metadata = MediaMetadata.Builder()
            .putString(MediaMetadata.METADATA_KEY_TITLE, track.title)
            .putString(MediaMetadata.METADATA_KEY_ARTIST, track.artist)
            .putString(MediaMetadata.METADATA_KEY_ALBUM, track.album)
            .putLong(MediaMetadata.METADATA_KEY_DURATION, track.duration)
            .build()
        
        mediaSession?.setMetadata(metadata)
    }
}
```

#### Foreground Service

```kotlin
class AudioPlaybackService : Service() {
    private val notificationManager: NotificationManager
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())
        return START_STICKY
    }
    
    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Now Playing")
            .setContentText("${track.title} - ${track.artist}")
            .setSmallIcon(R.drawable.ic_music_note)
            .setLargeIcon(coverArtBitmap)
            .addAction(R.drawable.ic_skip_previous, "Previous", previousPendingIntent)
            .addAction(
                if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play,
                if (isPlaying) "Pause" else "Play",
                playPausePendingIntent
            )
            .addAction(R.drawable.ic_skip_next, "Next", nextPendingIntent)
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setShowActionsInCompactView(0, 1, 2)
            )
            .build()
    }
}
```

#### Lifecycle Handling

**Activity Lifecycle:**

```kotlin
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Audio engine initialized via platform channel
    }
    
    override fun onPause() {
        super.onPause()
        // Audio continues playing in background
        // Update notification
    }
    
    override fun onResume() {
        super.onResume()
        // Sync UI with current playback state
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Don't destroy audio engine (service handles it)
    }
}
```

**Service Lifecycle:**

```kotlin
class AudioPlaybackService : Service() {
    override fun onCreate() {
        super.onCreate()
        // Initialize audio engine
        audioEngine.initialize()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Clean up audio engine
        audioEngine.release()
    }
}
```

### Native vs Flutter Responsibilities

#### Flutter Layer Responsibilities

**AudioEngine (Flutter):**

- High-level playback control (play, pause, seek)
- Queue management
- State synchronization
- UI state updates
- Error handling and user feedback
- Settings management (EQ presets, ReplayGain mode)

**PlaybackQueue (Flutter):**

- Track queue management
- Shuffle/repeat logic
- Queue persistence
- Next/previous track selection

**AudioEffects (Flutter):**

- EQ preset management
- ReplayGain mode selection
- Crossfade configuration
- Settings persistence

#### Native Layer Responsibilities

**ExoPlayerAudioEngine (Native):**

- Low-level audio playback
- Format decoding
- Audio session management
- Lifecycle handling
- Audio focus management
- Media session integration

**DSP Processors (Native):**

- Real-time audio processing
- EQ filtering
- ReplayGain application
- Crossfade mixing
- Performance optimization

**VisualizerTap (Native):**

- FFT analysis
- Audio data extraction
- Visualizer engine communication

### Performance Considerations

#### Audio Thread Constraints

**Critical Requirements:**

- **Latency**: Total processing must be < 50ms
- **Blocking**: Never block audio thread
- **Memory**: Minimize allocations in processing loop
- **CPU**: Efficient algorithms (O(n) or better)

**Optimization Strategies:**

1. **Pre-allocate buffers**: Reuse ByteBuffer/FloatArray
2. **Cache calculations**: Filter coefficients, gain values
3. **Early exit**: Skip processing if effect disabled
4. **SIMD**: Use vectorized operations (if JNI)
5. **Batch processing**: Process multiple samples in loops

#### Memory Management

**Buffer Management:**

```kotlin
class AudioBufferPool {
    private val bufferPool = ArrayDeque<FloatArray>()
    
    fun acquire(size: Int): FloatArray {
        return bufferPool.removeFirstOrNull()?.takeIf { it.size >= size }
            ?: FloatArray(size)
    }
    
    fun release(buffer: FloatArray) {
        if (bufferPool.size < MAX_POOL_SIZE) {
            bufferPool.addLast(buffer)
        }
    }
}
```

**Garbage Collection:**

- Minimize object creation in audio thread
- Reuse objects where possible
- Use object pools for frequently allocated objects

#### CPU Optimization

**Algorithm Selection:**

- **FFT**: Use efficient FFT library (FFTW, KissFFT)
- **Filtering**: Biquad filters (efficient, low latency)
- **Mixing**: Simple addition (very fast)

**Profiling:**

- Use Android Profiler to identify bottlenecks
- Measure processing time per buffer
- Optimize hot paths

### Error Handling

#### Decoder Errors

```kotlin
class ExoPlayerAudioEngine {
    private val playerListener = object : Player.Listener {
        override fun onPlayerError(error: PlaybackException) {
            when (error.errorCode) {
                PlaybackException.ERROR_CODE_IO_NETWORK_OFFLINE -> {
                    // Network error
                    notifyError("Network unavailable")
                }
                PlaybackException.ERROR_CODE_IO_BAD_HTTP_STATUS -> {
                    // HTTP error
                    notifyError("Server error: ${error.message}")
                }
                PlaybackException.ERROR_CODE_PARSING_CONTAINER_MALFORMED -> {
                    // Corrupt file
                    notifyError("File format error")
                }
                PlaybackException.ERROR_CODE_DECODER_INIT_FAILED -> {
                    // Decoder error
                    notifyError("Audio format not supported")
                }
                else -> {
                    notifyError("Playback error: ${error.message}")
                }
            }
        }
    }
}
```

#### DSP Processing Errors

```kotlin
class ParametricEQProcessor : AudioProcessor {
    override fun process(inputBuffer: ByteBuffer): Boolean {
        try {
            // Processing code
            return true
        } catch (e: Exception) {
            // Log error
            Log.e("ParametricEQ", "Processing error", e)
            // Bypass processing (return false = no modification)
            return false
        }
    }
}
```

#### Recovery Strategies

**Automatic Recovery:**

- Retry failed network requests
- Fallback to cached content
- Skip corrupted tracks
- Reset DSP on error

**User Notification:**

- Show error messages in UI
- Log errors for debugging
- Provide retry options

### Extensibility

#### Plugin Architecture for DSP

```kotlin
interface AudioEffect {
    fun process(samples: FloatArray, sampleRate: Int): FloatArray
    fun configure(config: EffectConfig)
    fun reset()
}

class AudioEffectChain {
    private val effects: MutableList<AudioEffect> = mutableListOf()
    
    fun addEffect(effect: AudioEffect) {
        effects.add(effect)
    }
    
    fun process(samples: FloatArray, sampleRate: Int): FloatArray {
        var processed = samples
        effects.forEach { effect ->
            processed = effect.process(processed, sampleRate)
        }
        return processed
    }
}
```

#### Custom Format Support

**Adding New Decoders:**

1. Implement ExoPlayer `Renderer`
2. Register in `RenderersFactory`
3. Add format detection logic

**Example:**

```kotlin
class CustomFormatRenderer : Renderer {
    // Implement renderer interface
}

class CustomRenderersFactory : RenderersFactory {
    override fun createRenderers(
        eventHandler: Handler,
        videoRendererEventListener: VideoRendererEventListener,
        audioRendererEventListener: AudioRendererEventListener,
        textOutput: TextOutput,
        metadataOutput: MetadataOutput
    ): Array<Renderer> {
        return arrayOf(
            CustomFormatRenderer(),
            // ... other renderers
        )
    }
}
```

#### Configuration System

**Runtime Configuration:**

```kotlin
data class AudioEngineConfig(
    val sampleRate: Int = 48000,
    val bufferSize: Int = 4096,
    val dspEnabled: Boolean = true,
    val gaplessEnabled: Boolean = true,
    val crossfadeEnabled: Boolean = false,
    val crossfadeDuration: Int = 3000
)

class ExoPlayerAudioEngine {
    fun configure(config: AudioEngineConfig) {
        // Apply configuration
        // Reinitialize if needed
    }
}
```

### 2. Provider System (`lib/core/providers/`)

**Unified Interface:**

```dart
abstract class MediaProvider {
  Future<List<Artist>> getArtists();
  Future<List<Album>> getAlbums();
  Future<List<Song>> getSongs();
  Future<List<Playlist>> getPlaylists();
  Future<Stream<List<int>>> getAudioStream(String songId);
  Future<String> getCoverArtUrl(String albumId);
}
```

**Provider Implementations:**

- `LocalProvider`: File system scanning, metadata extraction
- `HttpProvider`: Simple HTTP streaming
- `WebDAVProvider`: WebDAV protocol support
- `SMBProvider`: SMB/CIFS protocol support
- `SubsonicProvider`: Subsonic API client
- `JellyfinProvider`: Jellyfin API client

**Provider Repository:**

- Manages multiple providers
- Unified library view across providers
- Caching layer for metadata

### 3. Recommendation Engine (`lib/core/recommendations/`)

**Analytics Collection:**

- Play frequency tracking
- Recency tracking (last played)
- Skip rate calculation
- Play duration analysis

**Algorithm:**

- Weighted scoring based on:
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Play frequency (higher = better)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Recency (more recent = better)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Skip rate (lower = better)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Genre/artist similarity
- Auto-generated playlists:
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - "Recently Played"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - "Most Played"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - "Discover Weekly" (local algorithm)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - "On Repeat"

### 4. Now Playing Screen (`lib/features/now_playing/`)

**Modular Components:**

- `CoverArtWidget`: Album art display
- `ProgressSliderWidget`: Customizable progress slider
- `ControlButtonsWidget`: Play/pause/skip controls
- `VisualizerWidget`: .milk visualizer display
- `LyricsOverlayWidget`: Lyrics overlay

**Background Modes:**

- `SolidColorBackground`: Static color
- `DynamicColorBackground`: Extracted from album art
- `GradientBackground`: Gradient from album art
- `AnimatedGradientBackground`: Animated gradient

**Progress Slider Types:**

- Simple: Basic Material 3 slider
- Material3: Enhanced Material 3 design
- AnimatedWave: Waveform visualization

## Now Playing Customization System - Detailed Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│              Now Playing Screen                               │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Background Layer                                      │  │
│  │  (Solid/Dynamic/Gradient/Animated)                    │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Slot-Based Layout System                              │  │
│  │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐              │  │
│  │  │Slot 1│  │Slot 2│  │Slot 3│  │Slot 4│              │  │
│  │  └──────┘  └──────┘  └──────┘  └──────┘              │  │
│  │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐              │  │
│  │  │Slot 5│  │Slot 6│  │Slot 7│  │Slot 8│              │  │
│  │  └──────┘  └──────┘  └──────┘  └──────┘              │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Component Library                                     │  │
│  │  (CoverArt, Progress, Controls, Visualizer, Lyrics)    │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Preset System                                         │  │
│  │  (Save, Load, Apply, Per-Source)                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Modular Layout Concept

#### Slot-Based System

**Layout Structure:**

The Now Playing screen uses a grid-based slot system where components can be placed in predefined slots. Each slot has:

- **Position**: Grid coordinates (row, column)
- **Size**: Span (1x1, 2x1, 1x2, 2x2, etc.)
- **Component**: Widget instance or null (empty slot)
- **Constraints**: Minimum/maximum size, allowed components

**Grid Definition:**

```dart
class NowPlayingLayout {
  static const int gridRows = 6;
  static const int gridColumns = 4;
  static const double slotAspectRatio = 1.0;
  
  final List<LayoutSlot> slots;
  
  LayoutSlot? getSlotAt(int row, int column) {
    return slots.firstWhere(
      (slot) => slot.row == row && slot.column == column,
      orElse: () => null,
    );
  }
}
```

**Slot Model:**

```dart
class LayoutSlot {
  final int row;
  final int column;
  final int rowSpan;
  final int columnSpan;
  final String? componentId;  // null if empty
  final Map<String, dynamic> componentConfig;
  
  // Constraints
  final List<String> allowedComponents;
  final SizeConstraints? sizeConstraints;
  
  // Visual properties
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
}
```

#### Component Types

**Available Components:**

1. **CoverArtComponent**

            - Displays album art
            - Supports: Square, Circle, Rounded rectangle
            - Animations: Rotation, Scale, Fade
            - Sizes: 1x1, 2x2, 3x3, 4x4

2. **ProgressSliderComponent**

            - Progress bar/slider
            - Variants: Simple, Material3, AnimatedWave
            - Sizes: 4x1 (full width), 2x1 (half width)

3. **ControlButtonsComponent**

            - Play/pause, previous, next, shuffle, repeat
            - Layout: Horizontal, Vertical, Grid
            - Sizes: 4x1, 2x2, 4x2

4. **TrackInfoComponent**

            - Title, artist, album
            - Layout: Stacked, Inline, Compact
            - Sizes: 2x1, 4x1, 2x2

5. **VisualizerComponent**

            - .milk visualizer display
            - Sizes: 2x2, 4x2, 4x4 (full screen)

6. **LyricsComponent**

            - Synced/unsynced lyrics
            - Overlay mode or dedicated slot
            - Sizes: 2x2, 4x2, 4x4

7. **QueuePreviewComponent**

            - Next tracks preview
            - Sizes: 2x2, 4x2

8. **MetadataComponent**

            - Genre, year, bitrate, etc.
            - Sizes: 2x1, 4x1

**Component Interface:**

```dart
abstract class NowPlayingComponent {
  final String id;
  final String type;
  final Map<String, dynamic> config;
  
  Widget build(BuildContext context, NowPlayingState state);
  
  // Constraints
  List<SizeOption> getSupportedSizes();
  bool canResizeTo(int rowSpan, int columnSpan);
  
  // Configuration
  Widget buildConfigPanel();
  Map<String, dynamic> getDefaultConfig();
}
```

### Slot-Based Rendering

#### Layout Engine

**Rendering Pipeline:**

```dart
class NowPlayingLayoutEngine {
  Widget buildLayout(NowPlayingLayout layout, NowPlayingState state) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: NowPlayingLayout.gridColumns,
        childAspectRatio: NowPlayingLayout.slotAspectRatio,
      ),
      itemCount: layout.slots.length,
      itemBuilder: (context, index) {
        final slot = layout.slots[index];
        return _buildSlot(slot, state);
      },
    );
  }
  
  Widget _buildSlot(LayoutSlot slot, NowPlayingState state) {
    if (slot.componentId == null) {
      return _buildEmptySlot(slot);
    }
    
    final component = _getComponent(slot.componentId!);
    return Container(
      padding: slot.padding,
      decoration: BoxDecoration(
        borderRadius: slot.borderRadius,
      ),
      child: component.build(context, state),
    );
  }
}
```

#### Drag-and-Drop System

**Component Rearrangement:**

```dart
class NowPlayingDragHandler extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return DragTarget<ComponentDragData>(
      onAccept: (data) {
        _handleDrop(data, targetSlot);
      },
      builder: (context, candidateData, rejectedData) {
        return _buildDropZone();
      },
    );
  }
}

class ComponentDragData {
  final String componentId;
  final LayoutSlot sourceSlot;
  final NowPlayingComponent component;
}
```

**Drag-and-Drop Flow:**

1. User long-presses component
2. Component enters drag mode (elevated, semi-transparent)
3. User drags to target slot
4. System validates drop (size constraints, component compatibility)
5. If valid: swap/move component, update layout
6. Save layout changes

**Validation Rules:**

```dart
class LayoutValidator {
  static bool canPlaceComponent(
    LayoutSlot targetSlot,
    NowPlayingComponent component,
    int rowSpan,
    int columnSpan,
  ) {
    // Check size constraints
    if (!component.canResizeTo(rowSpan, columnSpan)) {
      return false;
    }
    
    // Check slot availability
    if (!_isSlotAvailable(targetSlot, rowSpan, columnSpan)) {
      return false;
    }
    
    // Check component compatibility
    if (!targetSlot.allowedComponents.contains(component.type)) {
      return false;
    }
    
    return true;
  }
}
```

### Preset System

#### Preset Model

**Preset Structure:**

```dart
class NowPlayingPreset {
  final String id;
  final String name;
  final String? description;
  final String? icon;  // Asset path or emoji
  final NowPlayingLayout layout;
  final BackgroundConfig background;
  final Map<String, dynamic> themeOverrides;
  final DateTime createdAt;
  final DateTime? lastModified;
  
  // Scope
  final PresetScope scope;  // Global, PerProvider, PerAlbum
  final String? sourceId;    // Provider ID or album ID
}

enum PresetScope {
  global,      // Applies to all sources
  perProvider, // Applies to specific provider
  perAlbum,    // Applies to specific album
}
```

**Background Configuration:**

```dart
class BackgroundConfig {
  final BackgroundType type;
  final Map<String, dynamic> config;
  
  // For SolidColorBackground
  final Color? color;
  
  // For DynamicColorBackground
  final ColorExtractionMode? extractionMode;
  
  // For GradientBackground
  final List<Color>? gradientColors;
  final GradientDirection? direction;
  
  // For AnimatedGradientBackground
  final AnimationConfig? animation;
}

enum BackgroundType {
  solid,
  dynamic,      // From album art
  gradient,     // From album art
  animatedGradient,
}
```

#### Preset Management

**Preset Repository:**

```dart
class NowPlayingPresetRepository {
  Future<List<NowPlayingPreset>> getAllPresets();
  Future<NowPlayingPreset?> getPreset(String id);
  Future<NowPlayingPreset?> getActivePreset(String? sourceId);
  Future<void> savePreset(NowPlayingPreset preset);
  Future<void> deletePreset(String id);
  Future<void> setActivePreset(String presetId, String? sourceId);
}
```

**Preset Selection Logic:**

```dart
class PresetSelector {
  Future<NowPlayingPreset> selectPreset(String? sourceId, String? albumId) async {
    // Priority order:
    // 1. Per-album preset (if albumId provided)
    // 2. Per-provider preset (if sourceId provided)
    // 3. Global preset
    
    if (albumId != null) {
      final albumPreset = await repository.getPresetForAlbum(albumId);
      if (albumPreset != null) return albumPreset;
    }
    
    if (sourceId != null) {
      final providerPreset = await repository.getPresetForProvider(sourceId);
      if (providerPreset != null) return providerPreset;
    }
    
    return await repository.getGlobalPreset() ?? _getDefaultPreset();
  }
}
```

#### Preset Application

**Applying Presets:**

```dart
class NowPlayingScreen extends StatefulWidget {
  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  NowPlayingPreset? currentPreset;
  
  @override
  void initState() {
    super.initState();
    _loadPreset();
  }
  
  Future<void> _loadPreset() async {
    final sourceId = context.read<PlaybackStateProvider>().currentSourceId;
    final albumId = context.read<PlaybackStateProvider>().currentAlbumId;
    
    final preset = await presetSelector.selectPreset(sourceId, albumId);
    setState(() {
      currentPreset = preset;
    });
  }
  
  Future<void> _applyPreset(NowPlayingPreset preset) async {
    setState(() {
      currentPreset = preset;
    });
    
    // Apply background
    _applyBackground(preset.background);
    
    // Apply layout
    _applyLayout(preset.layout);
    
    // Apply theme overrides
    _applyThemeOverrides(preset.themeOverrides);
  }
}
```

### User Interaction: Rearranging Components

#### Edit Mode

**Entering Edit Mode:**

```dart
class NowPlayingScreen {
  bool _isEditMode = false;
  
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }
  
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isEditMode 
        ? _buildEditMode()
        : _buildNormalMode(),
      floatingActionButton: _isEditMode
        ? FloatingActionButton(
            onPressed: _saveLayout,
            child: Icon(Icons.check),
          )
        : FloatingActionButton(
            onPressed: _toggleEditMode,
            child: Icon(Icons.edit),
          ),
    );
  }
}
```

**Edit Mode UI:**

- Components show drag handles
- Empty slots show drop zones
- Component library panel (bottom sheet)
- Undo/redo functionality
- Reset to default option

**Component Library Panel:**

```dart
class ComponentLibraryPanel extends StatelessWidget {
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          children: [
            _buildComponentTile('Cover Art', CoverArtComponent()),
            _buildComponentTile('Progress Bar', ProgressSliderComponent()),
            _buildComponentTile('Controls', ControlButtonsComponent()),
            _buildComponentTile('Visualizer', VisualizerComponent()),
            _buildComponentTile('Lyrics', LyricsComponent()),
            // ... more components
          ],
        );
      },
    );
  }
  
  Widget _buildComponentTile(String name, NowPlayingComponent component) {
    return Draggable<ComponentDragData>(
      data: ComponentDragData(component: component),
      feedback: _buildComponentPreview(component),
      child: ListTile(
        leading: Icon(Icons.drag_handle),
        title: Text(name),
      ),
    );
  }
}
```

### User Interaction: Saving Presets

#### Preset Creation Flow

**Save Preset Dialog:**

```dart
class SavePresetDialog extends StatefulWidget {
  final NowPlayingLayout currentLayout;
  final BackgroundConfig currentBackground;
  
  @override
  State<SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends State<SavePresetDialog> {
  final _nameController = TextEditingController();
  PresetScope _selectedScope = PresetScope.global;
  String? _selectedSourceId;
  
  Future<void> _savePreset() async {
    final preset = NowPlayingPreset(
      id: Uuid().v4(),
      name: _nameController.text,
      layout: widget.currentLayout,
      background: widget.currentBackground,
      scope: _selectedScope,
      sourceId: _selectedSourceId,
    );
    
    await presetRepository.savePreset(preset);
    Navigator.pop(context, preset);
  }
  
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Save Preset'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Preset Name'),
          ),
          DropdownButton<PresetScope>(
            value: _selectedScope,
            items: [
              DropdownMenuItem(
                value: PresetScope.global,
                child: Text('Global'),
              ),
              DropdownMenuItem(
                value: PresetScope.perProvider,
                child: Text('Per Provider'),
              ),
              DropdownMenuItem(
                value: PresetScope.perAlbum,
                child: Text('Per Album'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedScope = value!;
              });
            },
          ),
          if (_selectedScope == PresetScope.perProvider)
            _buildProviderSelector(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _savePreset,
          child: Text('Save'),
        ),
      ],
    );
  }
}
```

#### Preset Management UI

**Presets Screen:**

```dart
class PresetsScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Now Playing Presets')),
      body: FutureBuilder<List<NowPlayingPreset>>(
        future: presetRepository.getAllPresets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final preset = snapshot.data![index];
              return PresetListTile(
                preset: preset,
                onTap: () => _applyPreset(preset),
                onDelete: () => _deletePreset(preset),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createPresetFromCurrent(),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### User Interaction: Applying Presets

#### Global Preset Application

**Settings Integration:**

```dart
class AppearanceSettingsScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Now Playing Preset'),
      subtitle: Text('Default layout and appearance'),
      trailing: Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PresetSelectorScreen(
              scope: PresetScope.global,
              onPresetSelected: (preset) {
                settingsRepository.setGlobalPreset(preset.id);
              },
            ),
          ),
        );
      },
    );
  }
}
```

#### Per-Source Preset Application

**Provider Settings:**

```dart
class ProviderSettingsScreen extends StatelessWidget {
  final String providerId;
  
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Now Playing Preset'),
      subtitle: Text('Custom layout for this provider'),
      trailing: Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PresetSelectorScreen(
              scope: PresetScope.perProvider,
              sourceId: providerId,
              onPresetSelected: (preset) {
                presetRepository.setPresetForProvider(
                  providerId,
                  preset.id,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
```

**Album-Specific Presets:**

```dart
class AlbumDetailScreen extends StatelessWidget {
  final Album album;
  
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Now Playing Preset'),
      subtitle: Text('Custom layout for this album'),
      trailing: Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PresetSelectorScreen(
              scope: PresetScope.perAlbum,
              sourceId: album.id,
              onPresetSelected: (preset) {
                presetRepository.setPresetForAlbum(
                  album.id,
                  preset.id,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
```

### Performance Considerations

#### Animation Performance

**Optimization Strategies:**

1. **Use RepaintBoundary:**
```dart
class AnimatedBackgroundWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return _buildAnimatedGradient();
        },
      ),
    );
  }
}
```

2. **Limit Animation Complexity:**

- Use simple transforms (translate, scale, rotate)
- Avoid complex shaders in animations
- Cache expensive computations

3. **Frame Rate Control:**
```dart
class AnimationController {
  static const double targetFPS = 60.0;
  
  void _updateAnimation() {
    // Limit to 60 FPS
    if (_lastFrameTime != null) {
      final delta = DateTime.now().difference(_lastFrameTime!);
      if (delta.inMilliseconds < (1000 / targetFPS)) {
        return;  // Skip frame
      }
    }
    _lastFrameTime = DateTime.now();
    // Update animation
  }
}
```


#### Visualizer Performance

**Optimization Strategies:**

1. **Texture Caching:**
```dart
class VisualizerWidget extends StatefulWidget {
  @override
  State<VisualizerWidget> createState() => _VisualizerWidgetState();
}

class _VisualizerWidgetState extends State<VisualizerWidget> {
  Texture? _cachedTexture;
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Texture(textureId: _cachedTexture?.id ?? 0),
    );
  }
}
```

2. **Frame Rate Limiting:**

- Limit visualizer updates to 30 FPS (sufficient for smooth animation)
- Skip frames if UI is not visible

3. **Memory Management:**
```dart
class VisualizerWidget extends StatefulWidget {
  @override
  void dispose() {
    _releaseTexture();
    super.dispose();
  }
  
  void _releaseTexture() {
    if (_textureId != null) {
      platformChannel.releaseTexture(_textureId!);
      _textureId = null;
    }
  }
}
```


#### Layout Rendering Performance

**Optimization Strategies:**

1. **Lazy Loading:**
```dart
class NowPlayingLayoutEngine {
  Widget buildLayout(NowPlayingLayout layout, NowPlayingState state) {
    return ListView.builder(
      itemCount: layout.slots.length,
      itemBuilder: (context, index) {
        final slot = layout.slots[index];
        return _buildSlotLazy(slot, state);
      },
    );
  }
}
```

2. **Widget Caching:**
```dart
class ComponentCache {
  final Map<String, Widget> _cache = {};
  
  Widget getCached(String componentId, NowPlayingState state) {
    final key = '$componentId-${state.hashCode}';
    if (!_cache.containsKey(key)) {
      _cache[key] = _buildComponent(componentId, state);
    }
    return _cache[key]!;
  }
}
```

3. **Selective Rebuilds:**
```dart
class NowPlayingComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Only rebuild when specific state changes
    return Consumer<PlaybackStateProvider>(
      builder: (context, state, child) {
        return _buildComponent(state);
      },
    );
  }
}
```


### Material 3 Theming Integration

#### Theme-Aware Components

**Color Scheme Integration:**

```dart
class NowPlayingScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      color: colorScheme.surface,
      child: _buildLayout(colorScheme),
    );
  }
}
```

#### Dynamic Color Extraction

**Album Art Color Extraction:**

```dart
class DynamicColorExtractor {
  Future<ColorScheme> extractFromImage(ImageProvider image) async {
    final palette = await Palette.fromImageProvider(image).generate();
    
    // Extract dominant colors
    final primary = palette.dominantColor?.color ?? Colors.blue;
    final secondary = palette.vibrantColor?.color ?? primary;
    final tertiary = palette.mutedColor?.color ?? primary;
    
    // Generate Material 3 color scheme
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: _calculateBrightness(primary),
    );
  }
  
  Brightness _calculateBrightness(Color color) {
    // Calculate if color is light or dark
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Brightness.light : Brightness.dark;
  }
}
```

#### Theme Override System

**Preset Theme Overrides:**

```dart
class ThemeOverride {
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? surfaceColor;
  final Brightness? brightness;
  final double? opacity;
  
  ThemeData applyTo(ThemeData baseTheme) {
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primaryColor ?? baseTheme.colorScheme.primary,
        secondary: secondaryColor ?? baseTheme.colorScheme.secondary,
        surface: surfaceColor ?? baseTheme.colorScheme.surface,
        brightness: brightness ?? baseTheme.colorScheme.brightness,
      ),
    );
  }
}
```

#### Component Theming

**Theme-Aware Component Base:**

```dart
abstract class ThemedNowPlayingComponent extends NowPlayingComponent {
  Widget buildThemed(BuildContext context, NowPlayingState state) {
    final theme = Theme.of(context);
    final overrides = _getThemeOverrides();
    
    return Theme(
      data: overrides.applyTo(theme),
      child: build(context, state),
    );
  }
  
  ThemeOverride _getThemeOverrides();
}
```

### Default Presets

**Built-in Presets:**

1. **Classic**

            - Cover art (large, center)
            - Track info (below cover)
            - Progress bar (full width)
            - Controls (bottom)
            - Background: Dynamic color from album art

2. **Minimal**

            - Cover art (small, top-left)
            - Track info (center)
            - Progress bar (full width)
            - Controls (bottom)
            - Background: Solid color

3. **Visualizer Focus**

            - Visualizer (full screen, background)
            - Cover art (overlay, small)
            - Track info (overlay, bottom)
            - Controls (overlay, bottom)
            - Background: Visualizer

4. **Lyrics Focus**

            - Lyrics (large, center)
            - Cover art (small, top)
            - Progress bar (full width)
            - Controls (bottom)
            - Background: Gradient from album art

5. **Compact**

            - Cover art (small, left)
            - Track info (center)
            - Progress bar (inline)
            - Controls (right)
            - Background: Solid color

### 5. Visualizer Engine (`lib/core/visualizer/`)

**Architecture:**

- Native Android OpenGL ES renderer
- .milk preset parser (Winamp format)
- Preset folder selection via platform channel
- Real-time audio FFT data from audio session

**Implementation:**

- Parse .milk preset files (XML-like format)
- Map preset variables to OpenGL shaders
- Render visualizations based on audio FFT data
- Support for common .milk preset features

### 6. Remote Control (`lib/features/remote/`)

**Web Server:**

- Embedded HTTP server (NanoHTTPD on Android)
- REST API endpoints:
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `GET /api/status` - Current playback state
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `POST /api/play` - Start playback
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `POST /api/pause` - Pause playback
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `POST /api/seek` - Seek to position
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `GET /api/queue` - Get current queue
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `POST /api/queue` - Modify queue
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `GET /api/library` - Browse library
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - `POST /api/eq/preset` - Switch EQ preset

**WebSocket:**

- Real-time updates (playback state, position)
- Bidirectional communication

**Web UI:**

- Simple HTML/JS interface
- Embedded in app assets
- Served at `/` endpoint

## Remote Control Feature - Detailed Design

### Embedded Web Server Architecture

#### Server Components

```
┌─────────────────────────────────────────────────────────┐
│              MusicrrWebServer (NanoHTTPD)                │
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │              Request Router                        │   │
│  │  - Static file serving (/ → Web UI)              │   │
│  │  - REST API routing (/api/*)                     │   │
│  │  - WebSocket upgrade (/ws)                        │   │
│  └──────────────────────────────────────────────────┘   │
│                           │                               │
│  ┌────────────────────────┼───────────────────────────┐   │
│  │                       │                           │   │
│  │  ┌────────────────────▼────────────┐              │   │
│  │  │      REST API Handler           │              │   │
│  │  │  - Authentication check         │              │   │
│  │  │  - Request parsing              │              │   │
│  │  │  - Response formatting          │              │   │
│  │  └────────────────────┬────────────┘              │   │
│  │                       │                           │   │
│  │  ┌────────────────────▼────────────┐              │   │
│  │  │      Audio Engine Bridge        │              │   │
│  │  │  (Platform Channel Access)      │              │   │
│  │  └─────────────────────────────────┘              │   │
│  │                                                    │   │
│  │  ┌─────────────────────────────────┐              │   │
│  │  │      WebSocket Handler          │              │   │
│  │  │  - Connection management        │              │   │
│  │  │  - Event broadcasting           │              │   │
│  │  │  - Client subscription          │              │   │
│  │  └─────────────────────────────────┘              │   │
│  └────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────┘
```

#### Server Lifecycle

1. **Initialization**

                                                                                                                                                                                                - Server starts on app launch (if enabled in settings)
                                                                                                                                                                                                - Binds to local network interface (not 127.0.0.1 only)
                                                                                                                                                                                                - Default port: 8080 (configurable in settings)
                                                                                                                                                                                                - Generates pairing token on first start
                                                                                                                                                                                                - Creates authentication token store

2. **Runtime**

                                                                                                                                                                                                - Handles HTTP requests on worker threads
                                                                                                                                                                                                - Maintains WebSocket connection pool
                                                                                                                                                                                                - Broadcasts events to all connected clients
                                                                                                                                                                                                - Monitors audio engine state changes

3. **Shutdown**

                                                                                                                                                                                                - Gracefully closes all WebSocket connections
                                                                                                                                                                                                - Stops accepting new requests
                                                                                                                                                                                                - Releases network resources

#### Network Binding Strategy

- **Primary**: Bind to all network interfaces (0.0.0.0)
                                                                                                                                - Allows access from other devices on LAN
                                                                                                                                - Requires network permission
- **Fallback**: Bind to localhost only (127.0.0.1)
                                                                                                                                - If network permission denied
                                                                                                                                - Still allows local device access
- **Port Selection**:
                                                                                                                                - Default: 8080
                                                                                                                                - Auto-increment if port in use (8081, 8082, ...)
                                                                                                                                - User-configurable in settings

### REST API Endpoints

#### Authentication

All API endpoints (except `/api/info` and `/api/pair`) require authentication via Bearer token in `Authorization` header:

```
Authorization: Bearer <token>
```

#### Endpoint Specifications

**1. Server Information**

```
GET /api/info
Response: {
  "name": "Musicrr",
  "version": "1.0.0",
  "serverId": "unique-device-id",
  "requiresAuth": true,
  "pairingEnabled": true
}
```

**2. Pairing (Initial Setup)**

```
POST /api/pair
Body: {
  "pairingToken": "user-entered-token"
}
Response: {
  "success": true,
  "accessToken": "long-lived-token",
  "expiresIn": 31536000  // seconds (1 year)
}
Error (401): {
  "error": "Invalid pairing token"
}
```

**3. Playback Status**

```
GET /api/status
Headers: Authorization: Bearer <token>
Response: {
  "state": "playing" | "paused" | "stopped",
  "currentTrack": {
    "id": "song-id",
    "title": "Song Title",
    "artist": "Artist Name",
    "album": "Album Name",
    "duration": 240000,  // milliseconds
    "coverArt": "http://.../cover.jpg"
  },
  "position": 125000,  // milliseconds
  "volume": 0.75,  // 0.0 - 1.0
  "shuffle": false,
  "repeat": "none" | "one" | "all"
}
```

**4. Playback Control**

```
POST /api/play
Headers: Authorization: Bearer <token>
Body (optional): {
  "trackId": "song-id",  // If provided, plays this track
  "position": 0  // Optional start position in ms
}
Response: {
  "success": true
}

POST /api/pause
Headers: Authorization: Bearer <token>
Response: {
  "success": true
}

POST /api/resume
Headers: Authorization: Bearer <token>
Response: {
  "success": true
}

POST /api/stop
Headers: Authorization: Bearer <token>
Response: {
  "success": true
}

POST /api/seek
Headers: Authorization: Bearer <token>
Body: {
  "position": 125000  // milliseconds
}
Response: {
  "success": true,
  "position": 125000
}
```

**5. Queue Management**

```
GET /api/queue
Headers: Authorization: Bearer <token>
Response: {
  "currentIndex": 2,
  "tracks": [
    {
      "id": "song-1",
      "title": "Song 1",
      "artist": "Artist",
      "album": "Album",
      "duration": 240000,
      "coverArt": "http://..."
    },
    // ... more tracks
  ]
}

POST /api/queue/add
Headers: Authorization: Bearer <token>
Body: {
  "trackIds": ["song-1", "song-2"],
  "position": 0  // Optional: insert at position
}
Response: {
  "success": true,
  "queueLength": 5
}

POST /api/queue/remove
Headers: Authorization: Bearer <token>
Body: {
  "indices": [0, 2]  // Remove tracks at these positions
}
Response: {
  "success": true,
  "queueLength": 3
}

POST /api/queue/reorder
Headers: Authorization: Bearer <token>
Body: {
  "fromIndex": 2,
  "toIndex": 0
}
Response: {
  "success": true
}

POST /api/queue/clear
Headers: Authorization: Bearer <token>
Response: {
  "success": true
}

POST /api/queue/shuffle
Headers: Authorization: Bearer <token>
Body: {
  "enabled": true
}
Response: {
  "success": true,
  "shuffle": true
}

POST /api/queue/repeat
Headers: Authorization: Bearer <token>
Body: {
  "mode": "none" | "one" | "all"
}
Response: {
  "success": true,
  "repeat": "all"
}
```

**6. Library Browsing**

```
GET /api/library/artists
Headers: Authorization: Bearer <token>
Query params:
  - limit: number (default: 50)
  - offset: number (default: 0)
  - search: string (optional)
Response: {
  "artists": [
    {
      "id": "artist-1",
      "name": "Artist Name",
      "albumCount": 5,
      "trackCount": 42
    }
  ],
  "total": 150,
  "limit": 50,
  "offset": 0
}

GET /api/library/albums
Headers: Authorization: Bearer <token>
Query params:
  - artistId: string (optional, filter by artist)
  - limit: number
  - offset: number
  - search: string
Response: {
  "albums": [
    {
      "id": "album-1",
      "title": "Album Title",
      "artist": "Artist Name",
      "artistId": "artist-1",
      "year": 2020,
      "coverArt": "http://...",
      "trackCount": 12
    }
  ],
  "total": 75,
  "limit": 50,
  "offset": 0
}

GET /api/library/tracks
Headers: Authorization: Bearer <token>
Query params:
  - albumId: string (optional)
  - artistId: string (optional)
  - playlistId: string (optional)
  - limit: number
  - offset: number
  - search: string
Response: {
  "tracks": [
    {
      "id": "track-1",
      "title": "Track Title",
      "artist": "Artist Name",
      "album": "Album Name",
      "albumId": "album-1",
      "duration": 240000,
      "trackNumber": 1,
      "discNumber": 1,
      "coverArt": "http://..."
    }
  ],
  "total": 500,
  "limit": 50,
  "offset": 0
}

GET /api/library/playlists
Headers: Authorization: Bearer <token>
Response: {
  "playlists": [
    {
      "id": "playlist-1",
      "name": "My Playlist",
      "trackCount": 25,
      "coverArt": "http://..."
    }
  ]
}

GET /api/library/track/{trackId}
Headers: Authorization: Bearer <token>
Response: {
  "id": "track-1",
  "title": "Track Title",
  "artist": "Artist Name",
  "album": "Album Name",
  "duration": 240000,
  "trackNumber": 1,
  "discNumber": 1,
  "genre": "Rock",
  "year": 2020,
  "coverArt": "http://...",
  "streamUrl": "http://.../api/stream/track-1"  // Temporary URL
}
```

**7. Audio Effects**

```
GET /api/eq/presets
Headers: Authorization: Bearer <token>
Response: {
  "presets": [
    {
      "id": "preset-1",
      "name": "Rock",
      "bands": [
        {"frequency": 60, "gain": 2.0, "q": 1.0},
        {"frequency": 250, "gain": -1.0, "q": 1.0}
      ]
    }
  ],
  "current": "preset-1"
}

POST /api/eq/preset
Headers: Authorization: Bearer <token>
Body: {
  "presetId": "preset-1"
}
Response: {
  "success": true,
  "preset": "preset-1"
}

POST /api/eq/bands
Headers: Authorization: Bearer <token>
Body: {
  "bands": [
    {"frequency": 60, "gain": 2.0, "q": 1.0},
    {"frequency": 250, "gain": -1.0, "q": 1.0}
  ]
}
Response: {
  "success": true
}

GET /api/volume
Headers: Authorization: Bearer <token>
Response: {
  "volume": 0.75  // 0.0 - 1.0
}

POST /api/volume
Headers: Authorization: Bearer <token>
Body: {
  "volume": 0.8  // 0.0 - 1.0
}
Response: {
  "success": true,
  "volume": 0.8
}
```

**8. Search**

```
GET /api/search
Headers: Authorization: Bearer <token>
Query params:
  - q: string (required, search query)
  - type: "all" | "artists" | "albums" | "tracks" (default: "all")
  - limit: number (default: 20)
Response: {
  "artists": [...],
  "albums": [...],
  "tracks": [...],
  "query": "search term"
}
```

**9. Error Responses**

All endpoints return errors in consistent format:

```
Status: 400/401/404/500
Response: {
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": {}  // Optional additional details
}
```

Common error codes:

- `INVALID_TOKEN`: Authentication token invalid/expired
- `INVALID_REQUEST`: Malformed request body/parameters
- `NOT_FOUND`: Resource not found
- `PLAYBACK_ERROR`: Audio engine error
- `PROVIDER_ERROR`: Provider-specific error

### WebSocket Event Model

#### Connection

```
Client → Server: WebSocket upgrade request
URL: ws://device-ip:8080/ws?token=<access-token>
Server → Client: Connection established
```

#### Event Types

**1. Playback State Events**

```
Event: playback.state
Data: {
  "state": "playing" | "paused" | "stopped",
  "timestamp": 1234567890
}
```

**2. Position Updates**

```
Event: playback.position
Data: {
  "position": 125000,  // milliseconds
  "duration": 240000,
  "timestamp": 1234567890
}
Note: Sent every 1 second when playing
```

**3. Track Changed**

```
Event: playback.track
Data: {
  "track": {
    "id": "song-id",
    "title": "Song Title",
    "artist": "Artist Name",
    "album": "Album Name",
    "duration": 240000,
    "coverArt": "http://..."
  },
  "position": 0,
  "timestamp": 1234567890
}
```

**4. Queue Updated**

```
Event: queue.updated
Data: {
  "currentIndex": 2,
  "queueLength": 10,
  "tracks": [...]  // Full queue array
}
```

**5. Volume Changed**

```
Event: volume.changed
Data: {
  "volume": 0.75,
  "timestamp": 1234567890
}
```

**6. EQ Preset Changed**

```
Event: eq.preset
Data: {
  "presetId": "preset-1",
  "presetName": "Rock"
}
```

**7. Error Events**

```
Event: error
Data: {
  "code": "ERROR_CODE",
  "message": "Error message",
  "timestamp": 1234567890
}
```

#### Client-to-Server Commands

WebSocket also accepts commands from client (alternative to REST):

```
Client → Server: {
  "command": "play",
  "params": {
    "trackId": "song-id"  // optional
  }
}

Server → Client: {
  "success": true,
  "command": "play"
}
```

Supported commands:

- `play`, `pause`, `resume`, `stop`
- `seek` (params: `{position: number}`)
- `next`, `previous`
- `setVolume` (params: `{volume: number}`)
- `addToQueue` (params: `{trackIds: string[]}`)
- `removeFromQueue` (params: `{indices: number[]}`)

### Security Model

#### Authentication Flow

**Initial Pairing:**

1. User enables remote control in app settings
2. App generates random pairing token (8-12 characters)
3. App displays pairing token and server URL in settings
4. User enters pairing token in web UI
5. Web UI sends pairing token to `/api/pair`
6. Server validates token and returns long-lived access token
7. Web UI stores access token (localStorage)
8. All subsequent requests use access token

**Token Management:**

- Pairing token: Short-lived (expires after first use or 24 hours)
- Access token: Long-lived (1 year, configurable)
- Token rotation: User can regenerate tokens in settings
- Token revocation: User can revoke all tokens (forces re-pairing)

#### Network Security

**LAN-Only Binding:**

- Server binds to local network interface
- Not accessible from internet (no port forwarding)
- Firewall: Android system firewall provides basic protection

**Optional Enhancements (Future):**

- IP whitelist (allow specific IPs only)
- Rate limiting (prevent abuse)
- HTTPS support (self-signed certificate)
- Basic HTTP auth (additional layer)

#### Token Storage

**Server Side:**

- Pairing tokens: Stored in SharedPreferences (encrypted)
- Access tokens: Stored in memory (validated on each request)
- Token validation: Simple string comparison (lightweight)

**Client Side:**

- Access token stored in localStorage
- No sensitive data in cookies
- Token sent in Authorization header (not URL)

### Web UI Scope and Limitations

#### Scope (What Web UI Can Do)

**Playback Control:**

- Play, pause, resume, stop
- Seek to position
- Next/previous track
- Volume control

**Queue Management:**

- View current queue
- Add tracks to queue
- Remove tracks from queue
- Reorder queue
- Clear queue
- Shuffle/repeat modes

**Library Browsing:**

- Browse artists, albums, tracks, playlists
- Search library
- View track details
- Play tracks/albums/playlists

**Audio Effects:**

- Switch EQ presets
- View current EQ settings
- Adjust volume

**Real-time Updates:**

- Playback state changes
- Position updates
- Queue changes
- Track changes

#### Limitations (What Web UI Cannot Do)

**Settings Management:**

- Cannot change app settings
- Cannot configure providers
- Cannot modify appearance settings
- Cannot access system settings

**Advanced Features:**

- Cannot access visualizer (requires native OpenGL)
- Cannot modify Now Playing screen layout
- Cannot access lyrics (unless exposed via API)
- Cannot manage downloads/cache

**Provider Management:**

- Cannot add/remove providers
- Cannot configure provider credentials
- Cannot trigger library scans

**Recommendations:**

- Cannot view recommendation algorithm details
- Cannot modify recommendation settings

#### UI Concept (Minimal but Extensible)

**Layout Structure:**

```
┌─────────────────────────────────────────┐
│  Musicrr Remote Control                 │
│  [Now Playing: Song Title - Artist]     │
├─────────────────────────────────────────┤
│  [◀◀] [▶] [▶▶]     [Volume: ████████░░] │
│  Progress: [████████░░░░] 2:05 / 4:00  │
├─────────────────────────────────────────┤
│  Queue (10 tracks)                      │
│  ┌───────────────────────────────────┐  │
│  │ 1. Current Song - Artist          │  │
│  │ 2. Next Song - Artist            │  │
│  │ 3. Another Song - Artist          │  │
│  │ ...                               │  │
│  └───────────────────────────────────┘  │
├─────────────────────────────────────────┤
│  Library                                │
│  [Artists] [Albums] [Tracks] [Search]   │
│  ┌───────────────────────────────────┐  │
│  │ Artist 1                          │  │
│  │ Artist 2                          │  │
│  │ ...                               │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**Key Features:**

- Responsive design (mobile + desktop)
- Dark theme (matches app)
- Real-time updates via WebSocket
- Minimal JavaScript (vanilla JS or lightweight framework)
- Progressive enhancement (works without JS for basic controls)

**Extensibility Points:**

- Plugin system for custom UI components
- Customizable layout (user preferences)
- Theme support (light/dark)
- Keyboard shortcuts
- Touch gestures (swipe for next/previous)

### Interaction with Audio Engine & State

#### State Synchronization Flow

```
1. Web UI Action (e.g., play button click)
   ↓
2. REST API Request → MusicrrWebServer
   ↓
3. ApiRouter validates token, parses request
   ↓
4. ApiRouter calls AudioEngineBridge
   ↓
5. AudioEngineBridge invokes platform channel
   ↓
6. Native AudioEngine executes command
   ↓
7. AudioEngine emits state change event
   ↓
8. EventChannel streams event to Flutter
   ↓
9. Flutter PlaybackStateProvider updates
   ↓
10. MusicrrWebServer subscribes to state changes
    ↓
11. WebSocketHandler broadcasts to all clients
    ↓
12. Web UI receives WebSocket event, updates UI
```

#### State Access Patterns

**Read-Only Access:**

- Web server reads state via platform channel (synchronous)
- For REST API responses (GET requests)
- Cached with short TTL (100ms) to reduce platform channel calls

**Write Access:**

- Web server writes via platform channel (synchronous)
- For REST API commands (POST requests)
- Waits for confirmation before responding

**Real-time Updates:**

- Web server subscribes to EventChannel streams
- Broadcasts events to WebSocket clients
- No polling required

#### Threading Considerations

**Web Server Thread:**

- Runs on background thread (NanoHTTPD worker)
- Platform channel calls must be on main thread
- Use Handler to post to main thread for platform channel access
- Cache state reads to minimize thread switching

**State Update Broadcasting:**

- EventChannel events arrive on main thread
- WebSocket broadcasting happens on server thread
- Use thread-safe queue for event delivery

#### Error Handling

**Audio Engine Errors:**

- Caught in platform channel handler
- Returned as error response to REST API
- Broadcasted as error event via WebSocket

**Network Errors:**

- Client disconnection handled gracefully
- WebSocket reconnection supported
- Token expiration returns 401, triggers re-pairing

### Implementation Details

#### Native Android Components

**MusicrrWebServer.kt:**

```kotlin
class MusicrrWebServer(
    port: Int,
    private val audioEngineBridge: AudioEngineBridge,
    private val tokenManager: TokenManager
) : NanoHTTPD(port) {
    // Request routing
    // Static file serving
    // WebSocket upgrade handling
}
```

**ApiRouter.kt:**

```kotlin
class ApiRouter(
    private val audioEngineBridge: AudioEngineBridge,
    private val libraryService: LibraryService,
    private val tokenManager: TokenManager
) {
    fun handleRequest(session: IHTTPSession): Response
    // Route to appropriate handler
    // Validate authentication
    // Format responses
}
```

**WebSocketHandler.kt:**

```kotlin
class WebSocketHandler(
    private val audioEngineBridge: AudioEngineBridge
) {
    private val clients = ConcurrentHashMap<String, WebSocket>()
    
    fun broadcast(event: String, data: JsonObject)
    fun addClient(clientId: String, socket: WebSocket)
    fun removeClient(clientId: String)
}
```

**AudioEngineBridge.kt:**

```kotlin
class AudioEngineBridge(
    private val methodChannel: MethodChannel,
    private val eventChannel: EventChannel
) {
    // Synchronous platform channel calls
    // State caching
    // Event subscription management
}
```

#### Flutter Components

**RemoteControlService (`lib/features/remote/remote_control_service.dart`):**

```dart
class RemoteControlService {
  // Start/stop web server
  // Get server URL and pairing token
  // Manage authentication tokens
}
```

**WebServerProvider (Riverpod):**

```dart
final webServerProvider = StateNotifierProvider<WebServerNotifier, WebServerState>((ref) {
  return WebServerNotifier();
});
```

### API Contract Examples

#### Example: Play a Track

**Request:**

```http
POST /api/play HTTP/1.1
Host: 192.168.1.100:8080
Authorization: Bearer abc123def456
Content-Type: application/json

{
  "trackId": "song-123",
  "position": 0
}
```

**Response:**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true
}
```

**WebSocket Event (broadcasted):**

```json
{
  "event": "playback.track",
  "data": {
    "track": {
      "id": "song-123",
      "title": "Example Song",
      "artist": "Example Artist",
      "album": "Example Album",
      "duration": 240000,
      "coverArt": "http://192.168.1.100:8080/api/cover/song-123"
    },
    "position": 0,
    "timestamp": 1234567890
  }
}
```

#### Example: Get Queue

**Request:**

```http
GET /api/queue HTTP/1.1
Host: 192.168.1.100:8080
Authorization: Bearer abc123def456
```

**Response:**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "currentIndex": 2,
  "tracks": [
    {
      "id": "song-1",
      "title": "Song 1",
      "artist": "Artist",
      "album": "Album",
      "duration": 180000,
      "coverArt": "http://192.168.1.100:8080/api/cover/song-1"
    },
    {
      "id": "song-2",
      "title": "Song 2",
      "artist": "Artist",
      "album": "Album",
      "duration": 200000,
      "coverArt": "http://192.168.1.100:8080/api/cover/song-2"
    },
    {
      "id": "song-3",
      "title": "Song 3",
      "artist": "Artist",
      "album": "Album",
      "duration": 240000,
      "coverArt": "http://192.168.1.100:8080/api/cover/song-3"
    }
  ]
}
```

#### Example: WebSocket Connection

**Client Connection:**

```javascript
const ws = new WebSocket('ws://192.168.1.100:8080/ws?token=abc123def456');

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  if (message.event === 'playback.position') {
    updateProgressBar(message.data.position, message.data.duration);
  }
};
```

**Server Broadcast:**

```json
{
  "event": "playback.position",
  "data": {
    "position": 125000,
    "duration": 240000,
    "timestamp": 1234567890
  }
}
```

### Event Flow Descriptions

#### Flow 1: User Plays Track from Web UI

```
1. User clicks "Play" on track in web UI
   ↓
2. Web UI sends: POST /api/play {trackId: "song-123"}
   ↓
3. ApiRouter validates token, extracts trackId
   ↓
4. AudioEngineBridge calls platform channel: play(uri)
   ↓
5. Native AudioEngine resolves URI, starts playback
   ↓
6. AudioEngine emits: playbackState = "playing"
   ↓
7. EventChannel streams event to Flutter
   ↓
8. PlaybackStateProvider updates state
   ↓
9. WebSocketHandler receives state change
   ↓
10. WebSocketHandler broadcasts: playback.state {state: "playing"}
    ↓
11. All connected web clients receive event
    ↓
12. Web UI updates play button, shows playing state
```

#### Flow 2: Position Updates During Playback

```
1. Native AudioEngine updates position every 1 second
   ↓
2. EventChannel streams: position {position: 125000, duration: 240000}
   ↓
3. PlaybackStateProvider updates position state
   ↓
4. WebSocketHandler receives position update
   ↓
5. WebSocketHandler broadcasts: playback.position {position: 125000, ...}
   ↓
6. All connected web clients receive position update
   ↓
7. Web UI updates progress bar
```

#### Flow 3: Queue Modified from App

```
1. User adds track to queue in Flutter app
   ↓
2. PlaybackQueue adds track, emits queue change
   ↓
3. PlaybackStateProvider updates queue state
   ↓
4. WebSocketHandler receives queue change event
   ↓
5. WebSocketHandler broadcasts: queue.updated {queue: [...]}
   ↓
6. All connected web clients receive queue update
   ↓
7. Web UI refreshes queue display
```

#### Flow 4: Authentication Token Expired

```
1. Web UI sends request with expired token
   ↓
2. ApiRouter validates token, finds it expired
   ↓
3. ApiRouter returns: 401 {error: "Token expired"}
   ↓
4. Web UI detects 401, clears stored token
   ↓
5. Web UI redirects to pairing page
   ↓
6. User enters new pairing token
   ↓
7. Web UI calls: POST /api/pair {pairingToken: "..."}
   ↓
8. Server validates, returns new access token
   ↓
9. Web UI stores new token, resumes normal operation
```

### 7. Settings & Customization (`lib/features/settings/`)

**Settings Categories:**

- **Appearance:**
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Theme (Light/Dark)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Accent color picker
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Tab order customization
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Start screen selection
- **Audio:**
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - EQ presets
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - ReplayGain settings
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Crossfade duration
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Sample rate selection
- **Library:**
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Provider configuration
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Cache management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Download settings
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Transcoding options
- **System:**
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Language selection
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Milk preset folder path
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Offline mode toggle

## Development Phases

### Phase 1: MVP (Minimum Viable Product)

**Duration: 6-8 weeks**

**Core Features:**

1. Basic Flutter UI with Material 3

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Bottom navigation (Home, Library, Settings)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Mini-player bar
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Basic Now Playing screen

2. Local file provider

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - File system scanning
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Basic metadata extraction

3. ExoPlayer integration

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Basic playback (MP3, M4A)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Play/pause/seek
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Queue management

4. Simple library browser

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Artists, Albums, Songs lists

5. Basic settings

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Theme selection
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Basic audio settings

**Deliverables:**

- Working music player for local files
- Basic UI/UX
- Foundation for future features

### Phase 2: v1.0 (Core Features)

**Duration: 8-10 weeks**

**Additional Features:**

1. Audio enhancements

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - FLAC, Opus, OGG support
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Gapless playback
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - ReplayGain (track level)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Basic EQ (3-band)

2. Provider system

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - HTTP provider
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - WebDAV provider
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Provider management UI

3. Recommendation engine

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Basic play frequency tracking
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - "Recently Played" playlist
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - "Most Played" playlist

4. Now Playing customization

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Background modes (solid, dynamic color)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Progress slider variants

5. Lyrics support

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - LRC file parsing
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Lyrics display in Now Playing

6. Offline mode

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Download management
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Cache management UI

**Deliverables:**

- Full-featured music player
- Multiple provider support
- Basic recommendations
- Customizable Now Playing

### Phase 3: v2.0 (Advanced Features)

**Duration: 10-12 weeks**

**Advanced Features:**

1. Advanced audio

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Parametric EQ (multiple bands, presets)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Album-level ReplayGain
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Crossfade
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Sample rate switching

2. Advanced providers

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - SMB provider
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Subsonic provider
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Jellyfin provider

3. Advanced recommendations

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Skip rate analysis
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Genre/artist similarity
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - "Discover Weekly" algorithm

4. Visualizer

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - .milk preset support
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Preset folder selection
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Visualizer in Now Playing

5. Remote control

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Embedded web server
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - REST API
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - WebSocket support
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Web UI

6. Advanced customization

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Tab order
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Start screen selection
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Now Playing presets
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                - Animated backgrounds

**Deliverables:**

- Power-user focused features
- Full customization
- Remote control capability

## Technically Risky Areas

### 1. Custom DSP/Parametric EQ

**Risk Level: High**

**Challenges:**

- ExoPlayer's `AudioProcessor` interface may be limiting
- Real-time audio processing performance
- Latency concerns
- May require JNI/C++ implementation

**Mitigation:**

- Start with simple 3-band EQ using ExoPlayer
- Evaluate performance early
- Consider libavfilter or similar library
- Fallback to system EQ if custom implementation fails

### 2. .milk Visualizer Compatibility

**Risk Level: High**

**Challenges:**

- .milk format is Winamp-specific
- Complex preset format with custom scripting
- OpenGL ES shader translation
- Performance on mobile devices

**Mitigation:**

- Research existing .milk parsers/ports
- Start with simple preset subset
- Consider alternative: custom visualizer format with .milk import
- Performance testing on target devices

### 3. Gapless Playback

**Risk Level: Medium**

**Challenges:**

- ExoPlayer gapless support varies by format
- Crossfade complicates gapless
- Buffer management

**Mitigation:**

- Use ExoPlayer's built-in gapless where possible
- Test extensively with different formats
- Consider dual-player approach for crossfade

### 4. Multi-Provider Unified Library

**Risk Level: Medium**

**Challenges:**

- Provider abstraction complexity
- Caching and synchronization
- Offline mode with multiple providers
- Performance with large libraries

**Mitigation:**

- Strong abstraction from start
- Efficient caching strategy
- Lazy loading and pagination
- Background sync for providers

### 5. Embedded Web Server

**Risk Level: Medium**

**Challenges:**

- Security concerns (local network)
- Performance impact
- WebSocket stability
- Port conflicts

**Mitigation:**

- Use proven library (NanoHTTPD)
- Local-only binding (127.0.0.1 or local network)
- Authentication option
- Graceful error handling

### 6. ReplayGain Implementation

**Risk Level: Medium**

**Challenges:**

- Tag parsing (varies by format)
- Album-level grouping
- Real-time gain adjustment
- Avoiding clipping

**Mitigation:**

- Use existing tag libraries
- Implement gain adjustment in audio processor
- Careful gain calculation to prevent clipping

## File Structure

```
lib/
├── main.dart
├── core/
│   ├── audio/
│   │   ├── audio_engine.dart
│   │   ├── playback_queue.dart
│   │   ├── audio_effects.dart
│   │   ├── gapless_player.dart
│   │   └── replay_gain_processor.dart
│   ├── providers/
│   │   ├── media_provider.dart
│   │   ├── local_provider.dart
│   │   ├── http_provider.dart
│   │   ├── webdav_provider.dart
│   │   ├── smb_provider.dart
│   │   ├── subsonic_provider.dart
│   │   ├── jellyfin_provider.dart
│   │   └── provider_repository.dart
│   ├── models/
│   │   ├── song.dart
│   │   ├── album.dart
│   │   ├── artist.dart
│   │   └── playlist.dart
│   ├── storage/
│   │   ├── database.dart
│   │   ├── cache_manager.dart
│   │   └── settings_repository.dart
│   ├── recommendations/
│   │   ├── recommendation_engine.dart
│   │   ├── analytics_service.dart
│   │   └── playlist_generator.dart
│   ├── lyrics/
│   │   ├── lrc_parser.dart
│   │   └── lyrics_service.dart
│   └── visualizer/
│       └── visualizer_engine.dart
├── features/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── recommendation_widgets.dart
│   ├── library/
│   │   ├── library_screen.dart
│   │   ├── artists_view.dart
│   │   ├── albums_view.dart
│   │   └── songs_view.dart
│   ├── now_playing/
│   │   ├── now_playing_screen.dart
│   │   ├── cover_art_widget.dart
│   │   ├── progress_slider_widget.dart
│   │   ├── control_buttons_widget.dart
│   │   ├── visualizer_widget.dart
│   │   └── lyrics_overlay_widget.dart
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── appearance_settings.dart
│   │   ├── audio_settings.dart
│   │   └── library_settings.dart
│   ├── mini_player/
│   │   └── mini_player_bar.dart
│   └── remote/
│       ├── web_server.dart
│       ├── api_handler.dart
│       └── websocket_handler.dart
└── shared/
    ├── widgets/
    ├── theme/
    └── utils/

android/
├── app/src/main/
│   ├── java/com/haasele/musicrr/
│   │   ├── MainActivity.kt
│   │   ├── audio/
│   │   │   ├── ExoPlayerAudioEngine.kt
│   │   │   ├── AudioSessionManager.kt
│   │   │   └── GaplessPlayer.kt
│   │   ├── dsp/
│   │   │   ├── ParametricEQ.kt
│   │   │   └── ReplayGainProcessor.kt
│   │   ├── visualizer/
│   │   │   ├── MilkVisualizer.kt
│   │   │   ├── MilkPresetParser.kt
│   │   │   └── VisualizerRenderer.kt
│   │   ├── webserver/
│   │   │   ├── MusicrrWebServer.kt
│   │   │   └── ApiRouter.kt
│   │   └── platform_channels/
│   │       ├── AudioMethodChannel.kt
│   │       └── AudioEventChannel.kt
│   └── res/
└── build.gradle
```

## Key Design Decisions

1. **State Management**: Riverpod recommended for complex state and dependency injection
2. **Navigation**: go_router for declarative routing and deep linking
3. **Audio Engine**: ExoPlayer with custom extensions for maximum compatibility
4. **Provider Abstraction**: Strong interface-based design for extensibility
5. **Local-First**: All recommendations and analytics are local-only (privacy-focused)
6. **Modular UI**: Now Playing screen uses composable widgets for customization
7. **Platform Channels**: MethodChannel for commands, EventChannel for streaming events

## Next Steps

1. Set up Flutter project structure
2. Create platform channel interfaces
3. Implement basic ExoPlayer integration
4. Build provider abstraction layer
5. Create basic UI with Material 3
6. Implement MVP features incrementally