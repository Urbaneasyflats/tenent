import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/property_service.dart';
import '../../core/api/razorpay_checkout_service.dart';
import '../../core/api/subscription_service.dart';
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

const Map<int, String> _propertyTypeLabels = <int, String>{
  1: 'Apartment',
  2: 'Villa',
  3: 'PG',
  4: 'Commercial',
};

const Map<int, Map<int, String>> _propertySubTypeLabels =
    <int, Map<int, String>>{
      1: <int, String>{
        1: '1 BHK',
        2: '2 BHK',
        3: '3 BHK',
        4: '4 BHK',
        5: 'Studio',
      },
      2: <int, String>{
        1: '2 BHK Villa',
        2: '3 BHK Villa',
        3: '4 BHK Villa',
        4: 'Duplex Villa',
      },
      3: <int, String>{
        1: 'Mens PG',
        2: 'Womens PG',
        3: 'Coliving',
      },
      4: <int, String>{
        1: 'Office',
        2: 'Retail',
        3: 'Warehouse',
        4: 'Showroom',
      },
    };

const Map<int, String> _pgSharingLabels = <int, String>{
  1: 'Single',
  2: 'Double',
  3: 'Triple',
  4: 'Quad',
  5: 'Dorm',
};

const Map<int, String> _categoryTypeLabels = <int, String>{
  1: 'Rent',
  2: 'Lease',
};

const Map<int, String> _facingDirectionLabels = <int, String>{
  0: 'Not Specified',
  1: 'North',
  2: 'South',
  3: 'East',
  4: 'West',
  5: 'North East',
  6: 'North West',
  7: 'South East',
  8: 'South West',
};

const Map<int, String> _furnishedTypeLabels = <int, String>{
  0: 'Not Specified',
  1: 'Unfurnished',
  2: 'Semi-Furnished',
  3: 'Fully-Furnished',
};

const Map<int, String> _billTypeLabels = <int, String>{
  1: 'Included',
  2: 'Separate Meter',
  3: 'Shared',
  4: 'Not Available',
};

const Map<int, String> _parkingTypeLabels = <int, String>{
  1: 'Covered',
  2: 'Open',
  3: 'Basement',
};

const Map<int, String> _tenantTypeLabels = <int, String>{
  1: 'Any',
  2: 'Family Only',
  3: 'Bachelor Only',
  4: 'Students Only',
};

const Map<int, String> _petPolicyLabels = <int, String>{
  1: 'Not Allowed',
  2: 'Allowed',
  3: 'Conditional',
};

const Map<int, String> _smokingPolicyLabels = <int, String>{
  1: 'Not Allowed',
  2: 'Allowed',
};

const Map<int, String> _visitorsPolicyLabels = <int, String>{
  1: 'Not Allowed',
  2: 'Allowed',
  3: 'Restricted Hours',
};

const Map<int, String> _genderLabels = <int, String>{
  0: 'Any',
  1: 'Male',
  2: 'Female',
  3: 'Co-ed',
};

const Map<int, String> _propertyAmenityLabels = <int, String>{
  1: 'AC',
  2: 'Modular Kitchen',
  3: 'Wardrobes',
  4: 'Geyser',
  5: 'WiFi',
  6: 'Security',
  7: 'Lift',
  8: 'CCTV',
  9: 'Power Backup',
  10: 'Parking',
  11: 'Swimming Pool',
  12: 'Gym',
  13: 'Club House',
  14: 'Garden',
  15: "Children's Play Area",
  16: 'Intercom',
  17: 'Fire Safety',
  18: 'Maintenance Staff',
  19: 'Housekeeping',
  20: 'Meals Included',
  21: 'Playground',
  22: 'Laundry',
  23: 'Refrigerator',
  24: 'Microwave',
  25: 'TV',
  26: 'DTH',
  27: 'Sofa',
  28: 'Curtains',
  29: 'Beds',
  30: 'Cooking Utensils',
  31: 'Drinking Water',
  32: 'Hot Water',
  33: 'Visitor Parking',
  34: 'Elevator',
  35: 'Gas Connection',
  36: 'Water Purifier',
  37: 'Sewage Treatment Plant',
  38: 'Rain Water Harvesting',
  39: 'Meals Not Included',
};

class _UploadedAsset {
  const _UploadedAsset({
    required this.id,
    required this.label,
    this.url,
  });

  final String id;
  final String label;
  final String? url;
}

class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key});

  @override
  State<PropertiesPage> createState() => _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  PropertyStatus? _statusFilter;
  int? _typeFilter;
  String? _stateId;
  String? _cityId;
  int _page = 0;
  final int _pageSize = 20;
  int _totalCount = 0;
  List<PropertyRecord> _properties = <PropertyRecord>[];
  List<PropertyStateData> _states = <PropertyStateData>[];
  List<PropertyCityData> _cities = <PropertyCityData>[];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        PropertyService.filterStates(limit: 100),
        PropertyService.filterProperties(
          skip: _page * _pageSize,
          limit: _pageSize,
          typeFilter: _typeFilter,
          stateId: _stateId,
          cityId: _cityId,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ),
      ]);

      if (!mounted) {
        return;
      }

      final statesResult =
          results[0] as ({List<PropertyStateData> states, int count});
      final propertyResult =
          results[1] as ({List<PropertyRecord> properties, int count});

      setState(() {
        _states = statesResult.states;
        _properties = _applyStatusFilter(propertyResult.properties);
        _totalCount = propertyResult.count;
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

  List<PropertyRecord> _applyStatusFilter(List<PropertyRecord> items) {
    if (_statusFilter == null) {
      return items;
    }
    return items
        .where((PropertyRecord item) => item.status == _statusFilter)
        .toList();
  }

  Future<void> _loadCitiesForSelectedState() async {
    if ((_stateId ?? '').isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cities = <PropertyCityData>[];
        _cityId = null;
      });
      return;
    }

    try {
      final result = await PropertyService.filterCities(
        stateId: _stateId,
        limit: 100,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _cities = result.cities;
        if (_cityId != null &&
            !_cities.any((PropertyCityData item) => item.cityId == _cityId)) {
          _cityId = null;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cities = <PropertyCityData>[];
        _cityId = null;
      });
    }
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PropertyService.filterProperties(
        skip: _page * _pageSize,
        limit: _pageSize,
        typeFilter: _typeFilter,
        stateId: _stateId,
        cityId: _cityId,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _properties = _applyStatusFilter(result.properties);
        _totalCount = result.count;
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

  Future<void> _applyFilters() async {
    setState(() {
      _page = 0;
    });
    await _loadProperties();
  }

  Future<void> _clearFilters() async {
    _searchController.clear();
    setState(() {
      _statusFilter = null;
      _typeFilter = null;
      _stateId = null;
      _cityId = null;
      _page = 0;
      _cities = <PropertyCityData>[];
    });
    await _loadProperties();
  }

  Future<void> _toggleProperty(PropertyRecord property) async {
    final bool isDeactivating = property.status != PropertyStatus.inactive;
    if (isDeactivating) {
      final bool? confirmed = await _confirmAction(
        title: 'Deactivate Property',
        message:
            'Deactivating "${property.title}" will hide it from listings. You can reactivate it anytime. Continue?',
        confirmLabel: 'Deactivate',
      );
      if (confirmed != true) return;
    }
    try {
      if (property.status == PropertyStatus.inactive) {
        await PropertyService.activateProperty(property.id);
      } else {
        await PropertyService.inactivateProperty(property.id);
      }
      _showMessage('Property status updated.');
      await _loadProperties();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _openPropertySheet({
    String? propertyId,
    String? cloneFromPropertyId,
  }) async {
    final bool isClone = cloneFromPropertyId != null;
    final String? sourcePropertyId = propertyId ?? cloneFromPropertyId;
    final PropertyData? existing = sourcePropertyId == null
        ? null
        : await PropertyService.fetchPropertyInfo(sourcePropertyId);
    final List<PropertyStateData> modalStates = _states.isNotEmpty
        ? _states
        : (await PropertyService.filterStates(limit: 100)).states;
    String? selectedStateId = existing?.stateId;
    List<PropertyCityData> modalCities =
        selectedStateId == null || selectedStateId.isEmpty
            ? <PropertyCityData>[]
            : (await PropertyService.filterCities(
                stateId: selectedStateId,
                limit: 100,
              ))
                .cities;
    String? selectedCityId = existing?.cityId;

    final TextEditingController titleController = TextEditingController(
      text: isClone && existing != null
          ? '${existing.title} Copy'
          : existing?.title ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final TextEditingController unitController = TextEditingController(
      text: existing?.flatUnitNo ?? '',
    );
    final TextEditingController locationController = TextEditingController(
      text: existing?.locationAddress ?? existing?.address ?? '',
    );
    final TextEditingController addressController = TextEditingController(
      text: existing?.address ?? '',
    );
    final TextEditingController rentController = TextEditingController(
      text: existing?.rent.toStringAsFixed(0) ?? '',
    );
    final TextEditingController depositController = TextEditingController(
      text: existing?.deposit.toStringAsFixed(0) ?? '',
    );
    final TextEditingController areaController = TextEditingController(
      text: existing?.area?.toStringAsFixed(0) ?? '',
    );
    final TextEditingController bedroomsController = TextEditingController(
      text: existing?.bedrooms?.toString() ?? '',
    );
    final TextEditingController bathroomsController = TextEditingController(
      text: existing?.bathrooms?.toString() ?? '',
    );
    final TextEditingController ownerNameController = TextEditingController(
      text: existing?.ownerName ?? '',
    );
    final TextEditingController ownerPhoneController = TextEditingController(
      text: existing?.ownerPhone ?? '',
    );
    final TextEditingController ownerEmailController = TextEditingController(
      text: existing?.ownerEmail ?? '',
    );
    final TextEditingController availableFromController =
        TextEditingController(
      text: existing?.availableFrom?.split('T').first ??
          DateTime.now().toIso8601String().split('T').first,
    );
    final TextEditingController maintenanceController = TextEditingController(
      text: existing?.maintenance?.toStringAsFixed(0) ?? '0',
    );
    final TextEditingController brokerageController = TextEditingController(
      text: existing?.brokerage?.toStringAsFixed(0) ?? '0',
    );
    final TextEditingController carpetAreaController = TextEditingController(
      text: existing?.carpetArea?.toStringAsFixed(0) ?? '',
    );
    final TextEditingController floorNoController = TextEditingController(
      text: existing?.floor?.toString() ?? '0',
    );
    final TextEditingController noOfFloorsController = TextEditingController(
      text: existing?.noOfFloors?.toString() ?? '0',
    );
    final TextEditingController noOfVacancyController = TextEditingController(
      text: existing?.noOfVacancy?.toString() ?? '0',
    );
    final TextEditingController balconiesController = TextEditingController(
      text: existing?.balconies?.toString() ?? '0',
    );
    final TextEditingController localityController = TextEditingController(
      text: existing?.locality ?? '',
    );
    final TextEditingController pincodeController = TextEditingController(
      text: existing?.pincode ?? '',
    );
    final TextEditingController ownerAddressController = TextEditingController(
      text: existing?.ownerAddress ?? '',
    );
    final TextEditingController parkingSlotsController = TextEditingController(
      text: existing?.parkingSlots?.toString() ?? '0',
    );
    final TextEditingController parkingChargesController = TextEditingController(
      text: existing?.parkingCharges?.toStringAsFixed(0) ?? '0',
    );
    final TextEditingController metroController = TextEditingController(
      text: existing?.metroOrBusStation ?? '',
    );
    final TextEditingController hospitalController = TextEditingController(
      text: existing?.hospital ?? '',
    );
    final TextEditingController schoolController = TextEditingController(
      text: existing?.schoolOrCollege ?? '',
    );
    final TextEditingController shoppingMallController = TextEditingController(
      text: existing?.shoppingMall ?? '',
    );
    final TextEditingController restaurantController = TextEditingController(
      text: existing?.restaurant ?? '',
    );
    final TextEditingController atmController = TextEditingController(
      text: existing?.atmOrBank ?? '',
    );
    final TextEditingController rulesController = TextEditingController(
      text: existing?.propertyRulesDescription ?? '',
    );

    int propertyType = existing?.propertyType ?? 1;
    int subType = existing?.subType ??
        (_propertySubTypeLabels[propertyType]?.keys.first ?? 1);
    int pgSharingType = existing?.pgSharingType ?? 1;
    int categoryType = existing?.category ?? 1;
    int facingDirection = existing?.facing != null
        ? _facingDirectionLabels.entries
                .where((MapEntry<int, String> e) =>
                    e.value.toLowerCase() ==
                    existing!.facing!.toLowerCase())
                .map((MapEntry<int, String> e) => e.key)
                .firstOrNull ??
            0
        : 0;
    int furnishedType = existing?.furnishedType ?? 0;
    int gender = existing?.gender ?? 0;
    bool parkingAvailable = existing?.whetherParkingAvailable ?? false;
    int parkingType = existing?.parkingType ?? 1;
    int electricityBillType = existing?.electricityBillType ?? 1;
    int waterBillType = existing?.waterBillType ?? 1;
    int gasBillType = existing?.gasBillType ?? 4;
    int internetBillType = existing?.internetBillType ?? 4;
    int tenantType = existing?.preferredTenantType ?? 1;
    int petPolicy = existing?.petPolicy ?? 1;
    int smokingPolicy = existing?.smokingPolicy ?? 1;
    int visitorsPolicy = existing?.visitorsPolicy ?? 2;
    List<int> selectedAmenities =
        List<int>.from(existing?.amenityIds ?? <int>[1]);
    List<_UploadedAsset> propertyImages = <_UploadedAsset>[
      for (
        int index = 0;
        index < (existing?.imageIds?.length ?? 0);
        index += 1
      )
        _UploadedAsset(
          id: existing!.imageIds![index],
          label: 'Image ${index + 1}',
          url: index < (existing.images?.length ?? 0)
              ? existing.images![index]
              : null,
        ),
    ];
    _UploadedAsset? floorPlanDocument =
        (existing?.floorPlanDocumentId?.isNotEmpty ?? false)
            ? _UploadedAsset(
                id: existing!.floorPlanDocumentId!,
                label: 'Floor Plan',
                url: existing.floorPlanDocumentUrl,
              )
            : null;
    bool isSubmitting = false;
    bool isUploadingMedia = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> changeState(String? value) async {
              setModalState(() {
                selectedStateId = value;
                selectedCityId = null;
                modalCities = <PropertyCityData>[];
              });

              if (value == null || value.isEmpty) {
                return;
              }

              final result = await PropertyService.filterCities(
                stateId: value,
                limit: 100,
              );

              if (!mounted) {
                return;
              }
              setModalState(() {
                modalCities = result.cities;
              });
            }

            Future<void> uploadPropertyImages() async {
              final FilePickerResult? result = await FilePicker.platform
                  .pickFiles(
                allowMultiple: true,
                type: FileType.custom,
                allowedExtensions: <String>['jpg', 'jpeg', 'png', 'webp'],
              );

              if (result == null || result.files.isEmpty) {
                return;
              }

              setModalState(() {
                isUploadingMedia = true;
              });

              try {
                for (final PlatformFile file in result.files) {
                  if ((file.path ?? '').isEmpty) {
                    continue;
                  }
                  final String? imageId = await UploadService.uploadImage(
                    File(file.path!),
                  );
                  if (imageId == null || imageId.isEmpty) {
                    throw Exception('Failed to upload ${file.name}.');
                  }
                  final String? imageUrl =
                      await UploadService.fetchImageInfo(imageId);
                  if (!mounted) {
                    return;
                  }
                  setModalState(() {
                    if (!propertyImages.any(
                      (_UploadedAsset item) => item.id == imageId,
                    )) {
                      propertyImages = <_UploadedAsset>[
                        ...propertyImages,
                        _UploadedAsset(
                          id: imageId,
                          label: file.name,
                          url: imageUrl,
                        ),
                      ];
                    }
                  });
                }
              } catch (error) {
                _showMessage(error.toString().replaceFirst('Exception: ', ''));
              } finally {
                if (mounted) {
                  setModalState(() {
                    isUploadingMedia = false;
                  });
                }
              }
            }

            Future<void> uploadFloorPlan() async {
              final FilePickerResult? result = await FilePicker.platform
                  .pickFiles(
                allowMultiple: false,
                type: FileType.custom,
                allowedExtensions: <String>[
                  'pdf',
                  'png',
                  'jpg',
                  'jpeg',
                  'webp',
                ],
              );

              if (result == null ||
                  result.files.isEmpty ||
                  (result.files.single.path ?? '').isEmpty) {
                return;
              }

              setModalState(() {
                isUploadingMedia = true;
              });

              try {
                final PlatformFile file = result.files.single;
                final String? documentId = await UploadService.uploadDocument(
                  File(file.path!),
                );
                if (documentId == null || documentId.isEmpty) {
                  throw Exception('Failed to upload the floor plan.');
                }
                final String? documentUrl =
                    await UploadService.fetchDocumentInfo(documentId);
                if (!mounted) {
                  return;
                }
                setModalState(() {
                  floorPlanDocument = _UploadedAsset(
                    id: documentId,
                    label: file.name,
                    url: documentUrl,
                  );
                });
              } catch (error) {
                _showMessage(error.toString().replaceFirst('Exception: ', ''));
              } finally {
                if (mounted) {
                  setModalState(() {
                    isUploadingMedia = false;
                  });
                }
              }
            }

            Future<void> submit() async {
              if (titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty ||
                  unitController.text.trim().isEmpty ||
                  locationController.text.trim().isEmpty ||
                  addressController.text.trim().isEmpty ||
                  availableFromController.text.trim().isEmpty ||
                  ownerNameController.text.trim().isEmpty ||
                  ownerPhoneController.text.trim().isEmpty ||
                  ownerEmailController.text.trim().isEmpty) {
                _showMessage(
                  'Title, description, unit, location, address, availability date, and owner contact fields are required.',
                );
                return;
              }

              if (selectedAmenities.isEmpty) {
                _showMessage('Select at least one amenity.');
                return;
              }

              setModalState(() {
                isSubmitting = true;
              });

              final Map<String, dynamic> payload = <String, dynamic>{
                if (propertyId != null) 'PropertyID': propertyId,
                'Property_Title': titleController.text.trim(),
                'Property_Description': descriptionController.text.trim(),
                'Flat_Or_Unit_No': unitController.text.trim(),
                'Property_Type': propertyType,
                'Category_Type': categoryType,
                'Sub_Type': subType,
                'Facing_Direction_Type': facingDirection,
                'Furnished_Type': furnishedType,
                'Floor_No':
                    int.tryParse(floorNoController.text.trim()) ?? 0,
                'No_Of_Floors':
                    int.tryParse(noOfFloorsController.text.trim()) ?? 0,
                'No_Of_Vacancy':
                    int.tryParse(noOfVacancyController.text.trim()) ?? 0,
                'PG_Sharing_Type': propertyType == 3 ? pgSharingType : 0,
                'Gender': propertyType == 3 ? gender : 0,
                'Total_Area':
                    double.tryParse(areaController.text.trim()) ?? 0,
                'Carpet_Area':
                    double.tryParse(carpetAreaController.text.trim()) ?? 0,
                'Bedrooms':
                    int.tryParse(bedroomsController.text.trim()) ?? 0,
                'Bathrooms':
                    int.tryParse(bathroomsController.text.trim()) ?? 0,
                'Balconies':
                    int.tryParse(balconiesController.text.trim()) ?? 0,
                'Locality': localityController.text.trim(),
                'Pincode': pincodeController.text.trim(),
                'Monthly_Rent':
                    double.tryParse(rentController.text.trim()) ?? 0,
                'Security_Deposit':
                    double.tryParse(depositController.text.trim()) ?? 0,
                'Maintainance_Charge':
                    double.tryParse(maintenanceController.text.trim()) ?? 0,
                'Brokerage_Percentage':
                    double.tryParse(brokerageController.text.trim()) ?? 0,
                'Available_From': availableFromController.text.trim(),
                'Electricity_Bill_Type': electricityBillType,
                'Water_Bill_Type': waterBillType,
                'Gas_Bill_Type': gasBillType,
                'Internet_Bill_Type': internetBillType,
                'Whether_Parking_Available': parkingAvailable,
                'Parking_Type': parkingAvailable ? parkingType : 1,
                'Parking_Slots': parkingAvailable
                    ? (int.tryParse(parkingSlotsController.text.trim()) ?? 0)
                    : 0,
                'Parking_Charges': parkingAvailable
                    ? (double.tryParse(
                            parkingChargesController.text.trim()) ??
                        0)
                    : 0,
                'Amenities': selectedAmenities,
                'Metro_Or_Bus_Station': metroController.text.trim(),
                'Hospital': hospitalController.text.trim(),
                'School_Or_College': schoolController.text.trim(),
                'Shopping_Mall': shoppingMallController.text.trim(),
                'Restaurant': restaurantController.text.trim(),
                'ATM_Or_Bank': atmController.text.trim(),
                'Preferred_Tenant_Type': tenantType,
                'Pet_Policy': petPolicy,
                'Smoking_Policy': smokingPolicy,
                'Visitors_Policy': visitorsPolicy,
                'Property_Rules_Description': rulesController.text.trim(),
                'Owner_Name': ownerNameController.text.trim(),
                'Owner_Phone': ownerPhoneController.text.trim(),
                'Owner_Email': ownerEmailController.text.trim(),
                'Owner_Address': ownerAddressController.text.trim(),
                'Whether_Property_Image_Array_Available':
                    propertyImages.isNotEmpty,
                'Property_ImageID_Array': propertyImages
                    .map((_UploadedAsset item) => item.id)
                    .toList(),
                'Whether_Floor_Plan_Document_Available':
                    floorPlanDocument != null,
                'Floor_Plan_DocumentID': floorPlanDocument?.id ?? '',
                'Latitude': existing?.latitude ?? 0,
                'Longitude': existing?.longitude ?? 0,
                'Location_Address': locationController.text.trim(),
                'Address': addressController.text.trim(),
                'Whether_State_Available':
                    selectedStateId != null && selectedStateId!.isNotEmpty,
                'StateID': selectedStateId ?? '',
                'Whether_City_Available':
                    selectedCityId != null && selectedCityId!.isNotEmpty,
                'CityID': selectedCityId ?? '',
              };

              try {
                if (propertyId == null) {
                  await PropertyService.createProperty(payload);
                } else {
                  await PropertyService.editProperty(payload);
                }
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pop();
                _showMessage(
                  isClone
                      ? 'Property cloned successfully.'
                      : propertyId == null
                      ? 'Property created successfully.'
                      : 'Property updated successfully.',
                );
                await _loadProperties();
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
                      isClone
                          ? 'Clone Property'
                          : propertyId == null
                              ? 'Add Property'
                              : 'Edit Property',
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
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Flat or unit no',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: propertyType,
                            decoration: const InputDecoration(
                              labelText: 'Property type',
                            ),
                            items: _propertyTypeLabels.entries
                                .map(
                                  (MapEntry<int, String> entry) =>
                                      DropdownMenuItem<int>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? value) {
                              setModalState(() {
                                propertyType = value ?? 1;
                                final Map<int, String> options =
                                    _propertySubTypeLabels[propertyType] ??
                                        const <int, String>{};
                                if (!options.containsKey(subType)) {
                                  subType =
                                      options.isEmpty ? 1 : options.keys.first;
                                }
                                if (propertyType != 3) {
                                  pgSharingType = 1;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: subType,
                            decoration:
                                const InputDecoration(labelText: 'Subtype'),
                            items: (_propertySubTypeLabels[propertyType] ??
                                    const <int, String>{})
                                .entries
                                .map(
                                  (MapEntry<int, String> entry) =>
                                      DropdownMenuItem<int>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? value) {
                              setModalState(() {
                                subType = value ?? subType;
                              });
                            },
                          ),
                        ),
                        if (propertyType == 3) ...<Widget>[
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: pgSharingType,
                              decoration:
                                  const InputDecoration(labelText: 'PG sharing'),
                              items: _pgSharingLabels.entries
                                  .map(
                                    (MapEntry<int, String> entry) =>
                                        DropdownMenuItem<int>(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (int? value) {
                                setModalState(() {
                                  pgSharingType = value ?? 1;
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: categoryType,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: _categoryTypeLabels.entries
                                .map(
                                  (MapEntry<int, String> entry) =>
                                      DropdownMenuItem<int>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? value) {
                              setModalState(() {
                                categoryType = value ?? 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: furnishedType,
                            decoration: const InputDecoration(
                              labelText: 'Furnished',
                            ),
                            items: _furnishedTypeLabels.entries
                                .map(
                                  (MapEntry<int, String> entry) =>
                                      DropdownMenuItem<int>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? value) {
                              setModalState(() {
                                furnishedType = value ?? 0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: facingDirection,
                      decoration: const InputDecoration(
                        labelText: 'Facing direction',
                      ),
                      items: _facingDirectionLabels.entries
                          .map(
                            (MapEntry<int, String> entry) =>
                                DropdownMenuItem<int>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (int? value) {
                        setModalState(() {
                          facingDirection = value ?? 0;
                        });
                      },
                    ),
                    if (propertyType == 3) ...<Widget>[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender preference',
                        ),
                        items: _genderLabels.entries
                            .map(
                              (MapEntry<int, String> entry) =>
                                  DropdownMenuItem<int>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (int? value) {
                          setModalState(() {
                            gender = value ?? 0;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: availableFromController,
                      decoration: const InputDecoration(
                        labelText: 'Available from',
                        hintText: 'YYYY-MM-DD',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location address',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: localityController,
                            decoration: const InputDecoration(
                              labelText: 'Locality',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pincode',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: selectedStateId,
                            decoration:
                                const InputDecoration(labelText: 'State'),
                            items: <DropdownMenuItem<String?>>[
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Select state'),
                              ),
                              ...modalStates.map(
                                (PropertyStateData state) =>
                                    DropdownMenuItem<String?>(
                                  value: state.stateId,
                                  child: Text(state.stateName),
                                ),
                              ),
                            ],
                            onChanged: changeState,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: selectedCityId,
                            decoration:
                                const InputDecoration(labelText: 'City'),
                            items: <DropdownMenuItem<String?>>[
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Select city'),
                              ),
                              ...modalCities.map(
                                (PropertyCityData city) =>
                                    DropdownMenuItem<String?>(
                                  value: city.cityId,
                                  child: Text(city.cityName),
                                ),
                              ),
                            ],
                            onChanged: (String? value) {
                              setModalState(() {
                                selectedCityId = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: rentController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Monthly rent',
                              prefixText: 'Rs ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: depositController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Security deposit',
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
                            controller: maintenanceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Maintenance charge',
                              prefixText: 'Rs ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: brokerageController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Brokerage %',
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
                            controller: areaController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(labelText: 'Area'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: bedroomsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Bedrooms'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: bathroomsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Bathrooms'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: carpetAreaController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Carpet area (sq ft)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: floorNoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Floor no',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: noOfFloorsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total floors',
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
                            controller: balconiesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Balconies',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: noOfVacancyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Vacancies',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Amenities',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _propertyAmenityLabels.entries.map(
                        (MapEntry<int, String> entry) {
                          final bool selected =
                              selectedAmenities.contains(entry.key);
                          return FilterChip(
                            label: Text(entry.value),
                            selected: selected,
                            onSelected: (bool value) {
                              setModalState(() {
                                if (value) {
                                  selectedAmenities = <int>[
                                    ...selectedAmenities,
                                    entry.key,
                                  ];
                                } else {
                                  selectedAmenities = selectedAmenities
                                      .where((int item) => item != entry.key)
                                      .toList();
                                }
                              });
                            },
                          );
                        },
                      ).toList(),
                    ),
                    const SizedBox(height: 16),
                    CustomCard(
                      padding: CustomCardPadding.sm,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Uploads',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isClone
                                ? 'You can keep or replace the copied uploads before saving the clone.'
                                : 'Upload property images and an optional floor plan to match the website property form flow.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: CustomButton(
                                  label: 'Upload Images',
                                  variant: CustomButtonVariant.outline,
                                  isLoading: isUploadingMedia,
                                  onPressed: isUploadingMedia
                                      ? null
                                      : uploadPropertyImages,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomButton(
                                  label: 'Upload Floor Plan',
                                  variant: CustomButtonVariant.outline,
                                  isLoading: isUploadingMedia,
                                  onPressed: isUploadingMedia
                                      ? null
                                      : uploadFloorPlan,
                                ),
                              ),
                            ],
                          ),
                          if (propertyImages.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              'Property Images',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: propertyImages.map(
                                (_UploadedAsset item) => InputChip(
                                  label: Text(item.label),
                                  onDeleted: () {
                                    setModalState(() {
                                      propertyImages = propertyImages
                                          .where(
                                            (_UploadedAsset image) =>
                                                image.id != item.id,
                                          )
                                          .toList();
                                    });
                                  },
                                ),
                              ).toList(),
                            ),
                          ],
                          if (floorPlanDocument != null) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              'Floor Plan',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            InputChip(
                              label: Text(floorPlanDocument!.label),
                              onDeleted: () {
                                setModalState(() {
                                  floorPlanDocument = null;
                                });
                              },
                            ),
                            if (floorPlanDocument!.url?.isNotEmpty ?? false) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                floorPlanDocument!.url!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ownerNameController,
                      decoration: const InputDecoration(labelText: 'Owner name'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: ownerPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Owner phone',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: ownerEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Owner email',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ownerAddressController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Owner address',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bill Types',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: electricityBillType,
                            decoration: const InputDecoration(
                              labelText: 'Electricity',
                            ),
                            items: _billTypeLabels.entries
                                .map(
                                  (MapEntry<int, String> e) =>
                                      DropdownMenuItem<int>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? v) => setModalState(() {
                              electricityBillType = v ?? 1;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: waterBillType,
                            decoration: const InputDecoration(
                              labelText: 'Water',
                            ),
                            items: _billTypeLabels.entries
                                .map(
                                  (MapEntry<int, String> e) =>
                                      DropdownMenuItem<int>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? v) => setModalState(() {
                              waterBillType = v ?? 1;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: gasBillType,
                            decoration: const InputDecoration(
                              labelText: 'Gas',
                            ),
                            items: _billTypeLabels.entries
                                .map(
                                  (MapEntry<int, String> e) =>
                                      DropdownMenuItem<int>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? v) => setModalState(() {
                              gasBillType = v ?? 4;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: internetBillType,
                            decoration: const InputDecoration(
                              labelText: 'Internet',
                            ),
                            items: _billTypeLabels.entries
                                .map(
                                  (MapEntry<int, String> e) =>
                                      DropdownMenuItem<int>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? v) => setModalState(() {
                              internetBillType = v ?? 4;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Parking',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Switch(
                          value: parkingAvailable,
                          onChanged: (bool v) => setModalState(() {
                            parkingAvailable = v;
                          }),
                        ),
                      ],
                    ),
                    if (parkingAvailable) ...<Widget>[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: parkingType,
                        decoration: const InputDecoration(
                          labelText: 'Parking type',
                        ),
                        items: _parkingTypeLabels.entries
                            .map(
                              (MapEntry<int, String> e) =>
                                  DropdownMenuItem<int>(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (int? v) => setModalState(() {
                          parkingType = v ?? 1;
                        }),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: parkingSlotsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Slots',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: parkingChargesController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Monthly charges',
                                prefixText: 'Rs ',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Nearby Facilities',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: metroController,
                            decoration: const InputDecoration(
                              labelText: 'Metro / Bus stop',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: hospitalController,
                            decoration: const InputDecoration(
                              labelText: 'Hospital',
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
                            controller: schoolController,
                            decoration: const InputDecoration(
                              labelText: 'School / College',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: shoppingMallController,
                            decoration: const InputDecoration(
                              labelText: 'Shopping mall',
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
                            controller: restaurantController,
                            decoration: const InputDecoration(
                              labelText: 'Restaurant',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: atmController,
                            decoration: const InputDecoration(
                              labelText: 'ATM / Bank',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rules & Policies',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: tenantType,
                            decoration: const InputDecoration(
                              labelText: 'Tenant type',
                            ),
                            items: _tenantTypeLabels.entries
                                .map(
                                  (MapEntry<int, String> e) =>
                                      DropdownMenuItem<int>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? v) => setModalState(() {
                              tenantType = v ?? 1;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: petPolicy,
                            decoration: const InputDecoration(
                              labelText: 'Pet policy',
                            ),
                            items: _petPolicyLabels.entries
                                .map(
                                  (MapEntry<int, String> e) =>
                                      DropdownMenuItem<int>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? v) => setModalState(() {
                              petPolicy = v ?? 1;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: smokingPolicy,
                            decoration: const InputDecoration(
                              labelText: 'Smoking',
                            ),
                            items: _smokingPolicyLabels.entries
                                .map(
                                  (MapEntry<int, String> e) =>
                                      DropdownMenuItem<int>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? v) => setModalState(() {
                              smokingPolicy = v ?? 1;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: visitorsPolicy,
                            decoration: const InputDecoration(
                              labelText: 'Visitors',
                            ),
                            items: _visitorsPolicyLabels.entries
                                .map(
                                  (MapEntry<int, String> e) =>
                                      DropdownMenuItem<int>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? v) => setModalState(() {
                              visitorsPolicy = v ?? 2;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rulesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Property rules',
                        hintText: 'Describe any additional rules...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: isClone
                            ? 'Create Clone'
                            : propertyId == null
                                ? 'Save Property'
                                : 'Update Property',
                        isLoading: isSubmitting,
                        onPressed: isSubmitting || isUploadingMedia
                            ? null
                            : submit,
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
    unitController.dispose();
    locationController.dispose();
    addressController.dispose();
    rentController.dispose();
    depositController.dispose();
    areaController.dispose();
    bedroomsController.dispose();
    bathroomsController.dispose();
    ownerNameController.dispose();
    ownerPhoneController.dispose();
    ownerEmailController.dispose();
    availableFromController.dispose();
    maintenanceController.dispose();
    brokerageController.dispose();
    carpetAreaController.dispose();
    floorNoController.dispose();
    noOfFloorsController.dispose();
    noOfVacancyController.dispose();
    balconiesController.dispose();
    localityController.dispose();
    pincodeController.dispose();
    ownerAddressController.dispose();
    parkingSlotsController.dispose();
    parkingChargesController.dispose();
    metroController.dispose();
    hospitalController.dispose();
    schoolController.dispose();
    shoppingMallController.dispose();
    restaurantController.dispose();
    atmController.dispose();
    rulesController.dispose();
  }

  Future<void> _showPropertyDetails(String propertyId) async {
    try {
      final PropertyData? property =
          await PropertyService.fetchPropertyInfo(propertyId);
      if (!mounted) {
        return;
      }
      if (property == null) {
        _showMessage('Unable to load property details.');
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          property.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ToneBadge(
                        label: _propertyTypeLabel(property.propertyType),
                        tone: UiTone.brand,
                      ),
                      ToneBadge(
                        label: _subTypeLabel(
                            property.propertyType, property.subType),
                        tone: UiTone.neutral,
                      ),
                      if (property.isSubscribed)
                        ToneBadge(
                          label: property.currentSubscriptionTitle?.isNotEmpty ==
                                  true
                              ? property.currentSubscriptionTitle!
                              : 'Subscribed',
                          tone: property.subscriptionExpired == true
                              ? UiTone.danger
                              : UiTone.success,
                        ),
                      if (property.whetherVerifiedPlus == true)
                        const ToneBadge(
                          label: 'Verified+',
                          tone: UiTone.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Overview',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _detailLine(
                    'Rent',
                    'Rs ${property.rent.toStringAsFixed(0)} / month',
                  ),
                  _detailLine(
                    'Deposit',
                    'Rs ${property.deposit.toStringAsFixed(0)}',
                  ),
                  if ((property.maintenance ?? 0) > 0)
                    _detailLine(
                      'Maintenance',
                      'Rs ${property.maintenance!.toStringAsFixed(0)}',
                    ),
                  _detailLine(
                    'Available',
                    property.availableFrom?.split('T').first ?? 'Not set',
                  ),
                  if (property.furnishedType != null)
                    _detailLine(
                      'Furnished',
                      _furnishedTypeLabels[property.furnishedType] ??
                          'Not specified',
                    ),
                  if (property.category != null)
                    _detailLine(
                      'Category',
                      _categoryTypeLabels[property.category] ?? 'Rent',
                    ),
                  if (property.propertyType == 3) ...<Widget>[
                    _detailLine(
                      'PG Sharing',
                      _pgSharingLabel(property.pgSharingType),
                    ),
                    if (property.gender != null)
                      _detailLine(
                        'Gender',
                        _genderLabels[property.gender] ?? 'Any',
                      ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Location',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _detailLine(
                    'Address',
                    property.locationAddress ?? property.address ?? 'N/A',
                  ),
                  if ((property.locality ?? '').isNotEmpty)
                    _detailLine('Locality', property.locality!),
                  if ((property.pincode ?? '').isNotEmpty)
                    _detailLine('Pincode', property.pincode!),
                  if ((property.state ?? '').isNotEmpty)
                    _detailLine(
                        'State / City',
                        <String>[
                          property.state ?? '',
                          property.city ?? '',
                        ]
                            .where((String s) => s.isNotEmpty)
                            .join(', ')),
                  const SizedBox(height: 16),
                  Text(
                    'Property Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if ((property.area ?? 0) > 0)
                    _detailLine(
                        'Area', '${property.area!.toStringAsFixed(0)} sq ft'),
                  if ((property.carpetArea ?? 0) > 0)
                    _detailLine(
                        'Carpet area',
                        '${property.carpetArea!.toStringAsFixed(0)} sq ft'),
                  if (property.bedrooms != null)
                    _detailLine('Bedrooms', '${property.bedrooms}'),
                  if (property.bathrooms != null)
                    _detailLine('Bathrooms', '${property.bathrooms}'),
                  if (property.balconies != null)
                    _detailLine('Balconies', '${property.balconies}'),
                  if (property.floor != null)
                    _detailLine(
                        'Floor',
                        property.noOfFloors != null
                            ? '${property.floor} of ${property.noOfFloors}'
                            : '${property.floor}'),
                  if ((property.noOfVacancy ?? 0) > 0)
                    _detailLine('Vacancies', '${property.noOfVacancy}'),
                  if (property.facing?.isNotEmpty == true)
                    _detailLine('Facing', property.facing!),
                  const SizedBox(height: 16),
                  Text(
                    'Owner',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _detailLine(
                    'Name',
                    property.ownerName?.isNotEmpty == true
                        ? property.ownerName!
                        : 'N/A',
                  ),
                  if ((property.ownerPhone ?? '').isNotEmpty)
                    _detailLine('Phone', property.ownerPhone!),
                  if ((property.ownerEmail ?? '').isNotEmpty)
                    _detailLine('Email', property.ownerEmail!),
                  if ((property.ownerAddress ?? '').isNotEmpty)
                    _detailLine('Owner address', property.ownerAddress!),
                  if (property.electricityBillType != null ||
                      property.waterBillType != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      'Bill Types',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (property.electricityBillType != null)
                      _detailLine(
                          'Electricity',
                          _billTypeLabels[property.electricityBillType] ??
                              ''),
                    if (property.waterBillType != null)
                      _detailLine(
                          'Water',
                          _billTypeLabels[property.waterBillType] ?? ''),
                    if (property.gasBillType != null)
                      _detailLine(
                          'Gas',
                          _billTypeLabels[property.gasBillType] ?? ''),
                    if (property.internetBillType != null)
                      _detailLine(
                          'Internet',
                          _billTypeLabels[property.internetBillType] ?? ''),
                  ],
                  if (property.whetherParkingAvailable == true) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      'Parking',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (property.parkingType != null)
                      _detailLine(
                          'Type',
                          _parkingTypeLabels[property.parkingType] ?? ''),
                    if ((property.parkingSlots ?? 0) > 0)
                      _detailLine('Slots', '${property.parkingSlots}'),
                    if ((property.parkingCharges ?? 0) > 0)
                      _detailLine(
                          'Monthly charges',
                          'Rs ${property.parkingCharges!.toStringAsFixed(0)}'),
                  ],
                  if (<String?>[
                        property.metroOrBusStation,
                        property.hospital,
                        property.schoolOrCollege,
                        property.shoppingMall,
                        property.restaurant,
                        property.atmOrBank,
                      ].any(
                          (String? s) => s != null && s.isNotEmpty)) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      'Nearby Facilities',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if ((property.metroOrBusStation ?? '').isNotEmpty)
                      _detailLine('Metro / Bus', property.metroOrBusStation!),
                    if ((property.hospital ?? '').isNotEmpty)
                      _detailLine('Hospital', property.hospital!),
                    if ((property.schoolOrCollege ?? '').isNotEmpty)
                      _detailLine('School / College', property.schoolOrCollege!),
                    if ((property.shoppingMall ?? '').isNotEmpty)
                      _detailLine('Shopping mall', property.shoppingMall!),
                    if ((property.restaurant ?? '').isNotEmpty)
                      _detailLine('Restaurant', property.restaurant!),
                    if ((property.atmOrBank ?? '').isNotEmpty)
                      _detailLine('ATM / Bank', property.atmOrBank!),
                  ],
                  if (property.preferredTenantType != null ||
                      property.petPolicy != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      'Rules & Policies',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (property.preferredTenantType != null)
                      _detailLine(
                          'Tenant',
                          _tenantTypeLabels[property.preferredTenantType] ??
                              ''),
                    if (property.petPolicy != null)
                      _detailLine(
                          'Pets',
                          _petPolicyLabels[property.petPolicy] ?? ''),
                    if (property.smokingPolicy != null)
                      _detailLine(
                          'Smoking',
                          _smokingPolicyLabels[property.smokingPolicy] ?? ''),
                    if (property.visitorsPolicy != null)
                      _detailLine(
                          'Visitors',
                          _visitorsPolicyLabels[property.visitorsPolicy] ?? ''),
                    if ((property.propertyRulesDescription ?? '').isNotEmpty)
                      _detailLine('Rules', property.propertyRulesDescription!),
                  ],
                  if (property.amenityIds?.isNotEmpty == true) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      'Amenities',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: property.amenityIds!
                          .map(
                            (int amenityId) => ToneBadge(
                              label: _amenityLabel(amenityId),
                              tone: UiTone.neutral,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _detailLine(
                    'Uploads',
                    '${property.imageIds?.length ?? 0} image(s)'
                    '${property.floorPlanDocumentId?.isNotEmpty == true ? ', floor plan attached' : ''}',
                  ),
                  if (property.totalLeads != null) ...<Widget>[
                    const SizedBox(height: 4),
                    _detailLine(
                      'Enquiries',
                      '${property.totalLeads} total, ${property.totalUnseenLeads ?? 0} unseen',
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openSubscriptionSheet(String propertyId) async {
    final PropertyData? property =
        await PropertyService.fetchPropertyInfo(propertyId);
    if (property == null) {
      _showMessage('Unable to load property subscription details.');
      return;
    }

    List<SubscriptionPlanData> plans = <SubscriptionPlanData>[];
    String? errorMessage;

    try {
      final result = await SubscriptionService.filterSubscriptions(
        propertyType: property.propertyType,
        limit: 50,
      );
      plans = result.plans;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    }

    String? selectedPlanId = property.currentSubscriptionId;
    if (!plans.any(
      (SubscriptionPlanData item) => item.subscriptionId == selectedPlanId,
    )) {
      selectedPlanId = null;
    }
    final TextEditingController extraContractsController =
        TextEditingController(
      text:
          '${property.totalPurchasedResidentContractsCreationCount ?? 0}',
    );
    SubscriptionCalculationData? calculation;
    String? successMessage;
    bool calculating = false;
    bool purchasing = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> calculate() async {
              if ((selectedPlanId ?? '').isEmpty) {
                setModalState(() {
                  errorMessage = 'Select a subscription plan first.';
                });
                return;
              }

              setModalState(() {
                calculating = true;
                errorMessage = null;
                successMessage = null;
              });

              try {
                calculation = await SubscriptionService.calculateSubscription(
                  propertyId: property.propertyId,
                  subscriptionId: selectedPlanId!,
                  extraResidentContracts:
                      int.tryParse(extraContractsController.text.trim()) ?? 0,
                );
                if (mounted) {
                  setModalState(() {});
                }
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
              if ((selectedPlanId ?? '').isEmpty) {
                setModalState(() {
                  errorMessage = 'Select and calculate a plan first.';
                });
                return;
              }

              setModalState(() {
                purchasing = true;
                errorMessage = null;
                successMessage = null;
              });

              try {
                final response = await SubscriptionService.purchaseSubscription(
                  propertyId: property.propertyId,
                  subscriptionId: selectedPlanId!,
                  extraResidentContracts:
                      int.tryParse(extraContractsController.text.trim()) ?? 0,
                );

                if (!response.success) {
                  throw Exception(
                    response.message ??
                        response.status ??
                        'Unable to continue with the subscription.',
                  );
                }

                final bool isFree =
                    response.extras['Is_Free_Subscription'] as bool? ?? false;
                final num amount = response.extras['Amount'] as num? ?? 0;
                final String orderId =
                    response.extras['Razorpay_Order_ID'] as String? ?? '';
                final String keyId =
                    response.extras['Razorpay_Key_ID'] as String? ?? '';
                final int amountInPaise =
                    response.extras['Amount_In_Paise'] as int? ??
                        (amount * 100).round();

                if (isFree || amount == 0) {
                  setModalState(() {
                    successMessage = 'Subscription activated successfully.';
                  });
                } else {
                  VendorData? vendor;
                  try {
                    vendor = await VendorService.fetchVendorInfo();
                  } catch (_) {
                    vendor = null;
                  }
                  final RazorpayCheckoutResult checkoutResult =
                      await RazorpayCheckoutService.openCheckout(
                    keyId: keyId,
                    amountInPaise: amountInPaise,
                    name: 'Urban Easy Flats',
                    description: 'Property Subscription',
                    orderId: orderId,
                    currency:
                        response.extras['Currency'] as String? ?? 'INR',
                    prefillName: vendor?.fullName,
                    prefillEmail: vendor?.email,
                    prefillContact: vendor?.phone,
                  );

                  if (!checkoutResult.success) {
                    throw Exception(
                      checkoutResult.message ??
                          'Subscription payment was not completed.',
                    );
                  }

                  setModalState(() {
                    successMessage =
                        'Payment completed. Subscription activation is being processed.';
                  });
                }
                await _loadProperties();
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
                      'Property Subscription',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      property.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ToneBadge(
                          label: _propertyTypeLabel(property.propertyType),
                          tone: UiTone.brand,
                        ),
                        if (property.currentSubscriptionTitle?.isNotEmpty == true)
                          ToneBadge(
                            label: property.currentSubscriptionTitle!,
                            tone: UiTone.warning,
                          ),
                        ToneBadge(
                          label:
                              '${property.availableResidentContractsCreationCount ?? 0} contracts available',
                          tone: UiTone.success,
                        ),
                      ],
                    ),
                    if (errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _InlineStatusCard(
                        title: 'Issue',
                        message: errorMessage!,
                        tone: UiTone.danger,
                      ),
                    ],
                    if (successMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _InlineStatusCard(
                        title: 'Updated',
                        message: successMessage!,
                        tone: UiTone.success,
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (plans.isEmpty)
                      const CustomCard(
                        child: Text(
                          'No subscription plans are available for this property type right now.',
                        ),
                      )
                    else
                      ...plans.map((SubscriptionPlanData plan) {
                        final bool selected =
                            selectedPlanId == plan.subscriptionId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CustomCard(
                            onTap: () {
                              setModalState(() {
                                selectedPlanId = plan.subscriptionId;
                                calculation = null;
                                successMessage = null;
                              });
                            },
                            color: selected
                                ? AppTheme.primarySoft
                                : AppTheme.surface,
                            borderColor: selected
                                ? AppTheme.primary
                                : AppTheme.borderSoft,
                            padding: CustomCardPadding.sm,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        plan.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Radio<String>(
                                      value: plan.subscriptionId,
                                      groupValue: selectedPlanId,
                                      onChanged: (String? value) {
                                        setModalState(() {
                                          selectedPlanId = value;
                                          calculation = null;
                                          successMessage = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  plan.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    ToneBadge(
                                      label:
                                          'Rs ${plan.price.toStringAsFixed(0)}',
                                      tone: UiTone.brand,
                                    ),
                                    ToneBadge(
                                      label: '${plan.duration} days',
                                      tone: UiTone.neutral,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: extraContractsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Extra resident contracts',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            label: 'Calculate',
                            isLoading: calculating,
                            onPressed: calculating ? null : calculate,
                          ),
                        ),
                      ],
                    ),
                    if (calculation != null) ...<Widget>[
                      const SizedBox(height: 16),
                      CustomCard(
                        padding: CustomCardPadding.sm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Calculation',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            _detailLine(
                              'Subscription',
                              'Rs ${calculation!.subscriptionPrice.toStringAsFixed(0)}',
                            ),
                            _detailLine(
                              'Extra contracts',
                              '${calculation!.extraContractsCount}',
                            ),
                            _detailLine(
                              'Subtotal',
                              'Rs ${calculation!.subtotal.toStringAsFixed(0)}',
                            ),
                            _detailLine(
                              'GST',
                              '${calculation!.gstPercentage.toStringAsFixed(0)}% | Rs ${calculation!.gstAmount.toStringAsFixed(0)}',
                            ),
                            _detailLine(
                              'Total',
                              'Rs ${calculation!.totalAmount.toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: CustomButton(
                            label: 'Close',
                            variant: CustomButtonVariant.outline,
                            onPressed: purchasing
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            label: 'Create Order',
                            isLoading: purchasing,
                            onPressed: purchasing ? null : purchase,
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

    extraContractsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int approvedCount = _properties
        .where((PropertyRecord item) => item.status == PropertyStatus.approved)
        .length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Properties'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPropertySheet,
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('Add Property'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            const PageHeader(
              title: 'Properties',
              description:
                  'Website-aligned property inventory with live type, location, pagination, subscription, and activation APIs.',
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MetricTile(
                    label: 'Inventory',
                    value: '$_totalCount',
                    tone: UiTone.brand,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    label: 'Approved',
                    value: '$approvedCount',
                    tone: UiTone.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search property',
                suffixIcon: IconButton(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _typeFilter,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ..._propertyTypeLabels.entries.map(
                        (MapEntry<int, String> entry) =>
                            DropdownMenuItem<int?>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      ),
                    ],
                    onChanged: (int? value) {
                      setState(() {
                        _typeFilter = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _stateId,
                    decoration: const InputDecoration(labelText: 'State'),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All States'),
                      ),
                      ..._states.map(
                        (PropertyStateData state) => DropdownMenuItem<String?>(
                          value: state.stateId,
                          child: Text(state.stateName),
                        ),
                      ),
                    ],
                    onChanged: (String? value) async {
                      setState(() {
                        _stateId = value;
                        _cityId = null;
                      });
                      await _loadCitiesForSelectedState();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _cityId,
                    decoration: const InputDecoration(labelText: 'City'),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Cities'),
                      ),
                      ..._cities.map(
                        (PropertyCityData city) => DropdownMenuItem<String?>(
                          value: city.cityId,
                          child: Text(city.cityName),
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _cityId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: 'Apply',
                    onPressed: _applyFilters,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: 'Clear',
                    variant: CustomButtonVariant.outline,
                    onPressed: _clearFilters,
                  ),
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
                      'Page ${_page + 1} | ${_properties.length} results in view',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  ToneBadge(label: 'Total $_totalCount', tone: UiTone.neutral),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomTabBar(
              style: CustomTabBarStyle.pill,
              currentIndex: _statusFilter == null
                  ? 0
                  : PropertyStatus.values.indexOf(_statusFilter!) + 1,
              onChanged: (int index) {
                setState(() {
                  _statusFilter = index == 0
                      ? null
                      : PropertyStatus.values[index - 1];
                });
                _loadProperties();
              },
              tabs: <CustomTabItem>[
                const CustomTabItem(label: 'All'),
                ...PropertyStatus.values.map(
                  (PropertyStatus status) => CustomTabItem(label: status.label),
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
              _PropertyErrorCard(
                message: _errorMessage!,
                onRetry: _loadInitialData,
              )
            else if (_properties.isEmpty)
              const CustomCard(
                child: Text('No properties found for the current filters.'),
              )
            else
              ..._properties.map((PropertyRecord property) {
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
                                    property.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    property.address ?? property.type,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ToneBadge(
                              label: property.status.label,
                              tone: property.status.tone,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            ToneBadge(label: property.type, tone: UiTone.brand),
                            ToneBadge(
                              label: 'Rent Rs ${property.rent.toStringAsFixed(0)}',
                              tone: UiTone.neutral,
                            ),
                            ToneBadge(
                              label:
                                  'Deposit Rs ${property.deposit.toStringAsFixed(0)}',
                              tone: UiTone.neutral,
                            ),
                            if (property.isSubscribed)
                              ToneBadge(
                                label: property.subscriptionExpired == true
                                    ? 'Plan Expired'
                                    : 'Subscribed',
                                tone: property.subscriptionExpired == true
                                    ? UiTone.danger
                                    : UiTone.success,
                              ),
                            if (property.whetherVerifiedPlus == true)
                              const ToneBadge(
                                label: 'Verified+',
                                tone: UiTone.warning,
                              ),
                            if ((property.noOfVacancy ?? 0) > 0)
                              ToneBadge(
                                label:
                                    '${property.noOfVacancy} vacant',
                                tone: UiTone.neutral,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: CustomButton(
                                label: 'Details',
                                variant: CustomButtonVariant.outline,
                                onPressed: () => _showPropertyDetails(property.id),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                label: 'Clone',
                                variant: CustomButtonVariant.outline,
                                onPressed: () => _openPropertySheet(
                                  cloneFromPropertyId: property.id,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: CustomButton(
                                label: 'Manage Plan',
                                variant: CustomButtonVariant.outline,
                                onPressed: () => _openSubscriptionSheet(property.id),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                label: 'Edit',
                                variant: CustomButtonVariant.outline,
                                onPressed: () => _openPropertySheet(
                                  propertyId: property.id,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            label: property.status == PropertyStatus.inactive
                                ? 'Activate'
                                : 'Deactivate',
                            variant: property.status == PropertyStatus.inactive
                                ? CustomButtonVariant.primary
                                : CustomButtonVariant.danger,
                            onPressed: () => _toggleProperty(property),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            if (!_isLoading && _totalCount > _pageSize) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CustomButton(
                      label: 'Previous',
                      variant: CustomButtonVariant.outline,
                      onPressed: _page == 0
                          ? null
                          : () async {
                              setState(() {
                                _page -= 1;
                              });
                              await _loadProperties();
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: 'Next',
                      onPressed: (_page + 1) * _pageSize >= _totalCount
                          ? null
                          : () async {
                              setState(() {
                                _page += 1;
                              });
                              await _loadProperties();
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _propertyTypeLabel(int type) {
    return _propertyTypeLabels[type] ?? 'Property';
  }

  String _subTypeLabel(int propertyType, int? subType) {
    if (subType == null) {
      return 'N/A';
    }
    return _propertySubTypeLabels[propertyType]?[subType] ?? 'Subtype $subType';
  }

  String _pgSharingLabel(int? sharingType) {
    if (sharingType == null) {
      return 'N/A';
    }
    return _pgSharingLabels[sharingType] ?? 'Sharing $sharingType';
  }

  String _amenityLabel(int amenityId) {
    return _propertyAmenityLabels[amenityId] ?? 'Amenity $amenityId';
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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

class _PropertyErrorCard extends StatelessWidget {
  const _PropertyErrorCard({
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
            'Unable to load properties',
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

class _InlineStatusCard extends StatelessWidget {
  const _InlineStatusCard({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: AppTheme.toneSoft(tone),
      borderColor: AppTheme.toneColor(tone).withValues(alpha: 0.2),
      padding: CustomCardPadding.sm,
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
}
