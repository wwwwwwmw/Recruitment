import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api.dart';
import '../services/auth_state.dart';
import '../widgets/app_picker.dart';

class OffersScreen extends StatefulWidget { const OffersScreen({super.key}); @override State<OffersScreen> createState()=> _OffersScreenState(); }
class _OffersScreenState extends State<OffersScreen>{
  int _tick = 0;
  Future<List<dynamic>> _load(BuildContext c) async {
    final role = c.read<AuthState>().role;
    final items = await apiGetList('/offers', params: _buildParams(role));
    if (role == 'candidate'){
      // Candidate sees: all interview invitations; other notifications only if they passed/got offer/accepted/hired
      try{
        final results = await apiGetList('/results', params: {'mine':'true'});
        final allowed = results.where((r){
          final v = (r['result']?.toString() ?? '').toLowerCase();
          return v=='passed' || v=='offer' || v=='accepted' || v=='hired';
        }).map<int?>((r)=> r['application_id'] as int?).whereType<int>().toSet();
        return items.where((o){
          final pos = (o['position']?.toString() ?? '');
          if (pos.toLowerCase()=='phỏng vấn' || pos.toLowerCase()=='phong van') return true; // interview invites always visible
          final appId = o['application_id'];
          return appId is int && allowed.contains(appId);
        }).toList();
      }catch(_){ return items; }
    }
    return items;
  }
  final _search = TextEditingController();
  int? _selectedJobId;
  int? _selectedSenderId; // admin only
  List<Map<String,dynamic>> _jobs = [];
  List<Map<String,dynamic>> _senders = [];
  @override void initState(){ super.initState(); _loadJobs(); }
  Future<void> _loadJobs() async {
    final role = context.read<AuthState>().role;
    if (role=='admin' || role=='recruiter'){
      final params = role=='admin'? <String,dynamic>{} : {'mine':'true'};
      final list = await apiGetList('/jobs', params: params);
      setState(()=> _jobs = list.cast<Map<String,dynamic>>());
      if (role=='admin'){
        final users = await apiGetList('/users');
        // Filter to admins/recruiters for sender dropdown
        setState(()=> _senders = users.cast<Map<String,dynamic>>().where((u){
          final r = (u['role']??'').toString();
          return r=='admin' || r=='recruiter';
        }).toList());
      }
    }
  }

  Map<String,dynamic> _buildParams(String role){
    final m = <String,dynamic>{};
    if (role != 'admin') m['mine'] = 'true'; // recruiter: see offers sent by me or for my jobs; candidate: mine shows their own
    if (_selectedJobId != null) m['job_id'] = _selectedJobId;
    if (role=='admin' && _selectedSenderId != null) m['sender_id'] = _selectedSenderId;
    if (_search.text.isNotEmpty) m['q'] = _search.text;
    return m;
  }

  @override
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role;
    return Scaffold(
        appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Thông báo'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState(()=> _tick++))],
      ),
        body: FutureBuilder<List<dynamic>>(
        key: ValueKey(_tick),
        future: _load(c),
        builder: (context, snap){
          if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Chưa có thông báo'));
          return Column(children: [
            if (role=='admin' || role=='recruiter') Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(builder: (context, constraints){
                final isNarrow = constraints.maxWidth < 720;
                final cols = (role=='admin') ? 3 : 2;
                final gap = 8.0;
                final fieldWidth = isNarrow ? constraints.maxWidth : (constraints.maxWidth - gap*(cols-1)) / cols;
                return Wrap(spacing: gap, runSpacing: gap, children: [
                  SizedBox(width: fieldWidth, child: DropdownButtonFormField<int>(
                    initialValue: _selectedJobId,
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text('Tất cả công việc')),
                      ..._jobs.map((j)=> DropdownMenuItem<int>(value: j['id'] as int, child: Text(j['title']?.toString()??'')))
                    ],
                    onChanged: (v){ setState(()=> _selectedJobId = v); },
                    decoration: const InputDecoration(labelText: 'Lọc theo công việc'),
                  )),
                  if (role=='admin') SizedBox(width: fieldWidth, child: DropdownButtonFormField<int>(
                    initialValue: _selectedSenderId,
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text('Tất cả người gửi')),
                      ..._senders.map((u)=> DropdownMenuItem<int>(value: u['id'] as int, child: Text('${u['full_name']} (${u['email']})')))
                    ],
                    onChanged: (v){ setState(()=> _selectedSenderId = v); },
                    decoration: const InputDecoration(labelText: 'Lọc theo người gửi'),
                  )),
                  SizedBox(width: fieldWidth, child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên hoặc email'), onSubmitted: (_)=> setState((){}))),
                ]);
              })
            ),
            Expanded(child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __)=> const Divider(height: 1),
            itemBuilder: (_, i){
              final o = items[i] as Map<String, dynamic>;
              return ListTile(
                title: Text('${o['position']??'Vị trí'} • ${o['start_date']??''}'),
                subtitle: Text('${o['full_name']??''} • ${o['email']??''} • ${o['job_title']??''}\nNgười gửi: ${o['sender_name']??'-'} • ${o['sender_email']??''}\nMức lương: ${o['salary']?.toString() ?? '-'}'),
                onTap: () => _viewOfferDialog(context, o),
                trailing: null,
              );
              },
            ))
          ]);
        },
      ),
      floatingActionButton: (role=='admin') ? FloatingActionButton(
        onPressed: ()=> _createOfferDialog(c),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Future<void> _viewOfferDialog(BuildContext c, Map<String,dynamic> o) async {
    await showDialog(context: c, builder: (_) => AlertDialog(
      title: const Text('Chi tiết thông báo'),
      content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Vị trí: ${o['position']??''}'),
        Text('Ngày bắt đầu: ${o['start_date']??''}'),
        Text('Lương: ${o['salary']?.toString() ?? ''}'),
        const SizedBox(height: 12),
        Text(o['content']?.toString() ?? '(Không có nội dung)')
      ])),
      actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Đóng'))],
    ));
  }

  Future<void> _createOfferDialog(BuildContext c) async {
    await _offerFormDialog(c, null);
    if (mounted) setState(()=> _tick++);
  }

  // Offers are immutable; no edit dialog

  Future<void> _offerFormDialog(BuildContext c, Map<String,dynamic>? offer) async {
    Map<String,dynamic>? selectedApp;
    DateTime? startDate;
    final posCtrl = TextEditingController(text: offer?['position']?.toString() ?? '');
    final salaryCtrl = TextEditingController(text: offer?['salary']?.toString() ?? '');
    final contentCtrl = TextEditingController(text: offer?['content']?.toString() ?? '');
    String? error;
    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (context, setState){
      return AlertDialog(
        title: Text(offer==null? 'Tạo thông báo' : 'Cập nhật thông báo'),
        content: SingleChildScrollView(child: Column(children: [
          if (offer==null) AppPickerTile(
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
                final d = await showDatePicker(context: context, initialDate: startDate ?? now, firstDate: DateTime(now.year-3), lastDate: DateTime(now.year+3));
                if (d!=null) setState(()=> startDate = d);
              },
              icon: const Icon(Icons.event),
              label: Text(startDate==null? 'Chọn ngày bắt đầu' : '${startDate!.year.toString().padLeft(4,'0')}-${startDate!.month.toString().padLeft(2,'0')}-${startDate!.day.toString().padLeft(2,'0')}'),
            ))
          ]),
          TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Vị trí')),
          TextField(controller: salaryCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Lương')),
          TextField(controller: contentCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Nội dung thông báo (HTML)')),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async {
            try{
              if (offer==null){
                if (selectedApp==null) { setState(()=> error='Vui lòng chọn ứng tuyển'); return; }
                final body = {
                  'application_id': selectedApp!['id'],
                  'start_date': startDate==null? '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-${DateTime.now().day.toString().padLeft(2,'0')}' : '${startDate!.year.toString().padLeft(4,'0')}-${startDate!.month.toString().padLeft(2,'0')}-${startDate!.day.toString().padLeft(2,'0')}',
                  'position': posCtrl.text.isEmpty? null : posCtrl.text,
                  'salary': salaryCtrl.text.isEmpty ? null : double.tryParse(salaryCtrl.text),
                  'content': contentCtrl.text.isEmpty? null : contentCtrl.text,
                };
                await apiPost('/offers', body);
              } else {
                final body = {
                  'start_date': startDate==null? null : '${startDate!.year.toString().padLeft(4,'0')}-${startDate!.month.toString().padLeft(2,'0')}-${startDate!.day.toString().padLeft(2,'0')}',
                  'position': posCtrl.text.isEmpty? null : posCtrl.text,
                  'salary': salaryCtrl.text.isEmpty? null : double.tryParse(salaryCtrl.text),
                  'content': contentCtrl.text.isEmpty? null : contentCtrl.text,
                };
                await apiPut('/offers/${offer['id']}', body);
              }
              if (context.mounted) Navigator.pop(context);
            } catch(e){ setState(()=> error='Lưu thất bại'); }
          }, child: const Text('Lưu')),
        ],
      );
    }));
    posCtrl.dispose(); salaryCtrl.dispose(); contentCtrl.dispose();
  }
}
