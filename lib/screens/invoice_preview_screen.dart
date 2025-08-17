import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/item.dart';
import '../models/party.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final Party party;
  final List<Item> items;
  final List<int> quantities;
  final DateTime date;
  final bool isCredit;
  final String? note;
  final List<String>? tags;

  const InvoicePreviewScreen({
    super.key,
    required this.party,
    required this.items,
    required this.quantities,
    required this.date,
    required this.isCredit,
    this.note,
    this.tags,
  });

  double get totalAmount {
    double total = 0;
    for (int i = 0; i < items.length; i++) {
      total += items[i].sellingPrice * quantities[i];
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(),
            tooltip: 'Print or Save as PDF',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text('INVOICE', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildPartyInfo(),
                const SizedBox(height: 12),
                Text('Date: ${DateFormat.yMMMd().format(date)}'),
                const SizedBox(height: 16),
                _buildItemTable(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment: ${isCredit ? 'Credit' : 'Cash'}'),
                    Text(
                      'Total: ₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tags != null && tags!.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: tags!.map((tag) => Chip(label: Text(tag))).toList(),
                  ),
                if (note != null && note!.isNotEmpty) ...[
                  const Divider(height: 30),
                  const Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(note!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Party: ${party.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        if (party.phone.isNotEmpty) Text('Phone: ${party.phone}'),
      ],
    );
  }

  Widget _buildItemTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      border: TableBorder.all(color: Colors.black12),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
          children: [
            Padding(padding: EdgeInsets.all(8), child: Text('Item')),
            Padding(padding: EdgeInsets.all(8), child: Text('Qty')),
            Padding(padding: EdgeInsets.all(8), child: Text('Price')),
            Padding(padding: EdgeInsets.all(8), child: Text('Total')),
          ],
        ),
        for (int i = 0; i < items.length; i++)
          TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8), child: Text(items[i].name)),
              Padding(padding: const EdgeInsets.all(8), child: Text('${quantities[i]}')),
              Padding(padding: const EdgeInsets.all(8), child: Text('₹${items[i].sellingPrice.toStringAsFixed(2)}')),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('₹${(items[i].sellingPrice * quantities[i]).toStringAsFixed(2)}'),
              ),
            ],
          )
      ],
    );
  }

  Future<void> _printInvoice() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Text('Party: ${party.name}'),
              if (party.phone.isNotEmpty) pw.Text('Phone: ${party.phone}'),
              pw.SizedBox(height: 8),
              pw.Text('Date: ${DateFormat.yMMMd().format(date)}'),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Item')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Price')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total')),
                    ],
                  ),
                  for (int i = 0; i < items.length; i++)
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(items[i].name)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${quantities[i]}')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('₹${items[i].sellingPrice.toStringAsFixed(2)}')),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('₹${(items[i].sellingPrice * quantities[i]).toStringAsFixed(2)}'),
                        ),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payment: ${isCredit ? 'Credit' : 'Cash'}'),
                  pw.Text('Total: ₹${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              if (tags != null && tags!.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Wrap(
                  spacing: 4,
                  children: tags!.map((tag) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey600),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(tag, style: const pw.TextStyle(fontSize: 10)),
                  )).toList(),
                ),
              ],
              if (note != null && note!.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Text('Note:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(note!),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
