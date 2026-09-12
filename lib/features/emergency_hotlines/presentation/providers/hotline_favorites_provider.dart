import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'hotline_favorites_provider.g.dart';

const _favoritesPrefsKey = 'elikas.hotlines.favorites';

/// Locally-favorited hotlines, keyed by [Hotline.name] — the closest
/// thing this static const list has to a stable id, and stable enough
/// for the purpose (the data file only changes via a code edit, which
/// would already require re-examining call sites like this one).
///
/// Backed by [SharedPreferences], the same lightweight mechanism
/// already used for the language/theme preference and per-domain sync
/// timestamps — deliberately not a new Isar collection just to persist
/// a handful of favorited names for a 7-entry static list.
@riverpod
class HotlineFavorites extends _$HotlineFavorites {
  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_favoritesPrefsKey) ?? const []).toSet();
  }

  Future<void> toggle(String hotlineName) async {
    final current = await future;
    final updated = {...current};
    if (!updated.remove(hotlineName)) updated.add(hotlineName);
    state = AsyncData(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesPrefsKey, updated.toList());
  }
}
