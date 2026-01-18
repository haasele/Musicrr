import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/network_status.dart';

class OfflineIndicator extends ConsumerWidget {
  final Widget child;
  
  const OfflineIndicator({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatusAsync = ref.watch(networkStatusProvider);
    
    return networkStatusAsync.when(
      data: (status) {
        if (status == NetworkStatus.disconnected) {
          return Stack(
            children: [
              child,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Offline Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return child;
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatusAsync = ref.watch(networkStatusProvider);
    
    return networkStatusAsync.when(
      data: (status) {
        if (status == NetworkStatus.disconnected) {
          return Container(
            color: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'You are offline. Some features may be unavailable.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
