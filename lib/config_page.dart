import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tecletea/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConfigPage extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback onCompletion;

  const ConfigPage({
    Key? key,
    required this.prefs,
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
    textControllerIncluded.text = _includedCategories.join(", ");
    textControllerExcluded.text = _excludedCategories.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 640.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          max: 8,
                          divisions: 8,
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
                          max: 8,
                          divisions: 8,
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
                  Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                          AppLocalizations.of(context)!.includedCategories,
                          textAlign: TextAlign.left,
                          style: prefItemStyle)),
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
                      child: Text(
                          AppLocalizations.of(context)!.excludedCategories,
                          textAlign: TextAlign.left,
                          style: prefItemStyle)),
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
                  const SizedBox(height: 30),
                  Align(
                      alignment: Alignment.center,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: () {
                                  widget.prefs
                                      .setInt("maxIterations", _maxIterations);
                                  widget.prefs
                                      .setInt("minCharacters", _minCharacters);
                                  widget.prefs
                                      .setInt("maxCharacters", _maxCharacters);
                                  widget.prefs.setStringList(
                                      "includedCategories",
                                      textControllerIncluded.text.split(", "));
                                  widget.prefs.setStringList(
                                      "excludedCategories",
                                      textControllerExcluded.text.split(", "));
                                  widget.onCompletion();
                                },
                                child: Text(AppLocalizations.of(context)!.save,
                                    style: buttonSyle)),
                            const SizedBox(width: 20),
                            ElevatedButton(
                                onPressed: () {
                                  widget.prefs.setInt(
                                      "maxIterations", DEFAULT_MAX_ITERATIONS);
                                  widget.prefs.setInt(
                                      "minCharacters", DEFAULT_MIN_CHARACTERS);
                                  widget.prefs.setInt(
                                      "maxCharacters", DEFAULT_MAX_CHARACTERS);
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
                                    textControllerIncluded.text =
                                        DEFAULT_INCLUDED_CATEGORIES.join(", ");
                                    textControllerExcluded.text =
                                        DEFAULT_EXCLUDED_CATEGORIES.join(", ");
                                  });
                                },
                                child: Text(
                                    AppLocalizations.of(context)!.restore,
                                    style: buttonSyle))
                          ]))
                ],
              )))
    ]);
  }
}
