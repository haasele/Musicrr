import '../layout/layout_engine.dart';
import 'cover_art_component.dart';
import 'progress_slider_component.dart';
import 'control_buttons_component.dart';
import 'track_info_component.dart';
import 'visualizer_component.dart';
import 'lyrics_component.dart';

/// Initialize and register all Now Playing components
void initializeComponents() {
  final coverArt = CoverArtComponent();
  final progressSlider = ProgressSliderComponent();
  final controlButtons = ControlButtonsComponent();
  final trackInfo = TrackInfoComponent();
  final visualizer = VisualizerComponent();
  final lyrics = LyricsComponent();
  
  ComponentRegistry.register(coverArt.id, (context, config, state) {
    return coverArt.build(context, config, state);
  });
  
  ComponentRegistry.register(progressSlider.id, (context, config, state) {
    return progressSlider.build(context, config, state);
  });
  
  ComponentRegistry.register(controlButtons.id, (context, config, state) {
    return controlButtons.build(context, config, state);
  });
  
  ComponentRegistry.register(trackInfo.id, (context, config, state) {
    return trackInfo.build(context, config, state);
  });
  
  ComponentRegistry.register(visualizer.id, (context, config, state) {
    return visualizer.build(context, config, state);
  });
  
  ComponentRegistry.register(lyrics.id, (context, config, state) {
    return lyrics.build(context, config, state);
  });
}
