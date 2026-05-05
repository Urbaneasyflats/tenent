import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/block_building_service.dart';
import '../../core/api/incident_service.dart';
import '../../core/api/upload_service.dart';
import '../../core/api/vendor_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  String _societyId = '';
  IncidentStatus? _statusFilter;
  String _blockFilter = '';
  String _buildingFilter = '';
  List<BlockData> _blocks = <BlockData>[];
  List<BuildingData> _buildings = <BuildingData>[];
  List<IncidentRecord> _incidents = <IncidentRecord>[];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
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
        IncidentService.filterSocietyIncidentRecords(
          societyId: societyId,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          status: _statusFilter,
          blockId: _blockFilter.isEmpty ? null : _blockFilter,
          buildingId: _buildingFilter.isEmpty ? null : _buildingFilter,
          limit: 200,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final blocksResult = results[0] as ({List<BlockData> blocks, int count});
      final buildingsResult =
          results[1] as ({List<BuildingData> buildings, int count});
      final incidentsResult =
          results[2] as ({List<IncidentRecord> incidents, int count});

      setState(() {
        _societyId = societyId;
        _blocks = blocksResult.blocks.where((BlockData item) => item.status).toList();
        _buildings = buildingsResult.buildings
            .where((BuildingData item) => item.status)
            .toList();
        _incidents = incidentsResult.incidents;
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

  Future<void> _openIncidentSheet({IncidentRecord? incident}) async {
    final TextEditingController titleController =
        TextEditingController(text: incident?.title ?? '');
    final TextEditingController descriptionController =
        TextEditingController(text: incident?.description ?? '');
    final TextEditingController locationController =
        TextEditingController(text: incident?.location ?? '');

    String blockId = _blockIdFromName(incident?.blockName) ?? '';
    String buildingId = _buildingIdFromName(incident?.buildingName) ?? '';
    int priority = _priorityToApi(incident?.priority) ?? 2;
    String? uploadedImageId;
    String? uploadedImagePath;
    bool isUploadingImage = false;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> pickImage() async {
              final FilePickerResult? result = await FilePicker.platform
                  .pickFiles(type: FileType.image);
              if (result == null || result.files.single.path == null) {
                return;
              }
              setModalState(() {
                isUploadingImage = true;
              });
              try {
                final String? imgId = await UploadService.uploadImage(
                  File(result.files.single.path!),
                );
                setModalState(() {
                  uploadedImageId = imgId;
                  uploadedImagePath = result.files.single.path;
                  isUploadingImage = false;
                });
              } catch (_) {
                setModalState(() {
                  isUploadingImage = false;
                });
                _showMessage('Image upload failed. Please try again.');
              }
            }

            Future<void> submit() async {
              if (titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty ||
                  locationController.text.trim().isEmpty) {
                _showMessage('Title, description, and location are required.');
                return;
              }

              setModalState(() {
                isSubmitting = true;
              });

              try {
                if (incident == null) {
                  await IncidentService.createIncident(
                    societyId: _societyId,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    location: locationController.text.trim(),
                    priority: priority,
                    blockId: blockId,
                    buildingId: buildingId,
                    imageId: uploadedImageId ?? '',
                  );
                } else {
                  await IncidentService.editIncident(
                    incidentId: incident.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    location: locationController.text.trim(),
                    priority: priority,
                    blockId: blockId,
                    buildingId: buildingId,
                    imageId: uploadedImageId ?? '',
                  );
                }
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pop();
                _showMessage(
                  incident == null
                      ? 'Incident created successfully.'
                      : 'Incident updated successfully.',
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
                      incident == null ? 'Create Incident' : 'Edit Incident',
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
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem(value: 1, child: Text('Low')),
                        DropdownMenuItem(value: 2, child: Text('Medium')),
                        DropdownMenuItem(value: 3, child: Text('High')),
                        DropdownMenuItem(value: 4, child: Text('Critical')),
                      ],
                      onChanged: (int? value) {
                        setModalState(() {
                          priority = value ?? 2;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: blockId.isEmpty ? null : blockId,
                      decoration: const InputDecoration(labelText: 'Block'),
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
                        setModalState(() {
                          blockId = value ?? '';
                          if (blockId.isNotEmpty &&
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
                      decoration: const InputDecoration(labelText: 'Building'),
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('All Buildings'),
                        ),
                        ..._buildings
                            .where((BuildingData item) =>
                                blockId.isEmpty || item.blockId == blockId)
                            .map((BuildingData building) {
                          return DropdownMenuItem<String>(
                            value: building.buildingId,
                            child: Text(building.name),
                          );
                        }),
                      ],
                      onChanged: (String? value) {
                        setModalState(() {
                          buildingId = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (uploadedImagePath != null)
                      Stack(
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(uploadedImagePath!),
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  uploadedImageId = null;
                                  uploadedImagePath = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'No image attached',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    const SizedBox(height: 8),
                    isUploadingImage
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : CustomButton(
                            label: uploadedImagePath != null
                                ? 'Change Image'
                                : 'Upload Image',
                            icon: const Icon(Icons.upload_outlined),
                            variant: CustomButtonVariant.outline,
                            onPressed: pickImage,
                          ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: incident == null ? 'Save Incident' : 'Update Incident',
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

    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
  }

  Future<void> _updateIncidentStatus(IncidentRecord incident, int status) async {
    try {
      await IncidentService.updateIncidentStatus(
        incidentId: incident.id,
        status: status,
      );
      _showMessage('Incident status updated.');
      await _loadAll();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _toggleIncident(IncidentRecord incident) async {
    try {
      await IncidentService.toggleIncident(
        incident.id,
        active: !incident.isActive,
      );
      _showMessage('Incident availability updated.');
      await _loadAll();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showIncidentDetails(IncidentRecord incident) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        incident.title,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ToneBadge(
                      label: incident.priority.label,
                      tone: incident.priority.tone,
                    ),
                    ToneBadge(
                      label: incident.status.label,
                      tone: incident.status.tone,
                    ),
                    ToneBadge(
                      label: incident.isActive ? 'Active' : 'Inactive',
                      tone: incident.isActive ? UiTone.success : UiTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (incident.description.isNotEmpty) ...<Widget>[
                  Text(
                    'Description',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incident.description,
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                if (incident.location?.isNotEmpty == true) ...<Widget>[
                  Text(
                    'Location',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incident.location!,
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                if (incident.blockName?.isNotEmpty == true ||
                    incident.buildingName?.isNotEmpty == true) ...<Widget>[
                  Text(
                    'Block / Building',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    <String?>[incident.blockName, incident.buildingName]
                        .where((String? s) => s?.isNotEmpty == true)
                        .join(' \u2022 '),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Reported',
                  style: Theme.of(ctx).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatCompactDate(incident.createdAt)} at ${formatClock(incident.createdAt)}',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                if (incident.imageUrl?.isNotEmpty == true) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    'Attached Image',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      incident.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext c, Widget child,
                          ImageChunkEvent? progress) {
                        if (progress == null) {
                          return child;
                        }
                        return Container(
                          height: 200,
                          color: AppTheme.border,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (BuildContext c, Object error,
                              StackTrace? stack) =>
                          Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int openCount = _incidents
        .where((IncidentRecord item) => item.status == IncidentStatus.open)
        .length;
    final int resolvedCount = _incidents
        .where((IncidentRecord item) => item.status == IncidentStatus.resolved)
        .length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Security'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      floatingActionButton: _societyId.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openIncidentSheet,
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('New Incident'),
            ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            const PageHeader(
              title: 'Security Management',
              description:
                  'Incident queue, create/edit actions, status updates, and active controls backed by society incident APIs.',
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _CountCard(
                    label: 'Open',
                    value: '$openCount',
                    tone: UiTone.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CountCard(
                    label: 'Resolved',
                    value: '$resolvedCount',
                    tone: UiTone.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search incident',
                suffixIcon: IconButton(
                  onPressed: _loadAll,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
              onSubmitted: (_) => _loadAll(),
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
                });
                _loadAll();
              },
            ),
            const SizedBox(height: 16),
            CustomTabBar(
              style: CustomTabBarStyle.pill,
              currentIndex: _statusFilter == null
                  ? 0
                  : IncidentStatus.values.indexOf(_statusFilter!) + 1,
              onChanged: (int index) {
                setState(() {
                  _statusFilter = index == 0
                      ? null
                      : IncidentStatus.values[index - 1];
                });
                _loadAll();
              },
              tabs: <CustomTabItem>[
                const CustomTabItem(label: 'All'),
                ...IncidentStatus.values.map(
                  (IncidentStatus status) => CustomTabItem(label: status.label),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _FailureCard(message: _errorMessage!, onRetry: _loadAll)
            else if (_incidents.isEmpty)
              const CustomCard(child: Text('No incidents found for this view.'))
            else
              ..._incidents.map((IncidentRecord incident) {
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
                                    incident.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    incident.description,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                ToneBadge(
                                  label: incident.priority.label,
                                  tone: incident.priority.tone,
                                ),
                                const SizedBox(height: 8),
                                ToneBadge(
                                  label: incident.status.label,
                                  tone: incident.status.tone,
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
                            if (incident.location?.isNotEmpty == true)
                              ToneBadge(label: incident.location!, tone: UiTone.neutral),
                            if (incident.blockName?.isNotEmpty == true)
                              ToneBadge(label: incident.blockName!, tone: UiTone.brand),
                            if (incident.buildingName?.isNotEmpty == true)
                              ToneBadge(label: incident.buildingName!, tone: UiTone.neutral),
                            ToneBadge(
                              label: incident.isActive ? 'Active' : 'Inactive',
                              tone: incident.isActive
                                  ? UiTone.success
                                  : UiTone.neutral,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Created ${formatCompactDate(incident.createdAt)} at ${formatClock(incident.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textMuted,
                              ),
                        ),
                        if (incident.imageUrl?.isNotEmpty == true) ...<Widget>[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              incident.imageUrl!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext c, Widget child,
                                  ImageChunkEvent? progress) {
                                if (progress == null) {
                                  return child;
                                }
                                return Container(
                                  height: 120,
                                  color: AppTheme.border,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (BuildContext c, Object error,
                                      StackTrace? stack) =>
                                  Container(
                                height: 120,
                                color: AppTheme.border,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Text(
                              'Status:',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<int>(
                              value: _statusToApi(incident.status),
                              underline: const SizedBox(),
                              isDense: true,
                              onChanged: (int? newStatus) {
                                if (newStatus != null &&
                                    newStatus != _statusToApi(incident.status)) {
                                  _updateIncidentStatus(incident, newStatus);
                                }
                              },
                              items: const <DropdownMenuItem<int>>[
                                DropdownMenuItem<int>(
                                  value: 1,
                                  child: Text('Open'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 2,
                                  child: Text('Investigating'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 3,
                                  child: Text('Resolved'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: CustomButton(
                                label: 'View Details',
                                variant: CustomButtonVariant.outline,
                                onPressed: () => _showIncidentDetails(incident),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                label: 'Edit',
                                variant: CustomButtonVariant.outline,
                                onPressed: () => _openIncidentSheet(incident: incident),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            label: incident.isActive ? 'Deactivate' : 'Activate',
                            variant: incident.isActive
                                ? CustomButtonVariant.danger
                                : CustomButtonVariant.primary,
                            onPressed: () => _toggleIncident(incident),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String? _blockIdFromName(String? name) {
    for (final BlockData block in _blocks) {
      if (block.name == name) {
        return block.blockId;
      }
    }
    return null;
  }

  String? _buildingIdFromName(String? name) {
    for (final BuildingData building in _buildings) {
      if (building.name == name) {
        return building.buildingId;
      }
    }
    return null;
  }

  int? _priorityToApi(IncidentPriority? priority) {
    return switch (priority) {
      IncidentPriority.low => 1,
      IncidentPriority.medium => 2,
      IncidentPriority.high => 3,
      IncidentPriority.critical => 4,
      null => null,
    };
  }

  int _statusToApi(IncidentStatus status) {
    return switch (status) {
      IncidentStatus.open => 1,
      IncidentStatus.investigating => 2,
      IncidentStatus.resolved => 3,
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
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

class _FailureCard extends StatelessWidget {
  const _FailureCard({
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
            'Unable to load incidents',
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
