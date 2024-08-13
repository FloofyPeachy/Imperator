import 'package:flutter/material.dart';
import 'package:imperator_desktop/core/cv/analyser.dart';
import 'package:imperator_desktop/core/config.dart';
import 'package:imperator_desktop/ui/page/edit/editor.dart';
import 'package:imperator_desktop/ui/page/home.dart';
import 'package:imperator_desktop/ui/page/result/result.dart';
import 'package:imperator_desktop/ui/settings.dart';
import 'package:imperator_desktop/ui/titlebar.dart';
import 'dart:io';

import 'package:media_kit/media_kit.dart';                      // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Necessary initialization for package:media_kit.
  MediaKit.ensureInitialized();

  if (!Config.get("system/system_frame")) {
    windowManager.waitUntilReadyToShow(
        WindowOptions(
          title: 'Imperator Desktop',
          size: Size(1280, 720),
          titleBarStyle: TitleBarStyle.hidden,
        )
    ).then((_) async{
    });
  }
  runApp(ImperatorDesktop());
}

class ImperatorDesktop extends StatelessWidget {
  ImperatorDesktop({super.key});
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Imperator Desktop',
      navigatorKey: _navigator,
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) =>  HomeScreen(),
        '/load': (context) =>  LoadingScreen(),
        '/edit': (context) => EditPage(),
        '/analyse': (context) => const AnalysisScreen(),
        '/settings': (context) => SettingsPage(),
      },
      builder: (context2, child) {
        return ValueListenableBuilder(valueListenable: Config.settings, builder: (context, value, child) {
          return Theme(
            data: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Color(Config.get("appearance/ui_color")), brightness: Config.get("appearance/dark_mode") ? Brightness.dark : Brightness.light),
              brightness: Config.get("appearance/dark_mode") ? Brightness.dark : Brightness.light,
              useMaterial3: true,
            ),
            child: Column(
              children: [
                !Config.get("system/system_frame") ? TitleBar(_navigator) : SizedBox(),
                Expanded(child: child!),

              ],
            ),
          );
        }, child: child);
      },
      initialRoute: '/load',

    );
  }
}


