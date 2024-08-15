
import 'package:flutter/material.dart';
import 'package:imperator_desktop/const.dart';

class Track {
  final int id;
  final String title;
  final String artist;
  final String difficulty;
  final int level;
  final int maxCombo;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.difficulty,
    required this.level,
    required this.maxCombo,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      difficulty: json['difficulty'],
      level: json['level'],
      maxCombo: json['maxCombo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'difficulty': difficulty,
      'level': level,
      'maxCombo': maxCombo,
    };
  }

}

class Song {
  final String title;
  final String internalTitle;
  final String id;
  final String artist;

  final List<Difficulty> difficulties;

  Song({
    required this.title,
    required this.internalTitle,
    required this.artist,
    required this.id,
    required this.difficulties,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'],
      internalTitle: json['internalTitle'],
      artist: json['artist'],
      id: json['id'],
      difficulties: List<Difficulty>.from(json['difficulties'].map((e) => Difficulty.fromJson(e))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'internalTitle': internalTitle,
      'artist': artist,
      'id': id,
      'difficulties': difficulties.map((e) => e.toJson()).toList(),
    };
  }

}

class Difficulty {
  final DifficultyType type;
  final int level;

  Difficulty({
    required this.type,
    required this.level,
  });

  factory Difficulty.fromJson(Map<String, dynamic> json) {
    return Difficulty(
      type: DifficultyType.types.firstWhere((element) => element.name == json['type']),
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'level': level,
    };
  }

  @override
  String toString() {
    return "${type.toString()} $level";
  }

}

class DifficultyType {
  final String name;
  final String abbreviation;

  const DifficultyType._(this.name, this.abbreviation);

  static final List<DifficultyType> _types = [];

  static final DifficultyType unknown = create("NOVICE", "NOV");

  static DifficultyType create(String name, String abbreviation) {
    final type = DifficultyType._(name, abbreviation);
    _types.add(type);
    return type;
  }

  static DifficultyType getType(String name) {
    return _types.firstWhere((element) => element.name == name);
  }

  static List<DifficultyType> get types => List.unmodifiable(_types);

  @override
  String toString() => name;
}
enum Gauges {
  effective,
  excessive,
  permissive,
  hexative,
  heavenly
}


class Section {
  int start;
  int end;

  Section({
    required this.start,
    required this.end,
  });
}

class Gameplay extends Section {
  Song? song;
  Score? score;
  final Games game;
  Gameplay({required this.song, required this.game, required this.score, required super.start, required super.end});

  factory Gameplay.fromJson(Map<String, dynamic> json) {
    return Gameplay(
      song: json['song'] != null ? Song.fromJson(json['song']) : null,
      game: Games.values[json['game']],
      score:  json['score'] != null ? Score.fromJson(json['score']) : null,
      start: json['start'],
      end: json['end'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'song': song?.toJson(),
      'game': game.index,
      'score': score?.toJson(),
      'difficulty': score?.difficulty.toJson(),
      'start': start,
      'end': end,
    };
  }



  @override
  String toString() {
    return "Gameplay: ${song!.title} by ${song!.artist} (${song!.difficulties[0].type.toString()} ${song!.difficulties[0].level})";
  }

}

class Score {
  final int score;
  final int maxCombo;
  final int criticalEarly;
  final int criticalLate;
  final int nearEarly;
  final int nearLate;
  final int missEarly;
  final int missLate;
  final double percentage;
  final Gauges gauge;
  final int sCritical;
  Difficulty difficulty;

  Score({
    required this.score,
    required this.maxCombo,
    required this.sCritical,
    required this.nearEarly,
    required this.nearLate,
    required this.missEarly,
    required this.missLate,
    required this.criticalEarly,
    required this.criticalLate,
    required this.percentage,
    required this.gauge,
    required this.difficulty,

  });

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      score: json['score'],
      maxCombo: json['maxCombo'],
      sCritical: json['sCritical'],
      nearEarly: json['nearEarly'],
      nearLate: json['nearLate'],
      missEarly: json['missEarly'],
      missLate: json['missLate'],
      criticalEarly: json['criticalEarly'],
      criticalLate: json['criticalLate'],
      percentage: json['percentage'],
      gauge: Gauges.values[json['gauge']],
      difficulty: Difficulty.fromJson(json['difficulty']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'maxCombo': maxCombo,
      'sCritical': sCritical,
      'nearEarly': nearEarly,
      'nearLate': nearLate,
      'missEarly': missEarly,
      'missLate': missLate,
      'criticalEarly': criticalEarly,
      'criticalLate': criticalLate,
      'percentage': percentage,
      'gauge': gauge.index,
      'difficulty': difficulty.toJson(),
    };
  }

  @override
  String toString() {
    return "Score: $score, $maxCombo, $sCritical, $nearEarly, $nearLate, $missEarly, $missLate, $criticalEarly, $criticalLate, $percentage, $gauge, $difficulty";
  }


}