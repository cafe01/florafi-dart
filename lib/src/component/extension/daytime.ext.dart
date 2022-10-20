import 'package:florafi/florafi.dart';

import 'datetime.ext.dart';

extension DayTimeExtension on Room {
  DateTime get currentTime => farm.getClock().now().toUtc();

  // Duration? get nightDuration => dayDuration == null
  //     ? null
  //     : Duration(seconds: Duration.secondsPerDay - dayDuration!.inSeconds);

  DateTime? get dayStartTime {
    final _dayStart = dayStart;
    final _isDaytime = isDaytime;
    if (_dayStart == null || _isDaytime == null) return null;

    final now = currentTime;

    var time = now.startOfDay().add(_dayStart);

    return (_isDaytime && time.isAfter(now))
        ? time.subtract(const Duration(days: 1))
        : time;
  }

  DateTime? get nightStartTime {
    final _dayStartTime = dayStartTime;
    final _dayDuration = dayDuration;
    final _isDaytime = isDaytime;
    if (_dayStartTime == null || _dayDuration == null || _isDaytime == null) {
      return null;
    }

    final now = currentTime;
    var time = _dayStartTime.startOfHour().add(_dayDuration);
    return (!_isDaytime && time.isAfter(now))
        ? time.subtract(const Duration(days: 1))
        : time;
  }

  Duration? get dayElapsed {
    final start = dayStartTime;
    final now = currentTime;
    return start == null ? null : now.difference(start);
  }

  Duration? get nightElapsed {
    final start = nightStartTime;
    final now = currentTime;
    return start == null ? null : now.difference(start);
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

  DateTime? get phaseStartTime =>
      isDaytime == true ? dayStartTime : nightStartTime;
  Duration? get phaseElapsed => isDaytime == true ? dayElapsed : nightElapsed;
  Duration? get phaseRemaining =>
      isDaytime == true ? dayRemaining : nightRemaining;
  double? get phaseProgress => isDaytime == true ? dayProgress : nightProgress;
}
