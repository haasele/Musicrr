package com.haasele.musicrr.platform_channels

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class AudioEventChannel(
    private val flutterEngine: FlutterEngine,
    private val audioEngine: AudioEventSource
) {
    private val channel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.haasele.musicrr/audio_events")

    fun setup() {
        channel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                audioEngine.setEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                audioEngine.setEventSink(null)
            }
        })
    }

    interface AudioEventSource {
        fun setEventSink(eventSink: EventChannel.EventSink?)
    }
}
