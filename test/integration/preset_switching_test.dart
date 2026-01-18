import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicrr/core/storage/now_playing_preset_repository.dart';
import 'package:musicrr/features/now_playing/layout/layout_preset.dart';
import 'package:musicrr/features/now_playing/layout/layout_slot.dart';

/// Integration test for preset switching
/// Tests: preset loading, scope-based selection, preset saving
void main() {
  group('Preset Switching Integration Tests', () {
    late ProviderContainer container;
    late NowPlayingPresetRepository repository;

    setUp(() {
      container = ProviderContainer();
      repository = container.read(nowPlayingPresetRepositoryProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('Save and load preset', () async {
      // Arrange
      final preset = NowPlayingLayout(
        id: 'test_preset',
        name: 'Test Preset',
        description: 'Test description',
        slots: [
          LayoutSlot(
            row: 0,
            column: 0,
            rowSpan: 2,
            columnSpan: 2,
            componentId: 'cover_art',
          ),
        ],
        background: BackgroundConfig(type: BackgroundType.solid),
        createdAt: DateTime.now(),
        scope: PresetScope.global,
      );

      // Act
      await repository.savePreset(preset);
      final loaded = await repository.getPreset('test_preset');

      // Assert
      expect(loaded, isNotNull);
      expect(loaded!.id, equals('test_preset'));
      expect(loaded.name, equals('Test Preset'));
      expect(loaded.slots.length, equals(1));
    });

    test('Get all presets', () async {
      // Arrange
      final preset1 = NowPlayingLayout(
        id: 'preset_1',
        name: 'Preset 1',
        slots: [],
        background: BackgroundConfig(type: BackgroundType.solid),
        createdAt: DateTime.now(),
        scope: PresetScope.global,
      );
      final preset2 = NowPlayingLayout(
        id: 'preset_2',
        name: 'Preset 2',
        slots: [],
        background: BackgroundConfig(type: BackgroundType.solid),
        createdAt: DateTime.now(),
        scope: PresetScope.global,
      );
      await repository.savePreset(preset1);
      await repository.savePreset(preset2);

      // Act
      final presets = await repository.getAllPresets();

      // Assert
      expect(presets.length, greaterThanOrEqualTo(2));
      expect(presets.any((p) => p.id == 'preset_1'), isTrue);
      expect(presets.any((p) => p.id == 'preset_2'), isTrue);
    });

    test('Get active preset by scope', () async {
      // Arrange
      final globalPreset = NowPlayingLayout(
        id: 'global_preset',
        name: 'Global Preset',
        slots: [],
        background: BackgroundConfig(type: BackgroundType.solid),
        createdAt: DateTime.now(),
        scope: PresetScope.global,
      );
      final providerPreset = NowPlayingLayout(
        id: 'provider_preset',
        name: 'Provider Preset',
        slots: [],
        background: BackgroundConfig(type: BackgroundType.solid),
        createdAt: DateTime.now(),
        scope: PresetScope.perProvider,
        sourceId: 'test_provider',
      );
      await repository.savePreset(globalPreset);
      await repository.savePreset(providerPreset);

      // Act - Get provider preset
      final activeProvider = await repository.getActivePreset(
        sourceId: 'test_provider',
      );

      // Assert
      expect(activeProvider, isNotNull);
      expect(activeProvider!.id, equals('provider_preset'));

      // Act - Get global preset (no provider)
      final activeGlobal = await repository.getActivePreset();

      // Assert
      expect(activeGlobal, isNotNull);
      expect(activeGlobal!.id, equals('global_preset'));
    });

    test('Delete preset', () async {
      // Arrange
      final preset = NowPlayingLayout(
        id: 'delete_test',
        name: 'Delete Test',
        slots: [],
        background: BackgroundConfig(type: BackgroundType.solid),
        createdAt: DateTime.now(),
        scope: PresetScope.global,
      );
      await repository.savePreset(preset);

      // Act
      await repository.deletePreset('delete_test');

      // Assert
      final loaded = await repository.getPreset('delete_test');
      expect(loaded, isNull);
    });
  });
}
