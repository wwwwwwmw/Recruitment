import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CommitteesScreen extends StatelessWidget {
  const CommitteesScreen({super.key});
  @override
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Hội đồng tuyển dụng'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> c.go('/committees'))],
      ),
      body: const Center(child: Text('Hội đồng tuyển dụng - TODO xây UI và API')),
    );
  }
}
