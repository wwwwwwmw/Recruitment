import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api.dart';
import '../services/auth_state.dart';
import '../utils/job_utils.dart';
import '../widgets/app_picker.dart';

class EvaluationsScreen extends StatefulWidget {
  const EvaluationsScreen({super.key});
  @override
  State<EvaluationsScreen> createState() => _EvaluationsScreenState();
}

class _EvaluationsScreenState extends State<EvaluationsScreen> {
  int _tick = 0;
  int? _selectedJobId;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _job;
  int _minPercent = 0;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final role = context.read<AuthState>().role;
    final params = role == 'admin' ? <String, dynamic>{} : {'mine': 'true'};
    final list = await apiGetList('/jobs', params: params);
    // Convert defensively to Map<String, dynamic> to avoid LinkedMap<dynamic,dynamic> cast issues on web
    setState(() => _jobs = list
        .whereType<dynamic>()
        .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
        .toList());
  }

  Future<void> _runScreening() async {
    if (_selectedJobId == null) return;
    final data = await apiGet('/evaluations/screening', params: {'job_id': _selectedJobId});
    setState(() {
      final rawJob = data['job'];
      _job = rawJob is Map ? Map<String, dynamic>.from(rawJob) : null;
      final rawResults = data['results'];
      _results = rawResults is List
          ? rawResults.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList()
          : <Map<String, dynamic>>[];
      _tick++;
    });
  }

  int _calcPercent(Map<String, dynamic> r) {
    final p = r['percent'];
    if (p is num) return p.toInt();
    final reqDyn = _job?['requirements']?['scores'];
    final Map<String, dynamic> req = (reqDyn is Map) ? Map<String, dynamic>.from(reqDyn) : <String, dynamic>{};
    if (req.isEmpty) return 0;
    final scoresDyn = r['scores'];
    final Map<String, dynamic> scores = (scoresDyn is Map) ? Map<String, dynamic>.from(scoresDyn) : <String, dynamic>{};
    double sum = 0;
    int count = 0;
    req.forEach((key, cfg) {
      final min = (cfg is Map && cfg['min'] is num) ? (cfg['min'] as num).toDouble() : null;
      if (min == null || min <= 0) return;
      final v = (scores[key] is num) ? (scores[key] as num).toDouble() : double.tryParse('${scores[key] ?? ''}') ?? 0.0;
      final ratio = (v <= 0) ? 0.0 : (v / min);
      sum += ratio;
      count += 1;
    });
    if (count == 0) return 0;
    return ((sum / count) * 100).round();
  }

  Future<void> _sendOfferFromResult(BuildContext c, Map<String, dynamic> r) async {
    Map<String, dynamic>? app;
    try {
      final list = await apiGetList('/applications', params: {
        if (_selectedJobId != null) 'job_id': _selectedJobId,
        'q': (r['email'] ?? '').toString(),
      });
      if (list.isNotEmpty) {
        final first = list.first;
        if (first is Map) app = Map<String, dynamic>.from(first);
      }
    } catch (_) {}
    if (app == null) {
      app = await showDialog<Map<String, dynamic>>(context: c, builder: (_) => const ApplicationPickerDialog());
      if (app == null) return;
    }
    final defaultHtml = 'Xin chào ${app['full_name']},<br/>Thông báo từ bộ phận tuyển dụng...';
    DateTime? startDate;
    final posCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final contentCtrl = TextEditingController(text: defaultHtml);
    String? error;
    await showDialog(
        context: c,
        builder: (_) => StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                title: Text('Gửi thông báo cho ${app!['full_name']}'),
                content: SingleChildScrollView(
                    child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final d = await showDatePicker(context: context, initialDate: startDate ?? now, firstDate: DateTime(now.year - 3), lastDate: DateTime(now.year + 3));
                        if (d != null) setState(() => startDate = d);
                      },
                      icon: const Icon(Icons.event),
                      label: Text(startDate == null
                          ? 'Chọn ngày bắt đầu'
                          : '${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'),
                    ))
                  ]),
                  TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Vị trí')),
                  TextField(controller: salaryCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Lương')),
                  TextField(controller: contentCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Nội dung thông báo (HTML)')),
                  if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red)))
                ])),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          final body = {
                            'application_id': app!['id'],
                            'start_date': startDate == null
                                ? '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
                                : '${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}',
                            'position': posCtrl.text.isNotEmpty ? posCtrl.text : null,
                            'salary': salaryCtrl.text.isNotEmpty ? double.tryParse(salaryCtrl.text) : null,
                            'content': contentCtrl.text.isNotEmpty ? contentCtrl.text : null,
                          };
                          await apiPost('/offers', body);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setState(() => error = 'Gửi thư thất bại');
                        }
                      },
                      child: const Text('Gửi'))
                ],
              );
            }));
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => c.go('/')),
        title: const Text('Sàng lọc & Đánh giá'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _runScreening)],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 420;
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int?>(
                    isExpanded: true,
                    value: _selectedJobId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Chọn công việc')),
                      ..._jobs.map((j) => DropdownMenuItem<int?>(value: j['id'] as int, child: Text(j['title']?.toString() ?? '')))
                    ],
                    onChanged: (v) => setState(() => _selectedJobId = v),
                    decoration: const InputDecoration(labelText: 'Công việc'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _minPercent,
                    decoration: const InputDecoration(labelText: 'Tối thiểu %'),
                    items: const [0, 50, 60, 70, 80, 90, 100].map((p) => DropdownMenuItem<int>(value: p, child: Text('≥ $p%'))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _minPercent = v); },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _runScreening, child: const Text('Lọc tự động')),
                ],
              );
            }
            return Row(children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  value: _selectedJobId,
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Chọn công việc')),
                    ..._jobs.map((j) => DropdownMenuItem<int?>(value: j['id'] as int, child: Text(j['title']?.toString() ?? '')))
                  ],
                  onChanged: (v) => setState(() => _selectedJobId = v),
                  decoration: const InputDecoration(labelText: 'Công việc'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<int>(
                  value: _minPercent,
                  decoration: const InputDecoration(labelText: 'Tối thiểu %'),
                  items: const [0, 50, 60, 70, 80, 90, 100].map((p) => DropdownMenuItem<int>(value: p, child: Text('≥ $p%'))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _minPercent = v); },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _runScreening, child: const Text('Lọc tự động'))
            ]);
          }),
        ),
        if (_job != null)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(alignment: Alignment.centerLeft, child: Text('Yêu cầu: ' + requirementsText(_job!), style: Theme.of(c).textTheme.bodySmall))),
        Expanded(
            child: ListView.separated(
          key: ValueKey(_tick),
          itemCount: _results.where((r) => _calcPercent(r) >= _minPercent).length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final visible = _results.where((r) => _calcPercent(r) >= _minPercent).toList();
            final r = visible[i];
            final pc = _calcPercent(r);
            return ListTile(
              leading: CircleAvatar(child: Text('$pc%')),
              title: Text(r['full_name']?.toString() ?? ''),
              subtitle: Text('${r['email'] ?? ''} • ${r['status'] ?? ''}'),
              trailing: IconButton(icon: const Icon(Icons.mail_outline), tooltip: 'Gửi thông báo', onPressed: () => _sendOfferFromResult(c, r)),
              onTap: () {
                final id = r['application_id'];
                if (id is int) {
                  final rawScores = r['scores'];
                  final scores = rawScores is Map ? Map<String, dynamic>.from(rawScores) : <String, dynamic>{};
                  c.push('/applications/$id', extra: {'scores': scores, 'email': r['email'], 'from': '/evaluations'});
                }
              },
            );
          },
        ))
      ]),
    );
  }
}
