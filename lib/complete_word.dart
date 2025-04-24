import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tecletea/constants.dart';
import 'package:tecletea/syllables.dart';
import 'package:tecletea/utils.dart';

class CompleteWord extends StatefulWidget {
  final String word;
  final String locale;
  final bool showHints;
  final int percentRevealed;
  final Random random;
  final VoidCallback onCompletion;

  const CompleteWord({
    Key? key,
    required this.word,
    required this.locale,
    required this.showHints,
    required this.percentRevealed,
    required this.random,
    required this.onCompletion,
  }) : super(key: key);

  @override
  State<CompleteWord> createState() => _CompleteWordState();
}

class _CompleteWordState extends State<CompleteWord> {
  late List<String> entry;
  late List<String> syllables;
  late List<String> hintA;
  late List<String> hintB;
  late List<String> hintC;
  late AudioPlayer _player;
  var _revealedLetters = [];
  var _focusNodes = [];
  var _entryEnabled = true;
  var _newWord = true;
  var _iteration = 0;
  var _success = false;
  final _entryTextStyle = const TextStyle(
      fontFamily: 'monospace',
      fontFeatures: [FontFeature.tabularFigures()],
      fontSize: 48,
      fontWeight: FontWeight.w600);
  final _textControllers = [];
  final List<String> emojis = const [
    "😁",
    "😄",
    "😃",
    "😀",
    "🎉",
    "👍",
    "👌",
    "🚀",
    "👏"
  ];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    entry = List.filled(LIMIT_MAX_CHARACTERS, '\u200b');

    resetHints();

    for (var i = 0; i < LIMIT_MAX_CHARACTERS; i++) {
      _focusNodes.add(FocusNode());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger a rebuild to work around focus logic.
      setState(() {});
    });
  }

  int next(int min, int max) => min + widget.random.nextInt(max - min);

  void resetHints() {
    if (widget.locale == "es") {
      syllables = Syllables.process(widget.word).getSyllables();
      hintA = [];
      hintB = [];
      hintC = [];

      var prevCorrect = 3;
      for (var syl in syllables) {
        List<List<String>> hints = [hintA, hintB, hintC];
        List<String> opts = [];
        opts.add(syl);
        opts.add(alterSyllable(syl));
        opts.add(alterSyllable(syl));

        int correct;
        while (true) {
          correct = widget.random.nextInt(3);
          if (correct != prevCorrect) {
            prevCorrect = correct;
            break;
          }
        }

        var hint = hints.removeAt(correct);
        hint.add(opts.removeAt(0));
        hint = hints.removeAt(0);
        hint.add(opts.removeAt(0));
        hint = hints.removeAt(0);
        hint.add(opts.removeAt(0));
      }
    } else {
      syllables = [widget.word];
    }
  }

  void resetRevealed() {
    _revealedLetters = [];
    var wordLength = widget.word.length;
    var numRevealedLetters = (wordLength * widget.percentRevealed) ~/ 100;
    if (numRevealedLetters == 0 && widget.percentRevealed != 0) {
      numRevealedLetters = 1;
    }
    if (numRevealedLetters >= wordLength) {
      numRevealedLetters = wordLength - 1;
    }
    var i = 0;
    while (i < numRevealedLetters) {
      var index = next(0, wordLength - 1);
      if (_revealedLetters.contains(index)) {
        continue;
      } else {
        _revealedLetters.add(index);
        i++;
      }
    }
  }

  void resetEntry() {
    entry = List.filled(LIMIT_MAX_CHARACTERS, '\u200b');

    for (var f in _focusNodes) {
      f.dispose();
    }
    _focusNodes = [];
    for (var i = 0; i < LIMIT_MAX_CHARACTERS; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  int findNextTarget(int current, bool backwards) {
    var increment = 1;
    if (backwards) {
      increment = -1;
    }
    var target = current + increment;
    var found = false;
    while (target >= 0 && target < widget.word.length) {
      if (!_revealedLetters.contains(target)) {
        found = true;
        break;
      }
      target += increment;
    }
    if (found) {
      return target;
    } else {
      return -1;
    }
  }

  String alterSyllable(String syl) {
    int tochange;
    if (syl.length < 2) {
      tochange = 0;
    } else {
      tochange = widget.random.nextInt(syl.length);
    }
    var altered = syl.replaceRange(
        tochange, tochange + 1, getRandomLetter(syl[tochange], widget.random));
    return altered;
  }

  void validate() async {
    setState(() {
      _entryEnabled = false;
    });

    var match = true;
    for (var i = 0; i < widget.word.length; i++) {
      if (widget.word[i] != entry[i]) {
        match = false;
        break;
      }
    }

    if (match) {
      _player.setAsset("sounds/success.mp3");
      _player.play();
      setState(() {
        _success = true;
      });

      await Future.delayed(const Duration(milliseconds: 2000));
      _newWord = true;
      widget.onCompletion();
    } else {
      await Future.delayed(const Duration(milliseconds: 250));
      for (var c in _textControllers) {
        c.text = "";
      }
    }

    resetEntry();

    _success = false;

    setState(() {
      _entryEnabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    var textDecoration = const InputDecoration(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(vertical: -2, horizontal: 12),
      counterText: "",
    );

    if (_newWord) {
      resetRevealed();
      resetHints();
      _newWord = false;
    }

    List<Widget> entryWidgets = [];
    List<Widget> hintAWidgets = [];
    List<Widget> hintBWidgets = [];
    List<Widget> hintCWidgets = [];
    LinkedHashMap<String, bool> letters = LinkedHashMap();

    for (var tc in _textControllers) {
      tc.dispose();
    }
    _textControllers.clear();

    for (var i = 0; i < widget.word.characters.length; ++i) {
      var l = widget.word.characters.elementAt(i);
      if (_revealedLetters.contains(i)) {
        letters[l] = true;
        entry[i] = l;
      } else {
        letters[l] = false;
      }
    }

    if (widget.locale == "es" && widget.showHints) {
      for (var hint in {
        hintA: hintAWidgets,
        hintB: hintBWidgets,
        hintC: hintCWidgets
      }.entries) {
        var first = true;

        for (var syl in hint.key) {
          if (first) {
            first = false;
          } else {
            hint.value.add(const SizedBox(width: 68));
          }

          for (var i = 0; i < syl.length; i++) {
            if (i != 0) {
              hint.value.add(const SizedBox(width: 20));
            }

            hint.value.add(SizedBox(
                width: 68,
                child: TextFormField(
                    key: UniqueKey(),
                    initialValue: syl[i],
                    maxLength: 1,
                    enabled: false,
                    readOnly: true,
                    textAlign: TextAlign.center,
                    style: _entryTextStyle,
                    showCursor: false,
                    decoration: textDecoration)));
          }
        }
      }
    }

    var first = true;
    var pos = 0;

    for (var syl in syllables) {
      if (first) {
        first = false;
      } else {
        entryWidgets.add(const SizedBox(width: 68));
      }

      for (var i = 0; i < syl.length; i++) {
        var lpos = pos;
        if (i != 0) {
          entryWidgets.add(const SizedBox(width: 20));
        }

        _textControllers.add(TextEditingController(text: entry[pos]));

        entryWidgets.add(SizedBox(
            width: 68,
            child: TextFormField(
                key: UniqueKey(),
                maxLength: 2,
                enabled: _entryEnabled && !_revealedLetters.contains(pos),
                focusNode: _focusNodes[pos],
                autofocus: false,
                controller: _textControllers[pos],
                onFieldSubmitted: (value) {},
                onEditingComplete: () {},
                onTapOutside: (event) {},
                onChanged: (text) {
                  if (text.isEmpty) {
                    _textControllers[lpos].text = "\u200b";
                    var target = findNextTarget(lpos, true);
                    if (target == -1) {
                      setState(() {
                        resetEntry();
                      });
                    } else {
                      _textControllers[target].text = "\u200b";
                      _focusNodes[target].requestFocus();
                    }
                  } else if (text.length == 1 || text.length == 2) {
                    entry[lpos] = text[text.length - 1];
                    var target = findNextTarget(lpos, false);
                    if (target >= 0) {
                      _focusNodes[target].requestFocus();
                    } else {
                      validate();
                    }
                  }
                },
                textAlign: TextAlign.center,
                style: _entryTextStyle,
                inputFormatters: [UpperCaseTextFormatter()],
                showCursor: false,
                decoration: textDecoration)));

        pos++;
      }
    }

    if (_iteration != 0) {
      var target = findNextTarget(-1, false);
      if (target >= 0) {
        _focusNodes[target].requestFocus();
      }
    }
    _iteration++;

    var successEmoji = next(0, emojis.length);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: hintAWidgets),
          const SizedBox(height: 10),
          Row(mainAxisSize: MainAxisSize.min, children: hintBWidgets),
          const SizedBox(height: 10),
          Row(mainAxisSize: MainAxisSize.min, children: hintCWidgets),
          const SizedBox(height: 30),
          Row(mainAxisSize: MainAxisSize.min, children: entryWidgets),
          const SizedBox(height: 10),
          if (_success)
            Text(emojis[successEmoji], style: const TextStyle(fontSize: 48))
          else
            const Text(" ", style: TextStyle(fontSize: 48))
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
