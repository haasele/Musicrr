import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import '../../features/now_playing/layout/layout_preset.dart';
import '../../features/now_playing/layout/layout_slot.dart';

class NowPlayingPresetRepository {
  final AppDatabase _database;
  
  NowPlayingPresetRepository(this._database);
  
  /// Get all presets
  Future<List<NowPlayingLayout>> getAllPresets() async {
    final presets = await _database.select(_database.nowPlayingPresets).get();
    return presets.map((p) => _presetFromRow(p)).toList();
  }
  
  /// Get preset by ID
  Future<NowPlayingLayout?> getPreset(String id) async {
    final query = _database.select(_database.nowPlayingPresets)
      ..where((p) => p.id.equals(id));
    final preset = await query.getSingleOrNull();
    return preset != null ? _presetFromRow(preset) : null;
  }
  
  /// Get active preset for a given scope
  Future<NowPlayingLayout?> getActivePreset({
    String? sourceId,
    String? albumId,
  }) async {
    // Priority: album → provider → global
    if (albumId != null) {
      final albumPreset = await _getPresetByScope(
        PresetScope.perAlbum,
        albumId,
      );
      if (albumPreset != null) return albumPreset;
    }
    
    if (sourceId != null) {
      final providerPreset = await _getPresetByScope(
        PresetScope.perProvider,
        sourceId,
      );
      if (providerPreset != null) return providerPreset;
    }
    
    return await _getPresetByScope(PresetScope.global, null);
  }
  
  Future<NowPlayingLayout?> _getPresetByScope(
    PresetScope scope,
    String? sourceId,
  ) async {
    final query = _database.select(_database.nowPlayingPresets)
      ..where((p) => p.scope.equals(_scopeToString(scope)));
    
    if (sourceId != null) {
      query.where((p) => p.sourceId.equals(sourceId));
    } else {
      query.where((p) => p.sourceId.isNull());
    }
    
    final preset = await query.getSingleOrNull();
    return preset != null ? _presetFromRow(preset) : null;
  }
  
  /// Save preset
  Future<void> savePreset(NowPlayingLayout preset) async {
    await _database.into(_database.nowPlayingPresets).insertOnConflictUpdate(
      NowPlayingPresetsCompanion(
        id: Value(preset.id),
        name: Value(preset.name),
        description: Value(preset.description),
        layoutJson: Value(jsonEncode(_slotsToJson(preset.slots))),
        backgroundConfigJson: Value(jsonEncode(preset.background.toJson())),
        scope: Value(_scopeToString(preset.scope)),
        sourceId: Value(preset.sourceId),
        createdAt: Value(preset.createdAt),
        lastModified: Value(preset.lastModified ?? DateTime.now()),
      ),
    );
  }
  
  /// Delete preset
  Future<void> deletePreset(String id) async {
    await (_database.delete(_database.nowPlayingPresets)
          ..where((p) => p.id.equals(id)))
        .go();
  }
  
  /// Set active preset for a scope
  Future<void> setActivePreset(String presetId, {String? sourceId}) async {
    // This would mark a preset as "active" for a scope
    // For now, we use the priority system in getActivePreset
    // Could add an "isActive" flag to the database if needed
  }
  
  NowPlayingLayout _presetFromRow(NowPlayingPreset row) {
    final slotsJson = jsonDecode(row.layoutJson) as List;
    final slots = slotsJson
        .map((s) => LayoutSlot.fromJson(s as Map<String, dynamic>))
        .toList();
    
    final backgroundJson = jsonDecode(row.backgroundConfigJson) as Map<String, dynamic>;
    final background = BackgroundConfig.fromJson(backgroundJson);
    
    return NowPlayingLayout(
      id: row.id,
      name: row.name,
      description: row.description,
      slots: slots,
      background: background,
      themeOverrides: null, // Could parse from JSON if stored
      createdAt: row.createdAt,
      lastModified: row.lastModified,
      scope: _scopeFromString(row.scope),
      sourceId: row.sourceId,
    );
  }
  
  List<Map<String, dynamic>> _slotsToJson(List<LayoutSlot> slots) {
    return slots.map((s) => s.toJson()).toList();
  }
  
  String _scopeToString(PresetScope scope) {
    switch (scope) {
      case PresetScope.global:
        return 'global';
      case PresetScope.perProvider:
        return 'provider';
      case PresetScope.perAlbum:
        return 'album';
    }
  }
  
  PresetScope _scopeFromString(String scope) {
    switch (scope) {
      case 'provider':
        return PresetScope.perProvider;
      case 'album':
        return PresetScope.perAlbum;
      default:
        return PresetScope.global;
    }
  }
}

final nowPlayingPresetRepositoryProvider = Provider<NowPlayingPresetRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return NowPlayingPresetRepository(database);
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
