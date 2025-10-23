import '../services/api.dart';

class CriteriaDef {
  final String key;
  final String label;
  final double min;
  final double max;
  final double step;
  const CriteriaDef(this.key, this.label, {required this.min, required this.max, this.step = 1});
}

Future<List<CriteriaDef>> fetchCriteria() async {
  final list = await apiGetList('/criteria');
  if (list.isEmpty) return const [];
  return list
      .map((e) => CriteriaDef(
            (e['key'] ?? '').toString(),
            (e['label'] ?? '').toString(),
            min: (double.tryParse('${e['min']}') ?? 0),
            max: (double.tryParse('${e['max']}') ?? 100),
            step: (double.tryParse('${e['step']}') ?? 1),
          ))
      .cast<CriteriaDef>()
      .toList();
}
