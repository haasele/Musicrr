# Network Testing Documentation

## Overview

This document outlines the network testing strategy for Musicrr, including provider failure tests, offline mode tests, cache behavior tests, and remote control network tests.

## Test Categories

### 1. Provider Failure Tests

#### Network Provider Failures

**Test Cases:**
- ✅ Connection timeout
- ✅ DNS resolution failure
- ✅ HTTP error responses (404, 500, etc.)
- ✅ Authentication failure
- ✅ SSL/TLS errors
- ✅ Network unavailable
- ✅ Partial response (connection dropped mid-stream)

**Test Scenarios:**
1. **Connection Timeout:**
   - Configure provider with unreachable server
   - Attempt to fetch data
   - Verify timeout error handling
   - Verify user-friendly error message

2. **HTTP Errors:**
   - Simulate 404 (not found)
   - Simulate 500 (server error)
   - Simulate 401 (unauthorized)
   - Verify error handling and user notification

3. **Authentication Failure:**
   - Provide invalid credentials
   - Verify authentication error
   - Verify credential retry mechanism

4. **Network Unavailable:**
   - Disable network connection
   - Attempt provider operations
   - Verify graceful degradation
   - Verify offline mode activation

5. **Partial Response:**
   - Start download/stream
   - Drop connection mid-transfer
   - Verify error recovery
   - Verify partial data handling

#### Provider-Specific Failures

**WebDAV Provider:**
- PROPFIND request failure
- Authentication failure
- Directory not found
- Permission denied

**SMB Provider:**
- Share connection failure
- Authentication failure
- Network path not found
- Permission denied

**Subsonic Provider:**
- API endpoint failure
- Authentication failure
- Invalid API version
- Server error

**Jellyfin Provider:**
- API endpoint failure
- JWT token expiration
- Authentication failure
- Server error

### 2. Offline Mode Tests

**Test Cases:**
- ✅ Offline mode activation
- ✅ Provider filtering (only local providers)
- ✅ Cache access
- ✅ Download queue management
- ✅ UI state updates
- ✅ Network status detection

**Test Scenarios:**
1. **Offline Mode Activation:**
   - Enable offline mode
   - Verify only local providers active
   - Verify network providers disabled
   - Verify UI shows offline indicator

2. **Cache Access:**
   - Play cached file in offline mode
   - Verify playback works
   - Verify cache metadata access

3. **Download Queue:**
   - Queue downloads
   - Enable offline mode
   - Verify download queue paused
   - Re-enable network
   - Verify downloads resume

4. **Network Status Detection:**
   - Monitor network connectivity
   - Verify automatic offline mode suggestion
   - Verify network status indicator

### 3. Cache Behavior Tests

**Test Cases:**
- ✅ Cache file storage
- ✅ Cache retrieval
- ✅ Cache size enforcement
- ✅ Cache priority retention
- ✅ Cache cleanup
- ✅ Cache metadata updates
- ✅ Cache invalidation

**Test Scenarios:**
1. **Cache Storage:**
   - Stream audio file
   - Verify file cached
   - Verify cache metadata created
   - Verify file size recorded

2. **Cache Retrieval:**
   - Request cached file
   - Verify file returned from cache
   - Verify access metadata updated
   - Verify no network request

3. **Cache Size Enforcement:**
   - Fill cache to limit
   - Add new file
   - Verify oldest/lowest priority files deleted
   - Verify cache size under limit

4. **Cache Priority:**
   - Mark files with different priorities
   - Fill cache to limit
   - Verify high-priority files retained
   - Verify low-priority files deleted first

5. **Cache Cleanup:**
   - Clear cache
   - Verify all files deleted
   - Verify metadata cleared
   - Verify disk space freed

### 4. Remote Control Network Tests

**Test Cases:**
- ✅ Server startup/shutdown
- ✅ Port binding conflicts
- ✅ Network interface binding
- ✅ Connection handling
- ✅ WebSocket stability
- ✅ Request timeout
- ✅ Concurrent connections

**Test Scenarios:**
1. **Server Lifecycle:**
   - Start server
   - Verify server running
   - Verify port bound
   - Stop server
   - Verify clean shutdown

2. **Port Conflicts:**
   - Start server on port 8080
   - Attempt to start another instance
   - Verify port conflict handling
   - Verify auto-increment to 8081

3. **Network Binding:**
   - Verify server binds to local network
   - Verify accessible from other devices
   - Verify not accessible from internet
   - Test localhost access

4. **WebSocket Stability:**
   - Establish WebSocket connection
   - Send multiple messages
   - Verify connection stability
   - Test reconnection on disconnect

5. **Concurrent Connections:**
   - Connect multiple clients
   - Send requests from all clients
   - Verify all clients receive updates
   - Verify server stability

6. **Request Timeout:**
   - Send slow request
   - Verify timeout handling
   - Verify error response
   - Verify server continues operating

## Test Execution

### Manual Testing

**Required Setup:**
- Test network environment
- Mock servers for providers
- Network simulation tools
- Multiple devices for remote control testing

**Test Procedure:**
1. Configure test environment
2. Execute test scenario
3. Monitor network traffic
4. Verify expected behavior
5. Document results

### Automated Testing

**Unit Tests:**
- Provider error handling
- Cache logic
- Network status detection
- Offline mode filtering

**Integration Tests:**
- Provider failure recovery
- Cache behavior
- Remote control server

## Test Results Documentation

**Test Report Format:**
```
Test: [Test Name]
Date: [Date]
Provider: [Provider Type]
Result: [Pass/Fail]
Error: [Error Details]
Recovery: [Recovery Behavior]
```

## Known Issues / Limitations

1. **Network Simulation:**
   - Requires network simulation tools
   - Some tests need real network conditions

2. **Provider Mocking:**
   - Need mock servers for each provider type
   - Authentication testing requires valid credentials

3. **Remote Control Testing:**
   - Requires multiple devices
   - Network conditions affect testing

## Future Improvements

1. **Network Simulation:**
   - Automated network condition simulation
   - Bandwidth throttling
   - Latency simulation

2. **Provider Mock Servers:**
   - Mock WebDAV server
   - Mock Subsonic server
   - Mock Jellyfin server

3. **Stress Testing:**
   - High concurrent connection count
   - Large file transfers
   - Extended offline mode
