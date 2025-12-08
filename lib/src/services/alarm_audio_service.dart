import 'package:just_audio/just_audio.dart';

import 'logging/app_logger.dart';

/// Service for playing alarm audio when timers expire.
///
/// This handles in-app audio playback (looping) when the timer
/// expired modal is displayed. For system notifications when the
/// app is in the background, see [NotificationService].
class AlarmAudioService {
  AlarmAudioService._();

  static final AlarmAudioService instance = AlarmAudioService._();

  final AudioPlayer _player = AudioPlayer();

  /// Cancellation flag to handle race condition between play and stop.
  /// Set to true when stop() is called, checked before play() is called.
  bool _cancelled = false;

  /// Start playing the alarm sound on loop.
  Future<void> playLooping() async {
    _cancelled = false;

    try {
      AppLogger.debug('AlarmAudioService: Starting looping playback');

      await _player.setAsset('assets/audio/alarm.mp3');
      if (_cancelled) {
        AppLogger.debug('AlarmAudioService: Cancelled during asset load');
        return;
      }

      await _player.setLoopMode(LoopMode.one);
      if (_cancelled) {
        AppLogger.debug('AlarmAudioService: Cancelled during loop mode set');
        return;
      }

      await _player.play();
      AppLogger.info('AlarmAudioService: Alarm audio started');
    } catch (e, stack) {
      AppLogger.error('AlarmAudioService: Failed to play alarm', e, stack);
      // Don't rethrow - audio failure shouldn't break the modal
    }
  }

  /// Stop the alarm sound.
  ///
  /// Safe to call even if not currently playing or still loading.
  Future<void> stop() async {
    _cancelled = true;

    try {
      AppLogger.debug('AlarmAudioService: Stopping playback');
      await _player.stop();
      AppLogger.info('AlarmAudioService: Alarm audio stopped');
    } catch (e, stack) {
      AppLogger.error('AlarmAudioService: Failed to stop alarm', e, stack);
    }
  }

  /// Whether alarm audio is currently playing.
  bool get isPlaying => _player.playing;

  /// Dispose of audio resources.
  ///
  /// Call this when the app is shutting down.
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
