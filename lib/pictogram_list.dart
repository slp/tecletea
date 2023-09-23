import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tecletea/constants.dart';

class Pictogram {
  final int id;
  final String name;

  const Pictogram({
    required this.id,
    required this.name,
  });
}

class PictogramList {
  final LinkedHashMap<int, Pictogram> list;

  const PictogramList({
    required this.list,
  });

  static bool isInList(List<dynamic> wordCategories, List<String> categories) {
    var included = false;
    for (var category in wordCategories) {
      if (categories.contains(category)) {
        included = true;
        break;
      }
    }

    return included;
  }

  factory PictogramList.fromJson(
      List<dynamic> json, SharedPreferences prefs, bool ignoreLocutions) {
    LinkedHashMap<int, Pictogram> list = LinkedHashMap();
    var i = 0;
    var minCharacters = DEFAULT_MIN_CHARACTERS;
    var maxCharacters = DEFAULT_MAX_CHARACTERS;
    var includedCategories = DEFAULT_INCLUDED_CATEGORIES;
    var excludedCategories = DEFAULT_EXCLUDED_CATEGORIES;

    if (prefs.getInt("minCharacters") != null) {
      minCharacters = prefs.getInt("minCharacters")!;
    }
    if (prefs.getInt("maxCharacters") != null) {
      maxCharacters = prefs.getInt("maxCharacters")!;
    }
    if (prefs.getStringList("includedCategories") != null) {
      includedCategories = prefs.getStringList("includedCategories")!;
    }
    if (prefs.getStringList("excludedCategories") != null) {
      excludedCategories = prefs.getStringList("excludedCategories")!;
    }

    for (var entry in json) {
      var tags = entry["tags"];
      if (entry["keywords"].length == 0) {
        continue;
      }
      var keyword = entry["keywords"][0]["keyword"];
      var hasLocution = entry["keywords"][0]["hasLocution"];

      if ((hasLocution || ignoreLocutions) &&
          keyword.length >= minCharacters &&
          keyword.length <= maxCharacters &&
          isInList(tags, includedCategories) &&
          !isInList(tags, excludedCategories)) {
        list[i] = (Pictogram(id: entry["_id"], name: keyword));
        i++;
      }
    }

    return PictogramList(list: list);
  }
}
