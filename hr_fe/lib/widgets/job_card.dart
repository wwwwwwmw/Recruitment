import 'package:flutter/material.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback? onTap;
  final Widget? trailing; // nút quản trị (edit/delete/close)
  const JobCard({super.key, required this.job, this.onTap, this.trailing});

  String _viJobStatus(String? s){
    switch((s??'').toLowerCase()){
      case 'open': return 'đang tuyển';
      case 'closed': return 'đã kết thúc';
      default: return s??'';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = job['title']?.toString() ?? 'Chưa đặt tiêu đề';
    final dept = job['department']?.toString() ?? '';
    final loc = job['location']?.toString() ?? '';
    final status = _viJobStatus(job['status']?.toString());

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo/company placeholder (theo Figma, có thể làm hình tròn nhỏ)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.work_outline, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          if (dept.isNotEmpty)
                            _Chip(icon: Icons.apartment_outlined, label: dept),
                          if (loc.isNotEmpty)
                            _Chip(icon: Icons.place_outlined, label: loc),
                          if (status.isNotEmpty)
                            _Chip(icon: Icons.flag_outlined, label: 'Trạng thái: $status'),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              if (trailing != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: trailing,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xFF374151))),
      ]),
    );
  }
}
