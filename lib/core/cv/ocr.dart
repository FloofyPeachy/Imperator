import 'dart:io';

class TesseractCLI {
  static List<String> extractText(String imagePath) {
    ProcessResult result = Process.runSync('tesseract', [imagePath, "-", "-l", "jpn+eng"]);
    return result.stdout.toString().split("\n").where((item) => item.isNotEmpty).toList();
  }
  static String extractNumber(String imagePath) {
    ProcessResult result = Process.runSync('tesseract', [imagePath, "-", "--psm", "7"]);
    return result.stdout.toString();
  }
  static List<String> extractNumbers(String imagePath) {
    ProcessResult result = Process.runSync('tesseract', [imagePath, "-", "--psm", "4"]);
    return result.stdout.toString().split("\n").where((item) => item.isNotEmpty).toList();
  }
}