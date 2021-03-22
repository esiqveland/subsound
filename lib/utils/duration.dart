Duration getDuration(dynamic durationParam) {
  if (durationParam is String) {
    return Duration(seconds: int.parse(durationParam));
  }
  if (durationParam is int) {
    return Duration(seconds: durationParam);
  }

  return Duration(seconds: 0);
}

String formatDuration(Duration duration) {
  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  if (duration.inMicroseconds == 0) {
    return "0:00";
  }

  final hours = duration.inHours;
  var minutes = duration.inMinutes;
  if (minutes > 75) {
    minutes = minutes - (hours * 60);
    var seconds = duration.inSeconds - (minutes * 60);
    return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
  } else {
    var seconds = duration.inSeconds - (minutes * 60);
    return '$minutes:${twoDigits(seconds)}';
  }
}
