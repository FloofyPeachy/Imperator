import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:imperator_desktop/const.dart';
import 'package:imperator_desktop/core/games.dart';
import 'package:imperator_desktop/core/songdb/fairyjoke.dart';
import 'package:imperator_desktop/core/util.dart';
import 'package:imperator_desktop/model/model.dart';
import 'package:imperator_desktop/state.dart';
import 'package:imperator_desktop/ui/widget/sdvx.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DetailView extends StatelessWidget {
  final bool vertical;
  DetailView({Key? key, required this.vertical}) : super(key: key);
  late TooltipBehavior _tooltip = TooltipBehavior(enable: true);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentSection,
      builder: (context, value, child) {
        return value == null ?
        Center(
          child: Text("Select a section to know more about it"),
        ) : buildGameplayDetails(context, value as Gameplay, currentGame.value!);
      },
    );
  }

  Widget buildGameplayDetails(BuildContext context, Gameplay section, Game game) {

    return Stack(
      children: [
        section.score != null ? Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment(0.9, 0.0),

              colors: [game.colors[section.score!.difficulty.type.toString()]!.withOpacity(0.5), Colors.transparent],
            ),
          ),
        ) : SizedBox(),
        section.score != null ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //Image.network("https://sdvxindex.com//img/" + ((int.tryParse(section.song!.id) != null && int.tryParse(section.song!.id)! < 1000) ? "0" + section.song!.id : section.song!.id ) + "_" + section.song!.internalTitle! + "/jk_" + ((int.tryParse(section.song!.id) != null && int.tryParse(section.song!.id)! < 1000) ? "0" + section.song!.id : section.song!.id ) + "_1.webp",
                Image.network(FairyJokeAPI.apiUrl + "games/sdvx/musics/" + section.song!.id + "/" + section.score!.difficulty.type.name + ".png" ,
                  height: dH(context) * 0.25,
                ),


                Text(section.song!.title, style: TextStyle(fontSize: dH(context) * 0.045, fontWeight: FontWeight.bold)),
                Text(section.song!.artist, style: TextStyle(fontSize: dH(context) * 0.035)),
                DifficultyWidget(score: section.score!),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        launchUrlString("https://remywiki.com/" + section.song!.title.replaceAll(" ", "_"));
                      },
                      icon: Icon(Icons.open_in_new),
                      label: Text("RemyWiki"),
                    ),
                    TextButton.icon(
                      onPressed: () {

                      },
                      icon: Icon(Icons.open_in_new),
                      label: Text("Sdvxindex"),
                    ),
                  ],
                ),
                //Text(Game[section.game] ?? "Unknown game", style: TextStyle(fontSize: dH(context) * 0.02),),
              ],
            ),
            /*Container(
              //with a border
                *//*decoration: BoxDecoration(
                  border: Border.all(color: section.score.maxCombo == section.song.maxCombo ? Colors.purple : Colors.white),
                ),*//*
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(scoreToGrade(section.score.score), style: TextStyle(fontSize: dH(context) * 0.05, fontWeight: FontWeight.bold)),
                    Container(width: 8),
                    Text("${section.score.score}", style: TextStyle(fontSize: dH(context) * 0.05)),
                    Text("S-Critical: ${section.score.sCritical}", style: TextStyle(fontSize: dH(context) * 0.03)),
                    Text("Critical: ${section.score.critical}", style: TextStyle(fontSize: dH(context) * 0.03)),
                    Text("Near: ${section.score.near}", style: TextStyle(fontSize: dH(context) * 0.03)),
                    Text("Error: ${section.score.miss}", style: TextStyle(fontSize: dH(context) * 0.03)),
                  ],
                )
            ),
           */
            section.score != null ? buildScoreCard(section.score!, context) : SizedBox()
         ],
        ) : SizedBox()
      ],


    );
  }

  static Widget buildScoreCard(Score score, BuildContext context) {
    var data = [

      _ChartData('S-Critical', 'S-Critical', score.sCritical.toDouble(), hexStringToColor("#10B6B7")),
      _ChartData('Critical', 'Critical', (score.criticalLate + score.criticalEarly).toDouble(),  Colors.yellow),
      _ChartData('Near', 'Near', (score.nearEarly + score.nearLate).toDouble(), hexStringToColor("#D8D84D")),
      _ChartData('Error', 'Error', (score.missLate + score.missEarly).toDouble(), hexStringToColor("#D8D84D")),

    ].reversed.toList();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(score.score.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'), style: TextStyle(fontSize: dH(context) * 0.05, fontWeight: FontWeight.bold),),
        SizedBox(
          height: dH(context) * 0.2,
          child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(minimum: 0, maximum:  score.sCritical.toDouble()),
              //t/ooltipBehavior: _tooltip,
              series: <CartesianSeries<_ChartData, String>>[
                BarSeries<_ChartData, String>(
                    dataSource: data,
                    xValueMapper: (_ChartData data, _) => data.x,
                    yValueMapper: (_ChartData data, _) => data.y,
                    pointColorMapper: (_ChartData data, _) => data.color,
                    animationDuration: 700,
                    dataLabelSettings:DataLabelSettings(isVisible : true),
                    name: 'Score',
                    color: Color.fromRGBO(8, 142, 255, 1))
              ]),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SfLinearGauge(
              minimum: 0,
              maximum: 100,
              showLabels: true,
              showTicks: true,
              showAxisTrack: true,
              axisTrackStyle: LinearAxisTrackStyle(
                thickness: 15,

              ),
              animationDuration: 600,
              barPointers: [
                LinearBarPointer(
                  value: score.percentage,
                  color: gaugeToColor(score.gauge),
                  thickness: 15,
                ),
              ],

              markerPointers: [
                LinearShapePointer(
                  offset: 10,
                  value: score.percentage,
                ),
                LinearWidgetPointer(
                    offset: 25,
                    value: score.percentage,
                    position: LinearElementPosition.outside,
                    child: Text(score.percentage.toStringAsFixed(2) + "%",
                        style: TextStyle(fontWeight: FontWeight.bold))
                ),
              ],


            ),

          ],
        ),
      ],
    );


  }


}

class _ChartData {
  _ChartData(this.x, this.displayX, this.y, this.color);

  final String x;
  String displayX;
  final double y;
  final Color? color;
}