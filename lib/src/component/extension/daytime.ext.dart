import '../daytime.g.dart';
import 'datetime.ext.dart';

extension DayTimeExtension on Daytime {
  bool get isConfigured => startHour != null && duration != null;

  Duration? get dayDuration =>
      duration == null ? null : Duration(minutes: duration!);

  Duration? get nightDuration => dayDuration == null
      ? null
      : Duration(seconds: Duration.secondsPerDay - dayDuration!.inSeconds);

  DateTime? get dayStart {
    final _startHour = startHour;
    final _isDaytime = isDaytime;
    if (_startHour == null || _isDaytime == null) return null;

    final now = room.currentTime;
    var time = now.startOfDay().add(Duration(hours: _startHour));

    if (_isDaytime && time.isAfter(now)) {
      time = time.subtract(const Duration(days: 1));
    }

    return time;
  }

  DateTime? get nightStart {
    final _dayStart = dayStart;
    final _dayDuration = dayDuration;
    final _isDaytime = isDaytime;
    if (_dayStart == null || _dayDuration == null || _isDaytime == null) {
      return null;
    }

    var time = _dayStart.startOfHour().add(_dayDuration);

    if (!_isDaytime && time.isAfter(room.currentTime)) {
      time = time.subtract(const Duration(days: 1));
    }

    return time;
  }

  Duration? get dayElapsed {
    final start = dayStart;
    return start == null ? null : room.currentTime.difference(start);
  }

  Duration? get nightElapsed {
    final start = nightStart;
    return start == null ? null : room.currentTime.difference(start);
  }

  Duration? get dayRemaining {
    final elapsed = dayElapsed;
    final duration = dayDuration;
    if (elapsed == null || duration == null) return null;
    return duration - elapsed;
  }

  Duration? get nightRemaining {
    final elapsed = nightElapsed;
    final duration = nightDuration;
    if (elapsed == null || duration == null) return null;
    return duration - elapsed;
  }

  double? get dayProgress {
    final elapsed = dayElapsed;
    final duration = dayDuration;
    return elapsed == null || duration == null
        ? null
        : elapsed.inSeconds / duration.inSeconds;
  }

  double? get nightProgress {
    final elapsed = nightElapsed;
    final duration = nightDuration;
    return elapsed == null || duration == null
        ? null
        : elapsed.inSeconds / duration.inSeconds;
  }

  Duration? get phaseDuration =>
      isDaytime == true ? dayDuration : nightDuration;
  DateTime? get phaseStart => isDaytime == true ? dayStart : nightStart;
  Duration? get phaseElapsed => isDaytime == true ? dayElapsed : nightElapsed;
  Duration? get phaseRemaining =>
      isDaytime == true ? dayRemaining : nightRemaining;
  double? get phaseProgress => isDaytime == true ? dayProgress : nightProgress;
}
