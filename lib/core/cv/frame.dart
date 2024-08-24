import 'package:imperator_desktop/live/obs.dart';
import 'package:obs_websocket/obs_websocket.dart';
import 'package:opencv_dart/opencv_dart.dart';

abstract class FrameSource {
  final int targetFps;
  final int sourceFps;
  int frameCount = 0;

  FrameSource(this.targetFps, this.sourceFps);


  //The higher level code will call this method to get the next frame at the target FPS
  Future<Mat?> getNextFrame() async {
    if (frameCount % (sourceFps ~/ targetFps) != 0) {
      frameCount++;
      return Future.value(null); // Indicate that no frame is returned
    } else {
      frameCount++;
      return await getFrame(); // Fetch and return the frame
    }
  }

  // The lower level implementation will implement this method to get the frame
  Future<Mat> getFrame();
}


class VideoFrameSource extends FrameSource {
  final VideoCapture video;

  VideoFrameSource(this.video, int targetFps, int sourceFps) : super(targetFps, sourceFps);

  factory VideoFrameSource.fromFile(String path, int targetFps, int sourceFps) {
    VideoCapture video = VideoCapture.fromFile(path);
    video.set(CAP_PROP_CONVERT_RGB, 0);
    return VideoFrameSource(video, targetFps, sourceFps);
  }

  @override
  Future<Mat> getFrame() async {
    final frame = video.read().$2;
    return frame;
  }

}

class OBSFrameSource extends FrameSource {
  final OBSConnection obsConnection;

  OBSFrameSource(this.obsConnection, int targetFps, int sourceFps) : super(targetFps, sourceFps);

  @override
  Future<Mat> getFrame() async {
    final response = await obsConnection.obs!.sources.getSourceScreenshot(
        SourceScreenshot(sourceName: obsConnection.sceneItem!, imageFormat: 'png')
    );
    return imdecode(response.bytes, IMREAD_GRAYSCALE);
  }
}