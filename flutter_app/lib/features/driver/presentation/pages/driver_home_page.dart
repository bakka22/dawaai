import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final hasRegulated =
        tripData['has_regulated_medications'] as bool? ?? false;
    final waypoints = tripData['waypoints'] as List? ?? [];
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
            const SizedBox(height: 12),
            if (waypoints.isNotEmpty) ...[
              _buildWaypointSequence(waypoints),
              const Divider(height: 24),
            ],
            ...instructions.asMap().entries.map((entry) {
              final idx = entry.key;
              final inst = entry.value;
              final step = inst['step'] as int? ?? idx + 1;
              final type = inst['type'] as String? ?? '';
              final message = inst['message'] as String? ?? '';

              return _InstructionStep(
                step: step,
                type: type,
                message: message,
                totalSteps: instructions.length,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointSequence(List waypoints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تسلسل المحطات',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...waypoints.asMap().entries.map((entry) {
          final idx = entry.key;
          final wp = entry.value;
          final wpType = wp['type'] as String? ?? '';
          final name = wp['name'] as String? ?? 'محطة ${idx + 1}';
          final lat = wp['lat'] as double? ?? 0;
          final lng = wp['lng'] as double? ?? 0;

          return _WaypointTile(
            index: idx + 1,
            name: name,
            type: wpType,
            lat: lat,
            lng: lng,
          );
        }),
      ],
    );
  }
}

class _WaypointTile extends StatelessWidget {
  final int index;
  final String name;
  final String type;
  final double lat;
  final double lng;

  const _WaypointTile({
    required this.index,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
  });

  Color get _color {
    switch (type) {
      case 'CUSTOMER':
        return Colors.green;
      case 'PHARMACY':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String get _label {
    switch (type) {
      case 'CUSTOMER':
        return 'العميل';
      case 'PHARMACY':
        return 'صيدلية';
      default:
        return 'محطة';
    }
  }

  Future<void> _openNavigation() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(_label, style: TextStyle(fontSize: 12, color: _color)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.navigation, color: Colors.blue),
            onPressed: _openNavigation,
            tooltip: 'فتح في خرائط Google',
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int step;
  final String type;
  final String message;
  final int totalSteps;

  const _InstructionStep({
    required this.step,
    required this.type,
    required this.message,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: step == totalSteps ? Colors.green : Colors.blue,
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontSize: 12),
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (step == totalSteps)
            const Icon(Icons.check_circle, color: Colors.green),
        ],
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
