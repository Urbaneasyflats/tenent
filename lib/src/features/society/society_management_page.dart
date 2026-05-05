import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/block_building_service.dart';
import '../../core/api/society_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class SocietyManagementPage extends StatefulWidget {
  const SocietyManagementPage({super.key});

  @override
  State<SocietyManagementPage> createState() => _SocietyManagementPageState();
}

class _SocietyManagementPageState extends State<SocietyManagementPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _year = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lng = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _one = TextEditingController();
  final TextEditingController _two = TextEditingController();
  final TextEditingController _three = TextEditingController();
  final TextEditingController _four = TextEditingController();
  final TextEditingController _villa = TextEditingController();
  final TextEditingController _billDay = TextEditingController();
  final TextEditingController _dueDays = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _error;
  String? _success;
  SocietyData? _society;
  List<BlockData> _blocks = <BlockData>[];
  List<BuildingData> _buildings = <BuildingData>[];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _name, _phone, _email, _year, _lat, _lng, _location, _address, _one,
      _two, _three, _four, _villa, _billDay, _dueDays,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final SocietyData? society = await SocietyService.fetchSocietyInfo();
      List<BlockData> blocks = <BlockData>[];
      List<BuildingData> buildings = <BuildingData>[];
      if (society != null && society.societyId.isNotEmpty) {
        final blockResult = await BlockBuildingService.filterBlocks(
          society.societyId,
          limit: 100,
        );
        final buildingResult = await BlockBuildingService.filterBuildings(
          society.societyId,
          limit: 100,
        );
        blocks = blockResult.blocks;
        buildings = buildingResult.buildings;
        _fillForm(society);
      } else {
        _fillDefaults();
      }
      if (!mounted) return;
      setState(() {
        _society = society;
        _blocks = blocks;
        _buildings = buildings;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _fillDefaults() {
    _name.text = '';
    _phone.text = '';
    _email.text = '';
    _year.text = '${DateTime.now().year}';
    _lat.text = '0';
    _lng.text = '0';
    _location.text = '';
    _address.text = '';
    _one.text = '0';
    _two.text = '0';
    _three.text = '0';
    _four.text = '0';
    _villa.text = '0';
    _billDay.text = '1';
    _dueDays.text = '15';
  }

  void _fillForm(SocietyData society) {
    _name.text = society.name;
    _phone.text = society.phone ?? '';
    _email.text = society.email ?? '';
    _year.text = society.estYear ?? '${DateTime.now().year}';
    _lat.text = '${society.latitude ?? 0}';
    _lng.text = '${society.longitude ?? 0}';
    _location.text = society.locationAddress ?? '';
    _address.text = society.address;
    _one.text = society.maintenanceRates.oneBhk.toStringAsFixed(0);
    _two.text = society.maintenanceRates.twoBhk.toStringAsFixed(0);
    _three.text = society.maintenanceRates.threeBhk.toStringAsFixed(0);
    _four.text = society.maintenanceRates.fourBhk.toStringAsFixed(0);
    _villa.text = society.maintenanceRates.villa.toStringAsFixed(0);
    _billDay.text = '${society.billingConfig.billGenerationDate}';
    _dueDays.text = '${society.billingConfig.paymentDueDays}';
  }

  SocietyMaintenanceRates get _rates => SocietyMaintenanceRates(
        oneBhk: double.tryParse(_one.text.trim()) ?? 0,
        twoBhk: double.tryParse(_two.text.trim()) ?? 0,
        threeBhk: double.tryParse(_three.text.trim()) ?? 0,
        fourBhk: double.tryParse(_four.text.trim()) ?? 0,
        villa: double.tryParse(_villa.text.trim()) ?? 0,
      );

  SocietyBillingConfig get _billing => SocietyBillingConfig(
        billGenerationDate: int.tryParse(_billDay.text.trim()) ?? 1,
        paymentDueDays: int.tryParse(_dueDays.text.trim()) ?? 15,
      );

  void _setFeedback({String? error, String? success}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _error = error;
      _success = success;
    });
  }

  Future<void> _save() async {
    final List<String> errors = SocietyService.validateSocietyForm(
      name: _name.text,
      phoneNumber: _phone.text,
      emailId: _email.text,
      estYear: int.tryParse(_year.text.trim()) ?? 0,
      latitude: double.tryParse(_lat.text.trim()),
      longitude: double.tryParse(_lng.text.trim()),
      locationAddress: _location.text,
      address: _address.text,
      billingConfig: _billing,
    );
    if (errors.isNotEmpty) {
      setState(() => _error = errors.join('\n'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      if (_society == null) {
        final ApiResponse response = await SocietyService.createSociety(
          name: _name.text,
          countryCode: '+91',
          phoneNumber: _phone.text,
          emailId: _email.text,
          estYear: int.tryParse(_year.text.trim()) ?? 0,
          latitude: double.tryParse(_lat.text.trim()) ?? 0,
          longitude: double.tryParse(_lng.text.trim()) ?? 0,
          locationAddress: _location.text,
          address: _address.text,
          maintenanceRates: _rates,
          billingConfig: _billing,
        );
        _ensureResponseSuccess(
          response,
          'Unable to create the society profile.',
        );
        final int freeResidentsCount = _readFreeResidentsCount(response);
        _success = 'Society created successfully.';
        _editing = false;
        await _loadAll();
        if (!mounted) {
          return;
        }
        await _showCreatedSocietyDialog(freeResidentsCount);
      } else {
        final ApiResponse response = await SocietyService.editSociety(
          societyId: _society!.societyId,
          name: _name.text,
          countryCode: _society!.countryCode ?? '+91',
          phoneNumber: _phone.text,
          emailId: _email.text,
          estYear: int.tryParse(_year.text.trim()) ?? 0,
          latitude: double.tryParse(_lat.text.trim()) ?? 0,
          longitude: double.tryParse(_lng.text.trim()) ?? 0,
          locationAddress: _location.text,
          address: _address.text,
          maintenanceRates: _rates,
          billingConfig: _billing,
        );
        _ensureResponseSuccess(
          response,
          'Unable to update the society profile.',
        );
        _success = 'Society updated successfully.';
        _editing = false;
        await _loadAll();
      }
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editBlock({BlockData? block}) async {
    final TextEditingController controller =
        TextEditingController(text: block?.name ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        bool saving = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> submit() async {
              if ((_society?.societyId ?? '').isEmpty ||
                  controller.text.trim().isEmpty) {
                return;
              }
              setModalState(() => saving = true);
              try {
                final ApiResponse response;
                if (block == null) {
                  response = await BlockBuildingService.createBlock(
                    _society!.societyId,
                    controller.text.trim(),
                  );
                } else {
                  response = await BlockBuildingService.editBlock(
                    block.blockId,
                    controller.text.trim(),
                  );
                }
                _ensureResponseSuccess(
                  response,
                  block == null
                      ? 'Unable to create the block.'
                      : 'Unable to update the block.',
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                _setFeedback(
                  success: block == null
                      ? 'Block created successfully.'
                      : 'Block updated successfully.',
                );
                await _loadAll();
              } catch (error) {
                if (mounted) {
                  setModalState(() => saving = false);
                }
                _setFeedback(
                  error: error.toString().replaceFirst('Exception: ', ''),
                );
              }
            }

            return _nameSheet(
              context,
              title: block == null ? 'Add Block' : 'Edit Block',
              label: 'Block name',
              controller: controller,
              saving: saving,
              onSubmit: submit,
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _editBuilding({BuildingData? building}) async {
    final List<BlockData> availableBlocks = building == null
        ? _blocks.where((BlockData item) => item.status).toList()
        : _blocks;
    if (availableBlocks.isEmpty) {
      _setFeedback(
        error: building == null
            ? 'Create an active block first before adding buildings.'
            : 'No matching block is available for this building.',
      );
      return;
    }
    final TextEditingController controller =
        TextEditingController(text: building?.name ?? '');
    String? blockId = building?.blockId;
    if (!availableBlocks.any((BlockData item) => item.blockId == blockId)) {
      blockId = availableBlocks.first.blockId;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        bool saving = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> submit() async {
              if (controller.text.trim().isEmpty || (blockId ?? '').isEmpty) {
                return;
              }
              setModalState(() => saving = true);
              try {
                final ApiResponse response;
                if (building == null) {
                  response = await BlockBuildingService.createBuilding(
                    <String, dynamic>{
                      'BlockID': blockId,
                      'Name': controller.text.trim(),
                    },
                  );
                } else {
                  response = await BlockBuildingService.editBuilding(
                    <String, dynamic>{
                      'BuildingID': building.buildingId,
                      'Name': controller.text.trim(),
                    },
                  );
                }
                _ensureResponseSuccess(
                  response,
                  building == null
                      ? 'Unable to create the building.'
                      : 'Unable to update the building.',
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                _setFeedback(
                  success: building == null
                      ? 'Building created successfully.'
                      : 'Building updated successfully.',
                );
                await _loadAll();
              } catch (error) {
                if (mounted) {
                  setModalState(() => saving = false);
                }
                _setFeedback(
                  error: error.toString().replaceFirst('Exception: ', ''),
                );
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
                      building == null ? 'Add Building' : 'Edit Building',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: blockId,
                      decoration: const InputDecoration(labelText: 'Block'),
                      items: availableBlocks
                          .map(
                            (BlockData item) => DropdownMenuItem<String>(
                              value: item.blockId,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: building == null
                          ? (String? value) {
                              setModalState(() => blockId = value);
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration:
                          const InputDecoration(labelText: 'Building name'),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      label: building == null ? 'Save Building' : 'Update Building',
                      isLoading: saving,
                      onPressed: saving ? null : submit,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _toggleBlock(BlockData block) async {
    try {
      final ApiResponse response = await BlockBuildingService.toggleBlock(
        block.blockId,
        active: !block.status,
      );
      _ensureResponseSuccess(
        response,
        'Unable to update the block status.',
      );
      _setFeedback(
        success: block.status
            ? 'Block inactivated successfully.'
            : 'Block activated successfully.',
      );
      await _loadAll();
    } catch (error) {
      _setFeedback(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _toggleBuilding(BuildingData building) async {
    try {
      final ApiResponse response = await BlockBuildingService.toggleBuilding(
        building.buildingId,
        active: !building.status,
      );
      _ensureResponseSuccess(
        response,
        'Unable to update the building status.',
      );
      _setFeedback(
        success: building.status
            ? 'Building inactivated successfully.'
            : 'Building activated successfully.',
      );
      await _loadAll();
    } catch (error) {
      _setFeedback(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Society Management'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            const PageHeader(
              title: 'Society Management',
              description:
                  'Create or edit the society profile, maintenance rules, billing configuration, blocks, and buildings with live backend APIs.',
            ),
            const SizedBox(height: 16),
            if (_error != null)
              _messageCard(context, 'Issue', _error!, UiTone.danger),
            if (_success != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _messageCard(context, 'Updated', _success!, UiTone.success),
              ),
            if (_loading && _society == null)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_society == null && !_editing)
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'No society found',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create the society profile first to unlock the rest of the society workflows.',
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'Create Society',
                      icon: const Icon(Icons.add_business_outlined),
                      onPressed: () => setState(() => _editing = true),
                    ),
                  ],
                ),
              )
            else if (_society != null && !_editing) ...<Widget>[
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _society!.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ToneBadge(
                          label: _society!.isActive ? 'Active' : 'Inactive',
                          tone: _society!.isActive ? UiTone.success : UiTone.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(_society!.address),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if ((_society!.phone ?? '').isNotEmpty)
                          ToneBadge(label: _society!.phone!, tone: UiTone.neutral),
                        if ((_society!.email ?? '').isNotEmpty)
                          ToneBadge(label: _society!.email!, tone: UiTone.neutral),
                        ToneBadge(
                          label:
                              '${_society!.availableResidentsCreationCount ?? 0} resident slots available',
                          tone: UiTone.success,
                        ),
                        ToneBadge(
                          label: '${_blocks.length} blocks',
                          tone: UiTone.brand,
                        ),
                        ToneBadge(
                          label: '${_buildings.length} buildings',
                          tone: UiTone.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'Edit Society',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => setState(() => _editing = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _setupProgressCard(context),
              const SizedBox(height: 12),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Maintenance And Billing',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ToneBadge(
                          label: '1 BHK Rs ${_society!.maintenanceRates.oneBhk.toStringAsFixed(0)}',
                          tone: UiTone.brand,
                        ),
                        ToneBadge(
                          label: '2 BHK Rs ${_society!.maintenanceRates.twoBhk.toStringAsFixed(0)}',
                          tone: UiTone.brand,
                        ),
                        ToneBadge(
                          label: '3 BHK Rs ${_society!.maintenanceRates.threeBhk.toStringAsFixed(0)}',
                          tone: UiTone.brand,
                        ),
                        ToneBadge(
                          label: '4 BHK Rs ${_society!.maintenanceRates.fourBhk.toStringAsFixed(0)}',
                          tone: UiTone.brand,
                        ),
                        ToneBadge(
                          label: 'Villa Rs ${_society!.maintenanceRates.villa.toStringAsFixed(0)}',
                          tone: UiTone.brand,
                        ),
                        ToneBadge(
                          label: 'Bill day ${_society!.billingConfig.billGenerationDate}',
                          tone: UiTone.success,
                        ),
                        ToneBadge(
                          label: 'Due in ${_society!.billingConfig.paymentDueDays} days',
                          tone: UiTone.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _entityCard<BlockData>(
                context,
                title: 'Blocks',
                items: _blocks,
                label: (BlockData item) => item.name,
                subtitle: (BlockData item) =>
                    item.status ? 'Active block' : 'Inactive block',
                onAdd: () => _editBlock(),
                onEdit: (BlockData item) => _editBlock(block: item),
                onToggle: _toggleBlock,
              ),
              const SizedBox(height: 12),
              _entityCard<BuildingData>(
                context,
                title: 'Buildings',
                items: _buildings,
                label: (BuildingData item) => item.name,
                subtitle: (BuildingData item) {
                  final String blockName = _blockNameFor(item.blockId);
                  final String stateLabel =
                      item.status ? 'Active building' : 'Inactive building';
                  return blockName.isEmpty
                      ? stateLabel
                      : '$stateLabel - $blockName';
                },
                onAdd: () => _editBuilding(),
                onEdit: (BuildingData item) => _editBuilding(building: item),
                onToggle: _toggleBuilding,
                onBulk: _buildings.length > 1 ? _openBuildingsBulkSheet : null,
              ),
            ] else
              _formCard(context),
          ],
        ),
      ),
    );
  }

  Widget _formCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _society == null ? 'Create Society' : 'Edit Society',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the same core fields as the website society setup flow: identity, contact, address, maintenance rates, and billing defaults.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Society name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: 'Phone number'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _year,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Establishment year',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _location,
                      decoration: const InputDecoration(
                        labelText: 'Location address',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _address,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Full address'),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _lat,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lng,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Maintenance Rates',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _one,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '1 BHK',
                        prefixText: 'Rs ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _two,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '2 BHK',
                        prefixText: 'Rs ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _three,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '3 BHK',
                        prefixText: 'Rs ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _four,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '4 BHK',
                        prefixText: 'Rs ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _villa,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Villa',
                  prefixText: 'Rs ',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Billing Configuration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _billDay,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bill generation day',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _dueDays,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Payment due days',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: CustomButton(
                label: 'Cancel',
                variant: CustomButtonVariant.outline,
                onPressed: _saving
                    ? null
                    : () {
                        setState(() {
                          _editing = false;
                          _error = null;
                          if (_society != null) {
                            _fillForm(_society!);
                          } else {
                            _fillDefaults();
                          }
                        });
                      },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                label: _society == null ? 'Create Society' : 'Save Changes',
                icon: Icon(
                  _society == null
                      ? Icons.add_business_outlined
                      : Icons.save_outlined,
                ),
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _setupProgressCard(BuildContext context) {
    final int freeResidents = _society?.freeResidentsCount ?? 0;
    final int availableResidents =
        _society?.availableResidentsCreationCount ?? freeResidents;
    final bool hasBlocks = _blocks.isNotEmpty;
    final bool hasBuildings = _buildings.isNotEmpty;

    return CustomCard(
      color: AppTheme.primarySoft,
      borderColor: AppTheme.primaryTone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Setup Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'The website flow guides setup in order: create society, add blocks, add buildings, then start residents and billing.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 14),
          _SetupStepRow(
            title: '1. Society profile',
            subtitle: 'Identity, address, maintenance rates, and billing config.',
            complete: _society != null,
          ),
          _SetupStepRow(
            title: '2. Blocks',
            subtitle: hasBlocks
                ? '${_blocks.length} block${_blocks.length == 1 ? '' : 's'} added.'
                : 'Add the first block before creating buildings.',
            complete: hasBlocks,
          ),
          _SetupStepRow(
            title: '3. Buildings',
            subtitle: hasBuildings
                ? '${_buildings.length} building${_buildings.length == 1 ? '' : 's'} added.'
                : 'Add at least one building under an active block.',
            complete: hasBuildings,
          ),
          _SetupStepRow(
            title: '4. Residents',
            subtitle: availableResidents > 0
                ? '$availableResidents resident slot${availableResidents == 1 ? '' : 's'} available.'
                : 'Resident slots are fully used right now.',
            complete: availableResidents > 0,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              CustomButton(
                label: 'Add Block',
                icon: const Icon(Icons.view_module_outlined),
                onPressed: _society == null ? null : () => _editBlock(),
              ),
              CustomButton(
                label: 'Add Building',
                variant: CustomButtonVariant.outline,
                icon: const Icon(Icons.apartment_outlined),
                onPressed: _society == null ? null : () => _editBuilding(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _blockNameFor(String? blockId) {
    if ((blockId ?? '').isEmpty) {
      return '';
    }
    for (final BlockData block in _blocks) {
      if (block.blockId == blockId) {
        return block.name;
      }
    }
    return '';
  }

  Future<void> _showCreatedSocietyDialog(int freeResidentsCount) async {
    final bool? openBlockFlow = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Congratulations'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Your society has been created successfully.',
              ),
              const SizedBox(height: 16),
              CustomCard(
                padding: CustomCardPadding.sm,
                color: AppTheme.primarySoft,
                borderColor: AppTheme.primaryTone,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$freeResidentsCount free resident slot${freeResidentsCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Next step: add blocks, then buildings, then start creating residents.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add Block'),
            ),
          ],
        );
      },
    );

    if (!mounted || openBlockFlow != true) {
      return;
    }
    await _editBlock();
  }

  Future<void> _openBuildingsBulkSheet() async {
    final Set<String> selected = <String>{};
    bool processing = false;
    String? sheetError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> applyBulk({required bool activate}) async {
              if (selected.isEmpty) return;
              setModalState(() {
                processing = true;
                sheetError = null;
              });
              try {
                for (final String buildingId in selected) {
                  final List<BuildingData> matching = _buildings
                      .where((BuildingData b) => b.buildingId == buildingId)
                      .toList();
                  if (matching.isEmpty) continue;
                  final BuildingData building = matching.first;
                  if (building.status != activate) {
                    await BlockBuildingService.toggleBuilding(
                      buildingId,
                      active: activate,
                    );
                  }
                }
                if (!mounted) return;
                Navigator.of(context).pop();
                _setFeedback(
                  success: activate
                      ? '${selected.length} building${selected.length == 1 ? '' : 's'} activated.'
                      : '${selected.length} building${selected.length == 1 ? '' : 's'} deactivated.',
                );
                await _loadAll();
              } catch (error) {
                setModalState(() {
                  processing = false;
                  sheetError =
                      error.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            final int count = selected.length;

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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Bulk Manage Buildings',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (count > 0)
                          Text(
                            '$count selected',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select buildings then activate or deactivate them all at once.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    if (sheetError != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        sheetError!,
                        style: TextStyle(
                          color: AppTheme.toneColor(UiTone.danger),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ..._buildings.map((BuildingData building) {
                      final bool isSelected =
                          selected.contains(building.buildingId);
                      final String blockName =
                          _blockNameFor(building.blockId);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: processing
                            ? null
                            : (bool? value) {
                                setModalState(() {
                                  if (value == true) {
                                    selected.add(building.buildingId);
                                  } else {
                                    selected.remove(building.buildingId);
                                  }
                                });
                              },
                        title: Text(building.name),
                        subtitle: Text(
                          blockName.isEmpty
                              ? (building.status ? 'Active' : 'Inactive')
                              : '$blockName · ${building.status ? 'Active' : 'Inactive'}',
                        ),
                        secondary: ToneBadge(
                          label: building.status ? 'Active' : 'Inactive',
                          tone: building.status
                              ? UiTone.success
                              : UiTone.warning,
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                    const SizedBox(height: 16),
                    if (_buildings.isEmpty)
                      Text(
                        'No buildings available.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      )
                    else
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: CustomButton(
                              label: count > 0
                                  ? 'Activate ($count)'
                                  : 'Activate',
                              isLoading: processing,
                              onPressed: (processing || count == 0)
                                  ? null
                                  : () => applyBulk(activate: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              label: count > 0
                                  ? 'Deactivate ($count)'
                                  : 'Deactivate',
                              variant: CustomButtonVariant.outline,
                              isLoading: processing,
                              onPressed: (processing || count == 0)
                                  ? null
                                  : () => applyBulk(activate: false),
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
  }

  void _ensureResponseSuccess(ApiResponse response, String fallbackMessage) {
    if (!response.success) {
      throw Exception(
        response.message ?? response.status ?? fallbackMessage,
      );
    }
  }

  int _readFreeResidentsCount(ApiResponse response) {
    final dynamic raw = response.extras['Free_Society_Residents_Count'];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw) ?? 0;
    }
    return 0;
  }
}

Widget _messageCard(
  BuildContext context,
  String title,
  String message,
  UiTone tone,
) {
  return CustomCard(
    color: AppTheme.toneSoft(tone),
    borderColor: AppTheme.toneColor(tone).withValues(alpha: 0.2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ToneBadge(label: title, tone: tone),
        const SizedBox(height: 10),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    ),
  );
}

Widget _entityCard<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T item) label,
  required String Function(T item) subtitle,
  required VoidCallback onAdd,
  required ValueChanged<T> onEdit,
  required ValueChanged<T> onToggle,
  VoidCallback? onBulk,
}) {
  return CustomCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (onBulk != null)
              IconButton(
                onPressed: onBulk,
                icon: const Icon(Icons.checklist_outlined),
                tooltip: 'Bulk manage',
              ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (items.isEmpty)
          Text(
            'No ${title.toLowerCase()} added yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          )
        else
          ...items.map(
            (T item) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(label(item)),
                        const SizedBox(height: 4),
                        Text(
                          subtitle(item),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => onEdit(item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: () => onToggle(item),
                    icon: const Icon(Icons.toggle_on_outlined),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _nameSheet(
  BuildContext context, {
  required String title,
  required String label,
  required TextEditingController controller,
  required bool saving,
  required Future<void> Function() onSubmit,
}) {
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
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
          ),
          const SizedBox(height: 20),
          CustomButton(
            label: title,
            isLoading: saving,
            onPressed: saving ? null : () => onSubmit(),
          ),
        ],
      ),
    ),
  );
}

class _SetupStepRow extends StatelessWidget {
  const _SetupStepRow({
    required this.title,
    required this.subtitle,
    required this.complete,
  });

  final String title;
  final String subtitle;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final UiTone tone = complete ? UiTone.success : UiTone.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              complete ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 18,
              color: AppTheme.toneColor(tone),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
