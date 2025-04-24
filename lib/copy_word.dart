import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tecletea/constants.dart';

class CopyWord extends StatefulWidget {
  final String word;
  final VoidCallback onCompletion;

  const CopyWord({
    Key? key,
    required this.word,
    required this.onCompletion,
  }) : super(key: key);

  @override
  State<CopyWord> createState() => _CopyWordState();
}

class _CopyWordState extends State<CopyWord> {
  late List<String> entry;
  late AudioPlayer _player;
  var _focusNodes = [];
  var _entryEnabled = true;
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

    List<Widget> entryWidgets = [];
    List<Widget> modelWidgets = [];
    var letters = [];

    for (var tc in _textControllers) {
      tc.dispose();
    }
    _textControllers.clear();

    for (var letter in widget.word.characters) {
      letters.add(letter);
    }

    for (var i = 0; i < widget.word.length; i++) {
      if (i != 0) {
        entryWidgets.add(const SizedBox(width: 20));
        modelWidgets.add(const SizedBox(width: 20));
      }

      _textControllers.add(TextEditingController(text: entry[i]));

      entryWidgets.add(SizedBox(
          width: 68,
          child: TextFormField(
              key: UniqueKey(),
              maxLength: 2,
              enabled: _entryEnabled,
              autofocus: false,
              focusNode: _focusNodes[i],
              controller: _textControllers[i],
              onFieldSubmitted: (value) {},
              onEditingComplete: () {},
              onTapOutside: (event) {},
              onChanged: (text) {
                if (text.isEmpty) {
                  _textControllers[i].text = "\u200b";
                  if (i == 0) {
                    setState(() {
                      resetEntry();
                    });
                  } else {
                    _textControllers[i - 1].text = "\u200b";
                    _focusNodes[i - 1].requestFocus();
                  }
                } else if (text.length == 1 || text.length == 2) {
                  entry[i] = text[text.length - 1];
                  if (i < widget.word.length - 1) {
                    _focusNodes[i + 1].requestFocus();
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

      modelWidgets.add(SizedBox(
          width: 68,
          child: TextFormField(
              key: UniqueKey(),
              initialValue: letters[i],
              maxLength: 1,
              enabled: false,
              readOnly: true,
              textAlign: TextAlign.center,
              style: _entryTextStyle,
              showCursor: false,
              decoration: textDecoration)));
    }

    if (_iteration != 0) {
      _focusNodes[0].requestFocus();
    }
    _iteration++;

    var successEmoji = next(0, emojis.length);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: modelWidgets),
          const SizedBox(height: 10),
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
