import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

import '../db/db_helper.dart';

class BackupExportScreen extends StatefulWidget {
  const BackupExportScreen({super.key});

  @override
  State<BackupExportScreen> createState() => _BackupExportScreenState();
}

class _BackupExportScreenState extends State<BackupExportScreen> {
  bool _isExporting = false;

  Future<void> _exportDataAsJson() async {
    setState(() => _isExporting = true);

    try {
      final parties = await DBHelper.getAllParties();
      final items = await DBHelper.getAllItems();
      final transactions = await DBHelper.getAllTransactions();

      final exportData = {
        'parties': parties.map((p) => p.toMap()).toList(),
        'items': items.map((i) => i.toMap()).toList(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/smart_ledger_backup.json');
      await file.writeAsString(jsonEncode(exportData));

      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: '📦 Smart Ledger Backup File',
        subject: 'Smart Ledger JSON Export',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Export')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Export your data as JSON for backup or transfer.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportDataAsJson,
              icon: const Icon(Icons.file_download),
              label: Text(_isExporting ? 'Exporting...' : 'Export JSON Backup'),
            ),
            const SizedBox(height: 20),
            const Text(
              'We’ll add Excel, PDF and Import options next.',
              style: TextStyle(color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }
}
