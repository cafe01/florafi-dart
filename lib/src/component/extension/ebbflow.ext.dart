import '../ebbflow.g.dart';

extension EbbflowExtension on Ebbflow {
  bool get isConfigured => dayInterval != null && nightInterval != null;

  // timestamps as DateTime
  DateTime? _inflateTimestamp(int? timestamp) {
    return timestamp == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(1000 * timestamp, isUtc: true);
  }

  DateTime? get lastEmptyTime => _inflateTimestamp(lastEmpty);
  DateTime? get lastDrainTime => _inflateTimestamp(lastDrain);
  DateTime? get lastFloodTime => _inflateTimestamp(lastFlood);
  DateTime? get lastFullTime => _inflateTimestamp(lastFull);
  DateTime? get phaseTime {
    switch (phase) {
      case 1:
        return lastEmptyTime;
      case 2:
        return lastDrainTime;
      case 3:
        return lastFloodTime;
      case 4:
        return lastFullTime;
      default:
        return null;
    }
  }

  // elapsed
  Duration? _durationSinceTimestamp(int? timestamp) {
    if (timestamp == null || timestamp == 0) return null;
    final time =
        DateTime.fromMillisecondsSinceEpoch(1000 * timestamp, isUtc: true);
    return room.currentTime.difference(time);
  }

  Duration? get lastEmptyElapsed => _durationSinceTimestamp(lastEmpty);
  Duration? get lastDrainElapsed => _durationSinceTimestamp(lastDrain);
  Duration? get lastFloodElapsed => _durationSinceTimestamp(lastFlood);
  Duration? get lastFullElapsed => _durationSinceTimestamp(lastFull);

  Duration? get currentPhaseElapsed {
    switch (phase) {
      case 1:
        return lastEmptyElapsed;
      case 2:
        return lastDrainElapsed;
      case 3:
        return lastFloodElapsed;
      case 4:
        return lastFullElapsed;
      default:
        return null;
    }
  }

  // interval
  Duration? get dayIntervalDuration {
    final minutes = dayInterval;
    return minutes == null ? null : Duration(minutes: minutes);
  }

  set dayIntervalDuration(Duration? duration) {
    if (duration != null) dayInterval = duration.inMinutes;
  }

  Duration? get nightIntervalDuration {
    final minutes = nightInterval;
    return minutes == null ? null : Duration(minutes: minutes);
  }

  set nightIntervalDuration(Duration? duration) {
    if (duration != null) nightInterval = duration.inMinutes;
  }

  Duration? get intervalDuration {
    final isDaytime = room.isDaytime ?? true;
    return isDaytime ? dayIntervalDuration : nightIntervalDuration;
  }

  // durations
  Duration? get currentPhaseDuration {
    switch (phase) {
      case 1:
        return intervalDuration;
      case 4:
        return maxFullDuration;
      default:
        return null;
    }
  }

  Duration? get minEmptyDuration {
    final seconds = minEmptySeconds;
    return seconds == null ? null : Duration(seconds: seconds);
  }

  Duration? get minDrainDuration {
    final seconds = minDrainSeconds;
    return seconds == null ? null : Duration(seconds: seconds);
  }

  Duration? get maxDrainDuration {
    final minutes = maxDrainMinutes;
    return minutes == null ? null : Duration(minutes: minutes);
  }

  set maxDrainDuration(Duration? duration) {
    if (duration != null) maxDrainMinutes = duration.inMinutes;
  }

  Duration? get maxFloodDuration {
    final minutes = maxFloodMinutes;
    return minutes == null ? null : Duration(minutes: minutes);
  }

  set maxFloodDuration(Duration? duration) {
    if (duration != null) maxFloodMinutes = duration.inMinutes;
  }

  Duration? get minFullDuration {
    final seconds = minFullSeconds;
    return seconds == null ? null : Duration(seconds: seconds);
  }

  Duration? get maxFullDuration {
    final seconds = maxFullSeconds;
    return seconds == null ? null : Duration(seconds: seconds);
  }

  set maxFullDuration(Duration? duration) {
    if (duration != null) maxFullSeconds = duration.inSeconds;
  }

  Duration? get maxUnfullDuration {
    final minutes = maxUnfullMinutes;
    return minutes == null ? null : Duration(minutes: minutes);
  }

  set maxUnfullDuration(Duration? duration) {
    if (duration != null) maxUnfullMinutes = duration.inMinutes;
  }

  // progrss
  double? get currentPhaseProgress {
    final elapsed = currentPhaseElapsed;
    final duration = currentPhaseDuration;
    if (elapsed == null || duration == null) return null;
    return elapsed.inSeconds / duration.inSeconds;
  }
}
