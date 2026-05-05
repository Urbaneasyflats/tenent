import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_models.dart';

class SocietyBillsExcelService {
  SocietyBillsExcelService._();

  static Future<void> exportToExcel({
    required List<BillRecord> bills,
    double pendingAmount = 0,
    double collectedAmount = 0,
    double overdueAmount = 0,
    double todayCollection = 0,
    double monthCollection = 0,
    double monthOverdue = 0,
    double monthPending = 0,
  }) async {
    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel['Bills'];

    // ── Header ──────────────────────────────────────────────────────────────
    final String today = _dateLabel(DateTime.now());
    _addRow(sheet, <String>[
      'Society Bills Export',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'Generated: $today',
    ]);
    _addRow(sheet, <String>[]);

    // ── Summary section ──────────────────────────────────────────────────────
    _addRow(sheet, <String>['Summary', '', '', '', '', '', '', '', '', '', '']);
    _addRow(sheet, <String>[
      'Total Pending',
      'Rs ${pendingAmount.toStringAsFixed(0)}',
      '',
      'Total Collected',
      'Rs ${collectedAmount.toStringAsFixed(0)}',
      '',
      'Total Overdue',
      'Rs ${overdueAmount.toStringAsFixed(0)}',
      '',
      '',
      '',
    ]);
    _addRow(sheet, <String>[
      "Today's Collection",
      'Rs ${todayCollection.toStringAsFixed(0)}',
      '',
      'Month Collection',
      'Rs ${monthCollection.toStringAsFixed(0)}',
      '',
      'Month Overdue',
      'Rs ${monthOverdue.toStringAsFixed(0)}',
      '',
      'Month Pending',
      'Rs ${monthPending.toStringAsFixed(0)}',
    ]);
    _addRow(sheet, <String>[]);

    // ── Column headers ───────────────────────────────────────────────────────
    _addRow(sheet, <String>[
      'Flat / Unit',
      'Resident',
      'Resident Type',
      'Block',
      'Building',
      'Bill Type',
      'Amount (Rs)',
      'Due Date',
      'Status',
      'Paid Date',
      'Payment Mode',
    ]);

    // ── Data rows ────────────────────────────────────────────────────────────
    for (final BillRecord bill in bills) {
      _addRow(sheet, <String>[
        bill.unitLabel,
        bill.residentName ?? '-',
        bill.residentTypeLabel ?? '-',
        bill.blockName ?? '-',
        bill.buildingName ?? '-',
        bill.category,
        (bill.finalAmount ?? bill.amount).toStringAsFixed(0),
        _dateLabel(bill.dueDate),
        bill.status.label,
        bill.paidDate != null ? _dateLabel(bill.paidDate!) : '-',
        _paymentModeLabel(bill.paymentType, bill.manualOnlinePaymentMode),
      ]);
    }

    // ── Save & share ─────────────────────────────────────────────────────────
    final List<int>? bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file.');
    }

    final Directory dir = await getTemporaryDirectory();
    final String filename =
        'Society_Bills_${today.replaceAll(' ', '_')}.xlsx';
    final File file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      <XFile>[XFile(file.path)],
      text: 'Society Bills Export — $today',
    );
  }

  static void _addRow(Sheet sheet, List<String> values) {
    sheet.appendRow(
      values.map((String v) => TextCellValue(v)).toList(),
    );
  }

  static String _dateLabel(DateTime date) {
    final List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _paymentModeLabel(int? paymentType, int? manualMode) {
    if (paymentType == 1) return 'Cash';
    if (paymentType == 2) return 'Online (Razorpay)';
    if (paymentType == 3) {
      return switch (manualMode) {
        1 => 'UPI',
        2 => 'Net Banking',
        3 => 'Credit/Debit Card',
        4 => 'Wallet',
        5 => 'NEFT',
        6 => 'IMPS',
        7 => 'RTGS',
        8 => 'Cash Deposit',
        9 => 'Bank Transfer',
        10 => 'Other',
        _ => 'Manual Online',
      };
    }
    return '-';
  }
}
