import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  // Stream controller to broadcast offline status changes
  final _offlineStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onOfflineChanged => _offlineStatusController.stream;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> initialize() async {
    // Initial check
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // If ANY result is something other than .none, we are technically "connected" (to a network).
    // However, usually we check if all are .none implies offline.
    // results is a List. If it contains .none only, or is empty?
    // Current connectivity_plus returns a list.
    // If the list contains at least one mobile, wifi, ethernet, vpn, bluetooth etc, we are online.
    // If the list contains purely ConnectivityResult.none, we are offline.

    bool isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    bool newOfflineStatus = !isConnected;

    if (_isOffline != newOfflineStatus) {
      _isOffline = newOfflineStatus;
      _offlineStatusController.add(_isOffline);
      print("Connectivity Changed: Offline = $_isOffline");
    }
  }

  void dispose() {
    _subscription?.cancel();
    _offlineStatusController.close();
  }
}
