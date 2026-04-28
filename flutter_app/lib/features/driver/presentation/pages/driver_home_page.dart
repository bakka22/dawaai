import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/driver_service.dart';

class DriverHomePage extends ConsumerStatefulWidget {
  const DriverHomePage({super.key});

  @override
  ConsumerState<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends ConsumerState<DriverHomePage> {
  int? _selectedOrderId;
  Map<String, dynamic>? _tripData;
  bool _isLoading = false;

  Future<void> _loadTrip(int orderId) async {
    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(driverServiceProvider)
          .planTrip(orderId, 15.5, 32.5);
      setState(() {
        _tripData = result;
        _selectedOrderId = orderId;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سائق - طلبات التوصيل'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الطلبات النشطة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _OrderCard(
                      orderId: 1,
                      pharmacyName: 'صيدلية الخرائط الكبرى',
                      address: 'الخرطوم - شارع الوحدة',
                      status: 'جاهز للاستلام',
                      onTap: () => _loadTrip(1),
                    ),
                    _OrderCard(
                      orderId: 2,
                      pharmacyName: 'صيدلية الواحة',
                      address: 'الخرطوم - شارع library',
                      status: 'جاري التحضير',
                      onTap: () => _loadTrip(2),
                    ),
                    if (_tripData != null) ...[
                      const SizedBox(height: 24),
                      _TripCard(tripData: _tripData!),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final int orderId;
  final String pharmacyName;
  final String address;
  final String status;
  final VoidCallback onTap;

  const _OrderCard({
    required this.orderId,
    required this.pharmacyName,
    required this.address,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'طلب #$orderId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.local_pharmacy,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(pharmacyName),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(address),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.navigation),
                      label: const Text('تصفح'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check_circle),
                      label: const Text('استلام'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> tripData;

  const _TripCard({required this.tripData});

  @override
  Widget build(BuildContext context) {
    final tripType = tripData['trip_type'] as String? ?? 'STANDARD';
    final hasRegulated =
        tripData['has_regulated_medications'] as bool? ?? false;
    final instructions = tripData['instructions'] as List? ?? [];

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'خط السير',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hasRegulated
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasRegulated ? 'ممنوعات' : 'عادي',
                    style: TextStyle(
                      color: hasRegulated ? Colors.red : Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasRegulated)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تحذير: يتطلب جمع الوصفة الطبية من العميل أولاً',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(),
            ...instructions.asMap().entries.map((entry) {
              final idx = entry.key;
              final inst = entry.value;
              final step = inst['step'] as int? ?? idx + 1;
              final type = inst['type'] as String? ?? '';
              final message = inst['message'] as String? ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: step == 1 ? Colors.green : Colors.blue,
                      child: Text(
                        '$step',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStepTitle(type),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (step == instructions.length)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(String type) {
    switch (type) {
      case 'START':
        return 'بدء الرحلة';
      case 'CUSTOMER_COLLECT_PAPER':
        return 'جمع الوصفة من العميل';
      case 'PHARMACY_EXCHANGE':
        return 'استلام الأدوية من الصيدلية';
      case 'PHARMACY_PICKUP':
        return 'التوجه للصيدلية';
      case 'CUSTOMER_DELIVER':
        return 'التوصيل للعميل';
      case 'COMPLETE':
        return 'اكتمال التوصيل';
      default:
        return 'خطوة $type';
    }
  }
}
