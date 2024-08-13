import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class Config {
  static ValueNotifier<Map<String, Map<String, ConfigOption>>> settings = ValueNotifier<Map<String, Map<String, ConfigOption>>>({
    "system": {
      "system_frame" : ConfigOption("system_frame", "Use system frame", false, false),
      "first_run" : ConfigOption("first_run", "Show first run message", false, false),
    },
    "appearance": {
      "ui_color" : ConfigOption("ui_color", "UI Color", Colors.blue.value, Colors.blue.value),
      "dark_mode" : ConfigOption("dark_mode", "Dark Mode", true, true),
    },
    "experimental": {
      "song_detection" : ConfigOption("song_detection", "Song Detection", false, false),
      "score_detection" : ConfigOption("score_detection", "Score Detection", false, false),
    },
  });

  static Map<String, String> descriptions = {
    "system_frame": "Use the system frame instead of Imperator's custom one",
    "song_detection": "Enable automatic song detection. May not work on all songs.",
    "score_detection": "Enable automatic score detection. May not return accurate results.",
  };

  static Future<void> load() async {
    //Load settings from disk
    print("Loading settings...");
    File configFile = File("config.json");
    if (!configFile.existsSync()) {
      //Create the file
      configFile.createSync();
      save();
      return;
    }

    //Create the settings dynamically from the file
    Map<String, dynamic> fileSettings = jsonDecode(configFile.readAsStringSync());
    settings.value.forEach((category, value) {
      value.forEach((key, value) {
        if (fileSettings.containsKey(category) == false) {
          //Must be a new category, add it to the file
          fileSettings[category] = {};
        }
        if (fileSettings[category][key] == null) {
          //Must be a new setting, add it to the file
          fileSettings[category][key] = settings.value[category]![key]!.defaultValue;
          save();
        } else {
          settings.value[category]![key] = ConfigOption.fromJson(fileSettings[category][key]);
        }

      });
    });

    print("Settings loaded!");
  }

  static void save() {
    //Save settings to disk
    print("Saving settings...");
    File configFile = File("config.json");
    configFile.writeAsStringSync(jsonEncode(settings.value));
    print("Settings saved!");
    settings.notifyListeners();
  }

  static void set(String path, dynamic value) {
    List<String> keys = path.split("/");
    settings.value[keys[0]]![keys[1]]!.value = value;
    save();
  }

  static dynamic? get(String path) {
    List<String> keys = path.split("/");
    ConfigOption option = settings.value[keys[0]]![keys[1]]!;
    return option.value ?? option.defaultValue;
  }

  static String? getDescription(String path) {
    List<String> keys = path.split("/");
    if (descriptions.containsKey(keys[1]) == false) {
      return null;
    }
    return descriptions[keys[1]]!;
  }

}

class ConfigOption {
  final String internalName;
  final String name;
  final dynamic defaultValue;
  dynamic value;

  ConfigOption(this.internalName, this.name, this.defaultValue, this.value);

  @override
  factory ConfigOption.fromJson(Map<String, dynamic> json) {
    return ConfigOption(json["internalName"], json["name"], json["defaultValue"], json["value"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "internalName": internalName,
      "name": name,
      "defaultValue": defaultValue,
      "value": value is Color ? value.value : value,
    };
  }
}
