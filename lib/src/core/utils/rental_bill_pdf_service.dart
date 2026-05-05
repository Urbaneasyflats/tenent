import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/app_models.dart';

class RentalBillPdfService {
  RentalBillPdfService._();

  // ── Colors ────────────────────────────────────────────────────────────
  static const PdfColor _blue = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor _blueBand = PdfColor.fromInt(0xFF1E40AF);
  static const PdfColor _green = PdfColor.fromInt(0xFF16A34A);
  static const PdfColor _yellow = PdfColor.fromInt(0xFFCA8A04);
  static const PdfColor _red = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor _stripedRow = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _white = PdfColors.white;

  /// Generate bill PDF bytes matching the structured receipt design.
  static Future<Uint8List> generateBillPdfBytes(BillRecord bill) async {
    final pw.Document document = pw.Document();
    final String generatedDate = _date(DateTime.now());

    final PdfColor statusColor = switch (bill.status) {
      BillStatus.paid => _green,
      BillStatus.overdue => _red,
      _ => _yellow,
    };

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context ctx) => _buildHeader(generatedDate),
        footer: (pw.Context ctx) => _buildFooter(ctx),
        build: (pw.Context ctx) {
          return <pw.Widget>[
            pw.SizedBox(height: 12),

            // ── Status Bar ──────────────────────────────────────────
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: pw.BoxDecoration(
                color: statusColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  _statusText('Status: ${bill.status.label}'),
                  _statusText(
                    'Bill Date: ${bill.billDate != null ? _date(bill.billDate!) : 'N/A'}',
                  ),
                  _statusText(
                    'Amount: Rs.${(bill.finalAmount ?? bill.amount).toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Property Details ────────────────────────────────────
            _sectionTable(
              'PROPERTY DETAILS',
              <List<String>>[
                <String>['Property', bill.propertyTitle ?? bill.title],
                <String>['Flat/Unit No', bill.unitLabel],
              ],
            ),
            pw.SizedBox(height: 12),

            // ── Tenant Information ──────────────────────────────────
            _sectionTable(
              'TENANT INFORMATION',
              <List<String>>[
                <String>['Name', _val(bill.residentName)],
                <String>['Email', _val(bill.residentEmail)],
                <String>['Phone', _val(bill.residentPhone)],
              ],
            ),
            pw.SizedBox(height: 12),

            // ── Owner Information ───────────────────────────────────
            _sectionTable(
              'OWNER INFORMATION',
              <List<String>>[
                <String>['Name', _val(bill.ownerName)],
                <String>['Email', _val(bill.ownerEmail)],
                <String>['Phone', _val(bill.ownerPhone)],
              ],
            ),
            pw.SizedBox(height: 12),

            // ── Bill Breakdown ──────────────────────────────────────
            _sectionTable(
              'BILL BREAKDOWN',
              <List<String>>[
                <String>[
                  'Bill Date',
                  bill.billDate != null ? _date(bill.billDate!) : 'N/A',
                ],
                <String>['Due Date', _date(bill.dueDate)],
                if (bill.rentAmount != null)
                  <String>[
                    'Monthly Rent',
                    'Rs ${bill.rentAmount!.toStringAsFixed(0)}',
                  ],
                if ((bill.maintenanceAmount ?? 0) > 0)
                  <String>[
                    'Maintenance',
                    'Rs ${bill.maintenanceAmount!.toStringAsFixed(0)}',
                  ],
                if ((bill.tokenAmount ?? 0) > 0)
                  <String>[
                    'Token Amount',
                    'Rs ${bill.tokenAmount!.toStringAsFixed(0)}',
                  ],
                if (bill.depositAmount != null)
                  <String>[
                    'Security Deposit',
                    'Rs ${bill.depositAmount!.toStringAsFixed(0)}',
                  ],
                <String>[
                  'Total Amount',
                  'Rs ${(bill.finalAmount ?? bill.amount).toStringAsFixed(0)}',
                ],
              ],
            ),
            pw.SizedBox(height: 12),

            // ── Payment Information ─────────────────────────────────
            _sectionTable(
              'PAYMENT INFORMATION',
              <List<String>>[
                <String>['Payment Status', bill.status.label],
                <String>[
                  'Paid Date',
                  bill.paidDate != null ? _date(bill.paidDate!) : 'N/A',
                ],
                <String>[
                  'Payment Mode',
                  bill.paymentType != null
                      ? _paymentTypeLabel(bill.paymentType!)
                      : 'N/A',
                ],
                if (bill.walletCredited != null)
                  <String>[
                    'Wallet Credit',
                    bill.walletCredited! ? 'Credited' : 'Pending',
                  ],
                if (bill.walletCreditTime != null)
                  <String>[
                    'Credit Initiated',
                    _dateTime(bill.walletCreditTime!),
                  ],
                if (bill.walletCreditedTime != null)
                  <String>[
                    'Credited At',
                    _dateTime(bill.walletCreditedTime!),
                  ],
                if ((bill.paymentNote ?? '').isNotEmpty)
                  <String>['Payment Note', bill.paymentNote!],
              ],
            ),
            pw.SizedBox(height: 12),

            // ── Contract Details ────────────────────────────────────
            if (bill.contractStartDate != null &&
                bill.contractEndDate != null)
              _sectionTable(
                'CONTRACT DETAILS',
                <List<String>>[
                  <String>[
                    'Contract Period',
                    '${_date(bill.contractStartDate!)} to ${_date(bill.contractEndDate!)}',
                  ],
                  if (bill.rentAmount != null)
                    <String>[
                      'Monthly Rent',
                      'Rs ${bill.rentAmount!.toStringAsFixed(0)}',
                    ],
                  if (bill.vacateDate != null)
                    <String>['Vacate Date', _date(bill.vacateDate!)],
                ],
              ),
          ];
        },
      ),
    );

    return document.save();
  }

  /// Generate and share a single bill PDF via the system share sheet.
  static Future<void> shareBillPdf(BillRecord bill) async {
    await Printing.sharePdf(
      bytes: await generateBillPdfBytes(bill),
      filename: 'bill-${bill.id}.pdf',
    );
  }

  /// Generate and share a tabular PDF report for a list of bills.
  static Future<void> shareBillsReportPdf(List<BillRecord> bills) async {
    final pw.Document document = pw.Document();
    final String today = _date(DateTime.now());

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              'Urban Easy Flats — Rental Bills Report',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Generated: $today  |  Total bills: ${bills.length}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 4),
          ],
        ),
        footer: (pw.Context ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (pw.Context ctx) {
          return <pw.Widget>[
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: <int, pw.TableColumnWidth>{
                0: const pw.FixedColumnWidth(24),
                1: const pw.FlexColumnWidth(2.0),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(2.0),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.5),
                6: const pw.FlexColumnWidth(1.8),
                7: const pw.FlexColumnWidth(1.8),
              },
              children: <pw.TableRow>[
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: <pw.Widget>[
                    _cell('#', bold: true),
                    _cell('Property / Unit', bold: true),
                    _cell('Tenant', bold: true),
                    _cell('Owner', bold: true),
                    _cell('Due Date', bold: true),
                    _cell('Amount (Rs)', bold: true),
                    _cell('Status', bold: true),
                    _cell('Paid Date', bold: true),
                  ],
                ),
                ...bills.asMap().entries.map(
                  (MapEntry<int, BillRecord> entry) {
                    final BillRecord b = entry.value;
                    return pw.TableRow(
                      children: <pw.Widget>[
                        _cell('${entry.key + 1}'),
                        _cell(
                          '${b.propertyTitle ?? b.societyName ?? '-'}\n${b.unitLabel}',
                        ),
                        _cell(
                          b.residentName ?? '-',
                        ),
                        _cell(b.ownerName ?? '-'),
                        _cell(_date(b.dueDate)),
                        _cell(
                          (b.finalAmount ?? b.amount).toStringAsFixed(0),
                        ),
                        _cell(b.status.label),
                        _cell(
                          b.paidDate != null ? _date(b.paidDate!) : '-',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'Rental_Bills_Report_$today.pdf',
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────

  static pw.Widget _buildHeader(String generatedDate) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          'Rental Bill Receipt',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: <pw.Widget>[
            pw.Text(
              'UrbanEasyFlats',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _blue,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Generated: $generatedDate',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text(
          'UrbanEasyFlats | Rental Bill Receipt',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
        pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }

  static pw.Widget _statusText(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: _white,
      ),
    );
  }

  /// Section table with a colored header band and alternating striped rows.
  static pw.Widget _sectionTable(String title, List<List<String>> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        // Header band
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _blueBand,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(3),
              topRight: pw.Radius.circular(3),
            ),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _white,
            ),
          ),
        ),
        // Data rows
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: <int, pw.TableColumnWidth>{
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(3.0),
          },
          children: rows.asMap().entries.map(
            (MapEntry<int, List<String>> entry) {
              final bool isEven = entry.key.isEven;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? _stripedRow : _white,
                ),
                children: <pw.Widget>[
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      entry.value[0],
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      entry.value[1],
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              );
            },
          ).toList(),
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Return value or 'N/A' when null or blank.
  static String _val(String? value) =>
      (value != null && value.trim().isNotEmpty) ? value : 'N/A';

  static String _paymentTypeLabel(int value) {
    return switch (value) {
      1 => 'Cash',
      2 => 'Online',
      3 => 'Manual Online',
      _ => 'Other',
    };
  }

  static String _date(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _dateTime(DateTime value) {
    final String h = value.hour.toString().padLeft(2, '0');
    final String m = value.minute.toString().padLeft(2, '0');
    return '${_date(value)} $h:$m';
  }
}
