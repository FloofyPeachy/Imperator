import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:imperator_desktop/core/widgetsize.dart';
import 'package:imperator_desktop/model/model.dart';
import 'package:imperator_desktop/state.dart';
import 'package:media_kit/media_kit.dart';
import 'package:widget_size/widget_size.dart';
class Timeline extends StatefulWidget {
  final List<Section> sections;
  final Player player;
  const Timeline({Key? key, required this.sections, required this.player}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Timeline();
}

class _Timeline extends State<Timeline> {
  Player player = Player();
  var childSize = Size(50, 50);
  double zoomLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    final videoDuration = widget.player.state.duration;
    final double scaleFactor = (childSize.width / videoDuration.inSeconds) * zoomLevel;
    const int intervalSeconds = 5; // Display time text every 5 seconds

    List<Widget> timeTextWidgets = [];
    for (int i = 0; i <= videoDuration.inSeconds; i += intervalSeconds) {
      final double leftPosition = i * scaleFactor;
      final String timeText = Duration(seconds: i).toString().split('.').first.padLeft(8, '0');

      Widget timeWidget = Text(timeText, style: TextStyle(fontSize: 10));

      timeTextWidgets.add(timeWidget);
    }

    return WidgetSize(
      onChange: (size) {
        setState(() {
          childSize = size;
        });
      },
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) onPointerScroll(pointerSignal);
        },
        child: SizedBox(
          width: childSize.width,
          height: childSize.height,

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                //a slightly lighter color than the background
                color: Theme.of(context).colorScheme.background.withOpacity(0.4),
                width: double.maxFinite,
                child: SingleChildScrollView(

                  scrollDirection: Axis.horizontal,
                  child:  Stack(
                    children: [
                      /*CustomPaint(
                        painter: TimelineTextPainter(
                          scaleFactor: scaleFactor,
                          videoDuration: videoDuration,
                          textStyle: TextStyle(fontSize: 10),
                          intervalSeconds: intervalSeconds,
                        ),
                        size: Size(childSize.width, childSize.height),
                      ),*/
                      /*Container(
                        color: Colors.amber,
                        width: scaleFactor * videoDuration.inSeconds,
                        height: 15,
                      ),*/
                      ...List<Widget>.generate(widget.sections.length, (index) {
                        return SectionWidget(
                          section: widget.sections[index],
                          scaleFactor: scaleFactor,
                        );
                      }),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onPointerScroll(PointerScrollEvent pointerSignal) {
    if (pointerSignal.scrollDelta.dy > 0) {
      setState(() {
        zoomLevel += 0.1;
      });
    } else {
      setState(() {
        zoomLevel -= 0.1;
      });
    }
  }
}


class TimelineTextPainter extends CustomPainter {
  final double scaleFactor;
  final Duration videoDuration;
  final TextStyle textStyle;
  final int intervalSeconds;

  TimelineTextPainter({
    required this.scaleFactor,
    required this.videoDuration,
    required this.textStyle,
    this.intervalSeconds = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i <= videoDuration.inSeconds; i += intervalSeconds) {
      final double leftPosition = i * scaleFactor;
      final String timeText = Duration(seconds: i).toString().split('.').first.padLeft(8, '0');
      textPainter.text = TextSpan(
        text: timeText,
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPosition, size.height - textPainter.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class TimelineWithMarkers extends StatelessWidget {
  final Duration videoDuration;
  final double scaleFactor;
  final int intervalSeconds;

  const TimelineWithMarkers({
    Key? key,
    required this.videoDuration,
    required this.scaleFactor,
    this.intervalSeconds = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int totalMarkers = videoDuration.inSeconds ~/ intervalSeconds;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: totalMarkers,
      itemBuilder: (context, index) {
        final double leftMargin = index * scaleFactor * intervalSeconds;
        final String timeText = Duration(seconds: index * intervalSeconds)
            .toString()
            .split('.')
            .first
            .padLeft(8, '0');

        return Container(
          margin: EdgeInsets.only(left: leftMargin),
          child: Text(timeText, style: TextStyle(fontSize: 10)),
        );
      },
    );
  }
}

class TimelineLinePainter extends CustomPainter {
  final double scaleFactor;
  final Duration videoDuration;
  final int intervalSeconds;

  TimelineLinePainter({
    required this.scaleFactor,
    required this.videoDuration,
    this.intervalSeconds = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    for (int i = 0; i <= videoDuration.inSeconds; i += intervalSeconds) {
      final double leftPosition = i * scaleFactor;
      canvas.drawLine(Offset(leftPosition, 0), Offset(leftPosition, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SectionWidget extends StatelessWidget {
  final Section section;
  final double scaleFactor;

  const SectionWidget({
    Key? key,
    required this.section,
    required this.scaleFactor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double leftPosition = section.start * scaleFactor;
    final double width = (section.end - section.start) * scaleFactor;

    return Positioned(
      left: leftPosition,
      child: InkWell(
        onTap: () {
          currentSection.value = section;
        },
        splashColor: Colors.white,
        child: Ink(
          width: width,
          height: 15,
          color: Colors.purple,
        ),
      ),
    );
  }
}

