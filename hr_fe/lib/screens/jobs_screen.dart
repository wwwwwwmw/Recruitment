import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/criteria.dart';
import '../services/api.dart';
import '../services/auth_state.dart';

class JobsScreen extends StatefulWidget {
  final bool mine;
  const JobsScreen({super.key, this.mine = false});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int _tick = 0;
  final _search = TextEditingController();

  Future<List<dynamic>> _load(BuildContext c) {
    final params = <String, dynamic>{};
    if (widget.mine) params['mine'] = 'true';
    if (_search.text.isNotEmpty) params['q'] = _search.text;
    return apiGetList('/jobs', params: params);
  }

  @override
  Widget build(BuildContext c) {
    final role = c.watch<AuthState>().role;
    final meId = c.watch<AuthState>().user?['id'];
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => c.go('/')), title: Text(widget.mine ? 'Việc làm của tôi' : 'Việc làm'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _tick++))]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tiêu đề/phòng ban/địa điểm'),
            onSubmitted: (_) => setState(() => _tick++),
          ),
        ),
        Expanded(
            child: FutureBuilder<List<dynamic>>(
          key: ValueKey(_tick),
          future: _load(c),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
            var items = (snap.data ?? []).cast<Map<String, dynamic>>();
            if (role == 'candidate' && !widget.mine) {
              items = items.where((j) => (j['status']?.toString() ?? '') != 'closed').toList();
            }
            String _viJobStatus(String? s){
              switch((s??'').toLowerCase()){
                case 'open': return 'đang tuyển';
                case 'closed': return 'đã kết thúc';
                default: return s??'';
              }
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final j = items[i];
                return ListTile(
                  title: Text(j['title']?.toString() ?? 'Chưa đặt tiêu đề'),
                  subtitle: Text('${j['department'] ?? ''}${(j['status'] != null) ? ' • Trạng thái: ${_viJobStatus(j['status']?.toString())}' : ''}'),
                  onTap: () => role == 'candidate' ? c.go('/jobs/${j['id']}') : null,
                  trailing: (role == 'admin' || role == 'recruiter')
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (role == 'admin' || (role == 'recruiter' && j['posted_by'] == meId))
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _editJobDialog(c, j)),
                            if ((role == 'admin' || (role == 'recruiter' && j['posted_by'] == meId)) && (j['status']?.toString() != 'closed'))
                              IconButton(
                                  icon: const Icon(Icons.flag_outlined),
                                  tooltip: 'Kết thúc tuyển dụng',
                                  onPressed: () async {
                                    try {
                                      await apiPost('/jobs/${j['id']}/close', {});
                                      if (mounted) setState(() => _tick++);
                                    } catch (_) {}
                                  }),
                            if (role == 'admin' || (role == 'recruiter' && j['posted_by'] == meId))
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  try {
                                    await apiDelete('/jobs/${j['id']}');
                                    setState(() => _tick++);
                                  } catch (_) {}
                                },
                              ),
                          ],
                        )
                      : null,
                );
              },
            );
          },
        ))
      ]),
      floatingActionButton: (role == 'admin' || role == 'recruiter')
          ? FloatingActionButton(
              onPressed: () async {
                final changed = await _createJobDialog(c);
                if (changed == true && mounted) setState(() => _tick++);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<bool?> _createJobDialog(BuildContext c) async {
    final title = TextEditingController();
    final dept = TextEditingController();
    final loc = TextEditingController();
    final desc = TextEditingController();
    String? error;
    final criteria = await fetchCriteria();
    final Map<String, Map<String, dynamic>> reqs = {for (final cd in criteria) cd.key: {'important': false, 'min': null}};
    bool changed = false;
    await showDialog(
        context: c,
        builder: (_) => StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                title: const Text('Đăng tin tuyển dụng'),
                content: SingleChildScrollView(
                    child: Column(children: [
                  TextField(controller: title, decoration: const InputDecoration(labelText: 'Tiêu đề')),
                  TextField(controller: dept, decoration: const InputDecoration(labelText: 'Phòng ban')),
                  TextField(controller: loc, decoration: const InputDecoration(labelText: 'Địa điểm')),
                  TextField(controller: desc, maxLines: 4, decoration: const InputDecoration(labelText: 'Mô tả công việc')),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: Text('Yêu cầu điểm', style: Theme.of(context).textTheme.titleSmall)),
                  const SizedBox(height: 4),
                  ...criteria.map((cd) {
                    final cfg = reqs[cd.key]!;
                    return Row(children: [
                      Expanded(child: Text(cd.label)),
                      Checkbox(value: (cfg['important'] as bool), onChanged: (v) => setState(() => cfg['important'] = v == true)),
                      SizedBox(
                          width: 80,
                          child: TextField(
                            decoration: const InputDecoration(hintText: 'Tối thiểu'),
                            keyboardType: TextInputType.number,
                            onChanged: (t) {
                              cfg['min'] = (t.trim().isEmpty ? null : double.tryParse(t));
                            },
                          )),
                    ]);
                  }),
                  if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red)))
                ])),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          final scores = <String, dynamic>{};
                          reqs.forEach((k, v) {
                            if (v['min'] != null) scores[k] = {'min': v['min'], 'important': v['important'] == true};
                          });
                          final requirements = scores.isEmpty ? null : {'scores': scores};
                          await apiPost('/jobs', {
                            'title': title.text,
                            'description': desc.text,
                            'department': dept.text.isEmpty ? null : dept.text,
                            'location': loc.text.isEmpty ? null : loc.text,
                            'requirements': requirements
                          });
                          changed = true;
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setState(() => error = 'Lưu thất bại');
                        }
                      },
                      child: const Text('Lưu'))
                ],
              );
            }));
    return changed;
  }

  Future<void> _editJobDialog(BuildContext c, Map<String, dynamic> job) async {
    final title = TextEditingController(text: job['title']?.toString() ?? '');
    final dept = TextEditingController(text: job['department']?.toString() ?? '');
    final loc = TextEditingController(text: job['location']?.toString() ?? '');
    final desc = TextEditingController(text: job['description']?.toString() ?? '');
    String? error;
    final criteria = await fetchCriteria();
    final existing = (job['requirements']?['scores'] ?? {}) as Map<String, dynamic>;
    final Map<String, Map<String, dynamic>> reqs = {
      for (final cd in criteria) cd.key: {'important': (existing[cd.key]?['important'] ?? false) == true, 'min': (existing[cd.key]?['min'])}
    };
    bool changed = false;
    await showDialog(
        context: c,
        builder: (_) => StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                title: const Text('Chỉnh sửa việc làm'),
                content: SingleChildScrollView(
                    child: Column(children: [
                  TextField(controller: title, decoration: const InputDecoration(labelText: 'Tiêu đề')),
                  TextField(controller: dept, decoration: const InputDecoration(labelText: 'Phòng ban')),
                  TextField(controller: loc, decoration: const InputDecoration(labelText: 'Địa điểm')),
                  TextField(controller: desc, maxLines: 4, decoration: const InputDecoration(labelText: 'Mô tả công việc')),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: Text('Yêu cầu điểm', style: Theme.of(context).textTheme.titleSmall)),
                  const SizedBox(height: 4),
                  ...criteria.map((cd) {
                    final cfg = reqs[cd.key]!;
                    return Row(children: [
                      Expanded(child: Text(cd.label)),
                      Checkbox(value: (cfg['important'] as bool), onChanged: (v) => setState(() => cfg['important'] = v == true)),
                      SizedBox(
                          width: 80,
                          child: TextField(
                            controller: TextEditingController(text: (cfg['min']?.toString() ?? '')),
                            keyboardType: TextInputType.number,
                            onChanged: (t) {
                              cfg['min'] = (t.trim().isEmpty ? null : double.tryParse(t));
                            },
                          )),
                    ]);
                  }),
                  if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red)))
                ])),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          final scores = <String, dynamic>{};
                          reqs.forEach((k, v) {
                            if (v['min'] != null) scores[k] = {'min': v['min'], 'important': v['important'] == true};
                          });
                          final requirements = scores.isEmpty ? null : {'scores': scores};
                          await apiPut('/jobs/${job['id']}', {
                            'title': title.text,
                            'description': desc.text,
                            'department': dept.text.isEmpty ? null : dept.text,
                            'location': loc.text.isEmpty ? null : loc.text,
                            'requirements': requirements
                          });
                          changed = true;
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setState(() => error = 'Lưu thất bại');
                        }
                      },
                      child: const Text('Lưu'))
                ],
              );
            }));
    if (changed && mounted) setState(() => _tick++);
  }
}
