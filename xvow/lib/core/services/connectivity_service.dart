import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield initial.any((result) => result != ConnectivityResult.none);
  await for (final results in connectivity.onConnectivityChanged) {
    yield results.any((result) => result != ConnectivityResult.none);
  }
});
