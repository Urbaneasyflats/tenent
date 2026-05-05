import 'package:flutter/material.dart';

import '../../core/api/announcement_service.dart';
import '../../core/api/block_building_service.dart';
import '../../core/api/vendor_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({
    super.key,
    required this.role,
    required this.announcements,
    this.isLoading = false,
    this.onRefresh,
  });

  final AppRole role;
  final List<AnnouncementRecord> announcements;
  final bool isLoading;
  final VoidCallback? onRefresh;

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0;
  int? _priorityFilter;
  String _blockFilter = '';
  String _buildingFilter = '';
  VendorData? _vendor;
  List<BlockData> _blocks = <BlockData>[];
  List<BuildingData> _buildings = <BuildingData>[];
  List<AnnouncementRecord> _announcements = <AnnouncementRecord>[];
  bool _isLoadingAnnouncements = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _announcements = widget.announcements;
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadVendor();
    await _loadAnnouncements();
  }

  Future<void> _loadVendor() async {
    try {
      final VendorData? vendor = await VendorService.fetchVendorInfo();
      if (!mounted) {
        return;
      }

      _vendor = vendor;
      if (widget.role.isSocietyScope &&
          (vendor?.societyId?.isNotEmpty ?? false)) {
        final results = await Future.wait<dynamic>(<Future<dynamic>>[
          BlockBuildingService.filterBlocks(vendor!.societyId!),
          BlockBuildingService.filterBuildings(vendor.societyId!),
        ]);
        if (!mounted) {
          return;
        }
        final blocksResult = results[0] as ({List<BlockData> blocks, int count});
        final buildingsResult =
            results[1] as ({List<BuildingData> buildings, int count});
        _blocks =
            blocksResult.blocks.where((BlockData item) => item.status).toList();
        _buildings = buildingsResult.buildings
            .where((BuildingData item) => item.status)
            .toList();
      }
    } catch (_) {
      _vendor = null;
      _blocks = <BlockData>[];
      _buildings = <BuildingData>[];
    }
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoadingAnnouncements = true;
      _errorMessage = null;
    });

    try {
      final String? search = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();

      if (widget.role.isSocietyScope &&
          (_vendor?.societyId?.isEmpty ?? true)) {
        throw Exception('Society information is not available for this user.');
      }

      final ({List<AnnouncementRecord> announcements, int count}) result =
          widget.role.isSocietyScope &&
                  (_vendor?.societyId?.isNotEmpty ?? false)
              ? await AnnouncementService.filterSocietyAnnouncements(
                  societyId: _vendor!.societyId!,
                  limit: 100,
                  search: search,
                  priority: _priorityFilter,
                  blockId: _blockFilter.isEmpty ? null : _blockFilter,
                  buildingId: _buildingFilter.isEmpty ? null : _buildingFilter,
                )
              : await AnnouncementService.filterTenantAnnouncements(
                  limit: 100,
                  search: search,
                );

      if (!mounted) {
        return;
      }

      setState(() {
        _announcements = result.announcements;
        _isLoadingAnnouncements = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoadingAnnouncements = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _loadVendor();
    await _loadAnnouncements();
    widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    final List<AnnouncementRecord> unreadOnly = _announcements
        .where((AnnouncementRecord item) => item.unread)
        .toList();
    final List<AnnouncementRecord> activeItems =
        _selectedIndex == 0 ? _announcements : unreadOnly;
    final bool isBusy = widget.isLoading || _isLoadingAnnouncements;

    Widget content = ListView(
      padding: AppTheme.pagePadding,
      children: <Widget>[
        const PageHeader(
          title: 'Communication Center',
          description:
              'Live announcements with website-style search, priority filters, and society targeting.',
        ),
        const SizedBox(height: 16),
        CustomTabBar(
          currentIndex: _selectedIndex,
          onChanged: (int value) {
            setState(() {
              _selectedIndex = value;
            });
          },
          tabs: <CustomTabItem>[
            const CustomTabItem(
              label: 'Announcements',
              icon: Icons.campaign_outlined,
            ),
            CustomTabItem(
              label: 'Unread',
              icon: Icons.notifications_none_outlined,
              trailing: unreadOnly.isEmpty
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${unreadOnly.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search announcements',
            suffixIcon: IconButton(
              onPressed: _loadAnnouncements,
              icon: const Icon(Icons.search_rounded),
            ),
          ),
          onSubmitted: (_) => _loadAnnouncements(),
        ),
        if (widget.role.isSocietyScope) ...<Widget>[
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: _priorityFilter,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const <DropdownMenuItem<int?>>[
              DropdownMenuItem<int?>(
                value: null,
                child: Text('All priorities'),
              ),
              DropdownMenuItem<int?>(value: 1, child: Text('Low')),
              DropdownMenuItem<int?>(value: 2, child: Text('Medium')),
              DropdownMenuItem<int?>(value: 3, child: Text('High')),
            ],
            onChanged: (int? value) {
              setState(() {
                _priorityFilter = value;
              });
              _loadAnnouncements();
            },
          ),
          const SizedBox(height: 12),
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
                if (_blockFilter.isNotEmpty &&
                    _buildingFilter.isNotEmpty &&
                    !_buildings.any((BuildingData item) =>
                        item.buildingId == _buildingFilter &&
                        item.blockId == _blockFilter)) {
                  _buildingFilter = '';
                }
              });
              _loadAnnouncements();
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
              });
              _loadAnnouncements();
            },
          ),
        ],
        const SizedBox(height: 16),
        CustomCard(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToneBadge(label: widget.role.label, tone: UiTone.brand),
              ToneBadge(
                label: '${activeItems.length} visible notices',
                tone: UiTone.neutral,
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
                  'Unable to load announcements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: 'Retry',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadAnnouncements,
                ),
              ],
            ),
          )
        else if (activeItems.isEmpty)
          const CustomCard(
            padding: CustomCardPadding.sm,
            child: Text('No notices match this view yet.'),
          )
        else
          ...activeItems.map((AnnouncementRecord item) {
            final UiTone tone = item.unread ? UiTone.brand : UiTone.neutral;
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
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.toneSoft(tone),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.category.icon,
                            color: AppTheme.toneColor(tone),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.message,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ToneBadge(
                          label: item.category.label,
                          tone: UiTone.brand,
                        ),
                        ToneBadge(
                          label: item.priorityLabel,
                          tone: UiTone.warning,
                        ),
                        ToneBadge(
                          label: item.unread ? 'Unread' : 'Read',
                          tone: item.unread ? UiTone.success : UiTone.neutral,
                        ),
                        ...item.blockNames.map(
                          (String name) =>
                              ToneBadge(label: name, tone: UiTone.neutral),
                        ),
                        ...item.buildingNames.map(
                          (String name) =>
                              ToneBadge(label: name, tone: UiTone.neutral),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Created ${formatCompactDate(item.createdAt)} at ${formatClock(item.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                    if (widget.role.isSocietyScope) ...<Widget>[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: 'Edit Announcement',
                          variant: CustomButtonVariant.outline,
                          onPressed: () =>
                              _openAnnouncementSheet(announcement: item),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );

    if (widget.onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: _refreshAll,
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Communication'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: content,
      floatingActionButton: widget.role.isSocietyScope &&
              (_vendor?.societyId?.isNotEmpty ?? false)
          ? FloatingActionButton.extended(
              onPressed: _openAnnouncementSheet,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Compose'),
            )
          : null,
    );
  }

  Future<void> _openAnnouncementSheet({AnnouncementRecord? announcement}) async {
    final TextEditingController titleController =
        TextEditingController(text: announcement?.title ?? '');
    final TextEditingController descriptionController =
        TextEditingController(text: announcement?.message ?? '');
    int priority = _priorityToApi(announcement?.priorityLabel);
    String blockId = announcement?.blockIds.isNotEmpty == true
        ? announcement!.blockIds.first
        : '';
    String buildingId = announcement?.buildingIds.isNotEmpty == true
        ? announcement!.buildingIds.first
        : '';
    bool sheetClosed = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void safeSetModalState(VoidCallback callback) {
              if (!mounted || sheetClosed) {
                return;
              }
              setModalState(callback);
            }

            Future<void> submit() async {
              if (titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty ||
                  (_vendor?.societyId?.isEmpty ?? true)) {
                _showMessage(
                  'Title, description, and a valid society are required.',
                );
                return;
              }

              safeSetModalState(() {
                isSubmitting = true;
              });

              try {
                if (announcement == null) {
                  await AnnouncementService.createAnnouncement(
                    societyId: _vendor!.societyId!,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    priority: priority,
                    blockIds:
                        blockId.isEmpty ? const <String>[] : <String>[blockId],
                    buildingIds: buildingId.isEmpty
                        ? const <String>[]
                        : <String>[buildingId],
                  );
                } else {
                  await AnnouncementService.editAnnouncement(
                    announcementId: announcement.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    priority: priority,
                    blockIds: blockId.isEmpty ? const <String>[] : <String>[blockId],
                    buildingIds: buildingId.isEmpty
                        ? const <String>[]
                        : <String>[buildingId],
                  );
                }
                if (!mounted || sheetClosed) {
                  return;
                }
                sheetClosed = true;
                Navigator.of(context).pop();
                _showMessage(
                  announcement == null
                      ? 'Announcement created successfully.'
                      : 'Announcement updated successfully.',
                );
                await _loadAnnouncements();
                widget.onRefresh?.call();
              } catch (error) {
                _showMessage(error.toString().replaceFirst('Exception: ', ''));
                safeSetModalState(() {
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
                      announcement == null
                          ? 'Compose Announcement'
                          : 'Edit Announcement',
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
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem<int>(value: 1, child: Text('Low')),
                        DropdownMenuItem<int>(
                          value: 2,
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem<int>(value: 3, child: Text('High')),
                      ],
                      onChanged: (int? value) {
                        safeSetModalState(() {
                          priority = value ?? 1;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: blockId.isEmpty ? null : blockId,
                      decoration:
                          const InputDecoration(labelText: 'Target block'),
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
                        safeSetModalState(() {
                          blockId = value ?? '';
                          if (blockId.isNotEmpty &&
                              buildingId.isNotEmpty &&
                              !_buildings.any((BuildingData item) =>
                                  item.buildingId == buildingId &&
                                  item.blockId == blockId)) {
                            buildingId = '';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: buildingId.isEmpty ? null : buildingId,
                      decoration: const InputDecoration(
                        labelText: 'Target building',
                      ),
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('All Buildings'),
                        ),
                        ..._buildings
                            .where((BuildingData item) =>
                                blockId.isEmpty ||
                                item.blockId == blockId)
                            .map((BuildingData building) {
                          return DropdownMenuItem<String>(
                            value: building.buildingId,
                            child: Text(building.name),
                          );
                        }),
                      ],
                      onChanged: (String? value) {
                        safeSetModalState(() {
                          buildingId = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: announcement == null
                            ? 'Publish Announcement'
                            : 'Save Changes',
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
    });

    titleController.dispose();
    descriptionController.dispose();
  }

  int _priorityToApi(String? label) {
    return switch (label?.toLowerCase()) {
      'medium' => 2,
      'high' => 3,
      _ => 1,
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
