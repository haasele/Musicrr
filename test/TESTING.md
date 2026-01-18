# Testing Documentation

## Overview

This document outlines the testing strategy for Musicrr, including integration tests, unit tests, and test scenarios.

## Test Structure

```
test/
├── integration/          # End-to-end integration tests
│   ├── playback_flow_test.dart
│   ├── provider_switching_test.dart
│   ├── queue_management_test.dart
│   └── preset_switching_test.dart
├── unit/                # Unit tests for individual components
│   ├── audio/
│   ├── providers/
│   ├── recommendations/
│   └── storage/
└── helpers/             # Test helpers and utilities
    └── test_helpers.dart
```

## Integration Test Scenarios

### 1. Playback Flow Tests

**Test Cases:**
- ✅ Play song from queue
- ✅ Pause and resume playback
- ✅ Seek to position
- ✅ Next track in queue
- ✅ Previous track in queue
- ✅ Queue reordering
- ✅ Shuffle mode
- ✅ Repeat mode

**Requirements:**
- Mock platform channels for native audio engine
- Mock provider repository for song data
- Verify state updates through Riverpod providers

### 2. Provider Switching Tests

**Test Cases:**
- ✅ Provider enable/disable
- ✅ Get artists from multiple providers
- ✅ Get albums from multiple providers
- ✅ Get songs from multiple providers
- ✅ Offline mode filtering
- ✅ Provider sync

**Requirements:**
- Mock network providers
- Test provider aggregation
- Test offline mode behavior

### 3. Queue Management Tests

**Test Cases:**
- ✅ Save queue snapshot
- ✅ Restore temporary queue
- ✅ Save queue as playlist
- ✅ Clear temporary queues

**Requirements:**
- In-memory database for testing
- Mock song data
- Verify queue persistence

### 4. Preset Switching Tests

**Test Cases:**
- ✅ Save and load preset
- ✅ Get all presets
- ✅ Get active preset by scope (global, provider, album)
- ✅ Delete preset

**Requirements:**
- In-memory database for testing
- Test preset scope priority

## Unit Test Scenarios

### Audio Engine Tests

**Components to Test:**
- `PlaybackQueue` - Queue management logic
- `AudioEngine` - State management (requires platform channel mocks)
- `QueuePersistence` - Queue save/restore

**Test Cases:**
- Queue add/remove/reorder
- Shuffle logic
- Repeat mode logic
- Next/previous track selection

### Provider Tests

**Components to Test:**
- `LocalProvider` - File system scanning
- `WebDAVProvider` - WebDAV protocol
- `ProviderRepository` - Provider aggregation

**Test Cases:**
- Provider initialization
- Data fetching
- Error handling
- Offline mode

### Recommendation Engine Tests

**Components to Test:**
- `AnalyticsService` - Event tracking
- `RecommendationEngine` - Scoring algorithm
- `PlaylistGenerator` - Playlist creation

**Test Cases:**
- Play event recording
- Frequency calculation
- Recency calculation
- Skip rate calculation
- Playlist generation

### Storage Tests

**Components to Test:**
- `SettingsRepository` - Settings persistence
- `NowPlayingPresetRepository` - Preset CRUD
- `Database` - Database operations

**Test Cases:**
- Settings read/write
- Preset save/load/delete
- Database migrations

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/integration/playback_flow_test.dart

# Run with coverage
flutter test --coverage
```

## Test Requirements

### Dependencies

Tests require:
- `flutter_test` (included in Flutter SDK)
- Mock platform channels for native functionality
- In-memory database for storage tests

### Mocking Strategy

**Platform Channels:**
- Mock `MethodChannel` and `EventChannel` for audio engine tests
- Return predefined responses for native calls
- Simulate event streams

**Network Providers:**
- Mock HTTP responses using `dio` interceptors
- Use test fixtures for provider data
- Simulate network failures

**Database:**
- Use in-memory SQLite database for tests
- Clean database between tests
- Use test fixtures for initial data

## Known Limitations

1. **Platform Channel Tests:**
   - Require mocking native functionality
   - Cannot test actual audio playback without device/emulator
   - Event streams need careful mocking

2. **Integration Tests:**
   - Some tests require full app context
   - May need widget tests for UI flows
   - Network tests require mock servers

3. **Performance Tests:**
   - Battery usage requires device testing
   - Memory profiling needs device/emulator
   - Large library tests need test data generation

## Future Test Improvements

1. **Widget Tests:**
   - Test UI components in isolation
   - Test navigation flows
   - Test user interactions

2. **Golden Tests:**
   - Visual regression testing
   - Screenshot comparison
   - UI consistency checks

3. **Performance Tests:**
   - Benchmark critical paths
   - Memory leak detection
   - Battery usage profiling

4. **E2E Tests:**
   - Full app flow testing
   - Device/emulator testing
   - Real network provider testing
