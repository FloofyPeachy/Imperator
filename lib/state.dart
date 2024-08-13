import 'package:flutter/material.dart';
import 'package:imperator_desktop/core/games.dart';
import 'package:imperator_desktop/model/model.dart';

ValueNotifier<Section?> currentSection = ValueNotifier(null);
ValueNotifier<Game?> currentGame = ValueNotifier(null);