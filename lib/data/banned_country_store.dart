import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// The configurable list of countries whose cards are refused, and the
/// reason recorded against each one.
///
/// Resolves in three layers: an admin's edits, then
/// `assets/config/banned_countries.json`, then a hard-coded fallback so a
/// missing asset cannot switch the check off. Swapping the asset layer for a
/// compliance feed needs no change outside this class.
class BannedCountryStore {
  BannedCountryStore({SharedPreferences? preferences}) : _preferences = preferences;

  static const String _key = 'banned_countries';
  static const String _assetPath = 'assets/config/banned_countries.json';

  static const Map<String, String> _fallback = {
    'IR': 'FATF call for action',
    'KP': 'FATF call for action',
    'MM': 'FATF call for action',
    'SY': 'Comprehensive sanctions',
    'CU': 'Comprehensive sanctions',
    'AF': 'Elevated AML risk',
  };

  SharedPreferences? _preferences;
  Map<String, String> _entries = {};
  Map<String, String> _defaults = {};
  String? _source;
  String? _reviewed;

  Set<String> get codes => _entries.keys.toSet();

  Set<String> get defaults => _defaults.keys.toSet();

  /// Provenance of the shipped list.
  String? get source => _source;

  String? get reviewed => _reviewed;

  bool get isCustomised => !_mapEquals(_entries, _defaults);

  bool isBanned(String countryCode) => _entries.containsKey(countryCode.toUpperCase());

  /// The recorded reason, or null if none was given.
  String? reasonFor(String countryCode) {
    final reason = _entries[countryCode.toUpperCase()];
    return (reason == null || reason.isEmpty) ? null : reason;
  }

  /// The reason the shipped list gives for a country, if it lists it. Used to
  /// pre-fill the field when an admin bans one of the defaults by hand.
  String? defaultReasonFor(String countryCode) {
    final reason = _defaults[countryCode.toUpperCase()];
    return (reason == null || reason.isEmpty) ? null : reason;
  }

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    _defaults = await _loadDefaults();

    final stored = _preferences!.getString(_key);
    if (stored == null) {
      _entries = Map.of(_defaults);
      return;
    }

    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      _entries = {
        for (final entry in decoded.entries)
          entry.key.toUpperCase(): (entry.value as String?) ?? '',
      };
    } catch (_) {
      _entries = Map.of(_defaults);
      await _preferences!.remove(_key);
    }
  }

  /// Adds a country, or replaces the reason if it is already listed.
  Future<void> add(String countryCode, {String? reason}) async {
    final code = countryCode.toUpperCase();
    _entries[code] = (reason ?? _defaults[code] ?? '').trim();
    await _persist();
  }

  /// Changes the reason recorded against a country already on the list.
  Future<void> setReason(String countryCode, String reason) async {
    final code = countryCode.toUpperCase();
    if (!_entries.containsKey(code)) return;
    _entries[code] = reason.trim();
    await _persist();
  }

  Future<void> remove(String countryCode) async {
    if (_entries.remove(countryCode.toUpperCase()) != null) await _persist();
  }

  Future<void> resetToDefaults() async {
    _entries = Map.of(_defaults);
    await _preferences?.remove(_key);
  }

  Future<Map<String, String>> _loadDefaults() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _source = json['source'] as String?;
      _reviewed = json['reviewed'] as String?;

      final entries = (json['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
      final parsed = {
        for (final entry in entries)
          (entry['code'] as String).toUpperCase(): entry['reason'] as String? ?? '',
      };
      return parsed.isEmpty ? _fallback : parsed;
    } catch (_) {
      _source = 'Built-in fallback list';
      _reviewed = null;
      return _fallback;
    }
  }

  Future<void> _persist() async {
    await _preferences?.setString(_key, jsonEncode(_entries));
  }

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.keys.every((k) => b[k] == a[k]);
}
