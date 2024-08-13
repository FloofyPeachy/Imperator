
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:imperator_desktop/model/model.dart';


List<Games> games = [];



Color gaugeToColor(Gauges gauge) {
  //effective: #F8397E
  //excessive: #F8397E
  //hexative: #F8397E
  //permissive: #F8397E
  switch (gauge) {
    case Gauges.effective:
      return Color(0xFFF8397E);
    case Gauges.excessive:
      return Color(0xFFF8397E);
    case Gauges.hexative:
      return Color(0xFFF8397E);
    case Gauges.permissive:
      return Color(0xFFF8397E);
    case Gauges.heavenly:
      return Colors.yellow;
  }


}


enum Games {
  SOUND_VOLTEX,
  GROOVE_COASTER,
  DJMAX,
  UNKNOWN
}