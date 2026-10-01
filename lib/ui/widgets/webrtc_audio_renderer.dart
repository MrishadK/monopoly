import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/voice_stream_service.dart';

class WebrtcAudioRenderer extends ConsumerWidget {
  const WebrtcAudioRenderer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state so it rebuilds when peers join/leave
    ref.watch(voiceStreamServiceProvider);
    final notifier = ref.read(voiceStreamServiceProvider.notifier);
    final renderers = notifier.remoteRenderers;

    if (renderers.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 1,
      height: 1,
      child: Stack(
        children: renderers.values.map((renderer) {
          return SizedBox(
            width: 1,
            height: 1,
            child: RTCVideoView(renderer),
          );
        }).toList(),
      ),
    );
  }
}
