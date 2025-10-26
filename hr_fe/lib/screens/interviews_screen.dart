import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api.dart';
import '../services/auth_state.dart';
import 'package:provider/provider.dart';
import '../widgets/app_picker.dart';

class InterviewsScreen extends StatefulWidget { const InterviewsScreen({super.key}); @override State<InterviewsScreen> createState()=> _InterviewsScreenState(); }
class _InterviewsScreenState extends State<InterviewsScreen>{
  int _tick = 0;
  Future<List<dynamic>> _load(BuildContext c) async {
    final role = c.read<AuthState>().role;
    final me = c.read<AuthState>().user ?? {};
    final meId = me['id'];
    final myEmail = (me['email']?.toString() ?? '').toLowerCase();

    final params = <String,dynamic>{};
    if (role != 'admin') params['mine'] = 'true';
    final raw = await apiGetList('/interviews', params: params);
    final items = raw.cast<Map<String,dynamic>>();

    if (role == 'admin') return items;

    // Additional client-side filtering to enforce visibility even if server ignores params
    final filtered = <Map<String,dynamic>>[];
    for (final itv in items){
      final appId = itv['application_id'];
      if (appId is! int) continue;
      try{
        final app = await apiGet('/applications/$appId');
        // Candidate: only interviews for their own application email
        if (role == 'candidate'){
          final email = (app['email']?.toString() ?? '').toLowerCase();
          if (email.isNotEmpty && email == myEmail) filtered.add(itv);
          continue;
        }
        // Recruiter: only interviews for jobs they own (posted_by == meId)
        if (role == 'recruiter'){
          final jobId = app['job_id'];
          if (jobId is int){
            try{
              final job = await apiGet('/jobs/$jobId');
              if (job['posted_by'] == meId) filtered.add(itv);
            }catch(_){ /* ignore job fetch errors */ }
          }
        }
      }catch(_){ /* ignore app fetch errors */ }
    }
    return filtered;
  }
  @override
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Lịch phỏng vấn'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState(()=> _tick++))],
      ),
      body: FutureBuilder<List<dynamic>>(
        key: ValueKey(_tick),
        future: _load(c),
        builder: (context, snap){
          if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
          final items = (snap.data ?? []).cast<Map<String,dynamic>>();
          if (items.isEmpty) return const Center(child: Text('Chưa có lịch phỏng vấn'));
          String _viMode(String? s){
            switch((s??'').toLowerCase()){
              case 'online': return 'trực tuyến';
              case 'offline': return 'trực tiếp';
              default: return s??'';
            }
          }
          String _viItvStatus(String? s){
            switch((s??'').toLowerCase()){
              case 'scheduled': return 'đã lên lịch';
              case 'completed': return 'đã hoàn thành';
              case 'canceled': return 'đã hủy';
              case 'no-show': return 'vắng mặt';
              default: return s??'';
            }
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __)=> const Divider(height: 1),
            itemBuilder: (_, i){
              final itv = items[i];
              return ListTile(
                title: Text('Ứng tuyển #${itv['application_id']} • ${itv['scheduled_at']}'),
                subtitle: Text('${itv['location']??''} • ${_viMode(itv['mode']?.toString())} • Trạng thái: ${_viItvStatus(itv['status']?.toString())}'),
                trailing: (role=='admin' || role=='recruiter') ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: ()=> _editInterviewDialog(context, itv)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { try{ await apiDelete('/interviews/${itv['id']}'); setState((){});} catch(_){}}),
                  ],
                ) : null,
              );
            },
          );
        },
      ),
      floatingActionButton: (role=='admin' || role=='recruiter') ? FloatingActionButton(
        onPressed: () async { await _createInterviewDialog(c); if (mounted) setState(()=> _tick++); }, child: const Icon(Icons.add),
      ) : null,
    );
  }
  Future<void> _createInterviewDialog(BuildContext c) async {
    Map<String,dynamic>? selectedApp; final loc=TextEditingController(); String? error;
    DateTime? scheduledAt; String mode='online';
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder: (context,setState){
      return AlertDialog(
        title: const Text('Tạo lịch phỏng vấn'),
        content: SingleChildScrollView(child: Column(children:[
          AppPickerTile(
            selectedLabel: selectedApp==null? 'Chọn ứng tuyển' : '#${selectedApp!['id']} • ${selectedApp!['full_name']} • ${selectedApp!['email']}',
            onPick: () async {
              final picked = await showDialog<Map<String,dynamic>>(context: context, builder: (_) => const ApplicationPickerDialog());
              if (picked!=null) setState(()=> selectedApp = picked);
            },
          ),
          Row(children:[
            Expanded(child: OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(context: context, initialDate: scheduledAt ?? now, firstDate: DateTime(now.year-3), lastDate: DateTime(now.year+3));
                if (d!=null){
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(scheduledAt ?? now));
                  final combined = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
                  setState(()=> scheduledAt = combined);
                }
              },
              icon: const Icon(Icons.event),
              label: Text(scheduledAt==null? 'Chọn thời gian' : scheduledAt!.toIso8601String()),
            )),
          ]),
          TextField(controller: loc, decoration: const InputDecoration(labelText:'Địa điểm')),
          DropdownButtonFormField<String>(
            initialValue: mode,
            decoration: const InputDecoration(labelText:'Hình thức'),
            items: const [
              DropdownMenuItem(value:'online', child: Text('Trực tuyến')),
              DropdownMenuItem(value:'offline', child: Text('Trực tiếp')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> mode=v); },
          ),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async { 
            try{
              if (selectedApp==null) { setState(()=> error='Vui lòng chọn ứng tuyển'); return; }
              final when = scheduledAt ?? DateTime.now();
              await apiPost('/interviews', {
                'application_id': selectedApp!['id'],
                'scheduled_at': when.toIso8601String(),
                'location': loc.text.trim().isEmpty? null:loc.text.trim(),
                'mode': mode,
              });
              // Không tự động tạo offer; backend đã tạo thông báo phỏng vấn
              if (context.mounted) Navigator.pop(context);
            }catch(e){ setState(()=> error='Lưu thất bại'); }
          }, child: const Text('Lưu'))
        ],
      );
    }));
  }
  Future<void> _editInterviewDialog(BuildContext c, Map<String,dynamic> itv) async {
    final loc=TextEditingController(text: itv['location']?.toString()??''); String? error;
    DateTime? scheduledAt = (){ try{ return DateTime.parse(itv['scheduled_at']?.toString()??''); } catch(_){ return null; } }();
    String mode = (itv['mode']?.toString()??'online');
    String status = (itv['status']?.toString() ?? 'scheduled');
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder: (context,setState){
      return AlertDialog(
        title: const Text('Cập nhật lịch phỏng vấn'),
        content: SingleChildScrollView(child: Column(children:[
          Row(children:[
            Expanded(child: OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(context: context, initialDate: scheduledAt ?? now, firstDate: DateTime(now.year-3), lastDate: DateTime(now.year+3));
                if (d!=null){
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(scheduledAt ?? now));
                  final combined = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
                  setState(()=> scheduledAt = combined);
                }
              },
              icon: const Icon(Icons.event),
              label: Text(scheduledAt==null? 'Chọn thời gian' : scheduledAt!.toIso8601String()),
            )),
          ]),
          TextField(controller: loc, decoration: const InputDecoration(labelText:'Địa điểm')),
          DropdownButtonFormField<String>(
            initialValue: mode,
            decoration: const InputDecoration(labelText:'Hình thức'),
            items: const [
              DropdownMenuItem(value:'online', child: Text('online')),
              DropdownMenuItem(value:'offline', child: Text('offline')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> mode=v); },
          ),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText:'Trạng thái'),
            items: const [
              DropdownMenuItem(value:'scheduled', child: Text('Đã lên lịch')),
              DropdownMenuItem(value:'completed', child: Text('Đã hoàn thành')),
              DropdownMenuItem(value:'canceled', child: Text('Đã hủy')),
              DropdownMenuItem(value:'no-show', child: Text('Vắng mặt')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> status=v); },
          ),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async { try{
            await apiPut('/interviews/${itv['id']}', {
              'scheduled_at': scheduledAt?.toIso8601String(),
              'location': loc.text.trim().isEmpty? null:loc.text.trim(),
              'mode': mode,
              'status': status,
            });
            if (context.mounted) { Navigator.pop(context); setState(()=> _tick++); }
          }catch(e){ setState(()=> error='Lưu thất bại'); }}, child: const Text('Lưu'))
        ],
      );
    }));
  }
}
