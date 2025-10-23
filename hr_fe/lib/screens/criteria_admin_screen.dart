import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api.dart';

// Admin screen to manage criteria list
class CriteriaAdminScreen extends StatefulWidget { const CriteriaAdminScreen({super.key}); @override State<CriteriaAdminScreen> createState()=> _CriteriaAdminScreenState(); }
class _CriteriaAdminScreenState extends State<CriteriaAdminScreen>{
  int _tick=0; final _search=TextEditingController();
  Future<List<dynamic>> _load() async { final list = await apiGetList('/criteria'); final q=_search.text.trim().toLowerCase(); if (q.isEmpty) return list; return list.where((e){ final m=(e as Map).map((k,v)=> MapEntry('$k','${v??''}'.toLowerCase())); return (m['key']??'').contains(q) || (m['label']??'').contains(q); }).toList(); }
  @override void dispose(){ _search.dispose(); super.dispose(); }
  @override Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Tiêu chí đánh giá'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState(()=> _tick++))],
      ),
      body: Column(children:[
        Padding(padding: const EdgeInsets.all(8), child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'Tìm theo mã/nhãn'), onSubmitted: (_)=> setState(()=> _tick++))),
        Expanded(child: FutureBuilder<List<dynamic>>(
          key: ValueKey(_tick), future: _load(), builder:(context,snap){
            if (snap.connectionState!=ConnectionState.done) return const Center(child:CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
            final items = (snap.data??[]).cast<Map<String,dynamic>>();
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __)=> const Divider(height:1),
              itemBuilder: (_, i){ final it=items[i]; return ListTile(
                title: Text('${it['label']} • ${it['key']}'),
                subtitle: Text('Tối thiểu:${it['min']}  Tối đa:${it['max']}  Bước:${it['step']} • Kích hoạt:${it['active']}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children:[
                  IconButton(icon: const Icon(Icons.edit), onPressed: () async { final changed = await _editDialog(context, it); if (changed==true && mounted) setState(()=> _tick++); }),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { try{ await apiDelete('/criteria/${it['id']}'); setState(()=> _tick++);} catch(_){}}),
                ]),
              ); },
            );
          })
        )
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () async { final changed = await _createDialog(context); if (changed==true && mounted) setState(()=> _tick++); }, child: const Icon(Icons.add)),
    );
  }
  Future<bool?> _createDialog(BuildContext c) async {
    final keyC=TextEditingController(); final labelC=TextEditingController(); final minC=TextEditingController(text:'0'); final maxC=TextEditingController(text:'100'); final stepC=TextEditingController(text:'1'); bool active=true; String? error;
    bool changed=false;
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder:(context,setState){ return AlertDialog(
      title: const Text('Thêm tiêu chí'), content: SingleChildScrollView(child: Column(children:[
  TextField(controller:keyC, decoration: const InputDecoration(labelText:'Mã (ví dụ: ielts)')),
        TextField(controller:labelC, decoration: const InputDecoration(labelText:'Nhãn hiển thị')),
  Row(children:[ Expanded(child: TextField(controller:minC, decoration: const InputDecoration(labelText:'Tối thiểu'), keyboardType: TextInputType.number)), const SizedBox(width:8), Expanded(child: TextField(controller:maxC, decoration: const InputDecoration(labelText:'Tối đa'), keyboardType: TextInputType.number)) ]),
        TextField(controller:stepC, decoration: const InputDecoration(labelText:'Bước'), keyboardType: TextInputType.number),
        CheckboxListTile(value: active, onChanged: (v)=> setState(()=> active=v==true), title: const Text('Kích hoạt')),
        if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
      ])),
      actions: [ TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async { try{
          await apiPost('/criteria', { 'key': keyC.text.trim(), 'label': labelC.text.trim(), 'min': double.tryParse(minC.text), 'max': double.tryParse(maxC.text), 'step': double.tryParse(stepC.text), 'active': active });
          changed=true; if (context.mounted) Navigator.pop(context);
        }catch(e){ setState(()=> error='Lưu thất bại'); } }, child: const Text('Lưu')) ],
    ); }));
    return changed;
  }
  Future<bool?> _editDialog(BuildContext c, Map<String,dynamic> it) async {
    final keyC=TextEditingController(text: '${it['key']??''}'); final labelC=TextEditingController(text: '${it['label']??''}'); final minC=TextEditingController(text:'${it['min']??0}'); final maxC=TextEditingController(text:'${it['max']??100}'); final stepC=TextEditingController(text:'${it['step']??1}'); bool active=(it['active']==true); String? error;
    bool changed=false;
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder:(context,setState){ return AlertDialog(
      title: const Text('Sửa tiêu chí'), content: SingleChildScrollView(child: Column(children:[
  TextField(controller:keyC, decoration: const InputDecoration(labelText:'Mã')),
        TextField(controller:labelC, decoration: const InputDecoration(labelText:'Nhãn')),
  Row(children:[ Expanded(child: TextField(controller:minC, decoration: const InputDecoration(labelText:'Tối thiểu'), keyboardType: TextInputType.number)), const SizedBox(width:8), Expanded(child: TextField(controller:maxC, decoration: const InputDecoration(labelText:'Tối đa'), keyboardType: TextInputType.number)) ]),
        TextField(controller:stepC, decoration: const InputDecoration(labelText:'Bước'), keyboardType: TextInputType.number),
        CheckboxListTile(value: active, onChanged: (v)=> setState(()=> active=v==true), title: const Text('Kích hoạt')),
        if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
      ])),
      actions: [ TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async { try{
          await apiPut('/criteria/${it['id']}', { 'key': keyC.text.trim(), 'label': labelC.text.trim(), 'min': double.tryParse(minC.text), 'max': double.tryParse(maxC.text), 'step': double.tryParse(stepC.text), 'active': active });
          changed=true; if (context.mounted) Navigator.pop(context);
        }catch(e){ setState(()=> error='Lưu thất bại'); } }, child: const Text('Lưu')) ],
    ); }));
    return changed;
  }
}
