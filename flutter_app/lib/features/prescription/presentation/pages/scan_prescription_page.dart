import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/prescription_state.dart';
import 'medication_list_page.dart';

class ScanPrescriptionPage extends ConsumerStatefulWidget {
  const ScanPrescriptionPage({super.key});

  @override
  ConsumerState<ScanPrescriptionPage> createState() =>
      _ScanPrescriptionPageState();
}

class _ScanPrescriptionPageState extends ConsumerState<ScanPrescriptionPage> {
  final _picker = ImagePicker();

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      await ref
          .read(prescriptionProvider.notifier)
          .scanPrescription(File(image.path));
      _navigateToList();
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      await ref
          .read(prescriptionProvider.notifier)
          .scanPrescription(File(image.path));
      _navigateToList();
    }
  }

  void _navigateToList() {
    final state = ref.read(prescriptionProvider);
    if (state.status == PrescriptionStatus.ready ||
        state.status == PrescriptionStatus.error) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MedicationListPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prescriptionProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مسح الروشتة'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.camera_alt, size: 80, color: Colors.teal),
                const SizedBox(height: 24),
                const Text(
                  'التقط صورة للروشتة',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'سيتم استخراج أسماء الأدوية تلقائياً',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                if (state.status == PrescriptionStatus.scanning ||
                    state.status == PrescriptionStatus.processing)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _captureImage,
                        icon: const Icon(Icons.camera),
                        label: const Text('التقاط صورة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('اختيار من المعرض'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                if (state.status == PrescriptionStatus.error)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.error ?? 'حدث خطأ',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
