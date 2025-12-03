import 'package:flutter/material.dart';

class TreeVisualization extends StatelessWidget {
  final Map<String, dynamic> treeData;

  const TreeVisualization({Key? key, required this.treeData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For now, we show a very simple tree using cards per founder
    final buffaloes = treeData['buffaloes'] as List<dynamic>;

    final founders = buffaloes.where((b) => (b as dynamic).parentId == null).toList();

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.5,
      maxScale: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          children: founders.map((f) {
            final data = f as dynamic;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Unit ${data.unit} - A${data.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Started: ${data.birthYear}'),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
