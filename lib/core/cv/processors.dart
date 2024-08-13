import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:fuzzywuzzy/extractor.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:fuzzywuzzy/model/extracted_result.dart';
import 'package:imperator_desktop/const.dart';
import 'package:imperator_desktop/core/cv/analyser.dart';
import 'package:imperator_desktop/core/cv/ocr.dart';
import 'package:imperator_desktop/core/games.dart';
import 'package:imperator_desktop/core/songdb/parser.dart';
import 'package:imperator_desktop/core/util.dart';
import 'package:imperator_desktop/model/model.dart';
import 'package:opencv_dart/opencv_dart.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:quiver/collection.dart';

/*
* A FrameProcessor is a class that processes a frame and determines what state the game is in, as well as getting the score, song, and difficulty.
* It is used by the VideoAnalyser to determine the state of the game.
* Different games use different FrameProcessors. (obviously)
* */

class FrameProcessor {
  late int version;

  FrameProcessor();
  Future<void> loadTemplates(int version) async {}

  Future<(GameplayStates, double)> processFrame(cv.Mat frame, bool forScore) async {
    return (GameplayStates.UNKNOWN, 100.0);
  }

  Future<Score> parseScore(cv.Mat frame) async {
    return Score(score: 0, maxCombo: 0, sCritical: 0, criticalEarly: 0, criticalLate: 0, nearEarly: 0, nearLate: 0, missEarly: 0, missLate :0, percentage: 0, gauge: Gauges.effective, difficulty: Difficulty(type: DifficultyType.getType("maximum"), level: 0));
  }

  Future<Song> parseSong(cv.Mat frame) async {
    return Song(title: "Test", artist: "Test", internalTitle: "Test", id: "", difficulties: []);
  }

}


class SoundVoltexProcessor extends FrameProcessor {
  SoundVoltexProcessor();

  Mat? startTemplate;
  Mat? startHexa1Template;
  Mat? startHexa2Template;
  Mat? scoreTemplate;
  Mat? scoreMegamixTemplate;
  //Numbers
  Mat? zero;
  Mat? one;
  Mat? two;
  Mat? three;
  Mat? four;
  Mat? five;
  Mat? six;
  Mat? seven;
  Mat? eight;
  Mat? nine;

  @override
  Future<void> loadTemplates(int version) async {
    this.version = version;
    startTemplate =
        imread("./template/sdvx/start_reg.jpg", flags: IMREAD_GRAYSCALE)
            .rowRange(700, 860);
    startHexa1Template =
        imread("./template/sdvx/start_hexa1.jpg", flags: IMREAD_GRAYSCALE)
            .rowRange(700, 860);
    startHexa2Template =
        imread("./template/sdvx/start_hexa2.jpg", flags: IMREAD_GRAYSCALE)
            .rowRange(700, 860);
    scoreTemplate =
        imread("./template/sdvx/score.jpg", flags: IMREAD_GRAYSCALE);
    scoreMegamixTemplate =
        imread("./template/sdvx/score_megamix.jpg", flags: IMREAD_GRAYSCALE);

    zero = imread("./template/sdvx/num/0.jpg", flags: IMREAD_GRAYSCALE);
    one = imread("./template/sdvx/num/1.jpg", flags: IMREAD_GRAYSCALE);
    two = imread("./template/sdvx/num/2.jpg", flags: IMREAD_GRAYSCALE);
    three = imread("./template/sdvx/num/3.jpg", flags: IMREAD_GRAYSCALE);
    four = imread("./template/sdvx/num/4.jpg", flags: IMREAD_GRAYSCALE);
    five = imread("./template/sdvx/num/5.jpg", flags: IMREAD_GRAYSCALE);
    six = imread("./template/sdvx/num/6.jpg", flags: IMREAD_GRAYSCALE);
    seven = imread("./template/sdvx/num/7.jpg", flags: IMREAD_GRAYSCALE);
    eight = imread("./template/sdvx/num/8.jpg", flags: IMREAD_GRAYSCALE);
    nine = imread("./template/sdvx/num/9.jpg", flags: IMREAD_GRAYSCALE);
  }

  @override
  Future<(GameplayStates, double)> processFrame(
      Mat frame, bool forScore) async {
    if (startTemplate == null) {
      loadTemplates(6);
    }

    frame = frame.rowRange(
      700,
      860,
    );

    var startResult = matchTemplate(frame, startTemplate!, TM_CCOEFF_NORMED);
    var minMax = minMaxLoc(startResult);
    if (minMax.$2 > 0.7) {
      return (GameplayStates.GAMEPLAY, minMax.$2 * 100);
    }

    var startHexa1Result =
        matchTemplate(frame, startHexa1Template!, TM_CCOEFF_NORMED);
    var startHexa1MinMax = minMaxLoc(startHexa1Result);
    if (startHexa1MinMax.$2 > 0.7) {
      //   imwrite("frame.jpg", frame);
      //  imwrite("title.jpg", prepareFrame(frame.colRange(240, frame.width - 80).rowRange(180, frame.height), 3.2));

      return (GameplayStates.GAMEPLAY, startHexa1MinMax.$2 * 100);
    }

    var startHexa2Result =
        matchTemplate(frame, startHexa2Template!, TM_CCOEFF_NORMED);
    var startHexa2MinMax = minMaxLoc(startHexa2Result);
    if (startHexa2MinMax.$2 > 0.7) {
      return (GameplayStates.GAMEPLAY, startHexa2MinMax.$2 * 100);
    }

    if (forScore) {
      //crop the frame

      var scoreResult = matchTemplate(frame, scoreTemplate!, TM_CCOEFF_NORMED);
      var scoreMinMax = minMaxLoc(scoreResult);
      //resize to 300dpi for better OCR
      //= np.ones((1, 1), np.uint8) but in c#
      //frame = prepareFrame(frame, 2.3);

      //imwrite("frame.jpg", frame);
      // imwrite("score.jpg", frame.colRange(600, frame.width).rowRange(500, frame.height));
      if (scoreMinMax.$2 > 0.7) {
        return (GameplayStates.POST_GAMEPLAY, scoreMinMax.$2 * 100);
      }

      var scoreMegamixResult =
          matchTemplate(frame, scoreMegamixTemplate!, TM_CCOEFF_NORMED);
      var scoreMegamixMinMax = minMaxLoc(scoreMegamixResult);
      if (scoreMegamixMinMax.$2 > 0.5) {
        return (GameplayStates.POST_GAMEPLAY, scoreMegamixMinMax.$2 * 100);
      }
    }

    return (GameplayStates.UNKNOWN, 100.0);
  }


  Future<Difficulty> processDifficulty(Mat frame, Song song) async {
    //Determine the difficulty by getting the color of the difficulty text, then getting that difficulty based on the song
    //We need to crop the frame to the difficulty area
    frame = frame.rowRange(580, 600).colRange(35, 130);
    imwrite("diff.jpg", frame);

    //Get the color of the text
    Vec3b color = frame.at(3, 0);
    Color closest = findClosestColor(GameList.getGame("sdvx").colors.values.toList(), Color.fromRGBO(color.val3, color.val2, color.val1, 1));
    DifficultyType type = DifficultyType.getType("novice");
    /*print("Closest: $closest");
    for (var element in difficultyColors.entries) {
      print(element.key.toString() + ": " + element.value.value.toString());
      if (closest == element.value) {
        print("Difficulty: ${element.key}");
        type = DifficultyType.values.byName(element.key.name);
        break;
      }
    }*/

    //Now get the difficulty based on the color
    /*Color foundColor = difficultyColors.values.toList()[difficultyColors.values.toList().indexOf(Color(closest))];
    DifficultyType type = DifficultyType.novice;
    for (var element in difficultyColors.entries) {
      print(element.key.toString() + ": " + element.value.value.toString());
      if (foundColor == element.value) {
        print("Difficulty: ${element.key}");
        type = DifficultyType.values.byName(element.key.name);
        break;
      }
    }*/
    //Now, get all the difficulty colors and find the closest one
    /*ExtractedResult<Color> result = extractOne(
        query: Color.fromRGBO(color.val3, color.val2, color.val1, 1).value.toString(),
        choices: difficultyColors.values.toList(),
        cutoff: 10,
        getter: (x) => x.value.toString()
    );
    //Now, get the difficulty based on the color
    print(result);
    print(difficultyColors[result.choice]);
    List<Color> colorList =  difficultyColors.values.toList();
    Color choiceColor = colorList[result.index];
    DifficultyType type = DifficultyType.novice;
    for (var element in difficultyColors.entries) {
      print(element.key.toString() + ": " + element.value.value.toString());
      if (choiceColor == element.value) {

        print("Difficulty: ${element.key}");
        type = DifficultyType.values.byName(element.key.name);
        break;
      }
    }*/
    Difficulty diff = song.difficulties.firstWhere((element) => element.type == type, orElse: () => Difficulty(type: DifficultyType.getType("novice"), level: 5));
    //Finally, infer the difficulty based on the song
    return Difficulty(type: type, level: diff.level);

  }


  @override
  Future<Song> parseSong(Mat frame) async {
    //Could be better. Ideally without converting it to a Mat

    frame = frame.colRange(230, frame.width - 650);
    imwrite(
        "title.jpg",
        prepareFrame(
            frame.colRange(240, frame.width - 80).rowRange(180, frame.height),
            3.2));
    List<String> text = TesseractCLI.extractText("title.jpg");
    if (text.isEmpty) {
      return Song(
          title: "Unknown",
          artist: "Unknown",
          internalTitle: "deez",
          id: "",
          difficulties: []);
    }
    return SongList.getSong(
        SoundVoltex(),
        text.elementAtOrNull(0) == null ? "" : text[0],
        text.elementAtOrNull(1) == null ? "" : text[1]);
  }

  @override
  Future<Score> parseScore(Mat frame) async {
    if (startTemplate == null) {
      loadTemplates(6);
    }
    frame = frame
        .colRange(412, frame.width - 255)
        .rowRange(825, frame.height - 314);
//    imwrite("score.jpg", frame);
    //   imwrite("score2.jpg", prepareFrame(frame, 1.5));
    //  imwrite("score3.jpg", prepareFrame2(frame,));
    //We gotta do some bullshit here because OCR cannot recognize the numbers
    //We need to do some template matching
    bool sCritical = true; //assume it's a sCritical for now
    if (sCritical) {
      //There are 7 columns of numbers. (in s-critical)
      //between each column is 6 pixels
      //Error, Near, Critical, S-Critical, Critical, Near, Error (early -> late)
      //Each column can contain 4 numbers
      //If the number is -1, then that area is blank
      List<int> columnY = [6, 26, 46, 66, 86, 106, 126];
      List<int> results = [];
      for (int i = 0; i < 7; i++) {
        Mat column = frame.rowRange(columnY[i] - 3, columnY[i] - 3 + 14);
        String number = await processNumber(column);
        //  print("column " + i.toString() + " : $number");

        //   imwrite("column$i.jpg", column);
        //String number = Tesseract.extractNumber("column$i.jpg");
        //print(number);
        if (number == "") {
          results.add(-1);
        } else {
          results.add(int.parse(number));
        }
      }
      print(results);

      return Score(
          score: 0,
          maxCombo: 0,
          sCritical: results[3],
          criticalEarly: results[4],
          criticalLate: results[2],
          nearEarly: results[5],
          nearLate: results[1],
          missEarly: results[6],
          missLate: results[0],
          percentage: 0,
          gauge: Gauges.effective,
          difficulty: Difficulty(type: DifficultyType.getType("novice"), level: 0));
    }


  }

  Future<String> processNumber(Mat frame) async {
    //Processes the number by column
    OutputArray result = OutputArray.empty();
    var zeroMatch =
        matchTemplate(frame, zero!, TM_CCOEFF_NORMED, result: result);

    var zeroMatches = getAllMatches(frame, zero!);
    var oneMatches = getAllMatches(frame, one!);
    var twoMatches = getAllMatches(frame, two!);
    var threeMatches = getAllMatches(frame, three!);
    var fourMatches = getAllMatches(frame, four!);
    var fiveMatches = getAllMatches(frame, five!);
    var sixMatches = getAllMatches(frame, six!);
    var sevenMatches = getAllMatches(frame, seven!);
    var eightMatches = getAllMatches(frame, eight!);
    var nineMatches = getAllMatches(frame, nine!);

    //Combine them all, and then sort them
    Multimap<int, int> leMatches = Multimap<int, int>();
    for (var element in zeroMatches) {
      leMatches.add(0, element);
    }
    for (var element in oneMatches) {
      leMatches.add(1, element);
    }
    for (var element in twoMatches) {
      leMatches.add(2, element);
    }
    for (var element in threeMatches) {
      leMatches.add(3, element);
    }
    for (var element in fourMatches) {
      leMatches.add(4, element);
    }
    for (var element in fiveMatches) {
      leMatches.add(5, element);
    }
    for (var element in sixMatches) {
      leMatches.add(6, element);
    }
    for (var element in sevenMatches) {
      leMatches.add(7, element);
    }
    for (var element in eightMatches) {
      leMatches.add(8, element);
    }
    for (var element in nineMatches) {
      leMatches.add(9, element);
    }
    //sort them
    String output = "";
    for (var element in leMatches.keys) {
      //leMatches[element].toList().sort();
    }

    return leMatches.keys.join();
  }

  //Returns a list of all matches's x coordinates
  List<int> getAllMatches(Mat frame, Mat template) {
    OutputArray result = OutputArray.empty();
    var match =
        matchTemplate(frame, template, TM_CCOEFF_NORMED, result: result);

    List<int> matches = [];
    threshold(match, 0.85, 1.0, THRESH_TOZERO);
    while (true) {
      double threshold = 0.85;
      var minMax = minMaxLoc(result);
      if (minMax.$2 >= threshold) {
        // print("Found a match at ${minMax.$1}, ${minMax.$2} with score ${minMax.$3}");
        var rect = Rect(minMax.$4.x, minMax.$4.y, zero!.width, zero!.height);
        rectangle(frame, rect, cv.Scalar.all(255), thickness: 1);
        rectangle(
            result, Rect(minMax.$4.x, minMax.$4.y, 1, 1), cv.Scalar.all(0),
            thickness: FILLED);
        matches.add(minMax.$4.x);
        print("pos: ${minMax.$4.x}");
      } else {
        break;
      }
    }
    //  print(matches);
    return matches;
  }

  List<(cv.Rect, double)> extractBoundingBoxes(cv.Mat frame, cv.Mat template) {
    List<(cv.Rect, double)> boxes = [];

    // Set a threshold for detecting matches
    double threshold = 100; // Adjust as needed

    for (int y = 0; y < frame.rows; y++) {
      for (int x = 0; x < frame.cols; x++) {
        var score = (frame.atNum<num>(y, x));
        print(score);
        if (score >= threshold) {
          // Create a bounding box around the detected match
          cv.Rect rect = cv.Rect(x, y, template.cols, template.rows);
          // boxes.add((rect, score));
          print("Found match at $x, $y with score $score");
        }
      }
    }

    return boxes;
  }
}
