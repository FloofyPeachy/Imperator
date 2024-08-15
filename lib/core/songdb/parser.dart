import 'dart:convert';
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:euc/jis.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:fuzzywuzzy/model/extracted_result.dart';
import 'package:imperator_desktop/const.dart';
import 'package:imperator_desktop/core/games.dart';
import 'package:imperator_desktop/model/model.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';
class SongList {
  static Map<String, List<Song>> tracks = {};
  static Song getSong(String game, String title, String artist) {
    ExtractedResult<Song> result = extractOne(
        query: title,
        choices: tracks[game]!,
        cutoff: 10,
        getter: (x) => x.title
    );
    if (result.score < 50) {
      result = extractOne(
          query: artist,
          choices: tracks[game]!,
          cutoff: 10,
          getter: (x) => x.artist
      );

    }

    return result.choice;

  }

  static Future<void> loadAll() async {
    print("Loading songs...");
    GameList.games.forEach((key, value) async {
      List<Song> songs = await value.parseSongs("./data/$key/songs.xml");
      tracks[key] = songs;
      print("Loaded ${songs.length} songs for ${value.title}");
    });

  }

}
