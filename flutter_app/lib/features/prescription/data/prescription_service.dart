import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';

class PrescriptionService {
  final Dio _dio;

  PrescriptionService(ApiClient apiClient) : _dio = apiClient.dio;

  Future<String> uploadPrescription(File imageFile) async {
    final formData = FormData.fromMap({
      'prescription': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'prescription_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });

    final response = await _dio.post('/ocr/relay', data: formData);
    final data = response.data as Map<String, dynamic>;

    return data['extractedText'] as String;
  }

  List<String> parseMedications(String extractedText) {
    final lines = extractedText
        .split('\n')
        .where((line) => line.trim().isNotEmpty);
    final medications = <String>[];

    for (final line in lines) {
      final cleaned = line.trim();
      if (cleaned.isNotEmpty) {
        final name = cleaned.split('-').first.trim();
        if (name.isNotEmpty) {
          medications.add(name);
        }
      }
    }

    return medications;
  }
}

final prescriptionServiceProvider = Provider<PrescriptionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PrescriptionService(apiClient);
});
