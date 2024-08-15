import 'package:imperator_desktop/core/config.dart';
import 'package:obs_websocket/obs_websocket.dart';
import 'package:obs_websocket/request.dart' hide Stream, Config;
import 'package:opencv_dart/opencv_dart.dart';

class OBSConnection {
  ObsWebSocket? obs;
  Sources? source;
  String? sourceName;

  Future<void> connect() async {
    obs = await ObsWebSocket.connect("${"ws://" + Config.get("live/ip_address")}:" + Config.get("live/port"),password: Config.get("live/password"));
  }

  Future<void> startCapture() async {
    Stream.periodic(Duration(seconds: 1)).listen((event) {
      readFrame();
    });
  }

  void readFrame() async {
    final response = await source!.getSourceScreenshot(SourceScreenshot(sourceName: sourceName!, imageFormat: 'png'));
    Mat frame = imdecode(response.bytes, IMREAD_GRAYSCALE);
    //print()
  }
}