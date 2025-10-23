import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api.dart';
import '../services/auth_state.dart';

class AppPickerTile extends StatelessWidget {
  final String selectedLabel;
  final VoidCallback onPick;
  const AppPickerTile({super.key, required this.selectedLabel, required this.onPick});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(selectedLabel),
      trailing: const Icon(Icons.search),
      onTap: onPick,
    );
  }
}

class ApplicationPickerDialog extends StatefulWidget {
  const ApplicationPickerDialog({super.key});
  @override
  State<ApplicationPickerDialog> createState() => _ApplicationPickerDialogState();
}

class _ApplicationPickerDialogState extends State<ApplicationPickerDialog> {
  final _search = TextEditingController();
  int? _selectedJobId;
  List<Map<String, dynamic>> _jobs = [];
  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _future = _fetch();
  }

  Future<void> _loadJobs() async {
    final role = context.read<AuthState>().role;
    final params = role == 'admin' ? <String, dynamic>{} : {'mine': 'true'};
    final list = await apiGetList('/jobs', params: params);
    setState(() => _jobs = list.cast<Map<String, dynamic>>());
  }

  Map<String, dynamic> _params() {
    final role = context.read<AuthState>().role;
    final p = <String, dynamic>{};
    if (role != 'admin') p['mine'] = 'true';
    if (_selectedJobId != null) p['job_id'] = _selectedJobId;
    if (_search.text.isNotEmpty) p['q'] = _search.text;
    return p;
  }

  Future<List<dynamic>> _fetch() => apiGetList('/applications', params: _params());

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn ứng tuyển'),
      content: SizedBox(
          width: 520,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                  child: DropdownButtonFormField<int>(
                initialValue: _selectedJobId,
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('Tất cả công việc')),
                  ..._jobs.map((j) => DropdownMenuItem<int>(value: j['id'] as int, child: Text(j['title']?.toString() ?? '')))
                ],
                onChanged: (v) {
                  setState(() => _selectedJobId = v);
                  _future = _fetch();
                },
                decoration: const InputDecoration(labelText: 'Lọc theo công việc'),
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                controller: _search,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên/email'),
                onSubmitted: (_) {
                  setState(() => _future = _fetch());
                },
              ))
            ]),
            const SizedBox(height: 8),
            SizedBox(
                height: 360,
                width: double.infinity,
                child: FutureBuilder<List<dynamic>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                    final items = (snap.data ?? []).cast<Map<String, dynamic>>();
                    if (items.isEmpty) return const Center(child: Text('Không có ứng tuyển'));
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final a = items[i];
                        return ListTile(
                          title: Text('#${a['id']} • ${a['full_name']}'),
                          subtitle: Text('${a['email']} • Job #${a['job_id']}'),
                          onTap: () => Navigator.pop(context, a),
                        );
                      },
                    );
                  },
                )),
          ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
    );
  }
}
