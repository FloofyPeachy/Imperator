import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:imperator_desktop/core/cv/processors.dart';
import 'package:imperator_desktop/core/songdb/parser.dart';
import 'package:imperator_desktop/model/model.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../../../const.dart';

import '../../../const.dart';

class VideoPlayer extends StatefulWidget {
  VideoController controller;
  VideoPlayer({Key? key, required this.controller}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoPlayer();
}


class _VideoPlayer extends State<VideoPlayer> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Video(controller: widget.controller)
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text("00:00:00"),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous),
                  tooltip: 'Skip to previous highlight',
                  onPressed: () {
                    //widget.player.seekTo(widget.player.state.position + Duration(seconds: 5));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.play_arrow),
                  onPressed: () {
                    widget.controller.player.playOrPause();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.skip_next),
                  tooltip: 'Skip to next highlight',
                  onPressed: () {
                    //widget.player.seekTo(widget.player.state.position + Duration(seconds: 5));
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
                                future: widget.controller.player.screenshot(format: "image/jpeg"),
                                builder: (BuildContext context,
                                    AsyncSnapshot<Uint8List?> snapshot) {
                                  if (snapshot.hasData) {

                                    cv.Mat theMat = cv.imdecode(snapshot.data!, cv.IMREAD_GRAYSCALE);
                                    return FutureBuilder(
                                      future: SoundVoltexProcessor().parseScore(theMat),
                                      builder: (BuildContext context, AsyncSnapshot<Score> snapshot) {
                                        if (snapshot.hasError) {
                                          print(snapshot.error);
                                          print(snapshot.stackTrace);
                                          return Text("Error: ${snapshot.error}");

                                        }
                                        if (snapshot.hasData) {
                                          return Column(
                                            children: [
                                              Text("Score: ${snapshot.data!}"),
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
                  icon: Icon(Icons.hardware),
                  tooltip: 'Analyze frame',
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {


                          return Dialog(
                              child: FutureBuilder(
                                future: widget.controller.player.screenshot(format: "image/jpeg"),
                                builder: (BuildContext context,
                                    AsyncSnapshot<Uint8List?> snapshot) {
                                  if (snapshot.hasData) {

                                    cv.Mat theMat = cv.imdecode(snapshot.data!, cv.IMREAD_COLOR);
                                    return FutureBuilder(
                                      future: SoundVoltexProcessor().processDifficulty(theMat, SongList.tracks[Games.SOUND_VOLTEX]!.first),
                                      builder: (BuildContext context, AsyncSnapshot<Difficulty> snapshot) {
                                        if (snapshot.hasError) {
                                          print(snapshot.error);
                                          print(snapshot.stackTrace);
                                          return Text("Error: ${snapshot.error}");

                                        }
                                        if (snapshot.hasData) {
                                          return Column(
                                            children: [
                                              Text("Difficulty: ${snapshot.data!}"),
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
              ],
            )
          ],
        ),




        /*Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(

            child: Text(player.state.position.toString().split('.').first.padLeft(8, "0"), style: TextStyle(fontSize: 20)),
          ),
        ),*/

      ],
    );
  }
}