import 'dart:io';

class ServerConstant {
  static String serverURL =
      Platform.isAndroid ? 'http://192.168.1.8:8000' : 'http://192.168.1.8:8000';
}
