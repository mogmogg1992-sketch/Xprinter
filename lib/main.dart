import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  String _scannedData = "Ничего не отсканировано";
  List<BluetoothDevice> _devicesList = [];

  @override
  void initState() {
    super.initState();
    _startBluetoothScan();
  }

  void _startBluetoothScan() async {
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _devicesList = results.map((r) => r.device).toList();
      });
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
  }

  void _printReceipt(String text) async {
    if (_selectedDevice == null) return;

    await _selectedDevice!.connect();
    List<BluetoothService> services = await _selectedDevice!.discoverServices();
    
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          List<int> bytes = [0x1B, 0x40, 0x1B, 0x74, 0x07]; 
          bytes.addAll(text.codeUnits);   
          bytes.addAll([0x0A, 0x0A, 0x0A]); 
          
          await characteristic.write(bytes);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xprinter 365b Сканер/Печать')),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  setState(() {
                    _scannedData = barcodes.first.rawValue ?? "Ошибка чтения";
                  });
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Данные: $_scannedData', style: const TextStyle(fontSize: 18)),
          ),
          DropdownButton<BluetoothDevice>(
            hint: const Text("Выберите принтер"),
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
            onPressed: () => _printReceipt("ТОВАР: $_scannedData\nЦЕНА: 100 РУБ.\nСПАСИБО!"),
            child: const Text('Распечатать чек'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

