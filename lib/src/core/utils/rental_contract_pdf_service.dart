import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/app_models.dart';

class RentalContractPdfService {
  RentalContractPdfService._();

  /// Generate contract PDF bytes without sharing.
  static Future<Uint8List> generateContractPdfBytes(
    RentalContractRecord contract,
  ) async {
    final pw.Document document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(
              'Urban Easy Flats Rental Contract',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Property: ${contract.propertyTitle}'),
            pw.Text('Status: ${contract.status.label}'),
            pw.SizedBox(height: 16),
            _section(
              'Tenant Information',
              <List<String>>[
                <String>['Name', contract.tenantName],
                <String>['Email', contract.tenantEmail ?? 'N/A'],
                <String>['Phone', contract.tenantPhone ?? 'N/A'],
              ],
            ),
            _section(
              'Owner Information',
              <List<String>>[
                <String>['Name', contract.ownerName],
                <String>['Email', contract.ownerEmail ?? 'N/A'],
                <String>['Phone', contract.ownerPhone ?? 'N/A'],
                <String>['Address', contract.ownerAddress ?? 'N/A'],
              ],
            ),
            _section(
              'Contract Details',
              <List<String>>[
                <String>['Flat / Unit', contract.flatNo ?? 'N/A'],
                <String>['Start Date', _date(contract.startDate)],
                <String>['End Date', _date(contract.endDate)],
                <String>[
                  'Vacate Date',
                  contract.vacateDate == null ? 'N/A' : _date(contract.vacateDate!),
                ],
                <String>['Property ID', contract.propertyId ?? 'N/A'],
              ],
            ),
            _section(
              'Financial Details',
              <List<String>>[
                <String>['Monthly Rent', 'Rs ${contract.rent.toStringAsFixed(0)}'],
                <String>['Security Deposit', 'Rs ${contract.deposit.toStringAsFixed(0)}'],
                <String>[
                  'Token Amount',
                  contract.tokenAmount == null
                      ? 'N/A'
                      : 'Rs ${contract.tokenAmount!.toStringAsFixed(0)}',
                ],
                <String>[
                  'Maintenance',
                  contract.maintenanceAmount == null
                      ? 'N/A'
                      : 'Rs ${contract.maintenanceAmount!.toStringAsFixed(0)}',
                ],
                <String>['Bill Day', contract.billDay?.toString() ?? 'N/A'],
              ],
            ),
            if ((contract.specialTerms ?? '').isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(
                    'Special Terms',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(contract.specialTerms!),
                  pw.SizedBox(height: 16),
                ],
              ),
            _section(
              'KYC Documents',
              <List<String>>[
                <String>[
                  'Tenant ID Proof',
                  _docLabel(contract.tenantIdProof),
                ],
                <String>[
                  'Tenant Address Proof',
                  _docLabel(contract.tenantAddressProof),
                ],
                <String>[
                  'Owner ID Proof',
                  _docLabel(contract.ownerIdProof),
                ],
                <String>[
                  'Owner Ownership Proof',
                  _docLabel(contract.ownerPropertyOwnershipProof),
                ],
                <String>[
                  'Owner Bank Proof',
                  _docLabel(contract.ownerBankProof),
                ],
              ],
            ),
          ];
        },
      ),
    );

    return document.save();
  }

  /// Generate and share a contract PDF via the system share sheet.
  static Future<void> shareContractPdf(RentalContractRecord contract) async {
    await Printing.sharePdf(
      bytes: await generateContractPdfBytes(contract),
      filename: 'rental-contract-${contract.id}.pdf',
    );
  }

  static pw.Widget _section(String title, List<List<String>> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        ...rows.map(
          (List<String> row) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.SizedBox(
                  width: 130,
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(child: pw.Text(row[1])),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static String _date(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _docLabel(ContractDocumentRecord? document) {
    if (document == null) {
      return 'Not uploaded';
    }
    return '${document.documentName} (${document.documentUrl})';
  }
}
