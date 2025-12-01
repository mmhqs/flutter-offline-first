import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();

  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Retorna true se houver internet disponível
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
           result.contains(ConnectivityResult.wifi);
  }

  /// Stream para mudanças de conectividade
  Stream<bool> get onStatusChange async* {
    await for (final status in _connectivity.onConnectivityChanged) {
      yield status.contains(ConnectivityResult.wifi) ||
            status.contains(ConnectivityResult.mobile);
    }
  }
}
