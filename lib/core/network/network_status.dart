import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus {
  connected,
  disconnected,
  unknown,
}

class NetworkStatusService {
  final Connectivity _connectivity = Connectivity();
  StreamController<NetworkStatus>? _statusController;
  StreamSubscription<ConnectivityResult>? _subscription;
  
  NetworkStatusService() {
    _statusController = StreamController<NetworkStatus>.broadcast();
    _init();
  }
  
  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final status = _mapConnectivityResult(result);
        _statusController?.add(status);
      },
    );
    
    // Get initial status
    _connectivity.checkConnectivity().then((result) {
      final status = _mapConnectivityResult(result);
      _statusController?.add(status);
    });
  }
  
  NetworkStatus _mapConnectivityResult(ConnectivityResult result) {
    if (result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet) {
      return NetworkStatus.connected;
    } else if (result == ConnectivityResult.none) {
      return NetworkStatus.disconnected;
    }
    return NetworkStatus.unknown;
  }
  
  Stream<NetworkStatus> get statusStream => _statusController!.stream;
  
  Future<NetworkStatus> getCurrentStatus() async {
    final result = await _connectivity.checkConnectivity();
    return _mapConnectivityResult(result);
  }
  
  void dispose() {
    _subscription?.cancel();
    _statusController?.close();
  }
}

final networkStatusServiceProvider = Provider<NetworkStatusService>((ref) {
  final service = NetworkStatusService();
  ref.onDispose(() => service.dispose());
  return service;
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final service = ref.watch(networkStatusServiceProvider);
  return service.statusStream;
});
