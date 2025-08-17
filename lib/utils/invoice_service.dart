// ignore: unused_import
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/party.dart';
import '../models/item.dart';
import '../models/transaction_model.dart';

class InvoiceService {
  static Future<void> printInvoice({
    required Party party,
    required List<TransactionModel> transactions,
    required Map<int, Item> itemMap,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Text('Date: ${date.toLocal().toString().split(' ')[0]}'),
              pw.Text('Party: ${party.name}'),
              pw.Text('Phone: ${party.phone}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Qty', 'Price', 'Amount'],
                data: transactions.map((txn) {
                  final item = itemMap[txn.itemId];
                  final amount = txn.quantity * (item?.sellingPrice ?? 0);
                  return [
                    item?.name ?? 'Unknown',
                    txn.quantity.toString(),
                    '₹${item?.sellingPrice.toStringAsFixed(2) ?? "0.00"}',
                    '₹${amount.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total: ₹${transactions.fold<double>(0, (sum, txn) => sum + txn.amount).toStringAsFixed(2)}',




                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
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
