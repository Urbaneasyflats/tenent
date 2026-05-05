import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/rental_contract_service.dart';
import '../../core/api/upload_service.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/pdf_saver.dart';
import '../../core/utils/rental_contract_pdf_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class TenantContractsPage extends StatefulWidget {
  const TenantContractsPage({super.key});

  @override
  State<TenantContractsPage> createState() => _TenantContractsPageState();
}

class _TenantContractsPageState extends State<TenantContractsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  String _search = '';
  int _statusIndex = 0;
  List<RentalContractRecord> _contracts = <RentalContractRecord>[];

  int get _activeCount => _contracts
      .where(
        (RentalContractRecord contract) =>
            contract.status == ContractStatus.active,
      )
      .length;

  int get _pendingRenewalCount => _contracts
      .where((RentalContractRecord contract) => _isPendingRenewal(contract))
      .length;

  int get _expiredCount => _contracts
      .where(
        (RentalContractRecord contract) =>
            contract.status == ContractStatus.expired ||
            contract.endDate.isBefore(DateTime.now()),
      )
      .length;

  double get _totalRent => _contracts.fold<double>(
        0,
        (double sum, RentalContractRecord contract) => sum + contract.rent,
      );

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  bool _isPendingRenewal(RentalContractRecord contract) {
    if (contract.status != ContractStatus.active) {
      return false;
    }
    final int daysLeft = contract.endDate.difference(DateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= 30;
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final bool? active = _statusIndex == 1 ? true : _statusIndex == 2 ? false : null;
      final result = await RentalContractService.filterTenantRentalContracts(
        active: active,
        search: _search.isEmpty ? null : _search,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _contracts = result.contracts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openVacateSheet(RentalContractRecord contract) async {
    DateTime? selected = contract.vacateDate;
    bool saving = false;
    bool sheetClosed = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          void safeSetModalState(VoidCallback callback) {
            if (!mounted || sheetClosed) {
              return;
            }
            setModalState(callback);
          }

          Future<void> pickDate() async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selected ?? DateTime.now(),
              firstDate: contract.startDate,
              lastDate: contract.endDate,
            );
            if (picked != null) {
              safeSetModalState(() => selected = picked);
            }
          }

          Future<void> submit() async {
            if (selected == null) {
              _showMessage('Select a vacate date.');
              return;
            }
            safeSetModalState(() => saving = true);
            try {
              await RentalContractService.markReadyToVacate(
                contract.id,
                _serverDate(selected!),
              );
              if (!mounted || sheetClosed) return;
              sheetClosed = true;
              Navigator.of(context).pop();
              _showMessage('Ready-to-vacate request submitted.');
              await _loadContracts();
            } catch (error) {
              _showMessage(error.toString().replaceFirst('Exception: ', ''));
              safeSetModalState(() => saving = false);
            }
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Ready To Vacate', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('Contract period: ${formatCompactDate(contract.startDate)} to ${formatCompactDate(contract.endDate)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  CustomCard(
                    padding: CustomCardPadding.sm,
                    child: Text(selected == null ? 'No date selected' : 'Vacate on ${formatCompactDate(selected!)}'),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(label: 'Pick Date', variant: CustomButtonVariant.outline, onPressed: pickDate),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(child: CustomButton(label: 'Cancel', variant: CustomButtonVariant.outline, onPressed: saving ? null : () => Navigator.of(context).pop())),
                      const SizedBox(width: 12),
                      Expanded(child: CustomButton(label: 'Confirm', isLoading: saving, onPressed: saving ? null : submit)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      sheetClosed = true;
    });
  }

  Future<void> _openDocumentsSheet(RentalContractRecord contract) async {
    File? idFile;
    File? addressFile;
    bool saving = false;
    bool sheetClosed = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          void safeSetModalState(VoidCallback callback) {
            if (!mounted || sheetClosed) {
              return;
            }
            setModalState(callback);
          }

          Future<void> pick(bool isId) async {
            final FilePickerResult? result = await FilePicker.platform.pickFiles(
              allowMultiple: false,
              type: FileType.custom,
              allowedExtensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
            );
            if (result == null || result.files.single.path == null) return;
            safeSetModalState(() {
              if (isId) {
                idFile = File(result.files.single.path!);
              } else {
                addressFile = File(result.files.single.path!);
              }
            });
          }

          Future<void> submit() async {
            if (idFile == null && addressFile == null) {
              _showMessage('Pick at least one document.');
              return;
            }
            safeSetModalState(() => saving = true);
            try {
              String idDocId = contract.tenantIdProof?.documentId ?? '';
              String addressDocId =
                  contract.tenantAddressProof?.documentId ?? '';
              if (idFile != null) {
                idDocId = await UploadService.uploadDocument(idFile!) ?? '';
              }
              if (addressFile != null) {
                addressDocId = await UploadService.uploadDocument(addressFile!) ?? '';
              }
              if (idFile != null && idDocId.isEmpty) {
                throw Exception('Failed to upload tenant ID proof.');
              }
              if (addressFile != null && addressDocId.isEmpty) {
                throw Exception('Failed to upload tenant address proof.');
              }
              await RentalContractService.updateTenantDocuments(
                contractId: contract.id,
                whetherTenantIdProofAvailable: idDocId.isNotEmpty,
                tenantIdProofDocumentId: idDocId,
                whetherTenantAddressProofAvailable: addressDocId.isNotEmpty,
                tenantAddressProofDocumentId: addressDocId,
              );
              if (!mounted || sheetClosed) return;
              sheetClosed = true;
              Navigator.of(context).pop();
              _showMessage('Tenant documents updated successfully.');
              await _loadContracts();
            } catch (error) {
              _showMessage(error.toString().replaceFirst('Exception: ', ''));
              safeSetModalState(() => saving = false);
            }
          }

          Widget picker(String label, File? file, String? existing, VoidCallback onPick, VoidCallback? onClear) {
            return CustomCard(
              padding: CustomCardPadding.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    file != null ? file.path.split(Platform.pathSeparator).last : (existing?.isNotEmpty ?? false) ? 'Current: $existing' : 'No document selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: file != null ? AppTheme.toneColor(UiTone.success) : AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(child: CustomButton(label: file == null ? 'Choose File' : 'Replace', variant: CustomButtonVariant.outline, onPressed: onPick)),
                      if (onClear != null) ...<Widget>[
                        const SizedBox(width: 10),
                        Expanded(child: CustomButton(label: 'Clear', variant: CustomButtonVariant.danger, onPressed: onClear)),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 24),
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  Text('Update Tenant Documents', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('Upload KYC documents for ${contract.propertyTitle}.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  picker('Tenant ID Proof', idFile, contract.tenantIdProof?.documentName, () => pick(true), idFile == null ? null : () => safeSetModalState(() => idFile = null)),
                  const SizedBox(height: 12),
                  picker('Tenant Address Proof', addressFile, contract.tenantAddressProof?.documentName, () => pick(false), addressFile == null ? null : () => safeSetModalState(() => addressFile = null)),
                  const SizedBox(height: 12),
                  Text('Accepted formats: PDF, JPG, JPEG, PNG', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted)),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(child: CustomButton(label: 'Cancel', variant: CustomButtonVariant.outline, onPressed: saving ? null : () => Navigator.of(context).pop())),
                      const SizedBox(width: 12),
                      Expanded(child: CustomButton(label: 'Upload', isLoading: saving, onPressed: saving ? null : submit)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      sheetClosed = true;
    });
  }

  Future<void> _openDocument(ContractDocumentRecord document) async {
    final bool launched = await launchUrl(Uri.parse(document.documentUrl), mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showMessage('Unable to open ${document.documentName}.');
    }
  }

  Future<void> _shareContractPdf(RentalContractRecord contract) async {
    try {
      final bytes = await RentalContractPdfService.generateContractPdfBytes(contract);
      if (!mounted) return;
      await PdfSaver.saveAndOffer(
        context,
        bytes: bytes,
        filename: 'rental-contract-${contract.id}.pdf',
      );
    } catch (error) {
      _showMessage('Unable to generate the contract PDF.');
    }
  }

  void _showDetails(RentalContractRecord contract) {
    Widget docTile(String title, ContractDocumentRecord? document) {
      final bool available = document != null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: CustomCard(
          color: available ? AppTheme.toneSoft(UiTone.success) : AppTheme.surfaceMuted,
          borderColor: available ? AppTheme.toneColor(UiTone.success).withValues(alpha: 0.2) : AppTheme.border,
          padding: CustomCardPadding.sm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: <Widget>[Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))), ToneBadge(label: available ? 'Uploaded' : 'Not Uploaded', tone: available ? UiTone.success : UiTone.warning)]),
              if (available) ...<Widget>[
                const SizedBox(height: 8),
                Text(document.documentName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: CustomButton(label: 'View Document', variant: CustomButtonVariant.outline, onPressed: () => _openDocument(document))),
              ],
            ],
          ),
        ),
      );
    }

    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: 112, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500))),
              Expanded(child: Text(value)),
            ],
          ),
        );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(contract.propertyTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                line('Tenant', contract.tenantName),
                line('Tenant Email', contract.tenantEmail ?? 'N/A'),
                line('Tenant Phone', contract.tenantPhone ?? 'N/A'),
                line('Owner', contract.ownerName),
                line('Owner Email', contract.ownerEmail ?? 'N/A'),
                line('Owner Phone', contract.ownerPhone ?? 'N/A'),
                line('Owner Address', contract.ownerAddress ?? 'N/A'),
                line('Period', '${formatCompactDate(contract.startDate)} to ${formatCompactDate(contract.endDate)}'),
                line('Status', contract.status.label),
                line('Rent', 'Rs ${contract.rent.toStringAsFixed(0)}'),
                line('Deposit', 'Rs ${contract.deposit.toStringAsFixed(0)}'),
                if (contract.tokenAmount != null) line('Token Amount', 'Rs ${contract.tokenAmount!.toStringAsFixed(0)}'),
                if (contract.maintenanceAmount != null) line('Maintenance', 'Rs ${contract.maintenanceAmount!.toStringAsFixed(0)}'),
                if (contract.billDay != null) line('Bill Day', '${contract.billDay}'),
                if (contract.vacateDate != null) line('Vacate Date', formatCompactDate(contract.vacateDate!)),
                if ((contract.specialTerms ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('Special Terms', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(contract.specialTerms!),
                ],
                const SizedBox(height: 16),
                Text('KYC Documents', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                docTile('Tenant ID Proof', contract.tenantIdProof),
                docTile('Tenant Address Proof', contract.tenantAddressProof),
                docTile('Owner ID Proof', contract.ownerIdProof),
                docTile('Owner Ownership Proof', contract.ownerPropertyOwnershipProof),
                docTile('Owner Bank Proof', contract.ownerBankProof),
              ],
            ),
          ),
        ),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('My Rental Contracts'),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, thickness: 1, color: AppTheme.border)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadContracts,
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            const PageHeader(title: 'My Rental Contracts', description: 'Tenant-side contract list with ready-to-vacate, KYC document upload, and detailed document visibility aligned to the website flow.'),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: <Widget>[
                _SummaryCard(
                  label: 'Active',
                  value: '$_activeCount',
                  tone: UiTone.success,
                ),
                _SummaryCard(
                  label: 'Due Soon',
                  value: '$_pendingRenewalCount',
                  tone: UiTone.warning,
                ),
                _SummaryCard(
                  label: 'Expired',
                  value: '$_expiredCount',
                  tone: UiTone.danger,
                ),
                _SummaryCard(
                  label: 'Total Rent',
                  value: 'Rs ${_totalRent.toStringAsFixed(0)}',
                  tone: UiTone.brand,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Search contract'),
              onChanged: (String value) => _search = value.trim(),
              onSubmitted: (_) => _loadContracts(),
            ),
            const SizedBox(height: 16),
            CustomTabBar(
              style: CustomTabBarStyle.pill,
              currentIndex: _statusIndex,
              onChanged: (int index) {
                setState(() => _statusIndex = index);
                _loadContracts();
              },
              tabs: const <CustomTabItem>[CustomTabItem(label: 'All'), CustomTabItem(label: 'Active'), CustomTabItem(label: 'Inactive')],
            ),
            const SizedBox(height: 16),
            Text('My Contracts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 64), child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              CustomCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text('Unable to load contracts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  CustomButton(label: 'Retry', icon: const Icon(Icons.refresh_rounded), onPressed: _loadContracts),
                ]),
              )
            else if (_contracts.isEmpty)
              const CustomCard(child: Text('No rental contracts found.'))
            else
              ..._contracts.map((RentalContractRecord contract) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomCard(
                      padding: CustomCardPadding.sm,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Row(children: <Widget>[Expanded(child: Text(contract.propertyTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))), ToneBadge(label: contract.status.label, tone: contract.status.tone)]),
                        const SizedBox(height: 8),
                        Text('${contract.flatNo ?? 'Unit'} | ${contract.ownerName}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            ToneBadge(label: 'Rent Rs ${contract.rent.toStringAsFixed(0)}', tone: UiTone.neutral),
                            ToneBadge(label: '${formatCompactDate(contract.startDate)} – ${formatCompactDate(contract.endDate)}', tone: UiTone.brand),
                            if (_isPendingRenewal(contract))
                              ToneBadge(label: 'Renews in ${contract.endDate.difference(DateTime.now()).inDays}d', tone: UiTone.warning),
                            if (contract.vacateDate != null) ToneBadge(label: 'Vacating ${formatCompactDate(contract.vacateDate!)}', tone: UiTone.warning),
                            ToneBadge(label: contract.tenantIdProof == null && contract.tenantAddressProof == null ? 'KYC Pending' : 'KYC Updated', tone: contract.tenantIdProof == null && contract.tenantAddressProof == null ? UiTone.warning : UiTone.success),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(children: <Widget>[
                          Expanded(child: CustomButton(label: 'View Details', variant: CustomButtonVariant.outline, onPressed: () => _showDetails(contract))),
                          const SizedBox(width: 10),
                          Expanded(child: CustomButton(label: 'Download PDF', variant: CustomButtonVariant.outline, onPressed: () => _shareContractPdf(contract))),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: <Widget>[
                          Expanded(child: CustomButton(label: 'Update Documents', variant: CustomButtonVariant.outline, onPressed: () => _openDocumentsSheet(contract))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                              label: contract.status == ContractStatus.readyToVacate ? 'Vacate Pending' : 'Ready To Vacate',
                              onPressed: contract.status == ContractStatus.readyToVacate ? null : () => _openVacateSheet(contract),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  String _serverDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: CustomCardPadding.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ToneBadge(label: label, tone: tone, size: ToneBadgeSize.small),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
