import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/criteria.dart';
import '../services/api.dart';
import '../widgets/resume_extra_editor.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});
  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  List<CriteriaDef> _criteria = const [];
  final Map<String, TextEditingController> _ctrl = {};
  final _extra = TextEditingController();
  bool _busy = false;
  String? _error;
  List<Map<String, String>> _certs = [];
  Map<String, dynamic> _extraMap = {};

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    _extra.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final me = await apiGet('/profiles/me');
      final crit = await fetchCriteria();
      setState(() => _criteria = crit);
      for (final c in crit) {
        _ctrl[c.key] = TextEditingController();
      }
      final scores = (me['scores'] ?? {}) as Map<String, dynamic>;
      for (final c in crit) {
        final v = scores[c.key];
        if (v != null) _ctrl[c.key]!.text = v.toString();
      }
  final extra = (me['extra'] ?? {});
  _extra.text = (extra['notes']?.toString() ?? '');
  _extraMap = Map<String, dynamic>.from(extra);
      final certs = (me['extra'] ?? {})['certificates'];
      if (certs is List) {
        _certs = certs
            .map((e) => {
                  'type': (e['type'] ?? '').toString(),
                  'name': (e['name'] ?? '').toString(),
                  'url': (e['url'] ?? '').toString(),
                })
            .toList();
      }
    } catch (_) {/* ignore */}
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final router = GoRouter.of(c);
                if (router.canPop()) {
                  router.pop();
                } else {
                  c.go('/');
                }
              }),
          title: const Text('Hồ sơ của tôi'),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          ..._criteria.map((cd) {
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: _ctrl[cd.key],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: cd.label),
                ));
          }),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Text('Thông tin hồ sơ', style: Theme.of(c).textTheme.titleMedium)),
          const SizedBox(height: 6),
          ResumeExtraEditor(
            initial: _extraMap,
            onChanged: (m) => _extraMap = m,
          ),
          TextField(controller: _extra, maxLines: 4, decoration: const InputDecoration(labelText: 'Thông tin thêm (tuỳ chọn)')),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Text('Chứng chỉ & Minh chứng', style: Theme.of(c).textTheme.titleSmall)),
          ..._certs.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            return Row(children: [
              SizedBox(width: 120, child: TextField(controller: TextEditingController(text: item['type']), decoration: const InputDecoration(hintText: 'Loại (IELTS, ...)'), onChanged: (v) => _certs[i]['type'] = v)),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: TextEditingController(text: item['name']), decoration: const InputDecoration(hintText: 'Tên chứng chỉ'), onChanged: (v) => _certs[i]['name'] = v)),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: TextEditingController(text: item['url']), decoration: const InputDecoration(hintText: 'Liên kết minh chứng'), onChanged: (v) => _certs[i]['url'] = v)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _certs.removeAt(i)))
            ]);
          }),
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => _certs.add({'type': '', 'name': '', 'url': ''})), icon: const Icon(Icons.add), label: const Text('Thêm chứng chỉ'))),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() {
                        _busy = true;
                        _error = null;
                      });
                      try {
                        final scores = <String, double>{};
                        for (final cd in _criteria) {
                          final t = (_ctrl[cd.key]?.text ?? '').trim();
                          if (t.isNotEmpty) {
                            final v = double.tryParse(t);
                            if (v != null) scores[cd.key] = v;
                          }
                        }
                        final extra = Map<String, dynamic>.from(_extraMap);
                        extra['notes'] = _extra.text.trim().isEmpty ? null : _extra.text.trim();
                        extra['certificates'] = _certs;
                        final body = {
                          'scores': scores,
                          'extra': extra,
                        };
                        await apiPut('/profiles/me', body);
                        if (mounted) ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
                      } catch (e) {
                        setState(() => _error = 'Lưu thất bại');
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: const Text('Lưu hồ sơ')),
        ]),
      ),
    );
  }
}
