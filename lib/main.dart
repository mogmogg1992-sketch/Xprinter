import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ReceiptScannerPrinter(),
    );
  }
}

class ReceiptScannerPrinter extends StatefulWidget {
  const ReceiptScannerPrinter({super.key});

  @override
  State<ReceiptScannerPrinter> createState() => _ReceiptScannerPrinterState();
}

class _ReceiptScannerPrinterState extends State<ReceiptScannerPrinter> {
  BluetoothDevice? _selectedDevice;
  final TextEditingController _codeController = TextEditingController();
  List<BluetoothDevice> _devicesList = [];

  @override
  void initState() {
    super.initState();
    _startBluetoothScan();
  }

  void _startBluetoothScan() async {
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _devicesList = results.map((r) => r.device).toList();
        });
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    } catch (e) {
      debugPrint("Bluetooth Error: $e");
    }
  }

  void _printReceipt(String text) async {
    if (_selectedDevice == null) return;

    try {
      await _selectedDevice!.connect();
      List<BluetoothService> services = await _selectedDevice!.discoverServices();
      
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            List<int> bytes = [0x1B, 0x40, 0x1B, 0x74, 0x07]; 
            bytes.addAll(text.codeUnits);   
            bytes.addAll([0x0A, 0x0A, 0x0A]); 
            
            await characteristic.write(bytes, withoutResponse: false);
          }
        }
      }
    } catch (e) {
      debugPrint("Print Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xprinter 365b Печать чеков')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Введите или отсканируйте штрих-код товара',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<BluetoothDevice>(
              hint: const Text("Выберите принтер Xprinter"),
              value: _selectedDevice,
              items: _devicesList.map((device) {
                return DropdownMenuItem(
                  value: device,
                  child: Text(device.platformName.isEmpty ? device.remoteId.toString() : device.platformName),
                );
              }).toList(),
              onChanged: (device) {
                setState(() { _selectedDevice = device; });
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _printReceipt("ТОВАР: ${_codeController.text}\nЦЕНА: 100 РУБ.\nСПАСИБО!"),
              child: const Text('Распечатать чек'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
