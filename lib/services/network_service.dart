import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._();
  factory NetworkService() => _instance;
  NetworkService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  void startMonitoring() {
    _connectivity.onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (connected != _isConnected) {
        _isConnected = connected;
        _controller.add(connected);
      }
    });
  }

  void dispose() {
    _controller.close();
  }
}
