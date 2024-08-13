import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void setCustomFrame(bool value) {

 if (!value) {
    windowManager.waitUntilReadyToShow(
        WindowOptions(
          title: 'Imperator Desktop',
          size: Size(1280, 720),
          titleBarStyle: TitleBarStyle.hidden,
        )
    ).then((_) async{
    });
  } else {
    windowManager.waitUntilReadyToShow(
        WindowOptions(
          title: 'Imperator Desktop',
          size: Size(1280, 720),
          titleBarStyle: TitleBarStyle.normal,
        )
    ).then((_) async{
    });
 }

}