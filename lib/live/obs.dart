import 'dart:async';
import 'dart:io';


import 'package:flutter/material.dart';
import 'package:imperator_desktop/const.dart';
import 'package:imperator_desktop/core/config.dart';
import 'package:imperator_desktop/core/cv/analyser.dart';
import 'package:imperator_desktop/core/cv/frame.dart';
import 'package:imperator_desktop/core/cv/processors.dart';
import 'package:imperator_desktop/model/model.dart';
import 'package:obs_websocket/obs_websocket.dart';
import 'package:obs_websocket/request.dart' hide Stream, Config;
import 'package:opencv_dart/opencv_dart.dart';

class OBSConnection {
  ObsWebSocket? obs;
  ValueNotifier<ObsConnectionState> connectionState = ValueNotifier(ObsConnectionState.disconnected);
  ValueNotifier<bool> isCapturing = ValueNotifier(false);

  int tryCount = 0;
  ValueNotifier<String?> sceneItem = ValueNotifier<String>("");
  StreamController<(GameplayStates, List<Gameplay>)> gameplayStream = StreamController();
  List<Gameplay> gameplays = [];

  Future<void> connect() async {

    try {
      connectionState.value = ObsConnectionState.connecting;
      obs = await ObsWebSocket.connect("${"ws://" + Config.get("live/ip_address")}:" + Config.get("live/port").toString(),password: Config.get("live/password"));

    } on Exception catch (e) {
      print("Couldn't connect to OBS: $e");

      await Future.delayed(Duration(seconds: 3));
      if (tryCount >= 5) {
        print("Failed to connect to OBS after 5 tries. Giving up.");
        connectionState.value = ObsConnectionState.error;
        throw Exception("Couldn't connect to OBS.$e");
      }
      tryCount++;
      //Couldn't connect...try again
      return connect();
    }
    print("Connected to OBS successfully!");
    connectionState.value = ObsConnectionState.connected;


    print(await obs!.scenes.getList());
    print(await obs!.scenes.getCurrentProgram());
    getSources();
  }

  Future<void> disconnect() async {
    await obs!.close();
    isCapturing.value = false;
    connectionState.value = ObsConnectionState.disconnected;
  }

  Future<void> startCapture() async {
    OBSFrameSource source = OBSFrameSource(this, 12, 60);
    SoundVoltexProcessor processor = SoundVoltexProcessor();
    GameplayStates globalState = GameplayStates.UNKNOWN;
    Mat startFrame = Mat.empty();
    int startCount = 0;
    Mat endFrame = Mat.empty();
    int stopCount = 0;

    isCapturing.value = true;

    obs!.outputs.startReplayBuffer("deez");
    Directory((await obs!.config.recordDirectory()).recordDirectory).watch().listen(directoryChanged);


    while (true) {
      if (isCapturing.value == false) {
        break;
      }
      Mat? frame = await source.getNextFrame();
      if (frame == null) {
        continue;
      }

      var (state, confidence) = await processor.processFrame(frame, globalState == GameplayStates.GAMEPLAY);

      if (state == GameplayStates.GAMEPLAY && globalState != GameplayStates.GAMEPLAY) {
        //Gameplay detected
        print("Gameplay detected at ${source.frameCount}");
        startFrame = frame;
        startCount = source.frameCount;

        gameplayStream.add((GameplayStates.GAMEPLAY, gameplays));
        //Now we need to find the end of the gameplay
        globalState = GameplayStates.GAMEPLAY;

      } else if (state == GameplayStates.POST_GAMEPLAY && globalState == GameplayStates.GAMEPLAY) {
        //Gameplay ended
        print("Gameplay ended at ${source.frameCount}");
        endFrame = frame;
        stopCount = source.frameCount;


        //Finalize the gameplay. Get the song, and score (if enabled)
        Gameplay gameplay;
        Song? song;
        Score? score;

        if (Config.get("experimental/song_detection")) {
          song = await processor.parseSong(startFrame.rotate(ROTATE_90_CLOCKWISE));
        }

        if (Config.get("experimental/score_detection")) {
          score = await processor.parseScore(endFrame);
        }

        gameplay = Gameplay(song: song, score: score, start: startCount, end: stopCount, game: Games.SOUND_VOLTEX);
        gameplays.add(gameplay);
        gameplayStream.add((GameplayStates.POST_GAMEPLAY, gameplays));
        obs!.outputs.saveReplayBuffer("deez");
        //Okay, the replay buffer is saved BUT let's watch for renames.

        globalState = GameplayStates.UNKNOWN;
      }
    }
  }

  Future<void> directoryChanged(FileSystemEvent event) async {
    print("File changed: $event");
    if (event is FileSystemCreateEvent && event.path.contains("Replay ")) {
      print("Replay file saved!");
      await Future.delayed(Duration(seconds: 5)); //really bad way to wait for the file to be written....
      File(event.path).renameSync("${gameplays[gameplays.length - 1].song!.title}${DateTime.now().millisecondsSinceEpoch}.mp4");
    }
  }

  Future<void> stopCapturing() async {
    isCapturing.value = false;
    gameplayStream.close();
  }

  Future<List<SceneItemDetail>> getSources() async {
    //Get current scene
    String sceneStr = await obs!.scenes.getCurrentProgram();
    return await obs!.sceneItems.getSceneItemList(sceneStr);
   // print(await obs!.sources.getList());
  }

  Future<(GameplayStates, double)> readFrame() async {

   final response = await obs!.sources.getSourceScreenshot(SourceScreenshot(sourceName: sceneItem.value!, imageFormat: 'png'));
    Mat frame = imdecode(response.bytes, IMREAD_GRAYSCALE);
    SoundVoltexProcessor processor = SoundVoltexProcessor();


    return processor.processFrame(frame, false);

    //print()
  }
}

enum ObsConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

enum GameplayEventType {
  GAMEPLAY_START,
  GAMEPLAY_END,
}


class ConnectionEvent {
  ObsConnectionState type;
  dynamic data;

  ConnectionEvent(this.type, this.data);
}