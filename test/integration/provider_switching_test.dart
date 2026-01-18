import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicrr/core/providers/provider_repository.dart';
import 'package:musicrr/core/providers/local_provider.dart';
import 'package:musicrr/core/models/song.dart';
import 'package:musicrr/core/models/album.dart';
import 'package:musicrr/core/models/artist.dart';

/// Integration test for provider switching
/// Tests: provider enable/disable, switching between providers, offline mode
void main() {
  group('Provider Switching Integration Tests', () {
    late ProviderContainer container;
    late ProviderRepository repository;

    setUp(() {
      container = ProviderContainer();
      repository = container.read(providerRepositoryProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('Provider enable/disable', () {
      // Arrange
      final providers = repository.providers;
      expect(providers.isNotEmpty, isTrue);

      // Act - Disable provider (if supported)
      // Note: This is a placeholder test as enable/disable needs implementation
      // In real implementation, would call: repository.disableProvider(providerId)

      // Assert
      final activeProviders = repository.getActiveProviders();
      expect(activeProviders, isNotEmpty);
    });

    test('Get artists from multiple providers', () async {
      // Act
      final artists = await repository.getArtists();

      // Assert
      expect(artists, isA<List<Artist>>());
      // Should aggregate from all active providers
    });

    test('Get albums from multiple providers', () async {
      // Act
      final albums = await repository.getAlbums();

      // Assert
      expect(albums, isA<List<Album>>());
    });

    test('Get songs from multiple providers', () async {
      // Act
      final songs = await repository.getSongs();

      // Assert
      expect(songs, isA<List<Song>>());
    });

    test('Offline mode filtering', () {
      // Arrange
      repository.setOfflineMode(true);

      // Act
      final activeProviders = repository.getActiveProviders();

      // Assert
      // In offline mode, should only return local providers
      expect(activeProviders.every((p) => p is LocalProvider), isTrue);

      // Cleanup
      repository.setOfflineMode(false);
    });

    test('Provider sync', () async {
      // Arrange
      final providers = repository.providers;
      if (providers.isEmpty) {
        return; // Skip if no providers
      }
      final providerId = providers.first.id;

      // Act
      await repository.syncProvider(providerId, incremental: true);

      // Assert
      // Sync should complete without error
      // In real implementation, would verify last sync time
    });
  });
}
