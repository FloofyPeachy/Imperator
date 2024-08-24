import 'dart:async';

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
  int connected = 0; //0: not connected, 1: connected, 2: connecting
  int tryCount = 0;
  String? sceneItem = "";
  StreamController<(GameplayStates, List<Gameplay>)> gameplayStream = StreamController();
  List<Gameplay> gameplays = [];

  Future<void> connect() async {
    connected = 2;

    try {
      obs = await ObsWebSocket.connect("${"ws://" + Config.get("live/ip_address")}:" + Config.get("live/port").toString(),password: Config.get("live/password"));
    } on Exception catch (e) {
      print("Couldn't connect to OBS: $e");

      await Future.delayed(Duration(seconds: 3));
      if (tryCount >= 5) {
        print("Failed to connect to OBS after 5 tries. Giving up.");
        connected = 0;
        throw Exception("Couldn't connect to OBS." + e.toString());
      }
      tryCount++;
      //Couldn't connect...try again
      return connect();
    }
    print("Connected to OBS successfully!");
    connected = 1;


    print(await obs!.scenes.getList());
    print(await obs!.scenes.getCurrentProgram());
    getSources();
  }

  Future<void> startCapture() async {
    OBSFrameSource source = OBSFrameSource(this, 12, 60);
    SoundVoltexProcessor processor = SoundVoltexProcessor();
    GameplayStates globalState = GameplayStates.UNKNOWN;

    while (true) {
      Mat? frame = await source.getNextFrame();
      if (frame == null) {
        continue;
      }

      var (state, confidence) = await processor.processFrame(frame, globalState == GameplayStates.GAMEPLAY);

      if (state == GameplayStates.GAMEPLAY && globalState != GameplayStates.GAMEPLAY) {
        //Gameplay detected
        print("Gameplay detected at ${source.frameCount}");
        gameplayStream.add((GameplayStates.GAMEPLAY, gameplays));
        //Now we need to find the end of the gameplay
        globalState = GameplayStates.GAMEPLAY;
      } else if (state == GameplayStates.POST_GAMEPLAY && globalState == GameplayStates.GAMEPLAY) {
        //Gameplay ended
        print("Gameplay ended at ${source.frameCount}");
        gameplayStream.add((GameplayStates.POST_GAMEPLAY, gameplays));
        globalState = GameplayStates.UNKNOWN;
      }
    }
  }

  Future<List<SceneItemDetail>> getSources() async {
    //Get current scene
    String sceneStr = await obs!.scenes.getCurrentProgram();
    return await obs!.sceneItems.getSceneItemList(sceneStr);
   // print(await obs!.sources.getList());
  }

  Future<(GameplayStates, double)> readFrame() async {

   final response = await obs!.sources.getSourceScreenshot(SourceScreenshot(sourceName: sceneItem!, imageFormat: 'png'));
    Mat frame = imdecode(response.bytes, IMREAD_GRAYSCALE);
    SoundVoltexProcessor processor = SoundVoltexProcessor();



    return processor.processFrame(frame, false);

    //print()
  }
}