import 'package:flutter/material.dart';
import 'package:imperator_desktop/const.dart';
import 'package:imperator_desktop/core/util.dart';
import 'package:imperator_desktop/model/model.dart';

class DifficultyWidget extends StatelessWidget {
  final Score score;

  DifficultyWidget({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
      //  color: difficultyToColor(score.difficulty.type),
        borderRadius: BorderRadius.circular(3),
      ),
      padding: EdgeInsets.all(5),
      child: Text(
        "${score.difficulty.type.abbreviation} ${score.difficulty.level}",
        style: TextStyle(
          color: Colors.white,
          fontSize: dH(context) * 0.03,
        ),
      ),
    );
  }
}