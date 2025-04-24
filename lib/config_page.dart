import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tecletea/constants.dart';
import 'package:tecletea/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConfigPage extends StatefulWidget {
  final SharedPreferences prefs;
  final String localeString;
  final VoidCallback onCompletion;

  const ConfigPage({
    Key? key,
    required this.prefs,
    required this.localeString,
    required this.onCompletion,
  }) : super(key: key);

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  var _maxIterations = DEFAULT_MAX_ITERATIONS;
  var _minCharacters = DEFAULT_MIN_CHARACTERS;
  var _maxCharacters = DEFAULT_MAX_CHARACTERS;
  var _includedCategories = DEFAULT_INCLUDED_CATEGORIES;
  var _excludedCategories = DEFAULT_EXCLUDED_CATEGORIES;
  var _appMode = DEFAULT_APP_MODE;
  var _appLocale = DEFAULT_APP_LOCALE;
  var _percentRevealed = DEFAULT_PERCENT_REVEALED;
  var _showMoreConfig = false;
  final textControllerIncluded = TextEditingController();
  final textControllerExcluded = TextEditingController();
  final prefItemStyle =
      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  final buttonSyle = const TextStyle(fontSize: 48);

  @override
  initState() {
    super.initState();
    if (widget.prefs.getInt("maxIterations") != null) {
      _maxIterations = widget.prefs.getInt("maxIterations")!;
    }
    if (widget.prefs.getInt("minCharacters") != null) {
      _minCharacters = widget.prefs.getInt("minCharacters")!;
    }
    if (widget.prefs.getInt("maxCharacters") != null) {
      _maxCharacters = widget.prefs.getInt("maxCharacters")!;
    }
    if (widget.prefs.getStringList("includedCategories") != null) {
      _includedCategories = widget.prefs.getStringList("includedCategories")!;
    }
    if (widget.prefs.getStringList("excludedCategories") != null) {
      _excludedCategories = widget.prefs.getStringList("excludedCategories")!;
    }
    if (widget.prefs.getInt("appMode") != null) {
      _appMode = widget.prefs.getInt("appMode")!;
    }
    if (widget.prefs.getInt("percentRevealed") != null) {
      _percentRevealed = widget.prefs.getInt("percentRevealed")!;
    }
    if (widget.prefs.getString("appLocale") != null) {
      _appLocale = widget.prefs.getString("appLocale")!;
    } else {
      _appLocale = widget.localeString;
    }
    textControllerIncluded.text = _includedCategories.join(", ");
    textControllerExcluded.text = _excludedCategories.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    var showMore = Row(
      children: [
        InkWell(
            onTap: () {
              setState(() {
                _showMoreConfig = true;
              });
            },
            child: SizedBox(
                width: 640,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.showMore,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.more),
                  ],
                )))
      ],
    );
    var moreConfig =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.all(5),
          child: Text(AppLocalizations.of(context)!.language,
              textAlign: TextAlign.left, style: prefItemStyle)),
      Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color.fromARGB(44, 150, 166, 115),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
              padding: const EdgeInsets.all(5),
              child: DropdownButton<String>(
                value: SUPPORTED_LANGUAGES[_appLocale],
                items: SUPPORTED_LANGUAGES.values
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    if (value != null) {
                      for (var l in SUPPORTED_LANGUAGES.entries) {
                        if (value == l.value) {
                          _appLocale = l.key;
                          MyApp.of(context)!.setLocale(
                              Locale.fromSubtags(languageCode: _appLocale));
                          break;
                        }
                      }
                    }
                  });
                },
              ))),
      Padding(
          padding: const EdgeInsets.all(5),
          child: Text(AppLocalizations.of(context)!.includedCategories,
              textAlign: TextAlign.left, style: prefItemStyle)),
      Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color.fromARGB(47, 125, 157, 179),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: textControllerIncluded,
              ))),
      const SizedBox(height: 10),
      Padding(
          padding: const EdgeInsets.all(5),
          child: Text(AppLocalizations.of(context)!.excludedCategories,
              textAlign: TextAlign.left, style: prefItemStyle)),
      Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color.fromARGB(76, 134, 125, 179),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: textControllerExcluded,
              ))),
    ]);

    Widget moreWidget = showMore;
    if (_showMoreConfig) {
      moreWidget = moreConfig;
    }

    return Column(children: [
      Expanded(
          child: SingleChildScrollView(
              child: Container(
                  constraints: const BoxConstraints(maxWidth: 640.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(AppLocalizations.of(context)!.appMode,
                              textAlign: TextAlign.left, style: prefItemStyle)),
                      Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(95, 218, 165, 165),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Column(children: [
                                Row(children: [
                                  SizedBox(
                                      width: 175,
                                      child: RadioListTile(
                                          title: Text(
                                              AppLocalizations.of(context)!
                                                  .copyWord),
                                          value: APP_MODE_COPY,
                                          groupValue: _appMode,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value != null)
                                                _appMode = value;
                                            });
                                          })),
                                  SizedBox(
                                      width: 175,
                                      child: RadioListTile(
                                          title: Text(
                                              AppLocalizations.of(context)!
                                                  .completeWord),
                                          value: APP_MODE_COMPLETE,
                                          groupValue: _appMode,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value != null)
                                                _appMode = value;
                                            });
                                          })),
                                  SizedBox(
                                      width: 250,
                                      child: RadioListTile(
                                          title: Text(
                                              AppLocalizations.of(context)!
                                                  .copyCompleteWord),
                                          value: APP_MODE_MIXED,
                                          groupValue: _appMode,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value != null)
                                                _appMode = value;
                                            });
                                          })),
                                ]),
                                Row(children: [
                                  SizedBox(
                                      width: 250,
                                      child: RadioListTile(
                                          title: Text(
                                              AppLocalizations.of(context)!
                                                  .completeWordHints),
                                          value: APP_MODE_COMPLETE_HINTS,
                                          groupValue: _appMode,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value != null)
                                                _appMode = value;
                                            });
                                          })),
                                  SizedBox(
                                      width: 350,
                                      child: RadioListTile(
                                          title: Text(
                                              AppLocalizations.of(context)!
                                                  .copyCompleteWordHints),
                                          value: APP_MODE_MIXED_HINTS,
                                          groupValue: _appMode,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value != null)
                                                _appMode = value;
                                            });
                                          })),
                                ])
                              ]))),
                      const SizedBox(height: 10),
                      Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                              "${AppLocalizations.of(context)!.percentRevealed}${_percentRevealed.toString()}%",
                              textAlign: TextAlign.left,
                              style: prefItemStyle)),
                      Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(95, 205, 80, 80),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Slider(
                              value: _percentRevealed.toDouble(),
                              min: 0,
                              max: 80,
                              divisions: 4,
                              label: AppLocalizations.of(context)!.percent,
                              onChanged: (double value) {
                                setState(() {
                                  _percentRevealed = value.toInt();
                                });
                              },
                            ),
                          )),
                      const SizedBox(height: 10),
                      Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                              AppLocalizations.of(context)!.wordsPerSession +
                                  _maxIterations.toString(),
                              textAlign: TextAlign.left,
                              style: prefItemStyle)),
                      Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(197, 125, 161, 179),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Slider(
                              value: _maxIterations.toDouble(),
                              min: 1,
                              max: 50,
                              divisions: 50,
                              label: AppLocalizations.of(context)!.words,
                              onChanged: (double value) {
                                setState(() {
                                  _maxIterations = value.round();
                                });
                              },
                            ),
                          )),
                      const SizedBox(height: 10),
                      Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                              AppLocalizations.of(context)!.minCharacters +
                                  _minCharacters.toString(),
                              textAlign: TextAlign.left,
                              style: prefItemStyle)),
                      Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(197, 114, 183, 159),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Slider(
                              value: _minCharacters.toDouble(),
                              min: 1,
                              max: LIMIT_MAX_CHARACTERS.toDouble(),
                              divisions: LIMIT_MAX_CHARACTERS,
                              label: AppLocalizations.of(context)!.characters,
                              onChanged: (double value) {
                                setState(() {
                                  _minCharacters = value.round();
                                  if (_maxCharacters < _minCharacters) {
                                    _maxCharacters = _minCharacters;
                                  }
                                });
                              },
                            ),
                          )),
                      const SizedBox(height: 10),
                      Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                              AppLocalizations.of(context)!.maxCharacters +
                                  _maxCharacters.toString(),
                              textAlign: TextAlign.left,
                              style: prefItemStyle)),
                      Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(197, 148, 179, 125),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Slider(
                              value: _maxCharacters.toDouble(),
                              min: 1,
                              max: LIMIT_MAX_CHARACTERS.toDouble(),
                              divisions: LIMIT_MAX_CHARACTERS,
                              label: AppLocalizations.of(context)!.characters,
                              onChanged: (double value) {
                                setState(() {
                                  _maxCharacters = value.round();
                                  if (_minCharacters > _maxCharacters) {
                                    _minCharacters = _maxCharacters;
                                  }
                                });
                              },
                            ),
                          )),
                      const SizedBox(height: 10),
                      moreWidget,
                      const SizedBox(height: 30),
                      Align(
                          alignment: Alignment.center,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                    onPressed: () {
                                      widget.prefs.setInt(
                                          "maxIterations", _maxIterations);
                                      widget.prefs.setInt(
                                          "minCharacters", _minCharacters);
                                      widget.prefs.setInt(
                                          "maxCharacters", _maxCharacters);
                                      widget.prefs.setInt("appMode", _appMode);
                                      widget.prefs.setInt(
                                          "percentRevealed", _percentRevealed);
                                      widget.prefs
                                          .setString("appLocale", _appLocale);
                                      widget.prefs.setStringList(
                                          "includedCategories",
                                          textControllerIncluded.text
                                              .split(", "));
                                      widget.prefs.setStringList(
                                          "excludedCategories",
                                          textControllerExcluded.text
                                              .split(", "));
                                      widget.onCompletion();
                                    },
                                    child: Text(
                                        AppLocalizations.of(context)!.save,
                                        style: buttonSyle)),
                                const SizedBox(width: 20),
                                ElevatedButton(
                                    onPressed: () {
                                      widget.prefs.setInt("maxIterations",
                                          DEFAULT_MAX_ITERATIONS);
                                      widget.prefs.setInt("minCharacters",
                                          DEFAULT_MIN_CHARACTERS);
                                      widget.prefs.setInt("maxCharacters",
                                          DEFAULT_MAX_CHARACTERS);
                                      widget.prefs
                                          .setInt("appMode", DEFAULT_APP_MODE);
                                      widget.prefs.setInt("percentRevealed",
                                          DEFAULT_PERCENT_REVEALED);
                                      widget.prefs.setStringList(
                                          "includedCategories",
                                          DEFAULT_INCLUDED_CATEGORIES);
                                      widget.prefs.setStringList(
                                          "excludedCategories",
                                          DEFAULT_EXCLUDED_CATEGORIES);
                                      setState(() {
                                        _maxIterations = DEFAULT_MAX_ITERATIONS;
                                        _minCharacters = DEFAULT_MIN_CHARACTERS;
                                        _maxCharacters = DEFAULT_MAX_CHARACTERS;
                                        _appMode = DEFAULT_APP_MODE;
                                        _percentRevealed =
                                            DEFAULT_PERCENT_REVEALED;
                                        textControllerIncluded.text =
                                            DEFAULT_INCLUDED_CATEGORIES
                                                .join(", ");
                                        textControllerExcluded.text =
                                            DEFAULT_EXCLUDED_CATEGORIES
                                                .join(", ");
                                      });
                                    },
                                    child: Text(
                                        AppLocalizations.of(context)!.restore,
                                        style: buttonSyle))
                              ])),
                      const SizedBox(height: 20)
                    ],
                  )))),
    ]);
  }
}
