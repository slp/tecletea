import 'dart:collection';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tecletea/config_page.dart';
import 'package:tecletea/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import './copy_word.dart';
import './complete_word.dart';
import './pictogram_list.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.getInstance().then((instance) {
    runApp(MyApp(prefs: instance));
  });
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  const MyApp({
    Key? key,
    required this.prefs,
  }) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();
}

class MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    if (widget.prefs.getString("appLocale") != null) {
      _locale = Locale(widget.prefs.getString("appLocale")!);
    }
    super.initState();
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_MyAppState>(
        create: (context) => _MyAppState(),
        child: MaterialApp(
          title: 'TecleTEA',
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ca'), // Catala
            Locale('en'), // English
            Locale('es'), // Spanish
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          home: MyHomePage(prefs: widget.prefs),
        ));
  }
}

class _MyAppState extends ChangeNotifier {}

class MyHomePage extends StatefulWidget {
  final SharedPreferences prefs;

  const MyHomePage({
    Key? key,
    required this.prefs,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = Localizations.localeOf(context);
    StatefulWidget page;
    switch (_selectedIndex) {
      case 0:
        page = MainPage(prefs: widget.prefs, locale: currentLocale.toString());
        break;
      case 1:
        page = ConfigPage(
          prefs: widget.prefs,
          localeString: currentLocale.toString(),
          onCompletion: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
        break;
      default:
        throw UnimplementedError('no widget for $_selectedIndex');
    }

    return Scaffold(
      bottomNavigationBar: SizedBox(
          height: 30,
          width: 100,
          child: DecoratedBox(
              decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 231, 231, 231)),
              child: Align(
                  alignment: Alignment.centerRight,
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    InkWell(
                        child: Text(AppLocalizations.of(context)!.credits,
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        onTap: () => html.window.location.href =
                            "https://github.com/slp/tecletea"),
                    const SizedBox(width: 50)
                  ])))),
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              backgroundColor: const Color.fromARGB(255, 231, 231, 231),
              extended: false,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  _selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
              child: Align(
                  alignment: Alignment.center,
                  child: Container(
                      //constraints: BoxConstraints(maxWidth: 540.0),
                      child: page)))
        ],
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  final _random = Random();
  final SharedPreferences prefs;
  final String locale;

  MainPage({
    Key? key,
    required this.prefs,
    required this.locale,
  }) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  LinkedHashMap<String, String> words = LinkedHashMap();
  var _state = 0;
  var _iteration = 1;
  var _appMode = DEFAULT_APP_MODE;
  var _firstMode = true;
  final _pictoHistory = <int>[];
  var _percentRevealed = DEFAULT_PERCENT_REVEALED;
  var _maxIterations = DEFAULT_MAX_ITERATIONS;
  var _word = "";
  var _image = "";
  var _isLoaded = false;
  var _isInitialized = false;
  final outFocus = FocusNode();

  late Future<PictogramList> futurePictogramList;
  LinkedHashMap<int, Pictogram> pictoLocal = LinkedHashMap();
  late AudioPlayer player;
  final discreteText = const TextStyle(
      color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500);

  @override
  void initState() {
    super.initState();
    futurePictogramList = fetchPictograms();
    player = AudioPlayer();
    if (widget.prefs.getInt("appMode") != null) {
      _appMode = widget.prefs.getInt("appMode")!;
    }
    if (widget.prefs.getInt("percentRevealed") != null) {
      _percentRevealed = widget.prefs.getInt("percentRevealed")!;
    }
    if (widget.prefs.getInt("maxIterations") != null) {
      _maxIterations = widget.prefs.getInt("maxIterations")!;
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  int next(int min, int max) => min + widget._random.nextInt(max - min);

  Future<PictogramList> fetchPictograms() async {
    final response = await http.get(Uri.parse(
        'https://api.arasaac.org/api/pictograms/all/${widget.locale}'));

    if (response.statusCode == 200) {
      return PictogramList.fromJson(jsonDecode(response.body), widget.prefs);
    } else {
      throw Exception('Failed to load album');
    }
  }

  void playSound(keyword) async {
    keyword = keyword.toLowerCase();
    player.setUrl(
        "https://static.arasaac.org/locutions/${widget.locale}/$keyword.mp3");
    player.play();
  }

  void configureNextWord() {
    var nextPicto = next(0, pictoLocal.keys.length);
    if (_appMode == APP_MODE_MIXED) {
      if (_iteration > (_maxIterations + 1) / 2) {
        _firstMode = false;
      }

      if (_firstMode) {
        _pictoHistory.add(nextPicto);
      } else {
        nextPicto = _pictoHistory.removeAt(0);
      }
    }

    var newWord = pictoLocal[nextPicto]!.name;
    var imageId = pictoLocal[nextPicto]!.id;

    _image = "https://api.arasaac.org/api/pictograms/$imageId?download=false";
    _word = newWord
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .toUpperCase();
    playSound(newWord);
    FocusScope.of(context).requestFocus(outFocus);
  }

  void changeWord() async {
    if (_iteration > _maxIterations) {
      setState(() {
        _state = 2;
      });
    } else {
      setState(() {
        configureNextWord();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _isLoaded = false;

    if (_state == 0) {
      return Column(children: [
        Expanded(
            child: Container(
                constraints: const BoxConstraints(maxWidth: 540.0),
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      BigCard(
                          text: AppLocalizations.of(context)!.introduction,
                          color: const Color.fromARGB(197, 96, 125, 139),
                          fontSize: 18),
                      const SizedBox(height: 20),
                      BigCard(
                          text:
                              AppLocalizations.of(context)!.keyboardRequirement,
                          color: Colors.grey,
                          fontSize: 12),
                      const SizedBox(height: 30),
                      ElevatedButton(
                          onPressed: () => setState(() {
                                _state = 1;
                              }),
                          child: Text(AppLocalizations.of(context)!.start,
                              style: const TextStyle(fontSize: 48))),
                      const SizedBox(height: 30),
                    ])))),
        Text(AppLocalizations.of(context)!.pictoUse, style: discreteText),
        Text(AppLocalizations.of(context)!.pictoLicense1, style: discreteText),
        InkWell(
            child: Text(
              AppLocalizations.of(context)!.pictoLicense2,
              style: discreteText,
            ),
            onTap: () => html.window.location.href = "http://arasaac.org"),
        InkWell(
            child: Text(AppLocalizations.of(context)!.pictoLicense3,
                style: discreteText),
            onTap: () => html.window.location.href =
                "https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es"),
        const SizedBox(height: 20),
      ]);
    } else if (_state == 1) {
      return Center(
          child: FutureBuilder<PictogramList>(
              future: futurePictogramList,
              builder: (context, snapshot) {
                if (_isInitialized || snapshot.hasData) {
                  if (!_isInitialized) {
                    var pictoList = snapshot.data!;
                    pictoLocal = pictoList.list;
                    configureNextWord();
                    _isInitialized = true;
                  }

                  Widget wordWidget;
                  if (_appMode == APP_MODE_COPY ||
                      (_appMode == APP_MODE_MIXED && _firstMode)) {
                    wordWidget = CopyWord(
                        word: _word,
                        onCompletion: () => {
                              _iteration++,
                              changeWord(),
                            });
                  } else {
                    wordWidget = CompleteWord(
                        word: _word,
                        percentRevealed: _percentRevealed,
                        onCompletion: () => {
                              _iteration++,
                              changeWord(),
                            });
                  }

                  return Column(children: [
                    Text("$_iteration/$_maxIterations", style: discreteText),
                    Expanded(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 300,
                            height: 300,
                            child: Image.network(
                              _image,
                              frameBuilder: (context, child, frame,
                                  wasSynchronouslyLoaded) {
                                _isLoaded = frame != null;
                                return child;
                              },
                              loadingBuilder: (context, child, progress) {
                                if (_isLoaded && progress == null) {
                                  return child;
                                }
                                return const CircularProgressIndicator();
                              },
                            )),
                        const SizedBox(height: 10),
                        SizedBox(child: wordWidget),
                        const SizedBox(height: 100),
                      ],
                    ))
                  ]);
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                return const CircularProgressIndicator();
              }));
    } else {
      player.setAsset("sounds/applause.mp3");
      player.play();
      return Center(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 540.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BigCard(
                        text: AppLocalizations.of(context)!.completed,
                        color: const Color.fromARGB(197, 96, 125, 139),
                        fontSize: 48),
                    const SizedBox(height: 30),
                    const Text("👏👏👏", style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                        onPressed: () => {
                              setState(() {
                                _iteration = 1;
                                _state = 1;
                              }),
                              changeWord(),
                            },
                        child: Text(AppLocalizations.of(context)!.again,
                            style: const TextStyle(fontSize: 48)))
                  ])));
    }
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    Key? key,
    required this.text,
    required this.color,
    required this.fontSize,
  }) : super(key: key);

  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: fontSize, color: Colors.white)),
      ),
    );
  }
}
