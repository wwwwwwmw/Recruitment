import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api.dart';
import '../services/auth_state.dart';
import '../widgets/app_picker.dart';

class ResultsScreen extends StatefulWidget { const ResultsScreen({super.key}); @override State<ResultsScreen> createState()=> _ResultsScreenState(); }
class _ResultsScreenState extends State<ResultsScreen>{
  final _search = TextEditingController();
  int? _selectedJobId;
  List<Map<String,dynamic>> _jobs = [];
  int _tick = 0;
  @override void initState(){ super.initState(); _loadJobs(); }
  Future<void> _loadJobs() async {
    final role = context.read<AuthState>().role;
    final params = role == 'admin' ? <String,dynamic>{} : {'mine':'true'};
    final list = await apiGetList('/jobs', params: params);
    setState(()=> _jobs = list.cast<Map<String,dynamic>>());
  }
  Map<String,dynamic> _buildParams(){
    final role = context.read<AuthState>().role;
    final p = <String,dynamic>{};
    if (role != 'admin') p['mine']='true';
    if (_selectedJobId != null) p['job_id'] = _selectedJobId;
    if (_search.text.isNotEmpty) p['q'] = _search.text;
    return p;
  }
        
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Kết quả tuyển dụng'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState(()=> _tick++))],
      ),
      body: Column(children: [
        if (role=='admin' || role=='recruiter') Padding(
          padding: const EdgeInsets.all(8.0), child: Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              initialValue: _selectedJobId,
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('Tất cả công việc')),
                ..._jobs.map((j)=> DropdownMenuItem<int>(value: j['id'] as int, child: Text(j['title']?.toString()??'')))
              ],
              onChanged: (v){ setState(()=> _selectedJobId = v); },
              decoration: const InputDecoration(labelText: 'Lọc theo công việc'),
            )),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên/email'), onSubmitted: (_)=> setState((){})))
          ]),
        ),
        Expanded(child: FutureBuilder<List<dynamic>>(
          key: ValueKey(_tick),
          future: apiGetList('/results', params: _buildParams()),
          builder: (context, snap){
            if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
            final items = (snap.data ?? []).cast<Map<String,dynamic>>();
            if (items.isEmpty) return const Center(child: Text('Chưa có kết quả'));
            String _viResult(String? s){
              switch((s??'').toLowerCase()){
                case 'passed': return 'đạt yêu cầu';
                case 'failed': return 'không đạt';
                case 'rejected': return 'bị loại';
                case 'hired': return 'được tuyển';
                case 'offer': return 'thành công';
                case 'accepted': return 'đã nhận';
                default: return s??'';
              }
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __)=> const Divider(height: 1),
              itemBuilder: (_, i){
                final r = items[i];
                return ListTile(
                  title: Text('${_viResult(r['result']?.toString())} • ${r['job_title']??''}'),
                  subtitle: Text('${r['full_name']??''} • ${r['email']??''}\n${r['notes']?.toString() ?? ''}'),
                  trailing: (role=='admin' || role=='recruiter') ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () async { await _editResultDialog(context, r); if (mounted) setState(()=> _tick++); }),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                        try{ await apiDelete('/results/${r['id']}'); if (mounted) setState(()=> _tick++); } catch(_){ }
                      }),
                    ],
                  ) : null,
                );
              },
            );
          },
        ))
      ]),
      floatingActionButton: (role=='admin' || role=='recruiter') ? FloatingActionButton(
        onPressed: () async { await _createResultDialog(context); if (mounted) setState(()=> _tick++); }, child: const Icon(Icons.add),
      ) : null,
    );
  }
  Future<void> _createResultDialog(BuildContext c) async {
    Map<String,dynamic>? selectedApp;
    String resultValue = 'passed';
    final notesCtrl = TextEditingController();
    String? error;
    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (context, setState){
      return AlertDialog(
        title: const Text('Thêm kết quả'),
        content: SingleChildScrollView(child: Column(children: [
          AppPickerTile(
            selectedLabel: selectedApp==null? 'Chọn ứng tuyển' : '#${selectedApp!['id']} • ${selectedApp!['full_name']} • ${selectedApp!['email']}',
            onPick: () async {
              final picked = await showDialog<Map<String,dynamic>>(context: context, builder: (_) => const ApplicationPickerDialog());
              if (picked!=null) setState(()=> selectedApp = picked);
            },
          ),
          DropdownButtonFormField<String>(
            initialValue: resultValue,
            decoration: const InputDecoration(labelText: 'Kết quả'),
            items: const [
              DropdownMenuItem(value:'passed', child: Text('Đạt yêu cầu')),
              DropdownMenuItem(value:'failed', child: Text('Không đạt')),
              DropdownMenuItem(value:'rejected', child: Text('Bị loại')),
              DropdownMenuItem(value:'hired', child: Text('Được tuyển')),
              DropdownMenuItem(value:'offer', child: Text('Thành công')),
              DropdownMenuItem(value:'accepted', child: Text('Đã nhận')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> resultValue=v); },
          ),
          TextField(controller: notesCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Ghi chú')),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async {
            try{
              if (selectedApp==null) { setState(()=> error='Vui lòng chọn ứng tuyển'); return; }
              await apiPost('/results', {
                'application_id': selectedApp!['id'],
                'result': resultValue,
                'notes': notesCtrl.text.isEmpty? null : notesCtrl.text,
              });
              if (context.mounted) Navigator.pop(context);
            } catch(e){ setState(()=> error='Lưu thất bại'); }
          }, child: const Text('Lưu')),
        ],
      );
    }));
  }
  Future<void> _editResultDialog(BuildContext c, Map<String,dynamic> r) async {
    String resultValue = (r['result']?.toString() ?? 'passed');
    final notesCtrl = TextEditingController(text: r['notes']?.toString() ?? '');
    String? error;
    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (context, setState){
      return AlertDialog(
        title: const Text('Cập nhật kết quả'),
        content: SingleChildScrollView(child: Column(children: [
          DropdownButtonFormField<String>(
            initialValue: resultValue,
            decoration: const InputDecoration(labelText: 'Kết quả'),
            items: const [
              DropdownMenuItem(value:'passed', child: Text('Đạt yêu cầu')),
              DropdownMenuItem(value:'failed', child: Text('Không đạt')),
              DropdownMenuItem(value:'rejected', child: Text('Bị loại')),
              DropdownMenuItem(value:'hired', child: Text('Được tuyển')),
              DropdownMenuItem(value:'offer', child: Text('Thành công')),
              DropdownMenuItem(value:'accepted', child: Text('Đã nhận')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> resultValue=v); },
          ),
          TextField(controller: notesCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Ghi chú')),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async {
            try{
              await apiPut('/results/${r['id']}', {
                'result': resultValue,
                'notes': notesCtrl.text.isEmpty? null : notesCtrl.text,
              });
              if (context.mounted) Navigator.pop(context);
            } catch(e){ setState(()=> error='Lưu thất bại'); }
          }, child: const Text('Lưu')),
        ],
      );
    }));
  }
}
