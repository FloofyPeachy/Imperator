import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imperator_desktop/core/cv/analyser.dart';
import 'package:imperator_desktop/core/cv/processors.dart';
import 'package:imperator_desktop/core/util.dart';
import 'package:imperator_desktop/model/model.dart';
import 'package:imperator_desktop/ui/page/edit/details.dart';
import 'package:imperator_desktop/ui/page/edit/preview.dart';
import 'package:imperator_desktop/ui/page/edit/timeline.dart';
import 'package:imperator_desktop/ui/titlebar.dart';
import 'package:split_view/split_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:media_kit/media_kit.dart'
    hide Track; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.
import 'package:opencv_dart/opencv_dart.dart' as cv;

class EditPage extends StatefulWidget {
  const EditPage();

  @override
  State<StatefulWidget> createState() => _EditPage();
}

class _EditPage extends State<EditPage> {
  _EditPage() : super();
  late final player = Player(configuration: PlayerConfiguration());
  late final controller = VideoController(player);
  late VideoAnalyser analyser;
  List<Section> sections = [

  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, String>;
      player.open(Media(args['video'].toString()));
      analyser =
          VideoAnalyser(args['video'].toString(), SoundVoltexProcessor());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: SplitView(
            viewMode: SplitViewMode.Horizontal,
            indicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal),
            children: [
              SplitView(
                viewMode: SplitViewMode.Vertical,
                children: [
                  VideoPlayer(controller: controller),
                  IconButton(
                    icon: Icon(Icons.movie_filter),
                    tooltip: 'Analyze frame',
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {


                            return Dialog(
                                child: FutureBuilder(
                              future: player.screenshot(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<Uint8List?> snapshot) {
                                if (snapshot.hasData) {

                                  cv.Mat theMat;
                                  theMat = cv.imdecode(snapshot.data!, cv.IMREAD_GRAYSCALE);
                                  return FutureBuilder(
                                    future: analyser.processor.processFrame(
                            theMat.rotate(cv.ROTATE_90_CLOCKWISE), true),
                                    builder: (BuildContext context, AsyncSnapshot<(GameplayStates, double)> snapshot) {
                                      if (snapshot.hasError) {
                                        return Text("Error: ${snapshot.error}");
                                      }
                                      if (snapshot.hasData) {
                                        return Column(
                                          children: [
                                            Text("State: ${snapshot.data!.$1}"),
                                            Text("Confidence: ${snapshot.data!.$2}"),
                                          ],
                                        );
                                      } else {
                                        return Text("Processing frame...");
                                      }


                                    },
                                  );
                                }
                                return Text("Taking a screenshot...");
                              },
                            ));
                          });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.music_note),
                    tooltip: 'Analyze frame',
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {


                            return Dialog(
                                child: FutureBuilder(
                                  future: player.screenshot(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<Uint8List?> snapshot) {
                                    if (snapshot.hasData) {

                                      cv.Mat theMat;
                                      theMat = cv.imdecode(snapshot.data!, cv.IMREAD_GRAYSCALE);
                                      return FutureBuilder(
                                        future: analyser.processor.parseSong(theMat.rotate(cv.ROTATE_90_CLOCKWISE)),
                                        builder: (BuildContext context, AsyncSnapshot<Song> snapshot) {
                                          if (snapshot.hasError) {
                                            return Text("Error: ${snapshot.error}");
                                          }
                                          if (snapshot.hasData) {
                                            return Column(
                                              children: [
                                                Text("Song: ${snapshot.data!.title}"),
                                              ],
                                            );
                                          } else {
                                            return Text("Processing frame...");
                                          }


                                        },
                                      );
                                    }
                                    return Text("Taking a screenshot...");
                                  },
                                ));
                          });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.auto_graph),
                    tooltip: 'Analyze frame',
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {


                            return Dialog(
                                child: FutureBuilder(
                                  future: player.screenshot(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<Uint8List?> snapshot) {
                                    if (snapshot.hasData) {

                                      cv.Mat theMat = cv.imdecode(snapshot.data!, cv.IMREAD_GRAYSCALE);
                                      return FutureBuilder(
                                        future: analyser.processor.parseScore(theMat),
                                        builder: (BuildContext context, AsyncSnapshot<Score> snapshot) {
                                          if (snapshot.hasError) {
                                            print(snapshot.error);
                                            print(snapshot.stackTrace);
                                            return Text("Error: ${snapshot.error}");

                                          }
                                          if (snapshot.hasData) {
                                            return Column(
                                              children: [
                                                Text("Score: ${snapshot.data!.score}"),
                                              ],
                                            );
                                          } else {
                                            return Text("Processing frame...");
                                          }


                                        },
                                      );
                                    }
                                    return Text("Taking a screenshot...");
                                  },
                                ));
                          });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.video_collection_outlined),
                    tooltip: 'Analyze video',
                    onPressed: () {

                      showDialog(context: context, builder: (BuildContext context) {
                       /* ReceivePort receivePort = ReceivePort();
                        Stream stream = receivePort.asBroadcastStream();
                        Future future = compute(analyser.analyse, receivePort.sendPort);
                        int frameCount = 0;
                        GameplayStates state = GameplayStates.UNKNOWN;
                        stream.listen((event) {
                          print("Event: $event");
                        });
*/                      ReceivePort receivePort = ReceivePort();
                        //analyser.startAnalysis();
                        return Dialog(

                          child: FutureBuilder(
                            future: compute(analyser.analyse, receivePort.sendPort),
                            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                              return StreamBuilder(
                                stream: receivePort.asBroadcastStream(),
                                builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                  if (snapshot.hasData) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("State: ${snapshot.data!.$1}"),
                                        Text("Confidence: ${snapshot.data!.$2}"),
                                        Text("Progress: ${(snapshot.data!.$3 / (player.state.duration.inSeconds * 60)) * 100}" ),
                                        Text("Gameplays: ${snapshot.data!.$4}"),
                                        SizedBox(height: 100, width: 100, child: Image(image: MemoryImage(Uint8List.fromList(snapshot.data!.$5)))),
                                        LinearProgressIndicator(value: snapshot.data!.$3 / (player.state.duration.inSeconds * 60),),
                                      ],
                                    );
                                  } else {
                                    return Text("Processing frames...");
                                  }
                                },
                              );

                            },
                          )
                        );
                      });
                    },
                  )
                  //Timeline(sections: sections, player: player,),
                ],
              ),
              Container(
                child: DetailView(vertical: true,),
              ),
            ],
          ),
        ),
      ],
    ));
  }
}
