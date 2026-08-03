import '../api.dart';
import '../formatters.dart';
import 'dashboard_metrics.dart';

class DriveScore {
  const DriveScore({
    required this.score,
    required this.label,
    required this.factors,
  });

  final int score;
  final String label;
  final List<String> factors;
}

class EnergyExplanation {
  const EnergyExplanation({
    required this.title,
    required this.summary,
    required this.reasons,
    required this.severity,
  });

  final String title;
  final String summary;
  final List<String> reasons;
  final int severity;
}

DriveScore drivingScore(JsonMap drive) {
  var score = 100.0;
  final factors = <String>[];

  final achievement = rangeAchievement(drive);
  if (achievement == null) {
    score -= 8;
    factors.add('续航达成数据不足');
  } else if (achievement < 70) {
    score -= 22;
    factors.add('续航达成偏低 ${achievement.toStringAsFixed(1)}%');
  } else if (achievement < 85) {
    score -= 12;
    factors.add('续航达成一般 ${achievement.toStringAsFixed(1)}%');
  } else if (achievement < 95) {
    score -= 5;
    factors.add('续航达成略低 ${achievement.toStringAsFixed(1)}%');
  } else {
    factors.add('续航达成良好 ${achievement.toStringAsFixed(1)}%');
  }

  final maxSpeed = asDouble(drive['speed_max']);
  if (maxSpeed != null && maxSpeed >= 120) {
    score -= 10;
    factors.add('最高速度较高 ${maxSpeed.toStringAsFixed(0)} km/h');
  } else if (maxSpeed != null && maxSpeed >= 100) {
    score -= 4;
    factors.add('有高速片段 ${maxSpeed.toStringAsFixed(0)} km/h');
  }

  final avg = _averageSpeedValue(drive);
  if (avg != null && avg >= 55) {
    score -= 5;
    factors.add('均速偏高 ${avg.toStringAsFixed(0)} km/h');
  }

  final maxPower = asDouble(drive['power_max']);
  if (maxPower != null && maxPower >= 280) {
    score -= 8;
    factors.add('峰值功率较高 ${maxPower.toStringAsFixed(0)} kW');
  } else if (maxPower != null && maxPower >= 200) {
    score -= 4;
    factors.add('加速功率偏高 ${maxPower.toStringAsFixed(0)} kW');
  }

  final temp = asDouble(drive['outside_temp_avg']);
  if (temp != null && (temp <= 5 || temp >= 34)) {
    score -= 4;
    factors.add('外温不利 ${temp.toStringAsFixed(0)}℃');
  }

  final ascent = asDouble(drive['ascent']) ?? 0;
  final descent = asDouble(drive['descent']) ?? 0;
  if (ascent - descent >= 80) {
    score -= 3;
    factors.add('净爬升较多');
  }

  final finalScore = score.clamp(0, 100).round();
  return DriveScore(
    score: finalScore,
    label: _scoreLabel(finalScore),
    factors: factors.take(4).toList(growable: false),
  );
}

double? averageDrivingScore(List<JsonMap> drives) {
  if (drives.isEmpty) return null;
  final scores = drives.map((drive) => drivingScore(drive).score).toList();
  return scores.reduce((a, b) => a + b) / scores.length;
}

EnergyExplanation explainEnergy(JsonMap drive) {
  final achievement = rangeAchievement(drive);
  final reasons = <String>[];
  var severity = 0;

  if (achievement == null) {
    return const EnergyExplanation(
      title: '能耗数据不足',
      summary: '缺少表显续航变化或里程，暂时无法判断异常。',
      reasons: ['TeslaMate 本次行程没有完整续航数据'],
      severity: 0,
    );
  }

  if (achievement < 70) {
    severity = 2;
  } else if (achievement < 85) {
    severity = 1;
  }

  final avg = _averageSpeedValue(drive);
  final maxSpeed = asDouble(drive['speed_max']);
  final maxPower = asDouble(drive['power_max']);
  final temp = asDouble(drive['outside_temp_avg']);
  final ascent = asDouble(drive['ascent']) ?? 0;
  final descent = asDouble(drive['descent']) ?? 0;
  final distance = asDouble(drive['distance']);
  final loss = ratedRangeLoss(drive);

  if (maxSpeed != null && maxSpeed >= 100) {
    reasons.add('最高速度 ${maxSpeed.toStringAsFixed(0)} km/h，风阻会明显抬高能耗');
  }
  if (avg != null && avg >= 45) {
    reasons.add('均速 ${avg.toStringAsFixed(0)} km/h，持续较快行驶会拉低续航达成');
  }
  if (maxPower != null && maxPower >= 200) {
    reasons.add('峰值功率 ${maxPower.toStringAsFixed(0)} kW，存在较强加速片段');
  }
  if (temp != null && temp <= 5) {
    reasons.add('外温 ${temp.toStringAsFixed(0)}℃，低温会增加电池和空调消耗');
  } else if (temp != null && temp >= 34) {
    reasons.add('外温 ${temp.toStringAsFixed(0)}℃，高温空调负载可能偏高');
  }
  if (ascent - descent >= 80) {
    reasons.add('净爬升 ${(ascent - descent).toStringAsFixed(0)} m，上坡路段偏多');
  }
  if (distance != null && loss != null) {
    reasons.add('实际 ${kmCompact(distance)} / 表显消耗 ${kmCompact(loss)}');
  }

  if (severity == 0 && reasons.isEmpty) {
    reasons.add('速度、温度、爬升和续航消耗都没有明显异常');
  }

  final title = switch (severity) {
    2 => '能耗明显偏高',
    1 => '能耗略高',
    _ => '能耗正常',
  };
  final summary = switch (severity) {
    2 => '续航达成 ${achievement.toStringAsFixed(1)}%，这次行程消耗偏重。',
    1 => '续航达成 ${achievement.toStringAsFixed(1)}%，有轻微偏高迹象。',
    _ => '续航达成 ${achievement.toStringAsFixed(1)}%，整体表现稳定。',
  };

  return EnergyExplanation(
    title: title,
    summary: summary,
    reasons: reasons.take(4).toList(growable: false),
    severity: severity,
  );
}

String shortEnergyExplanation(JsonMap drive) {
  final explanation = explainEnergy(drive);
  if (explanation.severity == 0) return explanation.title;
  return '${explanation.title} · ${explanation.reasons.first}';
}

double? _averageSpeedValue(JsonMap drive) {
  final distance = asDouble(drive['distance']);
  final duration = asInt(drive['duration_min']);
  if (distance == null || duration == null || duration <= 0) return null;
  return distance / (duration / 60);
}

String _scoreLabel(int score) {
  if (score >= 90) return '优秀';
  if (score >= 80) return '良好';
  if (score >= 70) return '稳定';
  if (score >= 60) return '偏耗';
  return '需关注';
}
