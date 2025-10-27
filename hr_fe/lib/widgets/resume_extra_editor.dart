import 'package:flutter/material.dart';

/// Editor for candidate resume extra info stored under profile.extra
/// Supported fields: position, dob, address, experiences[], education[]
class ResumeExtraEditor extends StatefulWidget {
  final Map<String, dynamic> initial;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool dense;
  const ResumeExtraEditor({super.key, required this.initial, required this.onChanged, this.dense = false});

  @override
  State<ResumeExtraEditor> createState() => _ResumeExtraEditorState();
}

class _ResumeExtraEditorState extends State<ResumeExtraEditor> {
  late TextEditingController _position;
  late TextEditingController _dob;
  late TextEditingController _address;
  List<Map<String, String>> _experiences = [];
  List<Map<String, String>> _education = [];

  @override
  void initState() {
    super.initState();
    _position = TextEditingController(text: (widget.initial['position'] ?? '').toString());
    _dob = TextEditingController(text: (widget.initial['dob'] ?? widget.initial['birthdate'] ?? '').toString());
    _address = TextEditingController(text: (widget.initial['address'] ?? '').toString());
    if (widget.initial['experiences'] is List) {
      _experiences = List<Map<String, String>>.from(
        List.from(widget.initial['experiences']).map((e) => {
              'from': (e['from'] ?? '').toString(),
              'to': (e['to'] ?? '').toString(),
              'company': (e['company'] ?? '').toString(),
              'role': (e['role'] ?? '').toString(),
              'description': (e['description'] ?? '').toString(),
            }),
      );
    }
    if (widget.initial['education'] is List) {
      _education = List<Map<String, String>>.from(
        List.from(widget.initial['education']).map((e) => {
              'from': (e['from'] ?? '').toString(),
              'to': (e['to'] ?? '').toString(),
              'school': (e['school'] ?? '').toString(),
              'major': (e['major'] ?? '').toString(),
            }),
      );
    }
    _emit();
  }

  @override
  void didUpdateWidget(covariant ResumeExtraEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent provides a different initial map (e.g., after async load),
    // refresh fields to reflect persisted values.
    if (!identical(oldWidget.initial, widget.initial)) {
      setState(() {
        _position.text = (widget.initial['position'] ?? '').toString();
        _dob.text = (widget.initial['dob'] ?? widget.initial['birthdate'] ?? '').toString();
        _address.text = (widget.initial['address'] ?? '').toString();
        _experiences = [];
        if (widget.initial['experiences'] is List) {
          _experiences = List<Map<String, String>>.from(
            List.from(widget.initial['experiences']).map((e) => {
                  'from': (e['from'] ?? '').toString(),
                  'to': (e['to'] ?? '').toString(),
                  'company': (e['company'] ?? '').toString(),
                  'role': (e['role'] ?? '').toString(),
                  'description': (e['description'] ?? '').toString(),
                }),
          );
        }
        _education = [];
        if (widget.initial['education'] is List) {
          _education = List<Map<String, String>>.from(
            List.from(widget.initial['education']).map((e) => {
                  'from': (e['from'] ?? '').toString(),
                  'to': (e['to'] ?? '').toString(),
                  'school': (e['school'] ?? '').toString(),
                  'major': (e['major'] ?? '').toString(),
                }),
          );
        }
      });
      _emit();
    }
  }

  @override
  void dispose() {
    _position.dispose();
    _dob.dispose();
    _address.dispose();
    super.dispose();
  }

  void _emit() {
    final map = <String, dynamic>{
      'position': _position.text.trim().isEmpty ? null : _position.text.trim(),
      'dob': _dob.text.trim().isEmpty ? null : _dob.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      'experiences': _experiences,
      'education': _education,
    };
    widget.onChanged(map);
  }

  DateTime? _tryParseDate(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    // dd/MM/yyyy
    final parts = t.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }
    // yyyy-MM-dd
    if (RegExp(r"^\d{4}-\d{2}-\d{2}$").hasMatch(t)) {
      final p = t.split('-');
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    }
    return null;
  }

  DateTime? _tryParseMonth(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    // MM/yyyy
    final parts = t.split('/');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final y = int.tryParse(parts[1]);
      if (m != null && y != null) return DateTime(y, m, 1);
    }
    return null;
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtMonth(DateTime d) => '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDob() async {
    final init = _tryParseDate(_dob.text) ?? DateTime(1995, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob.text = _fmtDate(picked));
      _emit();
    }
  }

  Future<void> _pickMonth(TextEditingController ctrl) async {
    final init = _tryParseMonth(ctrl.text) ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
    );
    if (picked != null) {
      setState(() => ctrl.text = _fmtMonth(picked));
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tăng khoảng cách khi không ở chế độ dense để dễ nhìn trên di động
    final spacing = widget.dense ? 8.0 : 12.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: _position, decoration: const InputDecoration(labelText: 'Chức danh (mong muốn)'), onChanged: (_) => _emit()),
      SizedBox(height: spacing),
      TextField(
        controller: _dob,
        readOnly: true,
        onTap: _pickDob,
        decoration: const InputDecoration(labelText: 'Ngày sinh', suffixIcon: Icon(Icons.calendar_today)),
      ),
      SizedBox(height: spacing),
      TextField(controller: _address, decoration: const InputDecoration(labelText: 'Địa chỉ'), onChanged: (_) => _emit()),
      SizedBox(height: spacing + 2),
      Text('Kinh nghiệm làm việc', style: Theme.of(context).textTheme.titleSmall),
  ..._experiences.asMap().entries.map((e) => _experienceItem(context, e.key)),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
            onPressed: () => setState(() {
                  _experiences.add({'from': '', 'to': '', 'company': '', 'role': '', 'description': ''});
                  _emit();
                }),
            icon: const Icon(Icons.add),
            label: const Text('Thêm kinh nghiệm')),
      ),
      SizedBox(height: spacing + 2),
      Text('Trình độ học vấn', style: Theme.of(context).textTheme.titleSmall),
      ..._education.asMap().entries.map((e) => _educationItem(context, e.key)),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
            onPressed: () => setState(() {
                  _education.add({'from': '', 'to': '', 'school': '', 'major': ''});
                  _emit();
                }),
            icon: const Icon(Icons.add),
            label: const Text('Thêm học vấn')),
      ),
    ]);
  }

  Widget _monthField({required String label, required String value, required ValueChanged<String> onPicked}) {
    final ctrl = TextEditingController(text: value);
    return TextField(
      controller: ctrl,
      readOnly: true,
      onTap: () async { await _pickMonth(ctrl); onPicked(ctrl.text); },
      decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_month)),
    );
  }

  Widget _experienceItem(BuildContext c, int i) {
    final item = _experiences[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _monthField(label: 'Từ (năm/tháng)', value: item['from'] ?? '', onPicked: (v){ _experiences[i]['from'] = v; _emit(); })),
          const SizedBox(width: 8),
          Expanded(child: _monthField(label: 'Đến (năm/tháng)', value: item['to'] ?? '', onPicked: (v){ _experiences[i]['to'] = v; _emit(); })),
          IconButton(onPressed: () { setState(() { _experiences.removeAt(i); _emit(); }); }, icon: const Icon(Icons.close))
        ]),
        Row(children: [
          Expanded(child: TextField(controller: TextEditingController(text: item['company']), decoration: const InputDecoration(labelText: 'Công ty'), onChanged: (v) { _experiences[i]['company'] = v; _emit(); })),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: TextEditingController(text: item['role']), decoration: const InputDecoration(labelText: 'Vị trí'), onChanged: (v) { _experiences[i]['role'] = v; _emit(); })),
        ]),
        TextField(controller: TextEditingController(text: item['description']), decoration: const InputDecoration(labelText: 'Mô tả'), onChanged: (v) { _experiences[i]['description'] = v; _emit(); }),
      ]),
    );
  }

  Widget _educationItem(BuildContext c, int i) {
    final item = _education[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _monthField(label: 'Từ (năm/tháng)', value: item['from'] ?? '', onPicked: (v){ _education[i]['from'] = v; _emit(); })),
          const SizedBox(width: 8),
          Expanded(child: _monthField(label: 'Đến (năm/tháng)', value: item['to'] ?? '', onPicked: (v){ _education[i]['to'] = v; _emit(); })),
          IconButton(onPressed: () { setState(() { _education.removeAt(i); _emit(); }); }, icon: const Icon(Icons.close))
        ]),
        Row(children: [
          Expanded(child: TextField(controller: TextEditingController(text: item['school']), decoration: const InputDecoration(labelText: 'Trường/Đơn vị'), onChanged: (v) { _education[i]['school'] = v; _emit(); })),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: TextEditingController(text: item['major']), decoration: const InputDecoration(labelText: 'Chuyên ngành/Chứng chỉ'), onChanged: (v) { _education[i]['major'] = v; _emit(); })),
        ]),
      ]),
    );
  }
}
