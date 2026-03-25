import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter/services.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isPlaying = false;
  Timer? _flashTimer;
  Timer? _vibrationTimer;
  bool _flashState = false;

  // WAV alarm tones
  static const Map<String, String> tones = {
    'siren':  'sounds/siren.wav',
    'beep':   'sounds/beep_alarm.wav',
    'scream': 'sounds/scream_alarm.wav',
    'horn':   'sounds/horn_alarm.wav',
  };

  // --- MAIN ALARM ---

  Future<void> startAlarm({
    required String tone,
    required bool vibration,
    required bool flashlight,
  }) async {
    if (_isPlaying) return;
    _isPlaying = true;

    await _startAudio(tone);
    if (vibration) _startVibration();
    if (flashlight) _startFlashlight();
  }

  Future<void> _startAudio(String tone) async {
    final assetPath = tones[tone] ?? tones['siren']!;
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      await _alarmPlayer.setVolume(1.0);
      await _alarmPlayer.play(AssetSource(assetPath));
    } catch (e) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void _startVibration() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;
    // Immediate first burst
    Vibration.vibrate(duration: 500, amplitude: 255);
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!_isPlaying) { t.cancel(); return; }
      Vibration.vibrate(duration: 500, amplitude: 255);
    });
  }

  void _startFlashlight() {
    _flashTimer = Timer.periodic(const Duration(milliseconds: 250), (t) async {
      if (!_isPlaying) {
        t.cancel();
        try { await TorchLight.disableTorch(); } catch (_) {}
        return;
      }
      _flashState = !_flashState;
      try {
        if (_flashState) {
          await TorchLight.enableTorch();
        } else {
          await TorchLight.disableTorch();
        }
      } catch (_) { t.cancel(); }
    });
  }

  Future<void> stopAlarm() async {
    if (!_isPlaying) return;
    _isPlaying = false;

    await _alarmPlayer.stop();

    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try { Vibration.cancel(); } catch (_) {}

    _flashTimer?.cancel();
    _flashTimer = null;
    try { await TorchLight.disableTorch(); } catch (_) {}
  }

  // --- SOUND EFFECTS ---

  /// Key tap on PIN numpad
  Future<void> playKeyTap() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.4);
      await _sfxPlayer.play(AssetSource('sounds/key_tap.wav'));
    } catch (_) {}
  }

  /// Correct PIN / alarm disarmed
  Future<void> playSuccess() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.8);
      await _sfxPlayer.play(AssetSource('sounds/success.wav'));
    } catch (_) {}
  }

  /// Wrong PIN entered
  Future<void> playError() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.9);
      await _sfxPlayer.play(AssetSource('sounds/error.wav'));
    } catch (_) {}
  }

  /// Countdown tick during arming
  Future<void> playTick() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.5);
      await _sfxPlayer.play(AssetSource('sounds/tick.wav'));
    } catch (_) {}
  }

  /// Short test beep from settings
  Future<void> playTestBeep() async {
    try {
      final p = AudioPlayer();
      await p.setVolume(0.8);
      await p.play(AssetSource('sounds/beep_alarm.wav'));
      await Future.delayed(const Duration(milliseconds: 600));
      await p.stop();
      p.dispose();
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  bool get isPlaying => _isPlaying;

  void dispose() {
    stopAlarm();
    _alarmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
