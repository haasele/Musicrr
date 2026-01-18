# Audio Testing Documentation

## Overview

This document outlines the audio testing strategy for Musicrr, including DSP processor tests, gapless playback tests, and format compatibility tests.

## Test Categories

### 1. DSP Processor Tests

#### Parametric EQ Processor

**Test Cases:**
- ✅ EQ band configuration (frequency, gain, Q)
- ✅ Multiple band processing
- ✅ Preamp gain application
- ✅ Limiter functionality (clipping prevention)
- ✅ Filter type selection (low shelf, peak, high shelf)
- ✅ Sample rate handling (44.1kHz, 48kHz, 96kHz)
- ✅ Channel handling (mono, stereo)
- ✅ Real-time processing performance

**Test Files:**
- `test/audio/dsp/parametric_eq_test.dart` - Unit tests for EQ logic
- Manual testing with audio files

**Test Scenarios:**
1. **Basic EQ Band:**
   - Configure single band at 1kHz with +3dB gain
   - Process test tone at 1kHz
   - Verify gain increase

2. **Multi-Band EQ:**
   - Configure 5-band EQ (60Hz, 250Hz, 1kHz, 4kHz, 12kHz)
   - Process full-range audio
   - Verify each band affects correct frequency range

3. **Preamp:**
   - Set preamp to +6dB
   - Process audio
   - Verify overall gain increase

4. **Limiter:**
   - Apply high gain (+12dB) to cause clipping
   - Enable limiter
   - Verify no clipping occurs

5. **Performance:**
   - Process 10 seconds of audio
   - Measure processing time
   - Verify < 50ms latency per buffer

#### ReplayGain Processor

**Test Cases:**
- ✅ Track-level gain application
- ✅ Album-level gain application
- ✅ Mode switching (track/album/disabled)
- ✅ Clipping prevention
- ✅ Gain calculation accuracy

**Test Scenarios:**
1. **Track Gain:**
   - Apply +3dB track gain
   - Process audio
   - Verify gain increase

2. **Album Gain:**
   - Apply -2dB album gain
   - Process audio
   - Verify gain decrease

3. **Clipping Prevention:**
   - Apply high gain (+15dB) to cause clipping
   - Enable limiter
   - Verify no clipping

4. **Mode Switching:**
   - Switch between track/album/disabled modes
   - Verify correct gain applied

#### Crossfade Mixer

**Test Cases:**
- ✅ Crossfade duration configuration
- ✅ Fade curve (linear, exponential)
- ✅ Dual stream mixing
- ✅ Transition timing
- ✅ Audio quality during crossfade

**Test Scenarios:**
1. **Basic Crossfade:**
   - Configure 3-second crossfade
   - Play two tracks with crossfade enabled
   - Verify smooth transition

2. **Fade Curves:**
   - Test linear fade
   - Test exponential fade
   - Compare audio quality

3. **Timing:**
   - Verify crossfade starts at correct time
   - Verify crossfade completes before track end

### 2. Gapless Playback Tests

**Test Cases:**
- ✅ Gapless transition between tracks
- ✅ Format support (MP3, FLAC, M4A)
- ✅ Gapless metadata detection
- ✅ Buffer management
- ✅ No gaps or clicks

**Test Scenarios:**
1. **MP3 Gapless:**
   - Play two MP3 tracks with gapless encoding
   - Verify no gap between tracks
   - Verify no clicks or pops

2. **FLAC Gapless:**
   - Play two FLAC tracks with padding metadata
   - Verify seamless transition

3. **M4A Gapless:**
   - Play two M4A tracks with iTunes gapless info
   - Verify seamless transition

4. **Mixed Formats:**
   - Play MP3 → FLAC transition
   - Verify acceptable transition quality

5. **Queue Playback:**
   - Play queue of 10 tracks
   - Verify all transitions are gapless

### 3. Format Compatibility Tests

**Supported Formats:**
- MP3 (MPEG-1/2 Layer 3)
- M4A/AAC (iTunes format)
- FLAC (Free Lossless Audio Codec)
- WAV (PCM)
- Opus (Ogg Opus)
- OGG (Vorbis)

**Test Cases:**
- ✅ Format detection
- ✅ Decoder initialization
- ✅ Playback correctness
- ✅ Metadata extraction
- ✅ Sample rate handling
- ✅ Bit depth handling
- ✅ Channel configuration

**Test Scenarios:**
1. **MP3:**
   - Test various bitrates (128kbps, 192kbps, 320kbps)
   - Test VBR and CBR
   - Test ID3v2 tags

2. **FLAC:**
   - Test various sample rates (44.1kHz, 48kHz, 96kHz)
   - Test various bit depths (16-bit, 24-bit)
   - Test VORBIS_COMMENT metadata

3. **M4A:**
   - Test AAC encoding
   - Test iTunes tags
   - Test gapless metadata

4. **Opus:**
   - Test various bitrates
   - Test Ogg container
   - Test metadata

5. **OGG:**
   - Test Vorbis codec
   - Test Ogg container
   - Test metadata

### 4. Audio Correctness Tests

**Test Cases:**
- ✅ Sample rate conversion
- ✅ Bit depth conversion
- ✅ Channel downmixing (5.1 → stereo)
- ✅ Volume normalization
- ✅ No distortion or artifacts
- ✅ Frequency response accuracy

**Test Scenarios:**
1. **Sample Rate Conversion:**
   - Play 96kHz file on 48kHz output
   - Verify correct downsampling
   - Verify no aliasing

2. **Bit Depth:**
   - Play 24-bit file
   - Verify correct conversion to 16-bit output
   - Verify no quantization artifacts

3. **Channel Downmixing:**
   - Play 5.1 surround file
   - Verify correct downmix to stereo
   - Verify channel balance

4. **Volume Normalization:**
   - Play tracks with varying loudness
   - Apply ReplayGain
   - Verify consistent perceived loudness

## Test Execution

### Manual Testing

**Required Test Files:**
- Test tones (sine waves at various frequencies)
- Full-range audio files
- Gapless test albums
- Format test files (MP3, FLAC, M4A, Opus, OGG)
- High-resolution test files (96kHz, 24-bit)

**Test Procedure:**
1. Load test file
2. Configure DSP settings
3. Play audio
4. Verify output (listening test or measurement)
5. Document results

### Automated Testing

**Unit Tests:**
- DSP processor logic
- Filter coefficient calculation
- Gain calculation
- Buffer management

**Instrumentation Tests:**
- Format detection
- Decoder initialization
- Playback state
- Error handling

## Test Results Documentation

**Test Report Format:**
```
Test: [Test Name]
Date: [Date]
Format: [Audio Format]
Result: [Pass/Fail]
Notes: [Observations]
```

## Known Issues / Limitations

1. **Platform Channel Mocking:**
   - Native audio tests require device/emulator
   - Platform channels need mocking for unit tests

2. **Audio Quality Verification:**
   - Subjective listening tests required
   - Objective measurements need audio analysis tools

3. **Performance Testing:**
   - Requires device profiling
   - Battery usage needs real device testing

## Future Improvements

1. **Automated Audio Analysis:**
   - Frequency response measurement
   - THD+N measurement
   - Phase response measurement

2. **Golden File Tests:**
   - Compare processed audio to reference
   - Detect regressions

3. **Stress Testing:**
   - Long playback sessions
   - Rapid format switching
   - Memory pressure testing
