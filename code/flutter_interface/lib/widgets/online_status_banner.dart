import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityStatusWidget extends StatefulWidget {
  const ConnectivityStatusWidget({super.key});

  @override
  State<ConnectivityStatusWidget> createState() => _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  bool _isOnline = true;
  late final Connectivity _connectivity;
  late final Stream<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();

    // Verifica status inicial
    _checkInitialStatus();

    // Novo tipo: Stream<List<ConnectivityResult>>
    _subscription = _connectivity.onConnectivityChanged;
    _subscription.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      setState(() {
        _isOnline = hasConnection;
      });
    });
  }

  Future<void> _checkInitialStatus() async {
    final results = await _connectivity.checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    setState(() {
      _isOnline = hasConnection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            _isOnline ? "Online" : "Offline",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
