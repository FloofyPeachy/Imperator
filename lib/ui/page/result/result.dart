import 'dart:convert';
import 'dart:isolate';

import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imperator_desktop/const.dart';
import 'package:imperator_desktop/core/config.dart';
import 'package:imperator_desktop/core/cv/analyser.dart';
import 'package:imperator_desktop/core/cv/processors.dart';
import 'package:imperator_desktop/core/games.dart';
import 'package:imperator_desktop/core/songdb/parser.dart';
import 'package:imperator_desktop/model/model.dart';
import 'package:imperator_desktop/state.dart';
import 'package:imperator_desktop/ui/page/edit/details.dart';
import 'package:imperator_desktop/ui/page/edit/preview.dart';
import 'package:imperator_desktop/ui/titlebar.dart';
import 'package:media_kit/media_kit.dart'
    hide Track; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart';
import 'package:split_view/split_view.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen();

  @override
  State<StatefulWidget> createState() => _AnalysisScreen();
}

class _AnalysisScreen extends State<AnalysisScreen> {
  _AnalysisScreen() : super();
  late final player = Player(configuration: PlayerConfiguration());
  late final controller = VideoController(player);
  late VideoAnalyser analyser;
  final ReceivePort receivePort = ReceivePort();
  bool analysing = false;
  Stream<dynamic>? receiveStream;
  List<Gameplay> sections = [];

  late (GameplayStates, double, int, List<Section>) currentState =
      (GameplayStates.UNKNOWN, 0, 0, []);
  List<Uint8List> previews = [];
  bool analyseVideo = true;
  SoundVoltexProcessor processor = SoundVoltexProcessor();

  Future<void> finalizeCurrentSection() async {
    //Seek to the start of the section
    await player.seek(Duration(seconds: (sections.last.start ~/ 60) + 1));
    //Take a screenshot of the "ready frame"
    Uint8List? readyFrame = await player.screenshot(format: "image/jpeg");
    Song? song;
    if (Config.get("experimental/song_detection")) {
      song = await processor.parseSong(cv
          .imdecode(readyFrame!, cv.IMREAD_GRAYSCALE)
          .rotate(cv.ROTATE_90_CLOCKWISE));
    }

    //Now, make a preview image by going halfway through the section
    await player.seek(Duration(
        seconds:
            ((sections.last.start ~/ 60) + (sections.last.end ~/ 60)) ~/ 2));
    Uint8List? previewFrame = await player.screenshot(format: "image/jpeg");
    //Finally, get the score
    await player.seek(Duration(seconds: (sections.last.end ~/ 60) - 1));
    Uint8List? endFrame = await player.screenshot(format: "image/jpeg");
    Score? score;
    if (Config.get("experimental/score_detection") && Config.get("experimental/song_detection")) {
      score = await processor
          .parseScore(cv.imdecode(endFrame!, cv.IMREAD_GRAYSCALE));

      Difficulty difficulty = await processor
          .processDifficulty(cv.imdecode(endFrame, cv.IMREAD_COLOR), song!);
      score.difficulty = difficulty;
    }
    //Update the section with the song data
    setState(() {
      previews[previews.length - 1] = previewFrame!;
      sections[sections.length - 1].song = song;
      sections[sections.length - 1].score = score;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, String>;
      player.open(Media(args['video'].toString()), play: false);
      analyser = VideoAnalyser(args['video'].toString(), processor);

      if (analyseVideo) {
        Future.delayed(Duration(seconds: 1), () {
          compute(analyser.process, receivePort.sendPort);
          setState(() {
            receiveStream = receivePort.asBroadcastStream() as Stream<dynamic>?;
            analysing = true;
          });
          receiveStream!.listen((snapshot) {
            var newSections = List<Section>.from(jsonDecode(snapshot!.$4)
                .map((e) => Gameplay.fromJson(e))
                .toList());
            if (sections.length != snapshot.$4.length) {
              //Add new item to list

              if (newSections.length != sections.length) {
                setState(() {
                  sections.add(newSections.last as Gameplay);
                  finalizeCurrentSection();
                  previews.add(Uint8List(0));
                });
              }
            }
            //currentState =
            //   (snapshot.$1, snapshot.$2, snapshot.$3, newSections);
          });

        });
      } else {
        currentSection.value = Gameplay(
            start: 0,
            end: 45,
            game: Games.SOUND_VOLTEX,
            score: Score(
              score: 9984184,
              maxCombo: 1754,
              missEarly: 1,
              nearEarly: 1,
              criticalEarly: 48,
              sCritical: 2124,
              criticalLate: 37,
              nearLate: 0,
              missLate: 2,
              difficulty: Difficulty(type: DifficultyType.unknown, level: 18),
              percentage: 87.9,
              gauge: Gauges.excessive,
            ),
            song: SongList.getSong("sdvx", "Imperator", "xe"));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SplitView(
      viewMode: SplitViewMode.Horizontal,
      gripColor: Colors.transparent,
      indicator: SplitIndicator(viewMode: SplitViewMode.Horizontal),
      children: [
        Column(
          children: [
            Card(
                child: AnimateGradient(
              animateAlignments: true,
              duration: Duration(seconds: 2),
              reverse: true,
              primaryColors: [
                Colors.red.withOpacity(0.2),
                Colors.pinkAccent.withOpacity(0.2),
              ],
              secondaryColors: [
                Colors.blueAccent.withOpacity(0.2),
                Colors.blue.withOpacity(0.2),
              ],
              child: analysing
                  ? ExpansionTile(
                      title: Text("Analyzing video..."),
                      children: [
                        ListTile(
                          leading: Icon(Icons.surround_sound),
                          title: Text('Processing video...'),
                          subtitle: Text(
                              "This might take a while, depending your computer's hardware. In the meantime, go hang out with your friends or something...you have friends, don't you?"),
                        ),
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () {},
                        ),
                        StreamBuilder<dynamic>(
                            stream: receiveStream!,
                            builder: (context, snapshot) {
                              return LinearProgressIndicator(
                                  value: snapshot.data!.$3 /
                                      (player.state.duration.inSeconds * 60));
                            })
                      ],
                    )
                  : SizedBox(),
            )),
            sections.isNotEmpty
                ? Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return buildSectionCard(
                            sections[index], previews[index]);
                      },
                      itemCount: sections.length,
                    ),
                  )
                : Center(
                    child: Column(
                    children: [
                      CircularProgressIndicator(),
                      Text("Looking for gameplay.."),
                    ],
                  )),
          ],
        ),
        SplitView(
          viewMode: SplitViewMode.Horizontal,
          indicator: SplitIndicator(viewMode: SplitViewMode.Horizontal),
          gripColor: Colors.transparent,
          children: [
            VideoPlayer(controller: controller),
            DetailView(
              vertical: true,
            ),
          ],
        )
      ],
    ));
  }

  Widget buildSectionCard(Gameplay section, Uint8List? preview) {
    return Card(
        child: InkWell(

      onTap: () {
        currentSection.value = section;
        currentSection.notifyListeners();
      },
      child: Column(
        children: [
          preview != null
              ? Image.memory(preview, height: 200)
              : CircularProgressIndicator(),
          Text(section.song == null ? "Unknown" : section.song!.title),
          //Text(section.score.score.toString()),
        ],
      ),
    ));
  }
}
