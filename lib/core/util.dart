import 'package:flutter/widgets.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
double dH(BuildContext context) => MediaQuery.of(context).size.height;
double dW(BuildContext context) => MediaQuery.of(context).size.width;

//Better for text
cv.Mat prepareFrame(cv.Mat frame, num scale, [bool blur = false]) {
  var kernel = cv.Mat.ones(1, 1, cv.MatType.CV_8SC3);
  frame = cv.resize(frame, ((frame.width * scale).toInt(), (frame.height * scale).toInt()), interpolation: cv.INTER_CUBIC);
  frame = cv.dilate(frame, kernel, iterations: 2);
  frame = cv.erode(frame, kernel, iterations: 1);
  if (blur)  frame = cv.blur(frame, (5, 5));
  //frame = cv.blur(frame, (5, 5));
  //increase the contrast
  frame = cv.threshold(frame, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU).$2;
  //invert the colors
  frame = cv.bitwiseNOT(frame);
  return frame;
}

//Better for numbers
cv.Mat prepareFrame2(cv.Mat frame) {
  num scale = 2;
  var kernel = cv.Mat.ones(1,1, cv.MatType.CV_8SC3);
  frame = cv.resize(frame, ((frame.width * scale).toInt(), (frame.height * scale).toInt()), interpolation: cv.INTER_CUBIC);
  frame = cv.bitwiseNOT(frame);
 //frame = cv.dilate(frame, kernel, iterations: 2);
 // frame = cv.getStructuringElement(cv.MORPH_RECT, (3,3));
  frame = cv.morphologyEx(frame, cv.MORPH_CLOSE, kernel);
  frame = cv.threshold(frame, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU).$2;
 // frame = cv.erode(frame, kernel, iterations: 1);
  return frame;
}

hexStringToColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF" + hexColor;
  }
  return Color(int.parse(hexColor, radix: 16));
}

double colorDistance(Color c1, Color c2) {
  int r1 = c1.red;
  int g1 = c1.green;
  int b1 = c1.blue;

  int r2 = c2.red;
  int g2 = c2.green;
  int b2 = c2.blue;

  return ((r1 - r2) * (r1 - r2) + (g1 - g2) * (g1 - g2) + (b1 - b2) * (b1 - b2)).toDouble();
}

// Function to find the closest color
Color findClosestColor(List<Color> colors, Color target) {
  if (colors.isEmpty) {
    throw ArgumentError('The list must not be empty');
  }

  Color closestColor = colors[0];
  double minDistance = colorDistance(closestColor, target);

  for (Color color in colors) {
    double distance = colorDistance(color, target);
    if (distance < minDistance) {
      closestColor = color;
      minDistance = distance;
    }
  }

  return closestColor;
}