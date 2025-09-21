import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/user_provider.dart';

class ReceiptService {
  static Future<void> generateAndDownloadReceipt(
    BuildContext context, 
    Order order, 
    String deliveryAddress, 
    String paymentMethod
  ) async {
    try {
      // Request proper storage permission based on Android version
      await _requestStoragePermission();
      
      // Get current user name
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userName = userProvider.user?.name ?? 'Customer';
      
      // Generate PDF
      final pdf = await _generateReceiptPDF(order, deliveryAddress, paymentMethod, userName);
      
      // Save to device
      final file = await _savePDFToDevice(pdf, order.id);
      
      // Show success message and share option
      await _showReceiptOptions(file, order.id);
      
    } catch (e) {
      throw Exception('Failed to generate receipt: $e');
    }
  }

  static Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ (API 33+) - Request specific media permissions
        final status = await [
          Permission.photos,
          Permission.videos,
          Permission.mediaLibrary,
        ].request();
        
        bool allGranted = status.values.every((status) => 
          status == PermissionStatus.granted || status == PermissionStatus.limited);
        
        if (!allGranted) {
          // Fallback: try to save to app-specific directory which doesn't need permissions
          return;
        }
      } else if (androidInfo.version.sdkInt >= 30) {
        // Android 11-12 (API 30-32) - Use MANAGE_EXTERNAL_STORAGE for broad access
        var status = await Permission.manageExternalStorage.status;
        if (status.isDenied) {
          status = await Permission.manageExternalStorage.request();
          if (status.isDenied) {
            // Fallback to app-specific directory
            return;
          }
        }
      } else {
        // Android 10 and below - Use legacy storage permission
        var status = await Permission.storage.status;
        if (status.isDenied) {
          status = await Permission.storage.request();
          if (status.isDenied) {
            throw Exception('Storage permission is required to save receipt');
          }
        }
      }
    }
  }

  static Future<pw.Document> _generateReceiptPDF(
    Order order, 
    String deliveryAddress, 
    String paymentMethod, 
    String userName
  ) async {
    final pdf = pw.Document();
    
    // Load logo if available
    Uint8List? logoBytes;
    try {
      final ByteData logoData = await rootBundle.load('assets/images/logo.png');
      logoBytes = logoData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Logo not found: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header with logo and company info
            _buildHeader(logoBytes, paymentMethod),
            
            pw.SizedBox(height: 30),
            
            // Receipt title
            _buildReceiptTitle(order),
            
            pw.SizedBox(height: 20),
            
            // Customer info
            _buildCustomerInfo(userName),
            
            pw.SizedBox(height: 20),
            
            // Order details
            _buildOrderDetails(order, deliveryAddress, paymentMethod),
            
            pw.SizedBox(height: 30),
            
            // Items table
            _buildItemsTable(order),
            
            pw.SizedBox(height: 30),
            
            // Total section
            _buildTotalSection(order),
            
            pw.SizedBox(height: 40),
            
            // Footer
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(Uint8List? logoBytes, String paymentMethod) {
    // Determine payment status based on payment method
    final bool isPaid = paymentMethod.toLowerCase() != 'cash on delivery';
    final String paymentStatus = isPaid ? 'PAID' : 'PENDING';
    final PdfColor statusColor = isPaid ? PdfColors.green : PdfColors.orange;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoBytes != null)
                pw.Image(
                  pw.MemoryImage(logoBytes),
                  width: 60,
                  height: 60,
                ),
              pw.SizedBox(height: 10),
              pw.Text(
                'MediScan Pharmacy',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'Your Health, Our Priority',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '20 Dubai Street, Thiruvandarkoil',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Puducherry 605107',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'RECEIPT',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: statusColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Text(
                  paymentStatus,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (!isPaid) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.orange200),
                  ),
                  child: pw.Text(
                    'Payment due on delivery',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.orange700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReceiptTitle(Order order) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Center(
        child: pw.Text(
          'Order Confirmation Receipt',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildCustomerInfo(String userName) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildDetailRow('Customer Name', userName),
        ],
      ),
    );
  }

  static pw.Widget _buildOrderDetails(Order order, String deliveryAddress, String paymentMethod) {
    final now = DateTime.now();
    final bool isPaid = paymentMethod.toLowerCase() != 'cash on delivery';
    
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Order Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'Date: ${now.day}/${now.month}/${now.year}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          _buildDetailRow('Order ID', '#${order.id.substring(0, 8).toUpperCase()}'),
          _buildDetailRow('Status', order.status),
          _buildDetailRow('Payment Method', paymentMethod),
          _buildDetailRow('Payment Status', isPaid ? 'Paid' : 'Pending (Cash on Delivery)'),
          _buildDetailRow('Delivery Address', deliveryAddress),
          _buildDetailRow('Order Date', '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}'),
          _buildDetailRow('Expected Delivery', '${now.add(const Duration(days: 3)).day}/${now.add(const Duration(days: 3)).month}/${now.add(const Duration(days: 3)).year}'),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Text(': '),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(Order order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Order Items',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Medicine Name', isHeader: true),
                _buildTableCell('Qty', isHeader: true),
                _buildTableCell('Unit Price', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            // Item rows
            ...order.items.map((item) => pw.TableRow(
              children: [
                _buildTableCell(item.medicine.name),
                _buildTableCell(item.quantity.toString()),
                _buildTableCell('₹${item.medicine.price.toStringAsFixed(2)}'),
                _buildTableCell('₹${(item.medicine.price * item.quantity).toStringAsFixed(2)}'),
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildTotalSection(Order order) {
    final subtotal = order.totalPrice;
    final deliveryFee = 50.0; // Assuming fixed delivery fee
    final tax = subtotal * 0.05; // 5% tax
    final discount = 0.0; // No discount for now
    final finalTotal = subtotal + deliveryFee + tax - discount;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        children: [
          _buildTotalRow('Subtotal', '₹ ${subtotal.toStringAsFixed(2)}'),
          _buildTotalRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(2)}'),
          _buildTotalRow('Tax (5%)', '₹${tax.toStringAsFixed(2)}'),
          if (discount > 0)
            _buildTotalRow('Discount', '-₹${discount.toStringAsFixed(2)}', color: PdfColors.red),
          pw.Divider(color: PdfColors.grey400, thickness: 1),
          _buildTotalRow('Total Amount', '₹${finalTotal.toStringAsFixed(2)}', 
                        isFinal: true, color: PdfColors.green),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isFinal = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isFinal ? 14 : 12,
              fontWeight: isFinal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isFinal ? 16 : 12,
              fontWeight: isFinal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Thank you for choosing MediScan Pharmacy!',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Contact Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Phone: +91 9786001567 | Email: support@mediscan.com',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'Address: 20 Dubai Street, Thiruvandarkoil, Puducherry 605107',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'For any queries regarding your order, please contact us within 7 days.',
            style: pw.TextStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Generated on: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  static Future<File> _savePDFToDevice(pw.Document pdf, String orderId) async {
    final bytes = await pdf.save();
    
    // Get the appropriate directory based on platform and permissions
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        // Try external storage first (Downloads folder)
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage directory
          directory = await getExternalStorageDirectory();
          if (directory == null) {
            // Final fallback to app documents directory
            directory = await getApplicationDocumentsDirectory();
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      // Create MediCare folder if possible
      Directory? medicareDir;
      try {
        medicareDir = Directory('${directory!.path}/MediScan');
        if (!await medicareDir.exists()) {
          await medicareDir.create(recursive: true);
        }
      } catch (e) {
        // If we can't create MediCare folder, use the main directory
        medicareDir = directory;
      }
      
      // Create file
      final fileName = 'Receipt_${orderId.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${medicareDir!.path}/$fileName');
      
      // Write PDF bytes to file
      await file.writeAsBytes(bytes);
      
      return file;
    } catch (e) {
      // If everything fails, save to app documents directory
      directory = await getApplicationDocumentsDirectory();
      final fileName = 'Receipt_${orderId.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    }
  }

  static Future<void> _showReceiptOptions(File file, String orderId) async {
    // Share the file and show success message
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Order Receipt #${orderId.substring(0, 8).toUpperCase()}\nSaved to: ${file.path}',
      subject: 'MediScan Pharmacy - Order Receipt',
    );
  }

  // Method to preview receipt before download
  static Future<Uint8List> generateReceiptPreview(
    Order order, 
    String deliveryAddress, 
    String paymentMethod, 
    String userName
  ) async {
    final pdf = await _generateReceiptPDF(order, deliveryAddress, paymentMethod, userName);
    return await pdf.save();
  }
}