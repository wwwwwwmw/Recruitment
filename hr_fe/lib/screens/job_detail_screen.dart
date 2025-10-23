import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api.dart';
import '../services/auth_state.dart';
import '../utils/job_utils.dart';

class JobDetailScreen extends StatefulWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});
  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Map<String, dynamic>? job;
  bool loading = true;
  String? error;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _resume = TextEditingController();
  final _cover = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      job = await apiGet('/jobs/${widget.jobId}');
      final me = context.read<AuthState>().user;
      if (me != null) {
        _name.text = me['full_name']?.toString() ?? _name.text;
        _email.text = me['email']?.toString() ?? _email.text;
      }
      try {
        final apps = await apiGetList('/applications', params: {'mine': 'true', 'job_id': widget.jobId});
        if (apps.isNotEmpty) {
          final a = (apps.first as Map<String, dynamic>);
          _name.text = a['full_name']?.toString() ?? _name.text;
          _email.text = a['email']?.toString() ?? _email.text;
          _phone.text = a['phone']?.toString() ?? _phone.text;
          _resume.text = a['resume_url']?.toString() ?? _resume.text;
          _cover.text = a['cover_letter']?.toString() ?? _cover.text;
        }
      } catch (_) {/* ignore prefill errors */}
    } catch (e) {
      error = 'Không tải được công việc';
    }
    setState(() => loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _resume.dispose();
    _cover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => c.go('/')),
        title: Text(job != null ? job!['title']?.toString() ?? 'Chi tiết công việc' : 'Chi tiết công việc'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(job!['title']?.toString() ?? '', style: Theme.of(c).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(job!['description']?.toString() ?? ''),
                    if (job!['requirements'] != null) ...[
                      const SizedBox(height: 12),
                      Text('Yêu cầu', style: Theme.of(c).textTheme.titleMedium),
                      Text(requirementsText(job!), style: Theme.of(c).textTheme.bodyMedium),
                    ],
                    const Divider(height: 32),
                    if ((job!['status']?.toString() ?? 'open') == 'closed') ...[
                      Text('Công việc đã kết thúc, không thể nộp hồ sơ', style: TextStyle(color: Colors.red.shade700)),
                    ] else ...[
                      Text('Nộp hồ sơ trực tuyến', style: Theme.of(c).textTheme.titleMedium),
                      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Họ tên')),
                      TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                      TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Số điện thoại')),
                      TextField(controller: _resume, decoration: const InputDecoration(labelText: 'Link CV (Drive, v.v.)')),
                      TextField(controller: _cover, maxLines: 4, decoration: const InputDecoration(labelText: 'Thư ứng tuyển')),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: () async {
                            try {
                              final body = {
                                'job_id': widget.jobId,
                                'full_name': _name.text,
                                'email': _email.text,
                                'phone': _phone.text.isEmpty ? null : _phone.text,
                                'resume_url': _resume.text.isEmpty ? null : _resume.text,
                                'cover_letter': _cover.text.isEmpty ? null : _cover.text,
                              };
                              await apiPost('/applications', body);
                              if (context.mounted) ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Đã nộp hồ sơ')));
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Nộp hồ sơ thất bại')));
                              }
                            }
                          },
                          child: const Text('Nộp hồ sơ'))
                    ]
                  ]),
                ),
    );
  }
}
