// Stub for web when dart:io is not available
class File {
  File(String path);
  void writeAsStringSync(String s, {dynamic mode}) {}
}

enum FileMode { append, write }
