import 'package:shared_preferences/shared_preferences.dart';

class PropertyOverrideService {
  static const _sponsoredKey = 'overridden_sponsored_properties';

  Future<Set<int>> _readSponsoredIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_sponsoredKey);
    if (raw == null) return {};
    return raw.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
  }

  Future<void> markAsSponsored(int propertyId) async {
    final ids = await _readSponsoredIds();
    ids.add(propertyId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _sponsoredKey,
      ids.map((e) => e.toString()).toList(),
    );
  }

  Future<bool> isSponsored(int propertyId) async {
    final ids = await _readSponsoredIds();
    return ids.contains(propertyId);
  }
}
