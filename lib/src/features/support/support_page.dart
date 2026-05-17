import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/rental_contract_service.dart';
import '../../core/api/society_service.dart';
import '../../core/api/support_service.dart';
import '../../core/api/upload_service.dart';
import '../../core/api/vendor_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/contact_launcher.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/fullscreen_image_viewer.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({
    super.key,
    required this.role,
    required this.tickets,
    this.isLoading = false,
    this.onRefresh,
  });

  final AppRole role;
  final List<TicketRecord> tickets;
  final bool isLoading;
  final VoidCallback? onRefresh;

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  static const int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  TicketStatus? _selectedFilter;
  int? _categoryFilter;
  int? _priorityFilter;
  VendorData? _vendor;
  List<TicketRecord> _tickets = <TicketRecord>[];
  bool _isLoadingTickets = true;
  String? _errorMessage;
  int _skip = 0;
  int _totalCount = 0;

  bool get _isManagementRole =>
      widget.role.isSocietyScope || widget.role == AppRole.propertyManager;

  bool get _usesTenantWebsiteFlow => widget.role == AppRole.tenant;

  @override
  void initState() {
    super.initState();
    _tickets = widget.tickets;
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadVendor();
    await _loadTickets();
  }

  Future<void> _loadVendor() async {
    try {
      _vendor = await VendorService.fetchVendorInfo();
    } catch (_) {
      _vendor = null;
    }
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoadingTickets = true;
      _errorMessage = null;
    });

    try {
      final int? ticketStatus = _selectedFilter == null
          ? null
          : _ticketStatusToApi(_selectedFilter!);
      final String? search = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();

      if (widget.role.isSocietyScope && (_vendor?.societyId?.isEmpty ?? true)) {
        throw Exception('Society information is not available for this user.');
      }

      final ({List<TicketRecord> tickets, int count}) result =
          widget.role.isSocietyScope &&
              (_vendor?.societyId?.isNotEmpty ?? false)
          ? await SupportService.filterSocietyTickets(
              societyId: _vendor!.societyId!,
              skip: _skip,
              limit: _pageSize,
              category: _categoryFilter,
              priority: _priorityFilter,
              ticketStatus: ticketStatus,
              search: search,
            )
          : widget.role == AppRole.propertyManager
          ? await SupportService.filterPropertyTickets(
              skip: _skip,
              limit: _pageSize,
              category: _categoryFilter,
              priority: _priorityFilter,
              ticketStatus: ticketStatus,
              search: search,
            )
          : await SupportService.filterTenantTickets(
              skip: _skip,
              limit: _pageSize,
              category: _categoryFilter,
              priority: _priorityFilter,
              ticketStatus: ticketStatus,
              search: search,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _tickets = result.tickets;
        _totalCount = result.count;
        _isLoadingTickets = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoadingTickets = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _loadVendor();
    await _loadTickets();
    widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isBusy = widget.isLoading || _isLoadingTickets;
    final List<TicketRecord> visibleTickets = _tickets;

    Widget content = ListView(
      padding: AppTheme.pagePadding,
      children: <Widget>[
        const PageHeader(
          title: 'Support',
          description:
              'Live support queue with website-style search, filters, creation, and status actions.',
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _MetricCard(
                label: 'Open',
                value:
                    '${_tickets.where((TicketRecord t) => t.status == TicketStatus.open).length}',
                tone: UiTone.warning,
              ),
              const SizedBox(width: 12),
              _MetricCard(
                label: 'In Progress',
                value:
                    '${_tickets.where((TicketRecord t) => t.status == TicketStatus.inProgress).length}',
                tone: UiTone.brand,
              ),
              const SizedBox(width: 12),
              _MetricCard(
                label: 'Resolved',
                value:
                    '${_tickets.where((TicketRecord t) => t.status == TicketStatus.resolved).length}',
                tone: UiTone.success,
              ),
              const SizedBox(width: 12),
              _MetricCard(
                label: 'Critical',
                value:
                    '${_tickets.where((TicketRecord t) => t.priority == TicketPriority.urgent).length}',
                tone: UiTone.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search tickets',
            suffixIcon: IconButton(
              onPressed: () {
                _searchDebounce?.cancel();
                setState(() {
                  _skip = 0;
                });
                _loadTickets();
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
              _loadTickets();
            });
          },
          onSubmitted: (_) {
            _searchDebounce?.cancel();
            setState(() {
              _skip = 0;
            });
            _loadTickets();
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: _categoryFilter,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const <DropdownMenuItem<int?>>[
                  DropdownMenuItem<int?>(value: null, child: Text('All')),
                  DropdownMenuItem<int?>(value: 1, child: Text('Maintenance')),
                  DropdownMenuItem<int?>(value: 2, child: Text('Billing')),
                  DropdownMenuItem<int?>(value: 3, child: Text('Security')),
                  DropdownMenuItem<int?>(value: 4, child: Text('Amenities')),
                  DropdownMenuItem<int?>(value: 5, child: Text('Others')),
                ],
                onChanged: (int? value) {
                  setState(() {
                    _skip = 0;
                    _categoryFilter = value;
                  });
                  _loadTickets();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: _priorityFilter,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const <DropdownMenuItem<int?>>[
                  DropdownMenuItem<int?>(value: null, child: Text('All')),
                  DropdownMenuItem<int?>(value: 1, child: Text('Low')),
                  DropdownMenuItem<int?>(value: 2, child: Text('Medium')),
                  DropdownMenuItem<int?>(value: 3, child: Text('High')),
                  DropdownMenuItem<int?>(value: 4, child: Text('Critical')),
                ],
                onChanged: (int? value) {
                  setState(() {
                    _skip = 0;
                    _priorityFilter = value;
                  });
                  _loadTickets();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTabBar(
          style: CustomTabBarStyle.pill,
          currentIndex: _selectedFilter == null
              ? 0
              : TicketStatus.values.indexOf(_selectedFilter!) + 1,
          onChanged: (int index) {
            setState(() {
              _skip = 0;
              _selectedFilter = index == 0
                  ? null
                  : TicketStatus.values[index - 1];
            });
            _loadTickets();
          },
          tabs: <CustomTabItem>[
            const CustomTabItem(label: 'All'),
            ...TicketStatus.values.map(
              (TicketStatus status) =>
                  CustomTabItem(label: _ticketStatusLabel(status)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomCard(
          padding: CustomCardPadding.sm,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _isManagementRole
                      ? 'Create and manage support tickets for the current backend queue.'
                      : 'Raise a support issue against your linked society or property context.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CustomButton(
                label: 'Create Ticket',
                icon: const Icon(Icons.add_rounded),
                onPressed: _openCreateTicketSheet,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isBusy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Unable to load support tickets',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: 'Retry',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadTickets,
                ),
              ],
            ),
          )
        else if (visibleTickets.isEmpty)
          const CustomCard(
            padding: CustomCardPadding.sm,
            child: Text('No tickets match the current filters.'),
          )
        else
          ...visibleTickets.map((TicketRecord ticket) {
            return _SupportTicketCard(
              ticket: ticket,
              role: widget.role,
              theme: theme,
              onDetails: () => _showTicketDetails(ticket),
              onAction: _isManagementRole
                  ? (int status) => _handleStatusAction(ticket, status)
                  : null,
            );
          }),
        if (!isBusy && _errorMessage == null && _totalCount > _pageSize)
          CustomCard(
            padding: CustomCardPadding.sm,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Page ${(_skip ~/ _pageSize) + 1} of ${(_totalCount / _pageSize).ceil()}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                CustomButton(
                  label: 'Previous',
                  variant: CustomButtonVariant.outline,
                  onPressed: _skip == 0
                      ? null
                      : () {
                          setState(() {
                            _skip = _skip >= _pageSize ? _skip - _pageSize : 0;
                          });
                          _loadTickets();
                        },
                ),
                const SizedBox(width: 10),
                CustomButton(
                  label: 'Next',
                  variant: CustomButtonVariant.outline,
                  onPressed: _skip + _pageSize >= _totalCount
                      ? null
                      : () {
                          setState(() {
                            _skip += _pageSize;
                          });
                          _loadTickets();
                        },
                ),
              ],
            ),
          ),
      ],
    );

    if (widget.onRefresh != null) {
      content = RefreshIndicator(onRefresh: _refreshAll, child: content);
    }

    return content;
  }

  String _ticketStatusLabel(TicketStatus status) {
    return status.label;
  }

  Future<void> _handleStatusAction(TicketRecord ticket, int status) async {
    try {
      await SupportService.updateTicketStatus(
        ticketId: ticket.id,
        status: status,
      );
      _showMessage('Ticket status updated.');
      await _loadTickets();
      widget.onRefresh?.call();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openCreateTicketSheet() async {
    if (_usesTenantWebsiteFlow) {
      await _openTenantCreateTicketSheet();
      return;
    }

    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    int ticketType = widget.role.isSocietyScope ? 1 : 2;
    int category = 1;
    int priority = 2;

    if (widget.role != AppRole.propertyManager &&
        (_vendor?.propertyId?.isEmpty ?? true) &&
        (_vendor?.societyId?.isNotEmpty ?? false)) {
      ticketType = 1;
    }

    File? imageFile;
    bool sheetClosed = false;

    Future<void> pickImage(StateSetter setModalState) async {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
      );
      final String? path = result?.files.single.path;
      if (path == null || path.isEmpty) {
        return;
      }
      final String extension =
          result!.files.single.extension?.toLowerCase() ?? '';
      if (extension == 'avif') {
        _showMessage('AVIF images are not supported.');
        return;
      }
      if (!mounted || sheetClosed) {
        return;
      }
      setModalState(() {
        imageFile = File(path);
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> submit() async {
              final String targetId = ticketType == 1
                  ? (_vendor?.societyId ?? '')
                  : (_vendor?.propertyId ?? '');
              if (titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty ||
                  targetId.isEmpty) {
                _showMessage(
                  'Title, description, and an active society or property context are required.',
                );
                return;
              }

              setModalState(() {
                isSubmitting = true;
              });

              try {
                String? imageId;
                if (imageFile != null) {
                  imageId = await UploadService.uploadImage(imageFile!);
                  if (imageId == null || imageId.isEmpty) {
                    throw Exception('Unable to upload the selected image.');
                  }
                }

                await SupportService.createSupportTicket(
                  ticketType: ticketType,
                  ticketTypeId: targetId,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  category: category,
                  priority: priority,
                  imageId: imageId,
                );
                if (!mounted || sheetClosed) {
                  return;
                }
                sheetClosed = true;
                Navigator.of(context).pop();
                _showMessage('Support ticket created successfully.');
                await _loadTickets();
                widget.onRefresh?.call();
              } catch (error) {
                _showMessage(error.toString().replaceFirst('Exception: ', ''));
                if (!mounted || sheetClosed) {
                  return;
                }
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
                      'Create Support Ticket',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if ((_vendor?.societyId?.isNotEmpty ?? false) &&
                        (_vendor?.propertyId?.isNotEmpty ?? false))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<int>(
                          value: ticketType,
                          decoration: const InputDecoration(
                            labelText: 'Ticket type',
                          ),
                          items: const <DropdownMenuItem<int>>[
                            DropdownMenuItem<int>(
                              value: 1,
                              child: Text('Society'),
                            ),
                            DropdownMenuItem<int>(
                              value: 2,
                              child: Text('Property'),
                            ),
                          ],
                          onChanged: (int? value) {
                            setModalState(() {
                              ticketType = value ?? 1;
                            });
                          },
                        ),
                      ),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: const <DropdownMenuItem<int>>[
                              DropdownMenuItem<int>(
                                value: 1,
                                child: Text('Maintenance'),
                              ),
                              DropdownMenuItem<int>(
                                value: 2,
                                child: Text('Billing'),
                              ),
                              DropdownMenuItem<int>(
                                value: 3,
                                child: Text('Security'),
                              ),
                              DropdownMenuItem<int>(
                                value: 4,
                                child: Text('Amenities'),
                              ),
                              DropdownMenuItem<int>(
                                value: 5,
                                child: Text('Others'),
                              ),
                            ],
                            onChanged: (int? value) {
                              setModalState(() {
                                category = value ?? 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                            ),
                            items: const <DropdownMenuItem<int>>[
                              DropdownMenuItem<int>(
                                value: 1,
                                child: Text('Low'),
                              ),
                              DropdownMenuItem<int>(
                                value: 2,
                                child: Text('Medium'),
                              ),
                              DropdownMenuItem<int>(
                                value: 3,
                                child: Text('High'),
                              ),
                              DropdownMenuItem<int>(
                                value: 4,
                                child: Text('Critical'),
                              ),
                            ],
                            onChanged: (int? value) {
                              setModalState(() {
                                priority = value ?? 2;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomCard(
                      padding: CustomCardPadding.sm,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Attachment (optional)',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          if (imageFile == null)
                            Text(
                              'Upload a JPG or PNG issue image. AVIF is not supported.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            )
                          else ...<Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                imageFile!,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              imageFile!.path
                                  .split(Platform.pathSeparator)
                                  .last,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: CustomButton(
                                  label: imageFile == null
                                      ? 'Choose Image'
                                      : 'Replace Image',
                                  variant: CustomButtonVariant.outline,
                                  onPressed: () => pickImage(setModalState),
                                ),
                              ),
                              if (imageFile != null) ...<Widget>[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CustomButton(
                                    label: 'Remove',
                                    variant: CustomButtonVariant.danger,
                                    onPressed: () {
                                      setModalState(() {
                                        imageFile = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Save Ticket',
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
    ).whenComplete(() {
      sheetClosed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        titleController.dispose();
        descriptionController.dispose();
      });
    });
  }

  Future<void> _openTenantCreateTicketSheet() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String ticketType = (_vendor?.societyId?.isNotEmpty ?? false)
        ? 'society'
        : 'property';
    String? selectedTypeId;
    bool ticketTypeTouched = false;
    int category = 1;
    int priority = 2;
    File? imageFile;
    List<ResidentRecord> residentOptions = <ResidentRecord>[];
    List<RentalContractRecord> contractOptions = <RentalContractRecord>[];
    bool isSubmitting = false;
    bool isLoadingTargets = false;
    bool initialized = false;
    bool sheetClosed = false;

    void safeSetModalState(StateSetter setModalState, VoidCallback callback) {
      if (!mounted || sheetClosed) {
        return;
      }
      setModalState(callback);
    }

    String residentTicketLabel(ResidentRecord resident) {
      final List<String> location = <String>[
        if ((resident.blockName ?? '').isNotEmpty)
          'Block ${resident.blockName}',
        if ((resident.buildingName ?? '').isNotEmpty)
          'Building ${resident.buildingName}',
        if (resident.flatNo.isNotEmpty) 'Flat ${resident.flatNo}',
      ];
      return location.isEmpty
          ? resident.name
          : '${resident.name} (${location.join(', ')})';
    }

    String contractTicketLabel(RentalContractRecord contract) {
      final String owner = contract.ownerName.trim().isEmpty
          ? ''
          : ' (Owner: ${contract.ownerName})';
      final List<String> propertyParts = <String>[
        if (contract.propertyTitle.trim().isNotEmpty) contract.propertyTitle,
        if ((contract.flatNo ?? '').trim().isNotEmpty)
          'Unit ${contract.flatNo}',
      ];
      final String property = propertyParts.isEmpty
          ? 'Rented property'
          : propertyParts.join(' | ');
      final String tenant = contract.tenantName.trim().isEmpty
          ? ''
          : ' - ${contract.tenantName}';
      return '$property$tenant$owner';
    }

    List<ResidentRecord> uniqueResidents(List<ResidentRecord> records) {
      final Set<String> seen = <String>{};
      return records.where((ResidentRecord record) {
        final String id = record.id.trim();
        return id.isNotEmpty && seen.add(id);
      }).toList();
    }

    List<RentalContractRecord> uniqueContracts(
      List<RentalContractRecord> records,
    ) {
      final Set<String> seen = <String>{};
      return records.where((RentalContractRecord record) {
        final String id = record.id.trim();
        return id.isNotEmpty && seen.add(id);
      }).toList();
    }

    Future<void> loadTargets(
      StateSetter setModalState, {
      bool loadAll = false,
    }) async {
      safeSetModalState(setModalState, () {
        isLoadingTargets = true;
        selectedTypeId = null;
      });

      // Initial load fetches both sets so the "Ticket For" radio controls
      // can be shown when this vendor has both resident and rental contexts.
      if (ticketType == 'society' || loadAll) {
        try {
          final result = await SocietyService.filterResidents(
            societyId: _vendor?.societyId ?? '',
            limit: 100,
            tenantVendorId: _vendor?.vendorId,
          );
          residentOptions = uniqueResidents(
            result.residents.where((ResidentRecord record) {
              return record.status && record.societyId.isNotEmpty;
            }).toList(),
          );
        } catch (_) {
          residentOptions = <ResidentRecord>[];
        }
      }

      if (ticketType == 'property' || loadAll) {
        try {
          final result =
              await RentalContractService.filterTenantRentalContracts(
                limit: 100,
              );
          contractOptions = uniqueContracts(result.contracts);
        } catch (_) {
          contractOptions = <RentalContractRecord>[];
        }
      }

      if (!mounted || sheetClosed) {
        return;
      }

      safeSetModalState(setModalState, () {
        if (loadAll && !ticketTypeTouched) {
          if (residentOptions.isNotEmpty) {
            ticketType = 'society';
          } else if (contractOptions.isNotEmpty) {
            ticketType = 'property';
          }
        }
        isLoadingTargets = false;
        selectedTypeId = ticketType == 'society'
            ? (residentOptions.isNotEmpty ? residentOptions.first.id : null)
            : (contractOptions.isNotEmpty ? contractOptions.first.id : null);
      });
    }

    Future<void> pickImage(StateSetter setModalState) async {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
      );
      final String? path = result?.files.single.path;
      if (path == null || path.isEmpty) {
        return;
      }

      final String extension =
          result!.files.single.extension?.toLowerCase() ?? '';
      if (extension == 'avif') {
        _showMessage('AVIF images are not supported.');
        return;
      }

      safeSetModalState(setModalState, () {
        imageFile = File(path);
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            if (!initialized) {
              initialized = true;
              Future<void>.microtask(
                () => loadTargets(setModalState, loadAll: true),
              );
            }

            Future<void> submit() async {
              ResidentRecord? selectedResident;
              RentalContractRecord? selectedContract;
              if (ticketType == 'society') {
                for (final ResidentRecord resident in residentOptions) {
                  if (resident.id == selectedTypeId) {
                    selectedResident = resident;
                    break;
                  }
                }
              } else {
                for (final RentalContractRecord contract in contractOptions) {
                  if (contract.id == selectedTypeId) {
                    selectedContract = contract;
                    break;
                  }
                }
              }
              final String ticketTypeIdForApi = ticketType == 'society'
                  ? (selectedResident?.societyId ?? '')
                  : (selectedContract?.propertyId ?? '');

              if (titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty ||
                  (selectedTypeId ?? '').isEmpty ||
                  ticketTypeIdForApi.isEmpty) {
                _showMessage(
                  'Title, description, and the related resident or contract are required.',
                );
                return;
              }

              safeSetModalState(setModalState, () {
                isSubmitting = true;
              });

              try {
                String? imageId;
                if (imageFile != null) {
                  imageId = await UploadService.uploadImage(imageFile!);
                  if (imageId == null || imageId.isEmpty) {
                    throw Exception('Unable to upload the selected image.');
                  }
                }

                await SupportService.createSupportTicket(
                  ticketType: ticketType == 'society' ? 1 : 2,
                  ticketTypeId: ticketTypeIdForApi,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  category: category,
                  priority: priority,
                  imageId: imageId,
                );

                if (!mounted || sheetClosed) {
                  return;
                }
                sheetClosed = true;
                Navigator.of(context).pop();
                _showMessage('Support ticket created successfully.');
                await _loadTickets();
                widget.onRefresh?.call();
              } catch (error) {
                _showMessage(error.toString().replaceFirst('Exception: ', ''));
                if (!mounted || sheetClosed) {
                  return;
                }
                safeSetModalState(setModalState, () {
                  isSubmitting = false;
                });
              }
            }

            final bool hasSocietyContext =
                (_vendor?.societyId?.isNotEmpty ?? false) ||
                residentOptions.isNotEmpty;
            final bool hasPropertyContext =
                (_vendor?.propertyId?.isNotEmpty ?? false) ||
                contractOptions.isNotEmpty;

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
                      'Create Support Ticket',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    if (hasSocietyContext && hasPropertyContext) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        'Ticket For',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: <Widget>[
                          SizedBox(
                            width: 184,
                            child: RadioListTile<String>(
                              value: 'society',
                              groupValue: ticketType,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Society Resident'),
                              onChanged: isLoadingTargets
                                  ? null
                                  : (String? value) {
                                      ticketTypeTouched = true;
                                      setModalState(() {
                                        ticketType = value ?? 'society';
                                        selectedTypeId = null;
                                      });
                                      loadTargets(setModalState);
                                    },
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: RadioListTile<String>(
                              value: 'property',
                              groupValue: ticketType,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Rented Property'),
                              onChanged: isLoadingTargets
                                  ? null
                                  : (String? value) {
                                      ticketTypeTouched = true;
                                      setModalState(() {
                                        ticketType = value ?? 'property';
                                        selectedTypeId = null;
                                      });
                                      loadTargets(setModalState);
                                    },
                            ),
                          ),
                        ],
                      ),
                    ] else if (hasSocietyContext ||
                        hasPropertyContext) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        'Ticket For',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ToneBadge(
                        label: hasSocietyContext
                            ? 'Society Resident'
                            : 'Rented Property',
                        tone: UiTone.neutral,
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedTypeId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: ticketType == 'society'
                            ? 'Select Resident Profile'
                            : 'Select Property Contract',
                      ),
                      items: <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          enabled: false,
                          child: Text(
                            isLoadingTargets
                                ? 'Loading...'
                                : ticketType == 'society'
                                ? 'Choose your resident profile'
                                : 'Choose a contract',
                          ),
                        ),
                        ...(ticketType == 'society'
                                ? residentOptions.map(
                                    (ResidentRecord resident) =>
                                        DropdownMenuItem<String>(
                                          value: resident.id,
                                          child: Text(
                                            residentTicketLabel(resident),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                  )
                                : contractOptions.map(
                                    (RentalContractRecord contract) =>
                                        DropdownMenuItem<String>(
                                          value: contract.id,
                                          child: Text(
                                            contractTicketLabel(contract),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                  ))
                            .toList(),
                      ],
                      onChanged: isLoadingTargets
                          ? null
                          : (String? value) {
                              setModalState(() {
                                selectedTypeId = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: const <DropdownMenuItem<int>>[
                              DropdownMenuItem<int>(
                                value: 1,
                                child: Text('Maintenance'),
                              ),
                              DropdownMenuItem<int>(
                                value: 2,
                                child: Text('Billing'),
                              ),
                              DropdownMenuItem<int>(
                                value: 3,
                                child: Text('Security'),
                              ),
                              DropdownMenuItem<int>(
                                value: 4,
                                child: Text('Amenities'),
                              ),
                              DropdownMenuItem<int>(
                                value: 5,
                                child: Text('Others'),
                              ),
                            ],
                            onChanged: (int? value) {
                              setModalState(() {
                                category = value ?? 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                            ),
                            items: const <DropdownMenuItem<int>>[
                              DropdownMenuItem<int>(
                                value: 1,
                                child: Text('Low'),
                              ),
                              DropdownMenuItem<int>(
                                value: 2,
                                child: Text('Medium'),
                              ),
                              DropdownMenuItem<int>(
                                value: 3,
                                child: Text('High'),
                              ),
                              DropdownMenuItem<int>(
                                value: 4,
                                child: Text('Critical'),
                              ),
                            ],
                            onChanged: (int? value) {
                              setModalState(() {
                                priority = value ?? 2;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomCard(
                      padding: CustomCardPadding.sm,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Attachment (optional)',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          if (imageFile == null)
                            Text(
                              'Upload a JPG or PNG issue image. AVIF is not supported.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            )
                          else ...<Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                imageFile!,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              imageFile!.path
                                  .split(Platform.pathSeparator)
                                  .last,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: CustomButton(
                                  label: imageFile == null
                                      ? 'Choose Image'
                                      : 'Replace Image',
                                  variant: CustomButtonVariant.outline,
                                  onPressed: () => pickImage(setModalState),
                                ),
                              ),
                              if (imageFile != null) ...<Widget>[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CustomButton(
                                    label: 'Remove',
                                    variant: CustomButtonVariant.danger,
                                    onPressed: () {
                                      setModalState(() {
                                        imageFile = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: CustomButton(
                            label: 'Cancel',
                            variant: CustomButtonVariant.outline,
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            label: 'Create Ticket',
                            isLoading: isSubmitting,
                            onPressed: isSubmitting ? null : submit,
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
    ).whenComplete(() {
      sheetClosed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        titleController.dispose();
        descriptionController.dispose();
      });
    });
  }

  void _showTicketDetails(TicketRecord ticket) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final double dialogWidth = (MediaQuery.sizeOf(context).width - 96)
            .clamp(280.0, 420.0)
            .toDouble();
        return AlertDialog(
          title: Text(ticket.title),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ToneBadge(
                        label: _ticketStatusLabel(ticket.status),
                        tone: ticket.status.tone,
                      ),
                      ToneBadge(
                        label: ticket.priority.label,
                        tone: ticket.priority.tone,
                      ),
                      ToneBadge(label: ticket.category, tone: UiTone.neutral),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if ((ticket.targetName ?? '').isNotEmpty) ...<Widget>[
                    Text(
                      'Regarding',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(ticket.targetName!),
                    const SizedBox(height: 16),
                  ],
                  if ((ticket.societyName ?? '').isNotEmpty ||
                      (ticket.blockName ?? '').isNotEmpty ||
                      (ticket.buildingName ?? '').isNotEmpty ||
                      (ticket.flatNo ?? '').isNotEmpty) ...<Widget>[
                    Text(
                      'Location Context',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if ((ticket.societyName ?? '').isNotEmpty)
                      Text('Society: ${ticket.societyName!}'),
                    if ((ticket.blockName ?? '').isNotEmpty)
                      Text('Block: ${ticket.blockName!}'),
                    if ((ticket.buildingName ?? '').isNotEmpty)
                      Text('Building: ${ticket.buildingName!}'),
                    if ((ticket.flatNo ?? '').isNotEmpty)
                      Text('Flat: ${ticket.flatNo!}'),
                    const SizedBox(height: 16),
                  ],
                  if ((ticket.imageUrl ?? '').isNotEmpty) ...<Widget>[
                    GestureDetector(
                      onTap: () => FullScreenImageViewer.show(
                        context,
                        imageUrl: ticket.imageUrl!,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          ticket.imageUrl!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: AppTheme.surfaceMuted,
                            alignment: Alignment.center,
                            child: const Text('Unable to load attachment'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(ticket.description),
                  const SizedBox(height: 16),
                  Text(
                    'Created ${formatCompactDate(ticket.createdAt ?? ticket.updatedAt)} at ${formatClock(ticket.createdAt ?? ticket.updatedAt)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated ${formatCompactDate(ticket.updatedAt)} at ${formatClock(ticket.updatedAt)}',
                  ),
                  if (ticket.assignee != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text('Assignee: ${ticket.assignee}'),
                  ],
                  if ((ticket.propertyTitle ?? '').isNotEmpty ||
                      (ticket.propertyFlatNo ?? '').isNotEmpty ||
                      (ticket.tenantName ?? '').isNotEmpty ||
                      (ticket.tenantPhone ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      'Property Context',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if ((ticket.propertyTitle ?? '').isNotEmpty)
                      Text('Property: ${ticket.propertyTitle!}'),
                    if ((ticket.propertyFlatNo ?? '').isNotEmpty)
                      Text('Unit: ${ticket.propertyFlatNo!}'),
                    if ((ticket.tenantName ?? '').isNotEmpty)
                      Text('Tenant: ${ticket.tenantName!}'),
                    if ((ticket.tenantPhone ?? '').isNotEmpty)
                      ContactTextButton.phone(
                        value: ticket.tenantPhone!,
                        label: 'Phone: ${ticket.tenantPhone!}',
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  int _ticketStatusToApi(TicketStatus status) {
    return switch (status) {
      TicketStatus.open => 1,
      TicketStatus.inProgress => 2,
      TicketStatus.resolved => 3,
      TicketStatus.rejected => 4,
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatusActionMenu extends StatelessWidget {
  const _StatusActionMenu({required this.ticket, required this.onAction});

  final TicketRecord ticket;
  final void Function(int status) onAction;

  @override
  Widget build(BuildContext context) {
    final List<({String label, int status})> actions = switch (ticket.status) {
      TicketStatus.open => <({String label, int status})>[
        (label: 'In Progress', status: 2),
        (label: 'Resolve', status: 3),
        (label: 'Reject', status: 4),
      ],
      TicketStatus.inProgress => <({String label, int status})>[
        (label: 'Resolve', status: 3),
        (label: 'Reject', status: 4),
        (label: 'Reopen', status: 1),
      ],
      TicketStatus.resolved => <({String label, int status})>[
        (label: 'Reopen', status: 1),
      ],
      TicketStatus.rejected => <({String label, int status})>[
        (label: 'Reopen', status: 1),
      ],
    };

    return PopupMenuButton<int>(
      onSelected: onAction,
      itemBuilder: (_) => actions
          .map(
            (({String label, int status}) a) =>
                PopupMenuItem<int>(value: a.status, child: Text(a.label)),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Actions',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      child: CustomCard(
        padding: CustomCardPadding.sm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ToneBadge(label: label, tone: tone, size: ToneBadgeSize.small),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTicketCard extends StatelessWidget {
  const _SupportTicketCard({
    required this.ticket,
    required this.role,
    required this.theme,
    required this.onDetails,
    required this.onAction,
  });

  final TicketRecord ticket;
  final AppRole role;
  final ThemeData theme;
  final VoidCallback onDetails;
  final ValueChanged<int>? onAction;

  bool get _isManagementRole =>
      role.isSocietyScope || role == AppRole.propertyManager;

  @override
  Widget build(BuildContext context) {
    final bool hasHeroImage = (ticket.imageUrl ?? '').isNotEmpty;
    final Color accent = ticket.priority.tone == UiTone.danger
        ? theme.colorScheme.error
        : ticket.priority.tone == UiTone.warning
            ? theme.colorScheme.secondary
            : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: CustomCard(
        padding: CustomCardPadding.none,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  border: Border(
                    left: BorderSide(color: accent, width: 4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            ticket.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ticket.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ToneBadge(
                      label: ticket.priority.label,
                      tone: ticket.priority.tone,
                      size: ToneBadgeSize.small,
                    ),
                  ],
                ),
              ),
              if (hasHeroImage)
                GestureDetector(
                  onTap: () => FullScreenImageViewer.show(
                    context,
                    imageUrl: ticket.imageUrl!,
                  ),
                  child: Image.network(
                    ticket.imageUrl!,
                    height: 176,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 176,
                      color: AppTheme.surfaceMuted,
                      alignment: Alignment.center,
                      child: const Text('Unable to load attachment'),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ToneBadge(
                          label: ticket.status.label,
                          tone: ticket.status.tone,
                          size: ToneBadgeSize.small,
                        ),
                        ToneBadge(
                          label: ticket.category,
                          tone: UiTone.neutral,
                          size: ToneBadgeSize.small,
                        ),
                        if (ticket.assignee != null)
                          ToneBadge(
                            label: 'Assigned: ${ticket.assignee}',
                            tone: UiTone.brand,
                            size: ToneBadgeSize.small,
                          ),
                        if ((ticket.targetName ?? '').isNotEmpty)
                          ToneBadge(
                            label: ticket.targetName!,
                            tone: UiTone.brand,
                            size: ToneBadgeSize.small,
                          ),
                        if ((ticket.propertyTitle ?? '').isNotEmpty)
                          ToneBadge(
                            label: ticket.propertyTitle!,
                            tone: UiTone.neutral,
                            size: ToneBadgeSize.small,
                          ),
                        if ((ticket.tenantName ?? '').isNotEmpty)
                          ToneBadge(
                            label: ticket.tenantName!,
                            tone: UiTone.brand,
                            size: ToneBadgeSize.small,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if ((ticket.societyName ?? '').isNotEmpty ||
                        (ticket.blockName ?? '').isNotEmpty ||
                        (ticket.buildingName ?? '').isNotEmpty ||
                        (ticket.flatNo ?? '').isNotEmpty) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            if ((ticket.societyName ?? '').isNotEmpty)
                              Text(ticket.societyName!),
                            if ((ticket.blockName ?? '').isNotEmpty)
                              Text('Block ${ticket.blockName!}'),
                            if ((ticket.buildingName ?? '').isNotEmpty)
                              Text('Building ${ticket.buildingName!}'),
                            if ((ticket.flatNo ?? '').isNotEmpty)
                              Text('Flat ${ticket.flatNo!}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_isManagementRole &&
                        ((ticket.propertyTitle ?? '').isNotEmpty ||
                            (ticket.propertyFlatNo ?? '').isNotEmpty ||
                            (ticket.tenantName ?? '').isNotEmpty ||
                            (ticket.tenantPhone ?? '').isNotEmpty)) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _SupportTicketAvatar(
                              label: ticket.tenantName ??
                                  ticket.targetName ??
                                  'Resident',
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if ((ticket.propertyTitle ?? '').isNotEmpty)
                                    Text(ticket.propertyTitle!),
                                  if ((ticket.propertyFlatNo ?? '').isNotEmpty)
                                    Text('Unit ${ticket.propertyFlatNo!}'),
                                  if ((ticket.tenantName ?? '').isNotEmpty)
                                    Text(ticket.tenantName!),
                                  if ((ticket.tenantPhone ?? '').isNotEmpty)
                                    ContactTextButton.phone(
                                      value: ticket.tenantPhone!,
                                      label: ticket.tenantPhone!,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${ticket.createdAt == null ? 'Updated' : 'Created'} ${formatCompactDate(ticket.createdAt ?? ticket.updatedAt)} at ${formatClock(ticket.createdAt ?? ticket.updatedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_isManagementRole)
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: CustomButton(
                              label: 'Details',
                              variant: CustomButtonVariant.outline,
                              onPressed: onDetails,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatusActionMenu(
                              ticket: ticket,
                              onAction: onAction ?? (_) {},
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: 'View Details',
                          variant: CustomButtonVariant.outline,
                          onPressed: onDetails,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTicketAvatar extends StatelessWidget {
  const _SupportTicketAvatar({
    this.imageUrl,
    required this.label,
  });

  final String? imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final String trimmedLabel = label.trim();
    final String initials = trimmedLabel.isEmpty
        ? '?'
        : trimmedLabel
            .split(RegExp(r'\s+'))
            .where((String part) => part.isNotEmpty)
            .map((String part) => part[0].toUpperCase())
            .take(2)
            .join();

    final String? trimmedImage = imageUrl?.trim();
    if (trimmedImage != null && trimmedImage.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.primaryTone,
        backgroundImage: NetworkImage(trimmedImage),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.primarySoft,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
      ),
    );
  }
}
