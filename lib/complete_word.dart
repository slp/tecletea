import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tecletea/constants.dart';

class CompleteWord extends StatefulWidget {
  final String word;
  final int percentRevealed;
  final VoidCallback onCompletion;

  const CompleteWord({
    Key? key,
    required this.word,
    required this.percentRevealed,
    required this.onCompletion,
  }) : super(key: key);

  @override
  State<CompleteWord> createState() => _CompleteWordState();
}

class _CompleteWordState extends State<CompleteWord> {
  late List<String> entry;
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
  final _random = Random();
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
    for (var i = 0; i < LIMIT_MAX_CHARACTERS; i++) {
      _focusNodes.add(FocusNode());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger a rebuild to work around focus logic.
      setState(() {});
    });
  }

  int next(int min, int max) => min + _random.nextInt(max - min);

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
      _newWord = false;
    }

    List<Widget> entryWidgets = [];
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

    for (var i = 0; i < widget.word.length; i++) {
      if (i != 0) {
        entryWidgets.add(const SizedBox(width: 20));
      }

      _textControllers.add(TextEditingController(text: entry[i]));

      entryWidgets.add(SizedBox(
          width: 68,
          child: TextFormField(
              key: UniqueKey(),
              maxLength: 2,
              enabled: _entryEnabled && !_revealedLetters.contains(i),
              focusNode: _focusNodes[i],
              autofocus: false,
              controller: _textControllers[i],
              onFieldSubmitted: (value) {},
              onEditingComplete: () {},
              onTapOutside: (event) {},
              onChanged: (text) {
                if (text.isEmpty) {
                  _textControllers[i].text = "\u200b";
                  var target = findNextTarget(i, true);
                  if (target == -1) {
                    setState(() {
                      resetEntry();
                    });
                  } else {
                    _textControllers[target].text = "\u200b";
                    _focusNodes[target].requestFocus();
                  }
                } else if (text.length == 1 || text.length == 2) {
                  entry[i] = text[text.length - 1];
                  var target = findNextTarget(i, false);
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
