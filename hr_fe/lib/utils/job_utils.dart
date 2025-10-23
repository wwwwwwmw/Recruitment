String requirementsText(Map<String, dynamic> job) {
  final scores = (job['requirements']?['scores'] ?? {}) as Map<String, dynamic>;
  if (scores.isEmpty) return 'Không có yêu cầu cụ thể';
  final parts = <String>[];
  scores.forEach((k, v) {
    final min = (v is Map && v['min'] != null) ? v['min'] : null;
    final imp = (v is Map && v['important'] == true);
    final label = k; // label mapping not available here
    if (min != null) parts.add('${imp ? '* ' : ''}$label ≥ $min');
  });
  return parts.join(' • ');
}
