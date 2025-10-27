import 'package:flutter/material.dart';

import '../models/criteria.dart';

/// A printable-like resume view inspired by the provided sample.
///
/// Data contract:
/// - app: { full_name, email, phone }
/// - profile: { scores: {key: number}, extra: { notes, certificates[], dob, address, position, avatar_url, experiences[], education[] } }
/// - job: { title }
/// Missing fields are rendered gracefully as blanks.
class ResumeView extends StatelessWidget {
  final Map<String, dynamic>? app;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? job;
  final List<CriteriaDef> criteria;

  const ResumeView({super.key, required this.app, required this.profile, required this.job, required this.criteria});

  String _s(dynamic v) => (v == null) ? '' : v.toString();

  @override
  Widget build(BuildContext context) {
    final name = _s(app?['full_name'] ?? profile?['full_name']);
    final email = _s(app?['email'] ?? profile?['email']);
    final phone = _s(app?['phone'] ?? profile?['phone']);
    final jobTitle = _s(profile?['extra']?['position'] ?? job?['title']);
    final extra = (profile?['extra'] is Map) ? Map<String, dynamic>.from(profile!['extra']) : <String, dynamic>{};
    final dob = _s(extra['dob'] ?? extra['birthdate']);
    final address = _s(extra['address']);
    final experiences = (extra['experiences'] is List) ? List<Map<String, dynamic>>.from(extra['experiences']) : <Map<String, dynamic>>[];
    final education = (extra['education'] is List) ? List<Map<String, dynamic>>.from(extra['education']) : <Map<String, dynamic>>[];
    final notes = _s(extra['notes']);
    final certs = (extra['certificates'] is List) ? List<Map<String, dynamic>>.from(extra['certificates']) : <Map<String, dynamic>>[];

    final scoresDyn = profile?['scores'];
    final Map<String, dynamic> scores = (scoresDyn is Map) ? Map<String, dynamic>.from(scoresDyn) : {};

    // Build a map label->(score,max) sorted by label to act like Skills in sample
  final List<_CritScore> critMap = [];
  for (final c in criteria) {
      final v = scores[c.key];
      final d = (v is num) ? v.toDouble() : double.tryParse('$v');
      critMap.add(_CritScore(label: c.label, value: d, max: c.max));
    }
    critMap.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final left = _leftColumn(context, name: name, email: email, phone: phone, dob: dob, address: address, notes: notes, crits: critMap);
            final right = _rightColumn(context, name: name, jobTitle: jobTitle, experiences: experiences, education: education, certs: certs);
            if (isWide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 2, child: left),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: right),
              ]);
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 16), right]);
          },
        ),
      ),
    );
  }

  Widget _leftColumn(BuildContext context,
      {required String name,
      required String email,
      required String phone,
      required String dob,
      required String address,
      required String notes,
      required List<_CritScore> crits}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 32)),
        const SizedBox(width: 12),
        Expanded(child: Text(name.isEmpty ? 'Ứng viên' : name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 16),
      _infoRow(context, 'Ngày sinh', dob.isEmpty ? '—' : dob),
      _infoRow(context, 'Địa chỉ', address.isEmpty ? '—' : address),
      _infoRow(context, 'Email', email.isEmpty ? '—' : email),
      _infoRow(context, 'Số điện thoại', phone.isEmpty ? '—' : phone),
      const SizedBox(height: 16),
      Text('Tiêu chí đánh giá', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
  ...crits.map((c) => _critBar(context, c)),
      if (notes.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Ghi chú', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(notes),
      ]
    ]);
  }

  Widget _rightColumn(BuildContext context,
      {required String name,
      required String jobTitle,
      required List<Map<String, dynamic>> experiences,
      required List<Map<String, dynamic>> education,
      required List<Map<String, dynamic>> certs}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(jobTitle.isEmpty ? 'Ứng viên' : jobTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
      ),
      const SizedBox(height: 12),
      _sectionTitle(context, 'Kinh nghiệm làm việc'),
      if (experiences.isEmpty)
        _bullet(context, 'Chưa cập nhật')
      else
        ...experiences.map((e) {
          final period = _join([e['from'], e['to']], sep: ' - ');
          final company = (e['company'] ?? '').toString();
          final role = (e['role'] ?? '').toString();
          final desc = (e['description'] ?? '').toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.circle, size: 6),
                const SizedBox(width: 8),
                Expanded(child: Text(period.isEmpty ? company : '$period · $company', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              ]),
              if (role.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 14, top: 2), child: Text('Vị trí: $role')),
              if (desc.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 14, top: 2), child: Text(desc)),
            ]),
          );
        }),

      const SizedBox(height: 12),
      _sectionTitle(context, 'Trình độ học vấn'),
      if (education.isEmpty)
        _bullet(context, 'Chưa cập nhật')
      else
        ...education.map((e) {
          final period = _join([e['from'], e['to']], sep: ' - ');
          final school = (e['school'] ?? '').toString();
          final major = (e['major'] ?? '').toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.circle, size: 6),
                const SizedBox(width: 8),
                Expanded(child: Text(period.isEmpty ? 'Thời gian' : period, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              ]),
              if (school.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 14, top: 2), child: Text('Trường/Đơn vị: $school')),
              if (major.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 14, top: 2), child: Text('Chuyên ngành: $major')),
            ]),
          );
        }),

      if (certs.isNotEmpty) ...[
        const SizedBox(height: 12),
        _sectionTitle(context, 'Chứng chỉ'),
        ...certs.map((e) {
          final type = (e['type'] ?? '').toString();
          final name = (e['name'] ?? '').toString();
          return _bullet(context, [name, type].where((x) => x.trim().isNotEmpty).join(' · '));
        })
      ]
    ]);
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final styleLabel = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final styleValue = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label, style: styleLabel)),
        Expanded(child: Text(value, style: styleValue)),
      ]),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _bullet(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 6)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );

  Widget _critBar(BuildContext context, _CritScore c) {
    final value = (c.value ?? 0).clamp(0, c.max);
    final fraction = c.max == 0 ? 0.0 : (value / c.max);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(c.label)),
          Text(c.value == null ? '—' : '${c.value!.toStringAsFixed(0)}/${c.max.toStringAsFixed(0)}'),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: c.value == null ? 0 : fraction,
            minHeight: 8,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ]),
    );
  }

  String _join(List<dynamic> parts, {String sep = ' '}) => parts
      .map((e) => (e == null) ? '' : e.toString().trim())
      .where((e) => e.isNotEmpty)
      .join(sep);
}

class _CritScore {
  final String label;
  final double? value;
  final double max;
  _CritScore({required this.label, required this.value, required this.max});
}
