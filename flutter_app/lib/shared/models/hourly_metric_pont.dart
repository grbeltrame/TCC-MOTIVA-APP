class HourlyMetricPoint {
  final String hour; // ex.: '06h'
  final double value; // numérico!

  HourlyMetricPoint(this.hour, num v) : value = v.toDouble();
}
