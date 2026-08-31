import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _connectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

bool _isOffline(List<ConnectivityResult> results) =>
    results.isEmpty || results.every((r) => r == ConnectivityResult.none);

/// Wraps [child] and shows a persistent [MaterialBanner] when the device
/// loses network connectivity. The banner auto-dismisses on reconnection.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      _connectivityProvider,
      (previous, next) {
        final messenger = ScaffoldMessenger.of(context);
        final wasOffline = previous?.valueOrNull != null &&
            _isOffline(previous!.valueOrNull!);
        final isNowOffline =
            next.valueOrNull != null && _isOffline(next.valueOrNull!);

        if (!wasOffline && isNowOffline) {
          messenger.showMaterialBanner(
            const MaterialBanner(
              content: Text('No internet connection'),
              leading: Icon(Icons.wifi_off),
              actions: [SizedBox.shrink()],
            ),
          );
        } else if (wasOffline && !isNowOffline) {
          messenger.hideCurrentMaterialBanner();
        }
      },
    );

    return child;
  }
}
