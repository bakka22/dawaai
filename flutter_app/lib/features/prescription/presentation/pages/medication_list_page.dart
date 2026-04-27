import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/prescription_state.dart';

class MedicationListPage extends ConsumerStatefulWidget {
  const MedicationListPage({super.key});

  @override
  ConsumerState<MedicationListPage> createState() => _MedicationListPageState();
}

class _MedicationListPageState extends ConsumerState<MedicationListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addMedication() {
    final name = _searchController.text.trim();
    if (name.isNotEmpty) {
      ref.read(prescriptionProvider.notifier).addMedication(name);
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prescriptionProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأدوية المستخرجة'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(prescriptionProvider.notifier).reset(),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'إضافة دواء جديد',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addMedication,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (state.status == PrescriptionStatus.processing)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('جاري استخراج الأدوية...'),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: state.medications.isEmpty
                    ? const Center(
                        child: Text(
                          'لم يتم العثور على أدوية',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.medications.length,
                        itemBuilder: (context, index) {
                          final medication = state.medications[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.withOpacity(0.2),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                medication,
                                style: const TextStyle(fontSize: 16),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () =>
                                        _editMedication(index, medication),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => ref
                                        .read(prescriptionProvider.notifier)
                                        .removeMedication(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: state.medications.isEmpty
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('البحث عن الصيدليات...'),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text('البحث عن الصيدليات (${state.medications.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editMedication(int index, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل اسم الدواء'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref
                    .read(prescriptionProvider.notifier)
                    .updateMedication(index, newName);
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
