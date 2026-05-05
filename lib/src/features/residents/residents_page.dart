import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/block_building_service.dart';
import '../../core/api/razorpay_checkout_service.dart';
import '../../core/api/society_service.dart';
import '../../core/api/vendor_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class ResidentsPage extends StatefulWidget {
  const ResidentsPage({super.key});

  @override
  State<ResidentsPage> createState() => _ResidentsPageState();
}

class _ResidentsPageState extends State<ResidentsPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  static const int _pageSize = 10;

  bool _isLoading = true;
  String? _errorMessage;
  String _societyId = '';
  bool? _statusFilter;
  int? _residentTypeFilter;
  String _blockFilter = '';
  String _buildingFilter = '';
  int _skip = 0;
  int _totalCount = 0;
  SocietyData? _societyInfo;
  List<BlockData> _blocks = <BlockData>[];
  List<BuildingData> _buildings = <BuildingData>[];
  List<ResidentRecord> _residents = <ResidentRecord>[];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final VendorData? vendor = await VendorService.fetchVendorInfo();
      final String societyId = vendor?.societyId ?? '';
      if (societyId.isEmpty) {
        throw Exception('Society information is not available for this user.');
      }

      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        BlockBuildingService.filterBlocks(societyId),
        BlockBuildingService.filterBuildings(societyId),
        SocietyService.filterResidents(
          societyId: societyId,
          skip: _skip,
          limit: _pageSize,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          statusFilter: _statusFilter,
          blockId: _blockFilter.isEmpty ? null : _blockFilter,
          buildingId: _buildingFilter.isEmpty ? null : _buildingFilter,
          residentType: _residentTypeFilter,
        ),
        SocietyService.fetchSocietyInfo(),
      ]);

      if (!mounted) {
        return;
      }

      final blocksResult = results[0] as ({List<BlockData> blocks, int count});
      final buildingsResult =
          results[1] as ({List<BuildingData> buildings, int count});
      final residentsResult =
          results[2] as ({List<ResidentRecord> residents, int count});
      final SocietyData? societyInfo = results[3] as SocietyData?;

      setState(() {
        _societyId = societyId;
        _societyInfo = societyInfo;
        _blocks = blocksResult.blocks.where((BlockData item) => item.status).toList();
        _buildings = buildingsResult.buildings
            .where((BuildingData item) => item.status)
            .toList();
        _residents = residentsResult.residents;
        _totalCount = residentsResult.count;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleResident(ResidentRecord resident) async {
    try {
      if (resident.status) {
        await SocietyService.inactivateResident(resident.id);
      } else {
        await SocietyService.activateResident(resident.id);
      }
      _showMessage('Resident status updated.');
      await _loadAll();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openResidentSlotsSheet({required bool renewal}) async {
    if (_societyId.isEmpty) {
      _showMessage('Society information is not available yet.');
      return;
    }

    final int initialCount = renewal
        ? ((_societyInfo?.totalResidentsCreationCount ?? _residents.length) > 0
            ? (_societyInfo?.totalResidentsCreationCount ?? _residents.length)
            : 1)
        : 1;
    final TextEditingController countController = TextEditingController(
      text: '$initialCount',
    );
    SocietyResidentsCalculationData? calculation;
    String? errorMessage;
    bool calculating = false;
    bool purchasing = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            int parseCount() {
              return int.tryParse(countController.text.trim()) ?? 0;
            }

            Future<void> calculate() async {
              final int count = parseCount();
              if (count < 1) {
                setModalState(() {
                  errorMessage = 'Enter at least one resident slot.';
                });
                return;
              }

              setModalState(() {
                calculating = true;
                errorMessage = null;
              });

              try {
                final SocietyResidentsCalculationData result = renewal
                    ? await SocietyService.calculateResidentsRenewal(
                        societyId: _societyId,
                        numberOfResidents: count,
                      )
                    : await SocietyService.calculateResidents(
                        societyId: _societyId,
                        numberOfResidents: count,
                      );
                if (!mounted) {
                  return;
                }
                setModalState(() {
                  calculation = result;
                });
              } catch (error) {
                setModalState(() {
                  errorMessage =
                      error.toString().replaceFirst('Exception: ', '');
                });
              } finally {
                if (mounted) {
                  setModalState(() {
                    calculating = false;
                  });
                }
              }
            }

            Future<void> purchase() async {
              if (calculation == null) {
                await calculate();
                if (calculation == null) {
                  return;
                }
              }

              final int count = parseCount();
              setModalState(() {
                purchasing = true;
                errorMessage = null;
              });

              try {
                final SocietyResidentsPurchaseData response = renewal
                    ? await SocietyService.renewResidents(
                        societyId: _societyId,
                        numberOfResidents: count,
                      )
                    : await SocietyService.purchaseResidents(
                        societyId: _societyId,
                        numberOfResidents: count,
                      );

                if (response.isFreePurchase || response.amount <= 0) {
                  if (!mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                  _showMessage(
                    renewal
                        ? 'Resident slots renewed successfully.'
                        : 'Resident slots added successfully.',
                  );
                  await _loadAll();
                  return;
                }

                VendorData? vendor;
                try {
                  vendor = await VendorService.fetchVendorInfo();
                } catch (_) {
                  vendor = null;
                }

                final RazorpayCheckoutResult checkoutResult =
                    await RazorpayCheckoutService.openCheckout(
                  keyId: response.razorpayKeyId ?? '',
                  amountInPaise: (response.amount * 100).round(),
                  name: 'Urban Easy Flats',
                  description: renewal
                      ? 'Renew $count resident slot${count == 1 ? '' : 's'}'
                      : 'Purchase $count resident slot${count == 1 ? '' : 's'}',
                  orderId: response.razorpayOrderId ?? '',
                  currency: response.currency,
                  prefillName: vendor?.fullName,
                  prefillEmail: vendor?.email,
                  prefillContact: vendor?.phone,
                );

                if (!checkoutResult.success) {
                  throw Exception(
                    checkoutResult.message ??
                        'Resident slot payment was not completed.',
                  );
                }

                if (!mounted) {
                  return;
                }
                Navigator.of(context).pop();
                _showMessage(
                  renewal
                      ? 'Payment completed. Resident slot renewal is being processed.'
                      : 'Payment completed. Resident slots are being processed.',
                );
                await _loadAll();
              } catch (error) {
                setModalState(() {
                  errorMessage =
                      error.toString().replaceFirst('Exception: ', '');
                });
              } finally {
                if (mounted) {
                  setModalState(() {
                    purchasing = false;
                  });
                }
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
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Text(
                      renewal
                          ? 'Renew Resident Slots'
                          : 'Purchase Resident Slots',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      renewal
                          ? 'Extend society resident capacity using the same renewal calculation and checkout flow as the website.'
                          : 'Add more resident creation slots using the same calculation and checkout flow as the website.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ToneBadge(
                          label:
                              'Available ${_societyInfo?.availableResidentsCreationCount ?? 0}',
                          tone: UiTone.success,
                        ),
                        ToneBadge(
                          label:
                              'Used ${_societyInfo?.usedResidentsCreationCount ?? _residents.length}',
                          tone: UiTone.warning,
                        ),
                        if ((_societyInfo?.purchasedResidentsExpiryDate ?? '')
                            .isNotEmpty)
                          ToneBadge(
                            label:
                                'Expiry ${_societyInfo!.purchasedResidentsExpiryDate!}',
                            tone: UiTone.neutral,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: renewal
                            ? 'Residents to renew'
                            : 'Residents to purchase',
                      ),
                      onChanged: (_) {
                        setModalState(() {
                          calculation = null;
                          errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (calculation != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CustomCard(
                          padding: CustomCardPadding.sm,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Calculation',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              _DetailRow(
                                label: 'Residents',
                                value: '${calculation!.numberOfResidents}',
                              ),
                              _DetailRow(
                                label: 'Per resident',
                                value:
                                    'Rs ${calculation!.amountPerResident.toStringAsFixed(0)}',
                              ),
                              _DetailRow(
                                label: 'Subtotal',
                                value:
                                    'Rs ${calculation!.subtotal.toStringAsFixed(0)}',
                              ),
                              _DetailRow(
                                label: 'GST',
                                value:
                                    '${calculation!.gstPercentage.toStringAsFixed(0)}% (Rs ${calculation!.gstAmount.toStringAsFixed(0)})',
                              ),
                              _DetailRow(
                                label: 'Total',
                                value:
                                    'Rs ${calculation!.totalAmount.toStringAsFixed(0)}',
                              ),
                              if (calculation!.residentsCountDifference !=
                                  null)
                                _DetailRow(
                                  label: 'Difference',
                                  value:
                                      '${calculation!.residentsCountDifference}',
                                ),
                              if ((calculation!.validityEndDate ?? '')
                                  .isNotEmpty)
                                _DetailRow(
                                  label: 'Valid till',
                                  value: calculation!.validityEndDate!,
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.toneColor(UiTone.danger),
                              ),
                        ),
                      ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: CustomButton(
                            label: 'Calculate',
                            variant: CustomButtonVariant.outline,
                            isLoading: calculating,
                            onPressed: calculating || purchasing ? null : calculate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            label: renewal ? 'Renew Now' : 'Purchase Now',
                            isLoading: purchasing,
                            onPressed: calculating || purchasing ? null : purchase,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    countController.dispose();
  }

  Future<void> _openResidentSheet({ResidentRecord? resident}) async {
    final TextEditingController nameController =
        TextEditingController(text: resident?.name ?? '');
    final TextEditingController phoneController =
        TextEditingController(text: resident?.phone ?? '');
    final TextEditingController emailController =
        TextEditingController(text: resident?.email ?? '');
    final TextEditingController flatController =
        TextEditingController(text: resident?.flatNo ?? '');
    final TextEditingController rentController = TextEditingController(
      text: resident?.rent?.toStringAsFixed(0) ?? '',
    );

    String buildingId = resident?.buildingId ?? _firstBuildingId();
    int residentType = switch (resident?.residentType) {
      ResidentType.owner => 1,
      ResidentType.pgResident => 3,
      _ => 2,
    };
    int flatType = _flatTypeToApi(resident?.flatType) ?? 1;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> submit() async {
              if (nameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty ||
                  flatController.text.trim().isEmpty ||
                  buildingId.isEmpty) {
                _showMessage('Name, phone, flat number, and building are required.');
                return;
              }

              setModalState(() {
                isSubmitting = true;
              });

              final Map<String, dynamic> payload = <String, dynamic>{
                if (resident != null) 'Society_ResidentID': resident.id,
                if (resident == null) 'BuildingID': buildingId,
                'Name': nameController.text.trim(),
                'CountryCode': '+91',
                'PhoneNumber': phoneController.text.trim(),
                'EmailID': emailController.text.trim(),
                'Flat_No': flatController.text.trim(),
                'Resident_Type': residentType,
                'Monthly_Rent': double.tryParse(rentController.text.trim()) ?? 0,
                'Flat_Type': flatType,
              };

              try {
                if (resident == null) {
                  await SocietyService.createResident(payload);
                } else {
                  await SocietyService.editResident(payload);
                }
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pop();
                _showMessage(
                  resident == null
                      ? 'Resident created successfully.'
                      : 'Resident updated successfully.',
                );
                await _loadAll();
              } catch (error) {
                _showMessage(error.toString().replaceFirst('Exception: ', ''));
                setModalState(() {
                  isSubmitting = false;
                });
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
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Text(
                      resident == null ? 'Add Resident' : 'Edit Resident',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: buildingId.isEmpty ? null : buildingId,
                      decoration: const InputDecoration(labelText: 'Building'),
                      items: _buildings.map((BuildingData building) {
                        final String blockName =
                            _blockNameForBuilding(building.blockId) ?? 'Block';
                        return DropdownMenuItem<String>(
                          value: building.buildingId,
                          child: Text('$blockName - ${building.name}'),
                        );
                      }).toList(),
                      onChanged: resident == null
                          ? (String? value) {
                              setModalState(() {
                                buildingId = value ?? '';
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone number',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: flatController,
                            decoration: const InputDecoration(
                              labelText: 'Flat number',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: residentType,
                            decoration: const InputDecoration(
                              labelText: 'Resident type',
                            ),
                            items: const <DropdownMenuItem<int>>[
                              DropdownMenuItem(value: 1, child: Text('Owner')),
                              DropdownMenuItem(value: 2, child: Text('Tenant')),
                              DropdownMenuItem(value: 3, child: Text('PG Resident')),
                            ],
                            onChanged: (int? value) {
                              setModalState(() {
                                residentType = value ?? 2;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: flatType,
                            decoration: const InputDecoration(labelText: 'Flat type'),
                            items: const <DropdownMenuItem<int>>[
                              DropdownMenuItem(value: 1, child: Text('1 BHK')),
                              DropdownMenuItem(value: 2, child: Text('2 BHK')),
                              DropdownMenuItem(value: 3, child: Text('3 BHK')),
                              DropdownMenuItem(value: 4, child: Text('4 BHK')),
                              DropdownMenuItem(value: 8, child: Text('Villa')),
                            ],
                            onChanged: (int? value) {
                              setModalState(() {
                                flatType = value ?? 1;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monthly rent',
                        prefixText: 'Rs ',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: resident == null ? 'Save Resident' : 'Update Resident',
                        isLoading: isSubmitting,
                        onPressed: isSubmitting ? null : submit,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    flatController.dispose();
    rentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int activeCount =
        _residents.where((ResidentRecord item) => item.status).length;
    final int availableSlots =
        _societyInfo?.availableResidentsCreationCount ?? 0;
    final int usedSlots =
        _societyInfo?.usedResidentsCreationCount ?? _residents.length;
    final bool canAddResident = _buildings.isNotEmpty && availableSlots > 0;
    final bool canRenewResidents =
        (_societyInfo?.purchasedResidentsCount ?? 0) > 0 ||
            ((_societyInfo?.purchasedResidentsExpiryDate ?? '').isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Residents'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      floatingActionButton: _societyId.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _buildings.isEmpty
                  ? null
                  : (canAddResident
                      ? _openResidentSheet
                      : () => _openResidentSlotsSheet(renewal: false)),
              icon: Icon(
                canAddResident
                    ? Icons.person_add_alt_1_outlined
                    : Icons.shopping_cart_checkout_rounded,
              ),
              label: Text(canAddResident ? 'Add Resident' : 'Buy Slots'),
            ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            const PageHeader(
              title: 'Residents',
              description:
                  'Directory, create/edit actions, and active-state controls using the society resident APIs.',
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _SummaryCard(
                    label: 'Residents',
                    value: '${_residents.length}',
                    tone: UiTone.brand,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Active',
                    value: '$activeCount',
                    tone: UiTone.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_societyInfo != null) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SummaryCard(
                      label: 'Available Slots',
                      value: '$availableSlots',
                      tone: UiTone.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Used Slots',
                      value: '$usedSlots',
                      tone: UiTone.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Resident slot setup',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      availableSlots > 0
                          ? 'You can keep adding residents while slots are available. Purchase or renew capacity here when you need more.'
                          : 'All available resident creation slots are used. Purchase or renew slots before adding more residents.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if ((_societyInfo?.totalResidentsCreationCount ?? 0) > 0)
                          ToneBadge(
                            label:
                                'Capacity ${_societyInfo!.totalResidentsCreationCount}',
                            tone: UiTone.brand,
                          ),
                        if ((_societyInfo?.purchasedResidentsCount ?? 0) > 0)
                          ToneBadge(
                            label:
                                'Purchased ${_societyInfo!.purchasedResidentsCount}',
                            tone: UiTone.neutral,
                          ),
                        if ((_societyInfo?.purchasedResidentsExpiryDate ?? '')
                            .isNotEmpty)
                          ToneBadge(
                            label:
                                'Expiry ${_societyInfo!.purchasedResidentsExpiryDate!}',
                            tone: UiTone.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: CustomButton(
                            label: 'Purchase Slots',
                            onPressed: () =>
                                _openResidentSlotsSheet(renewal: false),
                          ),
                        ),
                        if (canRenewResidents) ...<Widget>[
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              label: 'Renew Slots',
                              variant: CustomButtonVariant.outline,
                              onPressed: () =>
                                  _openResidentSlotsSheet(renewal: true),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search resident',
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchDebounce?.cancel();
                    setState(() {
                      _skip = 0;
                    });
                    _loadAll();
                  },
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
              onChanged: (String _) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                  setState(() {
                    _skip = 0;
                  });
                  _loadAll();
                });
              },
              onSubmitted: (_) {
                _searchDebounce?.cancel();
                setState(() {
                  _skip = 0;
                });
                _loadAll();
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _blockFilter.isEmpty ? null : _blockFilter,
              decoration: const InputDecoration(labelText: 'Filter by block'),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('All Blocks'),
                ),
                ..._blocks.map((BlockData block) {
                  return DropdownMenuItem<String>(
                    value: block.blockId,
                    child: Text(block.name),
                  );
                }),
              ],
              onChanged: (String? value) {
                setState(() {
                  _blockFilter = value ?? '';
                  _skip = 0;
                  if (_blockFilter.isNotEmpty &&
                      _buildingFilter.isNotEmpty &&
                      !_buildings.any((BuildingData item) =>
                          item.buildingId == _buildingFilter &&
                          item.blockId == _blockFilter)) {
                    _buildingFilter = '';
                  }
                });
                _loadAll();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _buildingFilter.isEmpty ? null : _buildingFilter,
              decoration:
                  const InputDecoration(labelText: 'Filter by building'),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('All Buildings'),
                ),
                ..._buildings
                    .where((BuildingData item) =>
                        _blockFilter.isEmpty || item.blockId == _blockFilter)
                    .map((BuildingData building) {
                  return DropdownMenuItem<String>(
                    value: building.buildingId,
                    child: Text(building.name),
                  );
                }),
              ],
              onChanged: (String? value) {
                setState(() {
                  _buildingFilter = value ?? '';
                  _skip = 0;
                });
                _loadAll();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _residentTypeFilter,
              decoration: const InputDecoration(labelText: 'Resident type'),
              items: const <DropdownMenuItem<int?>>[
                DropdownMenuItem<int?>(value: null, child: Text('All Types')),
                DropdownMenuItem<int?>(value: 1, child: Text('Owner')),
                DropdownMenuItem<int?>(value: 2, child: Text('Tenant')),
                DropdownMenuItem<int?>(value: 3, child: Text('PG Resident')),
              ],
              onChanged: (int? value) {
                setState(() {
                  _residentTypeFilter = value;
                  _skip = 0;
                });
                _loadAll();
              },
            ),
            const SizedBox(height: 16),
            CustomTabBar(
              style: CustomTabBarStyle.pill,
              currentIndex: _statusFilter == null ? 0 : (_statusFilter! ? 1 : 2),
              onChanged: (int index) {
                setState(() {
                  _statusFilter = switch (index) {
                    1 => true,
                    2 => false,
                    _ => null,
                  };
                  _skip = 0;
                });
                _loadAll();
              },
              tabs: const <CustomTabItem>[
                CustomTabItem(label: 'All'),
                CustomTabItem(label: 'Active'),
                CustomTabItem(label: 'Inactive'),
              ],
            ),
            const SizedBox(height: 16),
            if (_blockFilter.isNotEmpty && !_isLoading && _totalCount > 0) ...<Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.primaryTone),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.apartment_outlined,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_blocks.where((BlockData b) => b.blockId == _blockFilter).map((BlockData b) => b.name).firstOrNull ?? 'Selected block'}'
                        ': $_totalCount resident${_totalCount == 1 ? '' : 's'} total',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _ErrorCard(message: _errorMessage!, onRetry: _loadAll)
            else if (_residents.isEmpty)
              const CustomCard(
                child: Text('No residents found for the current filters.'),
              )
            else
              ..._residents.map((ResidentRecord resident) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
                    padding: CustomCardPadding.sm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    resident.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${resident.flatNo}${resident.buildingName?.isNotEmpty == true ? ' | ${resident.buildingName}' : ''}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                ToneBadge(
                                  label: resident.residentType.label,
                                  tone: resident.residentType.tone,
                                ),
                                ToneBadge(
                                  label: resident.status ? 'Active' : 'Inactive',
                                  tone: resident.status
                                      ? UiTone.success
                                      : UiTone.neutral,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            ToneBadge(label: resident.phone, tone: UiTone.neutral),
                            if (resident.email?.isNotEmpty == true)
                              ToneBadge(label: resident.email!, tone: UiTone.neutral),
                            if (resident.flatType?.isNotEmpty == true)
                              ToneBadge(label: resident.flatType!, tone: UiTone.brand),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: CustomButton(
                                label: 'Edit',
                                variant: CustomButtonVariant.outline,
                                onPressed: () => _openResidentSheet(resident: resident),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                label: resident.status ? 'Deactivate' : 'Activate',
                                variant: resident.status
                                    ? CustomButtonVariant.danger
                                    : CustomButtonVariant.primary,
                                onPressed: () => _toggleResident(resident),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            if (!_isLoading &&
                _errorMessage == null &&
                _totalCount > _pageSize) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CustomButton(
                      label: 'Previous',
                      variant: CustomButtonVariant.outline,
                      onPressed: _skip == 0
                          ? null
                          : () {
                              setState(() {
                                _skip = (_skip - _pageSize).clamp(0, _totalCount);
                              });
                              _loadAll();
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Showing ${_skip + 1}–${_skip + _residents.length} of $_totalCount',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: 'Next',
                      variant: CustomButtonVariant.outline,
                      onPressed: _skip + _pageSize >= _totalCount
                          ? null
                          : () {
                              setState(() {
                                _skip += _pageSize;
                              });
                              _loadAll();
                            },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  int? _flatTypeToApi(String? flatType) {
    return switch (flatType) {
      '1 BHK' => 1,
      '2 BHK' => 2,
      '3 BHK' => 3,
      '4 BHK' => 4,
      'Villa' => 8,
      _ => null,
    };
  }

  String _firstBuildingId() {
    return _buildings.isEmpty ? '' : _buildings.first.buildingId;
  }

  String? _blockNameForBuilding(String? blockId) {
    for (final BlockData block in _blocks) {
      if (block.blockId == blockId) {
        return block.name;
      }
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextStyle? valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
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
        children: <Widget>[
          ToneBadge(label: label, tone: tone, size: ToneBadgeSize.small),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Unable to load residents',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Retry',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
