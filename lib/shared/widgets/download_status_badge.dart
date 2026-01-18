import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/download/download_manager.dart';
import '../../core/models/song.dart';

class DownloadStatusBadge extends ConsumerWidget {
  final Song song;
  final Widget child;
  
  const DownloadStatusBadge({
    super.key,
    required this.song,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadManager = ref.watch(downloadManagerProvider);
    final downloadStatusAsync = FutureProvider((ref) async {
      return await downloadManager.getDownloadStatus(song.id);
    });
    
    return Consumer(
      builder: (context, ref, _) {
        final status = ref.watch(downloadStatusAsync);
        
        return status.when(
          data: (downloadStatus) {
            if (downloadStatus == DownloadStatus.completed) {
              return Stack(
                children: [
                  child,
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.download_done,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              );
            } else if (downloadStatus == DownloadStatus.downloading) {
              return Stack(
                children: [
                  child,
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
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
      },
    );
  }
}
