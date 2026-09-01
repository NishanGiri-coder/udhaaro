// lib/services/pdf_service.dart

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/shop.dart';
import '../models/item.dart';
import '../core/utils/nepali_date_utils.dart';

class PdfService {
  // ------------------------------------------------------------
  // Helper to load logo image from assets
  // ------------------------------------------------------------
  static Future<pw.MemoryImage?> _loadLogoImage() async {
    try {
      final logoBytes = await rootBundle.load('assets/images/udhaaro_logo.png');
      return pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------
  // PDF Currency Formatter
  // Displays: NPR 2,500 / NPR 1,25,000
  // ------------------------------------------------------------
  static String formatPdfNPR(double amount) {
    String valueStr = amount.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))');
    String mathFunc(Match match) => '${match[1]},';
    String formatted = valueStr.replaceAllMapped(reg, mathFunc);
    return 'NPR $formatted';
  }

  // ------------------------------------------------------------
  // Generate PDF for a single shop
  // ------------------------------------------------------------
  static Future<File> generateShopPdf(
    Shop shop,
    List<Item> items,
  ) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogoImage();

    // Get only unpaid items
    final unpaidItems = items.where((i) => !i.isPaid).toList();

    // Calculate total outstanding
    final double total = unpaidItems.fold(
      0.0,
      (sum, item) => sum + item.price,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // Header with Logo
              // ------------------------------------------------
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(right: 12),
                      child: pw.Image(
                        logoImage,
                        width: 42,
                        height: 42,
                      ),
                    ),
                  pw.Column(
                    crossAxisAlignment: logoImage != null
                        ? pw.CrossAxisAlignment.start
                        : pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'UDHAARO',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Know What You Owe',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // ------------------------------------------------
              // Shop Details
              // ------------------------------------------------
              pw.Text(
                'SHOP DETAILS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),

              pw.SizedBox(height: 5),

              pw.Text('Shop Name: ${shop.name}'),

              if (shop.ownerName.isNotEmpty)
                pw.Text('Owner: ${shop.ownerName}'),

              if (shop.phone.isNotEmpty)
                pw.Text('Phone: ${shop.phone}'),

              if (shop.address.isNotEmpty)
                pw.Text('Address: ${shop.address}'),

              pw.SizedBox(height: 15),

              // ------------------------------------------------
              // Unpaid Items
              // ------------------------------------------------
              pw.Text(
                'UNPAID ITEMS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),

              pw.SizedBox(height: 5),

              if (unpaidItems.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  child: pw.Text(
                    'No unpaid items.',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                    ),
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Item Description',
                    'Purchased Date',
                    'Amount',
                  ],
                  data: unpaidItems.map((item) {
                    return [
                      item.name +
                          (item.note.isNotEmpty
                              ? ' (${item.note})'
                              : ''),
                      NepaliDateHelper.formatBsDateEnglish(
                        item.purchaseDate,
                      ),
                      formatPdfNPR(item.price),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF12355B),
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellAlignments: {
                    2: pw.Alignment.centerRight,
                  },
                ),

              pw.Divider(),

              // ------------------------------------------------
              // Total Outstanding
              // ------------------------------------------------
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL OUTSTANDING:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    formatPdfNPR(total),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              pw.Text(
                'Total Items: ${unpaidItems.length}',
              ),

              pw.Text(
                'Generated Date: ${NepaliDateHelper.formatBsDateEnglish(
                  DateTime.now(),
                )}',
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final safeShopName = shop.name
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w\-]'), '');

    final file = File('${output.path}/Udhaaro_$safeShopName.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // ------------------------------------------------------------
  // Generate overall report
  // ------------------------------------------------------------
  static Future<File> generateOverallReport(
    List<Shop> shops,
    List<Item> allItems,
  ) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogoImage();

    double grandTotal = 0;

    final shopDataList = shops.map((shop) {
      final shopUnpaidItems = allItems.where(
        (item) => item.shopId == shop.id && !item.isPaid,
      ).toList();

      final shopTotal = shopUnpaidItems.fold(
        0.0,
        (sum, item) => sum + item.price,
      );

      grandTotal += shopTotal;

      return {
        'shop': shop,
        'count': shopUnpaidItems.length,
        'total': shopTotal,
      };
    }).where((element) {
      return (element['count'] as int) > 0;
    }).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // Header with Logo
              // ------------------------------------------------
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(right: 12),
                      child: pw.Image(
                        logoImage,
                        width: 42,
                        height: 42,
                      ),
                    ),
                  pw.Column(
                    crossAxisAlignment: logoImage != null
                        ? pw.CrossAxisAlignment.start
                        : pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'UDHAARO REPORT',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Know What You Owe',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 15),

              // ------------------------------------------------
              // Shops Table
              // ------------------------------------------------
              if (shopDataList.isEmpty)
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(20),
                    child: pw.Text(
                      'No outstanding credit.',
                      style: const pw.TextStyle(
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Shop Name',
                    'Location / Contact',
                    'Unpaid Items',
                    'Outstanding',
                  ],
                  data: shopDataList.map((data) {
                    final Shop shop = data['shop'] as Shop;

                    return [
                      shop.name,
                      shop.address.isNotEmpty
                          ? shop.address
                          : shop.phone,
                      '${data['count']}',
                      formatPdfNPR(data['total'] as double),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF12355B),
                  ),
                  cellAlignments: {
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                  },
                ),

              pw.Divider(),

              // ------------------------------------------------
              // Grand Total
              // ------------------------------------------------
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'GRAND TOTAL OUTSTANDING:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    formatPdfNPR(grandTotal),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              pw.Text(
                'Report Date: ${NepaliDateHelper.formatBsDateEnglish(
                  DateTime.now(),
                )}',
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Udhaaro_Overall_Report.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // ------------------------------------------------------------
  // Share PDF
  // ------------------------------------------------------------
  static Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Udhaaro Credit Statement PDF',
    );
  }
}