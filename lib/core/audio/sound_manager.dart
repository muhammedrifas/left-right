import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pure-Dart procedural audio & tactile feedback controller.
/// Can also output raw WAV bytes (Uint8List) for `audioplayers` BytesSource!
class SoundManager {
  static final SoundManager instance = SoundManager._();
  SoundManager._();

  bool soundEnabled = true;

  void playTap({required bool isBlitz}) {
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
    if (isBlitz) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void playMirrorSwitch() {
    if (!soundEnabled) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  void playGameOver() {
    if (!soundEnabled) return;
    HapticFeedback.vibrate();
  }

  /// Generates a 16-bit mono PCM WAV file in memory for any frequency sweep.
  /// If you add `audioplayers`, pass `BytesSource(generateSynthWav(...))` to play!
  static Uint8List generateSynthWav({
    required double startFreqHz,
    required double endFreqHz,
    required double durationSeconds,
    double volume = 0.4,
  }) {
    const int sampleRate = 44100;
    final int numSamples = (sampleRate * durationSeconds).toInt();
    final int dataSize = numSamples * 2; // 16-bit = 2 bytes per sample
    final ByteData buffer = ByteData(44 + dataSize);

    // RIFF WAV Header
    void writeString(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        buffer.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little); // PCM chunk size
    buffer.setUint16(20, 1, Endian.little);  // AudioFormat 1 = PCM
    buffer.setUint16(22, 1, Endian.little);  // NumChannels = 1 (Mono)
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    buffer.setUint16(32, 2, Endian.little);  // BlockAlign
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample
    writeString(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final double progress = i / numSamples;
      final double freq =
          startFreqHz + (endFreqHz - startFreqHz) * progress;
      final double envelope = (1.0 - progress); // Linear decay envelope
      phase += (2 * pi * freq) / sampleRate;

      // Square-sine hybrid wave for punchy arcade timbre
      final double rawWave = (sin(phase) + (sin(phase * 2) * 0.35)).clamp(-1.0, 1.0);
      final int sample = (rawWave * volume * envelope * 32767).toInt();
      buffer.setInt16(44 + (i * 2), sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}