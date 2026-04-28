import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/pharmacist_service.dart';

class InventoryScannerPage extends ConsumerStatefulWidget {
  final int pharmacyId;

  const InventoryScannerPage({super.key, required this.pharmacyId});

  @override
  ConsumerState<InventoryScannerPage> createState() =>
      _InventoryScannerPageState();
}

class _InventoryScannerPageState extends ConsumerState<InventoryScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  final List<ScannedItem> _scannedItems = [];
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _processBarcode(barcode.rawValue!);
      }
    }
  }

  Future<void> _processBarcode(String barcode) async {
    setState(() => _isProcessing = true);

    try {
      final service = ref.read(pharmacistServiceProvider);
      final result = await service.lookupMedicationByBarcode(barcode);

      if (result != null) {
        final existingIndex = _scannedItems.indexWhere(
          (item) => item.barcode == barcode,
        );

        setState(() {
          if (existingIndex >= 0) {
            _scannedItems[existingIndex] = ScannedItem(
              barcode: barcode,
              medicationName: result['name'] ?? 'غير معروف',
              medicationId: result['id'],
              isInStock: !_scannedItems[existingIndex].isInStock,
              scannedAt: DateTime.now(),
            );
          } else {
            _scannedItems.add(
              ScannedItem(
                barcode: barcode,
                medicationName: result['name'] ?? 'غير معروف',
                medicationId: result['id'],
                isInStock: false,
                scannedAt: DateTime.now(),
              ),
            );
          }
        });

        await _updateStock(
          result['id'],
          !_scannedItems.any((s) => s.barcode == barcode && s.isInStock),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تحديث: ${result['name']}'),
              backgroundColor: Colors.teal,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الصنف غير موجود في قاعدة البيانات'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateStock(int medicationId, bool isInStock) async {
    try {
      final service = ref.read(pharmacistServiceProvider);
      await service.updateInventoryStock(
        pharmacyId: widget.pharmacyId,
        medicationId: medicationId,
        isInStock: isInStock,
      );
    } catch (e) {
      debugPrint('Failed to update stock: $e');
    }
  }

  void _clearScannedItems() {
    setState(() => _scannedItems.clear());
  }

  @override
  Widget build(BuildContext context) {
    final inStockCount = _scannedItems.where((item) => item.isInStock).length;
    final outOfStockCount = _scannedItems
        .where((item) => !item.isInStock)
        .length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ماسح الجرد'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            if (_scannedItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _clearScannedItems,
                tooltip: 'مسح القائمة',
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onBarcodeDetected,
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isProcessing ? Colors.orange : Colors.teal,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                    label: 'متوفر',
                    count: inStockCount,
                    color: Colors.green,
                  ),
                  _StatChip(
                    label: 'غير متوفر',
                    count: outOfStockCount,
                    color: Colors.red,
                  ),
                  _StatChip(
                    label: 'الإجمالي',
                    count: _scannedItems.length,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _scannedItems.isEmpty
                  ? const Center(
                      child: Text(
                        'قم بمسح الباركود لتحديث المخزون',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _scannedItems.length,
                      itemBuilder: (context, index) {
                        final item = _scannedItems[index];
                        return _ScannedItemCard(item: item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannedItem {
  final String barcode;
  final String medicationName;
  final int medicationId;
  final bool isInStock;
  final DateTime scannedAt;

  ScannedItem({
    required this.barcode,
    required this.medicationName,
    required this.medicationId,
    required this.isInStock,
    required this.scannedAt,
  });
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _ScannedItemCard extends StatelessWidget {
  final ScannedItem item;

  const _ScannedItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          item.isInStock ? Icons.check_circle : Icons.cancel,
          color: item.isInStock ? Colors.green : Colors.red,
        ),
        title: Text(item.medicationName),
        subtitle: Text(item.barcode, style: const TextStyle(fontSize: 12)),
        trailing: Text(
          item.isInStock ? 'متوفر' : 'غير متوفر',
          style: TextStyle(
            color: item.isInStock ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
