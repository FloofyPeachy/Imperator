import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:imperator_desktop/const.dart';
import 'package:imperator_desktop/core/cv/frame.dart';
import 'package:imperator_desktop/core/cv/processors.dart';
import 'package:imperator_desktop/model/model.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:opencv_dart/opencv_dart.dart';

/*
* This is the main class for video analysis.
* Pretty cool stuff, right?
* */

class VideoAnalyser {
  final String video;
  final FrameProcessor processor;
  final double verticalRatio = 0.5625;
  final double horizontalRatio = 1.77777777778;
  final StreamController<Section> progressStream = StreamController<Section>.broadcast();

  VideoAnalyser(this.video, this.processor);

  Future<(GameplayStates, double)> processFrame(List message) async {
    //Process the frame
    return await processor.processFrame(Mat.fromList(message[0], message[1], MatType.CV_8UC1, message[2]), false);
  }

  void process(SendPort port) async {
    print("Starting analysis...");
    //So how do we do this?
    //We need to read the video frame by frame from a FrameSource (which can be a video file or OBS)
    //Then we need to process each frame using the FrameProcessor, to determine the state of the game.
    //Normally, the game first shows a "ready" screen, then the gameplay, then the score screen.
    //We need to detect these states and record the time at which they occur.
    //Once we have all the sections, we can then analyze them to get the song, score, etc.
    //Pretty cool, right?
    //Let's get started!


    FrameSource source = VideoFrameSource.fromFile(video, 12, 60); //Let's just assume 60 FPS for now
    GameplayStates globalState = GameplayStates.UNKNOWN;
    List<Gameplay> gameplays = [];
    int gameplayStartFrame = 0;

    while (true) {
      Mat? frame = await source.getNextFrame();
      if (frame == null || frame.isEmpty) {
        continue;
      }

      var (state, confidence) = await processor.processFrame(frame, globalState == GameplayStates.GAMEPLAY);

      if (state == GameplayStates.GAMEPLAY && globalState != GameplayStates.GAMEPLAY) {
        //Gameplay detected
        print("Gameplay detected at ${source.frameCount}");
        //Now we need to find the end of the gameplay
            if (globalState != GameplayStates.GAMEPLAY) {
              //Okay, the game is being played. Wait for the score screen
              print("Gameplay detected at frame $frameCount");
              globalState = GameplayStates.GAMEPLAY;
              gameplayStartFrame = frameCount;
              //Now look for the song name
              //var track = await processor.processSong(frame);
              //gameplayStartFrameMat = frame.clone();
            }
          }


      if (state == GameplayStates.POST_GAMEPLAY) {
        //Score screen detected
        print("Score screen detected at frame $frameCount");

        //var song = await processor.processSong(gameplayStartFrameMat);
        //var score = await processor.parseScore(frame);
        // print("Score: $score");

        Gameplay gameplay = Gameplay(song: null, game: Games.SOUND_VOLTEX, score: null, start: gameplayStartFrame, end: frameCount + 100);
        gameplays.add(gameplay);
        //gameplays.add(Gameplay(track: Track(id: 0, title: "Test", artist: "Test", difficulty: "Test", level: 0, maxCombo: 0), game: 0, score: score, start: gameplayStartFrame, end: frameCount + 100));
        print("Added gameplay!!");
        globalState = GameplayStates.POST_GAMEPLAY;
        //gameplayStartFrameMat = cv.Mat.empty();

      }
      frameCount++;
      port.send((globalState, confidence, frameCount, jsonEncode(gameplays)));
    }





  }


  int frameCount = 0;
  GameplayStates state = GameplayStates.UNKNOWN; //0 = pre-gameplay 1 = gameplay 2 = post-gameplay (score screen)
   void analyse(SendPort sendPort) async {
    print("Analyzing video...");
    final video = cv.VideoCapture.fromFile(this.video);
    video.set(cv.CAP_PROP_CONVERT_RGB, 0);
   // video.set(cv.CAP_PROP_FORMAT, cv.MatType.CV_8U.toDouble());
    var skipInterval = 60 ~/ 15;
    var frame = cv.Mat.empty();
    // Read the video frame by frame
    GameplayStates globalState = GameplayStates.UNKNOWN;
    List<Gameplay> gameplays = [];
    int gameplayStartFrame = 0;
    cv.Mat gameplayStartFrameMat = cv.Mat.empty();
    print("Isolating gameplay...");
    frame = video.read().$2;
    frameCount++;

    //(int, int, int, int) gameplayArea = getGameplayArea(frame);
    //print("Gameplay area: $gameplayArea");
   // cv.imwrite("area.jpg", frame.rowRange(gameplayArea.$2, gameplayArea.$4).colRange(gameplayArea.$1, gameplayArea.$3));

    while (true) {

      var newframe = video.read();
      frame = newframe.$2;

      if (frame.isEmpty) {
        break;
      }
      if (frameCount % skipInterval != 0) {
        frameCount++;
        continue;
      }

      var (state, confidence) = await processor.processFrame(frame, globalState == GameplayStates.GAMEPLAY);

      //
      if (state == GameplayStates.GAMEPLAY) {
        if (globalState != GameplayStates.GAMEPLAY) {
          //Okay, the game is being played. Wait for the score screen
          print("Gameplay detected at frame $frameCount");
          globalState = GameplayStates.GAMEPLAY;
          gameplayStartFrame = frameCount;
          //Now look for the song name
          //var track = await processor.processSong(frame);
          gameplayStartFrameMat = frame.clone();
        }
      }

      if (state == GameplayStates.POST_GAMEPLAY) {
        //Score screen detected
        print("Score screen detected at frame $frameCount");

        //var song = await processor.processSong(gameplayStartFrameMat);
        //var score = await processor.parseScore(frame);
       // print("Score: $score");

        Gameplay gameplay = Gameplay(song: null, game: Games.SOUND_VOLTEX, score: null, start: gameplayStartFrame, end: frameCount + 100);
        gameplays.add(gameplay);
        //gameplays.add(Gameplay(track: Track(id: 0, title: "Test", artist: "Test", difficulty: "Test", level: 0, maxCombo: 0), game: 0, score: score, start: gameplayStartFrame, end: frameCount + 100));
        print("Added gameplay!!");
        globalState = GameplayStates.POST_GAMEPLAY;
        gameplayStartFrameMat = cv.Mat.empty();

      }

      /*if (frameCount >= 165) {
        //Going on for too long. End the section
        print("Score screen detected at frame $frameCount");
        var score = await processor.processScore(frame);
        print("Score: $score");
        //gameplays.add(Gameplay(song: Track(id: 0, title: "Test", artist: "Test", difficulty: "Test", level: 0, maxCombo: 0), game: 0, score: score, start: gameplayStartFrame, end: frameCount + 100));
        print("Added gameplay!!");
        globalState = GameplayStates.POST_GAMEPLAY;
      }*/
      frameCount++;
/*      print("State: $state");
      print("Frame: $frameCount");
      print("Time: ${frameCount / 60}");*/
    sendPort.send((globalState, confidence, frameCount, jsonEncode(gameplays)));
    }
    print("Done analyzing!!!");
  }

  (int, int, int, int) getGameplayArea(cv.Mat frame) {
    //Get the gameplay area
    cv.Mat threshFrame = cv.threshold(frame, 100, 255, cv.THRESH_BINARY).$2;
    (cv.Contours contours, cv.Mat hierarchy) contours = cv.findContours(threshFrame, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
    //Get the 4 corners of the gameplay area

    List<cv.Point> corners = contours.$1.first.props;
    return (corners[0].x, corners[0].y, corners[2].x, corners[2].y);

    }




}

enum GameplayStates {
  UNKNOWN,
  PRE_GAMEPLAY,
  GAMEPLAY,
  TRACK_CRASH,
  POST_GAMEPLAY,
}