import 'dart:convert';
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:flutter/material.dart';
import 'package:imperator_desktop/const.dart';
import 'package:imperator_desktop/core/cv/processors.dart';
import 'package:imperator_desktop/model/model.dart';
import 'package:xml/xml.dart';

class GameList {
  static Map<String, Game> games = {
    "sdvx": SoundVoltex(),
  };


  static Game getGame(String code) {
    return games[code]!;
  }


}



abstract class Game {
  String title;
  FrameProcessor processor;
  Map<String, Color> colors;
  List<String> versions;

  Game({
    required this.title,
    required this.versions,
    required this.colors,
    required this.processor,
  });

  String scoreToGrade(int score);

  Future<List<Song>> parseSongs(String path);
}

class SoundVoltex extends Game {
  SoundVoltex() : super(
      title: "SOUND VOLTEX",
      processor: SoundVoltexProcessor(),
      colors: {
        "NOVICE": const Color(0xFF8B49C0),
        "ADVANCED": const Color(0xFFA4A10A),
        "EXHAUST": const Color(0xFF923536),
        "MAXIMUM": const Color(0xFF6D6E70),
        "INFINITE": const Color(0xFFB22464),
        "GRAVITY": const Color(0xFF9E4200),
        "HEAVENLY": const Color(0xFF007EA6),
        "VIVID": const Color(0xFFB7449B),
        "EXCEED": const Color(0xFF365191),
      },
      versions: [
        "BOOTH",
        "INFINITE INFECTION",
        "GRAVITY WARS",
        "HEAVENLY HAVEN",
        "VIVID WAVE",
        "EXCEED GEAR",
      ]
  ) {

    DifficultyType.create("NOVICE", "NOV");
    DifficultyType.create("ADVANCED", "ADV");
    DifficultyType.create("EXHAUST", "EXH");
    DifficultyType.create("MAXIMUM", "MXM");
    DifficultyType.create("INFINITE", "INF");
    DifficultyType.create("GRAVITY", "GRV");
    DifficultyType.create("HEAVENLY", "HVN");
    DifficultyType.create("VIVID", "VVD");
    DifficultyType.create("EXCEED", "EXD");


  }
  @override
  String scoreToGrade(int score) {
    if (score > 9900000) {
      return "S";
    } else if (score > 9800000) {
      return "AAA+";
    } else if (score > 9700000) {
      return "AAA";
    } else if (score > 9500000) {
      return "AA+";
    } else if (score > 9300000) {
      return "AA";
    } else if (score > 9000000) {
      return "A+";
    } else if (score > 8700000) {
      return "A";
    } else if (score > 7500000) {
      return "B";
    } else if (score > 6500000) {
      return "C";
    } else {
      return "D";
    }
  }

  @override
  Future<List<Song>> parseSongs(String path) async {
      List<Song> songs = [];
      File file = File(path);

      try {
        // Read the file as bytes
        List<int> bytes = await file.readAsBytes();
        // Decode the bytes using Shift-JIS
        String content = utf8.decode(bytes);

        final document = XmlDocument.parse(content);
        for (var element in document.root.children) {
          element.children.forEach((element) {
            if (element.children.isNotEmpty) {
              XmlNode info = element.children[1];
              List<Difficulty> difficulties = [];
              XmlNode difficulties_xml = element.children[3];

              difficulties_xml.children.forEach((element) {
                //  print("Difficulty: ${element.getElement("difficulty")!.innerText}");
                //check if element tag name is in the enum of difficulties
                if (element is! XmlText) {
                  Difficulty diff = Difficulty(
                    type:  DifficultyType.getType((element as XmlElement).name.toString().toUpperCase()),
                    level: int.parse(element.children[1].innerText),
                  );
                  difficulties.add(diff);
                }

              });

              songs.add(Song(
                title: info.getElement("title_name")!.innerText,
                artist: info.getElement("artist_name")!.innerText,
                internalTitle: info.getElement("ascii")!.innerText,
                id: info.getElement("label")!.innerText,
                difficulties: difficulties,
              ));
            }

          });
        }
      } catch (e, stacktrace) {
        print("Error reading file: $e");
        print(stacktrace);
      }
      songs.add(Song(
        title: "MEGAMIX BATTLE",
        artist: "? ? ? ? ?",
        internalTitle: "smegamix",
        id: "",
        difficulties: [],
      ));

      return songs;
    }


}