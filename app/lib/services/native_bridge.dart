import 'package:flutter/services.dart';

class NativeBridge {
  static const channel = MethodChannel('palm_ai');
  static const stream = EventChannel('palm_stream');

  Stream<dynamic> streamResults() {
    return stream.receiveBroadcastStream();
  }

  Future<void> startCamera() async {
    try {
      await channel.invokeMethod('startCamera');
    } catch (e) {
      print("Failed to start camera: '${e}'.");
    }
  }
}
