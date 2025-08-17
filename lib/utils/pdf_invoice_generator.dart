// ignore_for_file: unused_import

import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/party.dart';
import '../models/item.dart';
import '../models/transaction_model.dart';

class PdfInvoiceGenerator {
  static Future<void> generateInvoice({
    required Party party,
    required DateTime date,
    required List<Item> items,
    required List<int> quantities,
    required bool isCredit,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat.yMMMd().format(date);

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Date: $dateStr'),
              pw.Text('Party: ${party.name}'),
              pw.Text('Type: ${isCredit ? "Credit" : "Cash"}'),
              pw.Divider(),

              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Qty', 'Rate', 'Total'],
                data: List.generate(items.length, (index) {
                  final item = items[index];
                  final qty = quantities[index];
                  final total = qty * item.sellingPrice;
                  return [item.name, qty.toString(), '₹${item.sellingPrice}', '₹${total.toStringAsFixed(2)}'];
                }),
              ),
              pw.Divider(),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total: ₹${_calculateTotal(items, quantities).toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static double _calculateTotal(List<Item> items, List<int> quantities) {
    double total = 0;
    for (int i = 0; i < items.length; i++) {
      total += items[i].sellingPrice * quantities[i];
    }
    return total;
  }
}
