# Performance Testing Documentation

## Overview

This document outlines the performance testing strategy for Musicrr, including battery usage profiling, visualizer performance, large library handling, memory leak detection, and UI FPS monitoring.

## Test Categories

### 1. Battery Usage Profiling

**Test Cases:**
- ✅ Playback power consumption
- ✅ DSP processing overhead
- ✅ Visualizer rendering overhead
- ✅ Network provider power usage
- ✅ Background sync power usage
- ✅ Screen-on vs screen-off power usage

**Test Scenarios:**
1. **Baseline Playback:**
   - Play audio without DSP
   - Measure power consumption
   - Establish baseline

2. **DSP Overhead:**
   - Enable EQ
   - Enable ReplayGain
   - Enable Crossfade
   - Measure additional power consumption

3. **Visualizer Overhead:**
   - Enable visualizer
   - Measure additional power consumption
   - Compare with/without visualizer

4. **Network Playback:**
   - Stream from network provider
   - Measure power consumption
   - Compare with local playback

5. **Background Sync:**
   - Enable auto-sync
   - Measure background power usage
   - Verify minimal impact

**Measurement Tools:**
- Android Battery Historian
- `adb shell dumpsys batterystats`
- Device power monitoring

**Target Metrics:**
- Playback: < 50mW additional power
- DSP: < 20mW additional power
- Visualizer: < 30mW additional power
- Background sync: < 5mW average power

### 2. Visualizer Performance

**Test Cases:**
- ✅ Frame rate (target: 30 FPS minimum)
- ✅ Rendering latency
- ✅ Memory usage
- ✅ CPU usage
- ✅ GPU usage
- ✅ Battery impact

**Test Scenarios:**
1. **Frame Rate:**
   - Enable visualizer
   - Measure frame rate
   - Verify >= 30 FPS

2. **Rendering Latency:**
   - Measure time from audio data to visual update
   - Verify < 100ms latency

3. **Memory Usage:**
   - Monitor memory during visualizer rendering
   - Verify no memory leaks
   - Verify reasonable memory footprint

4. **CPU Usage:**
   - Monitor CPU during visualizer rendering
   - Verify < 20% CPU usage on mid-range device

5. **GPU Usage:**
   - Monitor GPU during visualizer rendering
   - Verify efficient GPU utilization

**Measurement Tools:**
- Android Profiler
- `adb shell dumpsys gfxinfo`
- Frame rate monitoring

**Target Metrics:**
- Frame rate: >= 30 FPS
- Latency: < 100ms
- Memory: < 50MB additional
- CPU: < 20% on mid-range device

### 3. Large Library Performance (50k+ tracks)

**Test Cases:**
- ✅ Library scanning performance
- ✅ Database query performance
- ✅ UI rendering performance
- ✅ Memory usage with large library
- ✅ Search performance
- ✅ Provider aggregation performance

**Test Scenarios:**
1. **Library Scanning:**
   - Scan 50,000 tracks
   - Measure scan time
   - Verify progress updates
   - Verify memory usage

2. **Database Queries:**
   - Query artists (50k tracks)
   - Query albums (50k tracks)
   - Query songs (50k tracks)
   - Measure query time
   - Verify < 1 second for common queries

3. **UI Rendering:**
   - Render library list (50k items)
   - Verify lazy loading
   - Verify smooth scrolling
   - Verify memory usage

4. **Search Performance:**
   - Search across 50k tracks
   - Measure search time
   - Verify < 500ms for search

5. **Provider Aggregation:**
   - Aggregate from multiple providers (50k total)
   - Measure aggregation time
   - Verify deduplication performance

**Test Data Generation:**
- Script to generate test library
- 50,000+ test tracks
- Various metadata combinations

**Target Metrics:**
- Scan time: < 10 minutes for 50k tracks
- Query time: < 1 second
- Search time: < 500ms
- Memory: < 200MB for library data

### 4. Memory Leak Detection

**Test Cases:**
- ✅ Long playback sessions
- ✅ Provider switching
- ✅ Preset switching
- ✅ Queue management
- ✅ Visualizer rendering
- ✅ Network operations

**Test Scenarios:**
1. **Long Playback:**
   - Play for 2+ hours
   - Monitor memory usage
   - Verify no memory growth

2. **Provider Switching:**
   - Switch between providers 100+ times
   - Monitor memory usage
   - Verify no leaks

3. **Preset Switching:**
   - Switch presets 100+ times
   - Monitor memory usage
   - Verify no leaks

4. **Queue Management:**
   - Add/remove tracks 1000+ times
   - Monitor memory usage
   - Verify no leaks

5. **Visualizer:**
   - Enable/disable visualizer 100+ times
   - Monitor memory usage
   - Verify no leaks

**Measurement Tools:**
- Android Profiler
- LeakCanary (if integrated)
- `adb shell dumpsys meminfo`

**Target Metrics:**
- Memory growth: < 10MB over 2 hours
- No memory leaks detected

### 5. UI FPS Monitoring

**Test Cases:**
- ✅ Navigation performance
- ✅ List scrolling performance
- ✅ Now Playing screen performance
- ✅ Animation performance
- ✅ Visualizer UI performance

**Test Scenarios:**
1. **Navigation:**
   - Navigate between screens
   - Measure frame rate
   - Verify >= 60 FPS

2. **List Scrolling:**
   - Scroll large lists
   - Measure frame rate
   - Verify >= 60 FPS

3. **Now Playing:**
   - Render Now Playing screen
   - Measure frame rate
   - Verify >= 60 FPS

4. **Animations:**
   - Play Material 3 animations
   - Measure frame rate
   - Verify >= 60 FPS

5. **Visualizer UI:**
   - Render visualizer in UI
   - Measure frame rate
   - Verify >= 30 FPS

**Measurement Tools:**
- Flutter DevTools Performance tab
- `adb shell dumpsys gfxinfo`
- Frame rate monitoring

**Target Metrics:**
- Navigation: >= 60 FPS
- Scrolling: >= 60 FPS
- Now Playing: >= 60 FPS
- Animations: >= 60 FPS
- Visualizer: >= 30 FPS

## Test Execution

### Manual Testing

**Required Tools:**
- Android Profiler
- Battery monitoring tools
- Memory profiling tools
- Performance monitoring tools

**Test Procedure:**
1. Set up test environment
2. Start profiling
3. Execute test scenario
4. Monitor metrics
5. Document results

### Automated Testing

**Unit Tests:**
- Algorithm performance
- Data structure efficiency
- Query optimization

**Benchmark Tests:**
- Performance benchmarks
- Memory benchmarks
- CPU benchmarks

## Test Results Documentation

**Test Report Format:**
```
Test: [Test Name]
Date: [Date]
Device: [Device Model]
Result: [Pass/Fail]
Metrics:
  - [Metric Name]: [Value]
  - [Metric Name]: [Value]
Notes: [Observations]
```

## Known Issues / Limitations

1. **Device-Specific:**
   - Performance varies by device
   - Need testing on multiple devices

2. **Battery Testing:**
   - Requires real device
   - Long test duration

3. **Large Library:**
   - Requires test data generation
   - Time-consuming tests

## Future Improvements

1. **Automated Benchmarking:**
   - Continuous performance monitoring
   - Regression detection

2. **Performance Profiling:**
   - Automated profiling
   - Performance reports

3. **Optimization:**
   - Identify bottlenecks
   - Optimize hot paths
