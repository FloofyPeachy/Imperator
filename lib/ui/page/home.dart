import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:imperator_desktop/core/config.dart';
import 'package:imperator_desktop/core/songdb/parser.dart';
import 'package:imperator_desktop/core/util.dart';
import 'package:imperator_desktop/ui/bar.dart';

class LoadingScreen extends StatefulWidget {
  @override
  State<LoadingScreen> createState() => _LoadingScreen();
}

class _LoadingScreen extends State<LoadingScreen> {
  int index = 0;
  Map<String, Future<void>> futures = {
    "Loading config...": Config.load(),
    "Reading song database...": SongList.loadAll(),
  };

  @override
  void initState() {
    super.initState();
    _loadFutures();
  }

  Future<void> _loadFutures() async {
    for (int i = 0; i < futures.length; i++) {
      setState(() {
        index = i;
      });
      await futures[i];
    }
    setCustomFrame(Config.get("system/system_frame"));
    Navigator.pushReplacementNamed(context, '/'); // Navigate to the next screen after loading
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/logo.svg', height: dH(context) * 0.07),
            Text("Version 0.1.0", style: TextStyle(fontSize: dH(context) * 0.025)),
            SizedBox(height: dH(context) * 0.011),
            Text(futures.keys.elementAt(index), style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {

  @override
  State<HomeScreen> createState() => _HomeScreen();
}
class _HomeScreen extends State<HomeScreen> with TickerProviderStateMixin {

  int pressCount = 0;
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );

  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!Config.get("system/first_run")) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Welcome to Imperator!"),
                content: Text("This program is still in development and may contain bugs. Please report any issues you find to me please!!!\nIf you live on the edge, you can enable some of the experimental features in the settings menu (click on the Imperator logo in the top left corner)\nEnjoy!!\n\n- FloofyPeachy <3"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Config.set("system/first_run", true);
                      Navigator.of(context).pop();
                    },
                    child: Text("Got it!"),
                  )
                ],
              );
            }
        );

      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: RotationTransition(
        turns: _animation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                    child: SvgPicture.asset('assets/images/logo.svg', height: dH(context) * 0.07),
                    onTap: () {
                      if (pressCount == 4) {
                        pressCount = 0;
                        player.setVolume(0.1);
                        player.play(AssetSource('audio_laser_slam.wav'));
                        _controller.reset();
                        _controller.animateTo(1);
                      } else {
                        pressCount++;
                      }
                    },
                ),
              ),
              Text("Version 0.1.0", style: TextStyle(fontSize: dH(context) * 0.025)),
              SizedBox(height: dH(context) * 0.011),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: dW(context) * 0.15,
                    child: OutlinedButton(
                      style: ButtonStyle(
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                              )
                          )
                      ),
                      onPressed: () async {
                        // Add the code to navigate to the next screen
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['mp4', 'mkv', 'avi', 'mov', 'flv', 'wmv', 'webm', 'm4v', '3gp', '3g2', 'mpg', 'mpeg', 'm2v', 'm4v', 'ts', 'mts', 'm2ts', 'vob', 'ogv', 'ogg', 'rm', 'rmvb', 'asf', 'dv', 'f4v', 'h261', 'h263', 'h264', 'hevc', 'mjpeg', 'mjpg', 'mkv', 'mng', 'mov', 'mp2', 'mp2v', 'mp4', 'mp4v', 'mpe', 'mpeg', 'mpg', 'mpv2', 'ogm', 'qt', 'rm', 'rmvb', 'swf', 'ts', 'vob', 'webm', 'wm', 'wmv', 'yuv']
                        );
        
                        if (result != null) {
                          Navigator.pushNamed(context, '/analyse' , arguments: {
                            'video': result.files.single.path!
                          });
                        }
        
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_collection_outlined, size: dH(context) * 0.12,),
                            Text('Video', style: TextStyle(fontSize: dH(context) * 0.04, fontWeight: FontWeight.bold)),
                            Text("Clip a video of gameplay", style: TextStyle(fontSize: dH(context) * 0.02)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: dW(context) * 0.03),
                  SizedBox(
                    height: dW(context) * 0.15,
                    child: OutlinedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                )
                            )
                        ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/live');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Icon(Icons.fiber_manual_record, size: dH(context) * 0.12,),
                            Text('Live', style: TextStyle(fontSize: dH(context) * 0.04, fontWeight: FontWeight.bold)),
                            Text("Automatically capture\n gameplay from OBS", style: TextStyle(fontSize: dH(context) * 0.02)),
                          ],
                                        ),
                      )
                    ),
                  ),
                ],
              ),
        
              /*ElevatedButton(
                onPressed: () {  },
                child: Column(
                  children: [
                    Icon(Icons.fiber_manual_record, size: dH(context) * 0.12,),
                    Text('Live video', style: TextStyle(fontSize: dH(context) * 0.08))
                  ],
                )
              */
            ],
        
          ),
        ),
      ),
    );
  }
}