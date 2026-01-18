package com.haasele.musicrr

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.haasele.musicrr.audio.ExoPlayerAudioEngine
import com.haasele.musicrr.platform_channels.AudioMethodChannel
import com.haasele.musicrr.platform_channels.AudioEventChannel
import com.haasele.musicrr.platform_channels.MetadataMethodChannel
import com.haasele.musicrr.platform_channels.RemoteControlMethodChannel

class MainActivity: FlutterActivity() {
    private lateinit var audioEngine: ExoPlayerAudioEngine
    private lateinit var methodChannel: AudioMethodChannel
    private lateinit var eventChannel: AudioEventChannel
    private lateinit var metadataChannel: MetadataMethodChannel
    private lateinit var remoteControlChannel: RemoteControlMethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        audioEngine = ExoPlayerAudioEngine(this)
        
        methodChannel = AudioMethodChannel(flutterEngine, audioEngine)
        methodChannel.setup()
        
        eventChannel = AudioEventChannel(flutterEngine, audioEngine)
        eventChannel.setup()
        
        metadataChannel = MetadataMethodChannel(flutterEngine)
        
        remoteControlChannel = RemoteControlMethodChannel(this, flutterEngine)
    }

    override fun onDestroy() {
        super.onDestroy()
        audioEngine.release()
    }
}
