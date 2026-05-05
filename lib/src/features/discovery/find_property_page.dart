import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/auth_storage.dart';
import '../../core/api/property_wishlist_service.dart';
import '../../core/api/public_property_service.dart';
import '../../core/models/api_models.dart';
import '../../core/theme/app_theme.dart';

const Color _studioPrimary = Color(0xFF6C5CE7);
const Color _studioSecondary = Color(0xFFA29BFE);
const Color _studioAccent = Color(0xFF00B894);
const Color _studioBackground = Color(0xFFF8F9FB);
const Color _studioSurface = Color(0xFFFFFFFF);
const Color _studioInk = Color(0xFF1F2937);
const Color _studioMuted = Color(0xFF6B7280);
const Color _studioLine = Color(0xFFE5E7EB);

const Map<int, String> _filterPropertyTypeLabels = <int, String>{
  1: 'Apartment',
  2: 'Villa',
  3: 'PG',
  4: 'Commercial',
};

const Map<int, Map<int, String>> _filterSubTypeLabels =
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

const Map<int, String> _filterPgSharingLabels = <int, String>{
  1: 'Single',
  2: 'Double',
  3: 'Triple',
  4: 'Quad',
  5: 'Dorm',
};

const Map<int, String> _filterCategoryLabels = <int, String>{
  1: 'Rent',
  2: 'Lease',
};

String _firstNonEmpty(List<String?> values) {
  for (final String? value in values) {
    final String clean = value?.trim() ?? '';
    if (clean.isNotEmpty) return clean;
  }
  return '';
}

String _joinLocationParts(List<String?> values) {
  final List<String> parts = <String>[];
  for (final String? value in values) {
    final String clean = value?.trim() ?? '';
    if (clean.isNotEmpty && !parts.contains(clean)) {
      parts.add(clean);
    }
  }
  return parts.join(', ');
}

class FindPropertyPage extends StatefulWidget {
  const FindPropertyPage({
    super.key,
    required this.onLoginPressed,
    this.showLoginButton = true,
    this.enableWishlist = false,
  });

  final VoidCallback onLoginPressed;
  final bool showLoginButton;
  final bool enableWishlist;

  @override
  State<FindPropertyPage> createState() => _FindPropertyPageState();
}

class _FindPropertyPageState extends State<FindPropertyPage> {
  static const int _pageSize = 15;
  static const String _fallbackImage =
      'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg';

  final TextEditingController _searchController = TextEditingController();

  List<PropertyData> _properties = <PropertyData>[];
  List<PublicCityData> _cities = <PublicCityData>[];
  bool _isLoading = true;
  bool _isLoadingCities = true;
  String? _errorMessage;
  int _total = 0;
  int _page = 1;
  int? _propertyType;
  int? _viewAllPropertyType;
  int? _subType;
  int? _pgSharingType;
  int? _categoryType;
  String? _cityId;
  _PriceRange _priceRange = _PriceRange.all;
  int _requestSerial = 0;
  double _latitude = 0;
  double _longitude = 0;
  String _locationTitle = 'Select location';
  String _locationSubtitle = 'Tap to find nearby properties';
  bool _hasUserLocation = false;
  Set<String> _wishlistIds = <String>{};
  List<PropertyData> _wishlistProperties = <PropertyData>[];
  bool _showWishlistOnly = false;

  @override
  void initState() {
    super.initState();
    _wishlistIds = AuthStorage.wishlistPropertyIds;
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    _loadSavedLocation();
    await _loadWishlist();
    await _loadCities();
    await _loadProperties();
  }

  Future<void> _loadWishlist() async {
    if (!widget.enableWishlist || !AuthStorage.isLoggedIn) {
      return;
    }

    try {
      final result = await PropertyWishlistService.filterWishlist();
      if (!mounted) return;
      setState(() {
        _wishlistIds = result.propertyIds;
        _wishlistProperties = result.properties;
      });
      await AuthStorage.setWishlistPropertyIds(result.propertyIds);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _wishlistIds = AuthStorage.wishlistPropertyIds;
      });
    }
  }

  void _loadSavedLocation() {
    final String? title = AuthStorage.locationTitle;
    final String? subtitle = AuthStorage.locationSubtitle;
    final double? latitude = AuthStorage.locationLatitude;
    final double? longitude = AuthStorage.locationLongitude;
    if (title == null ||
        title.trim().isEmpty ||
        subtitle == null ||
        latitude == null ||
        longitude == null) {
      return;
    }

    _locationTitle = title;
    _locationSubtitle = subtitle;
    _latitude = latitude;
    _longitude = longitude;
    _hasUserLocation = true;
  }

  Future<void> _loadUserLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationFallback('Location off', 'Turn on GPS to see nearby stays');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setLocationFallback(
          'Select location',
          'Allow location to find nearby properties',
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      _latitude = position.latitude;
      _longitude = position.longitude;
      _hasUserLocation = true;
      await _loadReadableLocation(position);
      await AuthStorage.saveLocation(
        title: _locationTitle,
        subtitle: _locationSubtitle,
        latitude: _latitude,
        longitude: _longitude,
      );
    } catch (_) {
      _latitude = 0;
      _longitude = 0;
      _setLocationFallback('Current location', 'Unable to detect your area');
    }
  }

  Future<void> _loadReadableLocation(Position position) async {
    try {
      final List<Placemark> places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isEmpty) {
        _locationTitle = 'Current location';
        _locationSubtitle =
            '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
        return;
      }

      final Placemark place = places.first;
      final String title = _firstNonEmpty(<String?>[
        place.subLocality,
        place.locality,
        place.name,
      ]);
      final String subtitle = _joinLocationParts(<String?>[
        place.locality,
        place.administrativeArea,
        place.postalCode,
      ]);

      _locationTitle = title.isEmpty ? 'Current location' : title;
      _locationSubtitle = subtitle.isEmpty
          ? 'Nearby properties from your area'
          : subtitle;
    } catch (_) {
      _locationTitle = 'Current location';
      _locationSubtitle =
          '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
    }
  }

  void _setLocationFallback(String title, String subtitle) {
    _hasUserLocation = false;
    _locationTitle = title;
    _locationSubtitle = subtitle;
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
    });
    try {
      final List<PublicCityData> cities =
          await PublicPropertyService.filterCities();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cities = <PublicCityData>[];
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _loadProperties() async {
    final int requestId = ++_requestSerial;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PublicPropertyService.filterProperties(
        skip: (_page - 1) * _pageSize,
        limit: _pageSize,
        search: _searchController.text,
        propertyType: _propertyType,
        subType: _subType,
        categoryType: _categoryType,
        pgSharingType: _propertyType == 3 ? _pgSharingType : null,
        cityId: _cityId,
        latitude: _latitude,
        longitude: _longitude,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _properties = result.properties;
        _total = result.count;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _properties = <PropertyData>[];
        _total = 0;
        _isLoading = false;
        _errorMessage = _cleanException(e);
      });
    }
  }

  Future<void> _refreshLocation() async {
    await _loadUserLocation();
    if (!mounted) return;
    setState(() {
      _page = 1;
    });
    await _loadProperties();
  }

  void _applyFilters() {
    setState(() {
      _page = 1;
    });
    _loadProperties();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _propertyType = null;
      _viewAllPropertyType = null;
      _subType = null;
      _pgSharingType = null;
      _categoryType = null;
      _cityId = null;
      _priceRange = _PriceRange.all;
      _page = 1;
    });
    _loadProperties();
  }

  List<PropertyData> get _visibleProperties {
    final List<PropertyData> source = _showWishlistOnly
        ? (_wishlistProperties.isNotEmpty ? _wishlistProperties : _properties)
        : _properties;
    return source.where((PropertyData property) {
      final double rent = property.rent;
      final bool matchesPrice = switch (_priceRange) {
        _PriceRange.all => true,
        _PriceRange.low => rent <= 15000,
        _PriceRange.mid => rent > 15000 && rent <= 30000,
        _PriceRange.high => rent > 30000,
      };
      final bool matchesSubType =
          _subType == null || property.subType == _subType;
      final bool matchesCategory =
          _categoryType == null || property.category == _categoryType;
      final bool matchesPgSharing =
          _pgSharingType == null ||
          property.propertyType != 3 ||
          property.pgSharingType == _pgSharingType;
      final bool matchesWishlist =
          !_showWishlistOnly || _isWishlisted(property);
      return matchesPrice &&
          matchesSubType &&
          matchesCategory &&
          matchesPgSharing &&
          matchesWishlist;
    }).toList();
  }

  int get _totalPages {
    if (_total <= 0) return 1;
    return (_total / _pageSize).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<PropertyData> visibleProperties = _visibleProperties;

    return Scaffold(
      backgroundColor: _studioBackground,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: ColoredBox(color: _studioBackground)),
            ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
              children: <Widget>[
                _buildHomeHeader(theme),
                const SizedBox(height: 14),
                _buildFilters(theme),
                if (widget.enableWishlist) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildWishlistToggle(theme),
                ],
                const SizedBox(height: 18),
                if (_isLoading && _properties.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 72),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  _StatePanel(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load properties',
                    message: _errorMessage!,
                    actionLabel: 'Try again',
                    onAction: _loadProperties,
                  )
                else if (visibleProperties.isEmpty)
                  _StatePanel(
                    icon: Icons.home_work_outlined,
                    title: 'No properties found',
                    message: 'Change the filters or search another property.',
                    actionLabel: 'Clear filters',
                    onAction: _clearFilters,
                  )
                else ...<Widget>[
                  if (_isLoading)
                    const Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (_showWishlistOnly)
                    ..._buildWishlistProperties(theme, visibleProperties)
                  else if (_viewAllPropertyType != null)
                    ..._buildViewAllProperties(theme, visibleProperties)
                  else ...<Widget>[
                    ..._buildPropertySections(theme, visibleProperties),
                    _buildPromoBanner(theme),
                  ],
                  if (!_showWishlistOnly && _totalPages > 1)
                    _buildPagination(theme),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeHeader(ThemeData theme) {
    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _studioPrimary.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/tenenet_logo.jpg',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: _refreshLocation,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _studioPrimary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _hasUserLocation
                          ? Icons.near_me_rounded
                          : Icons.location_on_outlined,
                      color: _studioPrimary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                _locationTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: _studioInk,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _studioInk,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _locationSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _studioMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showLoginButton)
          _PurpleGradientButton(
            label: 'Login',
            icon: Icons.login_rounded,
            onPressed: widget.onLoginPressed,
            compact: true,
          ),
      ],
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 48,
              decoration: BoxDecoration(
                color: _studioSurface,
                borderRadius: BorderRadius.circular(23),
              border: Border.all(color: _studioLine),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x146C5CE7),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 5, 5, 5),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.search_rounded,
                    color: _studioPrimary,
                    size: 23,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _applyFilters(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _studioInk,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        labelText: null,
                        hintText: 'Search property, city or locality',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filters',
                    onPressed: _showFilterSheet,
                    style: IconButton.styleFrom(
                      backgroundColor: _studioPrimary,
                      foregroundColor: Colors.white,
                      fixedSize: const Size(38, 38),
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 19),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWishlistToggle(ThemeData theme) {
    return InkWell(
      onTap: () {
        setState(() {
          _showWishlistOnly = !_showWishlistOnly;
          _viewAllPropertyType = null;
          _page = 1;
        });
        if (_showWishlistOnly) {
          _loadWishlist();
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _showWishlistOnly
              ? const Color(0xFFFFEEF2)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _showWishlistOnly
                ? const Color(0xFFFDA4AF)
                : _studioLine,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              _showWishlistOnly
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: const Color(0xFFE11D48),
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _showWishlistOnly
                    ? 'Showing wishlist'
                    : 'Wishlist (${_wishlistIds.length})',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _studioInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              _showWishlistOnly ? 'Show all' : 'View',
              style: theme.textTheme.labelMedium?.copyWith(
                color: _studioPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 0, bottom: 18),
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Color(0xFFEDEBFF), Color(0xFFF8F9FB)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -14,
            bottom: -6,
            child: Icon(
              Icons.weekend_rounded,
              size: 106,
              color: _studioSecondary.withValues(alpha: 0.22),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Find your perfect stay',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: _studioInk,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comfortable. Verified. Curated for you.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _studioMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _showFilterSheet,
                        style: FilledButton.styleFrom(
                          backgroundColor: _studioPrimary,
                          foregroundColor: Colors.white,
                          shadowColor: _studioPrimary.withValues(alpha: 0.24),
                          elevation: 8,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Explore Now'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPropertySections(
    ThemeData theme,
    List<PropertyData> properties,
  ) {
    const List<int> order = <int>[3, 2, 1, 4];
    final Map<int, List<PropertyData>> grouped = <int, List<PropertyData>>{};
    for (final PropertyData property in properties) {
      grouped.putIfAbsent(property.propertyType, () => <PropertyData>[]).add(
            property,
          );
    }

    final List<int> sectionTypes = <int>[
      ...order.where(grouped.containsKey),
      ...grouped.keys.where((int type) => !order.contains(type)),
    ];

    return sectionTypes.expand((int type) {
      final List<PropertyData> items = grouped[type] ?? <PropertyData>[];
      return <Widget>[
        _PropertySectionHeader(
          title: _sectionTitleForType(type),
          onViewAll: () {
            setState(() {
              _propertyType = type;
              _viewAllPropertyType = type;
              _subType = null;
              _pgSharingType = null;
              _page = 1;
            });
            _loadProperties();
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 258,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final PropertyData property = items[index];
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.68,
                child: _StudioPropertyCard(
                  property: property,
                  fallbackImage: _fallbackImage,
                  onDetails: () => _showPropertyDetails(property),
                  onEnquiry: () => _showEnquirySheet(property),
                  wishlistEnabled: widget.enableWishlist,
                  isWishlisted: _isWishlisted(property),
                  onWishlistToggle: () => _toggleWishlist(property),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _SectionDots(count: items.length.clamp(1, 5)),
        const SizedBox(height: 12),
      ];
    }).toList();
  }

  List<Widget> _buildViewAllProperties(
    ThemeData theme,
    List<PropertyData> properties,
  ) {
    final int type = _viewAllPropertyType ?? _propertyType ?? 0;
    return <Widget>[
      _ViewAllHeader(
        title: type == 0 ? 'All properties' : _sectionTitleForType(type),
        count: _total,
        onBack: () {
          setState(() {
            _viewAllPropertyType = null;
            _propertyType = null;
            _subType = null;
            _pgSharingType = null;
            _page = 1;
          });
          _loadProperties();
        },
      ),
      const SizedBox(height: 12),
      ...properties.map(
        (PropertyData property) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _StudioPropertyCard(
            property: property,
            fallbackImage: _fallbackImage,
            onDetails: () => _showPropertyDetails(property),
            onEnquiry: () => _showEnquirySheet(property),
            wishlistEnabled: widget.enableWishlist,
            isWishlisted: _isWishlisted(property),
            onWishlistToggle: () => _toggleWishlist(property),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildWishlistProperties(
    ThemeData theme,
    List<PropertyData> properties,
  ) {
    return <Widget>[
      _ViewAllHeader(
        title: 'Wishlist',
        count: properties.length,
        onBack: () {
          setState(() {
            _showWishlistOnly = false;
            _page = 1;
          });
        },
      ),
      const SizedBox(height: 12),
      ...properties.map(
        (PropertyData property) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _StudioPropertyCard(
            property: property,
            fallbackImage: _fallbackImage,
            onDetails: () => _showPropertyDetails(property),
            onEnquiry: () => _showEnquirySheet(property),
            wishlistEnabled: widget.enableWishlist,
            isWishlisted: _isWishlisted(property),
            onWishlistToggle: () => _toggleWishlist(property),
          ),
        ),
      ),
    ];
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _studioBackground,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final ThemeData theme = Theme.of(context);
            final Map<int, String> subTypeOptions =
                _propertyType == null
                    ? const <int, String>{}
                    : (_filterSubTypeLabels[_propertyType] ??
                          const <int, String>{});
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                6,
                16,
                18 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Filters',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FilterField(
                      icon: Icons.apartment_rounded,
                      label: 'Property type',
                      child: DropdownButtonFormField<int?>(
                        value: _propertyType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: <DropdownMenuItem<int?>>[
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All types'),
                          ),
                          ..._filterPropertyTypeLabels.entries.map(
                            (MapEntry<int, String> entry) =>
                                DropdownMenuItem<int?>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                          ),
                        ],
                        onChanged: (int? value) {
                          setState(() {
                            _propertyType = value;
                            _viewAllPropertyType = null;
                            _subType = null;
                            if (value != 3) {
                              _pgSharingType = null;
                            }
                          });
                          setSheetState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FilterField(
                      icon: Icons.grid_view_rounded,
                      label: 'Sub type',
                      child: DropdownButtonFormField<int?>(
                        value: _subType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: <DropdownMenuItem<int?>>[
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All sub types'),
                          ),
                          ...subTypeOptions.entries.map(
                            (MapEntry<int, String> entry) =>
                                DropdownMenuItem<int?>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                          ),
                        ],
                        onChanged: subTypeOptions.isEmpty
                            ? null
                            : (int? value) {
                                setState(() {
                                  _subType = value;
                                });
                                setSheetState(() {});
                              },
                      ),
                    ),
                    if (_propertyType == 3) ...<Widget>[
                      const SizedBox(height: 12),
                      _FilterField(
                        icon: Icons.bed_rounded,
                        label: 'PG sharing',
                        child: DropdownButtonFormField<int?>(
                          value: _pgSharingType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          items: <DropdownMenuItem<int?>>[
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All sharing types'),
                            ),
                            ..._filterPgSharingLabels.entries.map(
                              (MapEntry<int, String> entry) =>
                                  DropdownMenuItem<int?>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                            ),
                          ],
                          onChanged: (int? value) {
                            setState(() {
                              _pgSharingType = value;
                            });
                            setSheetState(() {});
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _FilterField(
                      icon: Icons.sell_rounded,
                      label: 'Category',
                      child: DropdownButtonFormField<int?>(
                        value: _categoryType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: <DropdownMenuItem<int?>>[
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All categories'),
                          ),
                          ..._filterCategoryLabels.entries.map(
                            (MapEntry<int, String> entry) =>
                                DropdownMenuItem<int?>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                          ),
                        ],
                        onChanged: (int? value) {
                          setState(() {
                            _categoryType = value;
                          });
                          setSheetState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FilterField(
                      icon: Icons.location_city_rounded,
                      label: 'City',
                      trailing: _isLoadingCities
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      child: DropdownButtonFormField<String?>(
                        value: _cityId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All cities'),
                          ),
                          ..._cities.map(
                            (PublicCityData city) => DropdownMenuItem<String?>(
                              value: city.cityId,
                              child: Text(city.cityName),
                            ),
                          ),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _cityId = value;
                          });
                          setSheetState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Budget',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _studioInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _PriceRange.values.map((_PriceRange range) {
                        final bool selected = _priceRange == range;
                        return ChoiceChip(
                          label: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(range.label),
                          ),
                          selected: selected,
                          showCheckmark: false,
                          labelStyle: theme.textTheme.labelLarge?.copyWith(
                            color: selected
                                ? Colors.white
                                : _studioInk,
                            fontWeight: FontWeight.w800,
                          ),
                          selectedColor: _studioPrimary,
                          backgroundColor: _studioSurface,
                          side: BorderSide(
                            color: selected
                                ? _studioPrimary
                                : _studioLine,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _priceRange = range;
                              _page = 1;
                            });
                            setSheetState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _clearFilters();
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _studioInk,
                              side: const BorderSide(color: _studioLine),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PurpleGradientButton(
                            label: 'Apply',
                            icon: Icons.tune_rounded,
                            onPressed: () {
                              Navigator.of(context).pop();
                              _applyFilters();
                            },
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

  Widget _buildPagination(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _page <= 1 || _isLoading
                  ? null
                  : () {
                      setState(() {
                        _page -= 1;
                      });
                      _loadProperties();
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: _studioInk,
                side: const BorderSide(color: _studioLine),
                backgroundColor: _studioSurface,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Previous'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$_page / $_totalPages',
              style: theme.textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: FilledButton.icon(
              onPressed: _page >= _totalPages || _isLoading
                  ? null
                  : () {
                      setState(() {
                        _page += 1;
                      });
                      _loadProperties();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: _studioPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _studioSecondary,
                disabledForegroundColor: Colors.white,
                elevation: 7,
                shadowColor: _studioPrimary.withValues(alpha: 0.22),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPropertyDetails(PropertyData property) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (BuildContext context) {
        return _PropertyDetailsSheet(
          property: property,
          fallbackImage: _fallbackImage,
          wishlistEnabled: widget.enableWishlist,
          isWishlisted: _isWishlisted(property),
          onWishlistToggle: () => _toggleWishlist(property),
          onEnquiry: () {
            Navigator.of(context).pop();
            _showEnquirySheet(property);
          },
        );
      },
    );
  }

  bool _isWishlisted(PropertyData property) {
    final String id = _wishlistIdFor(property);
    return id.isNotEmpty && _wishlistIds.contains(id);
  }

  Future<void> _toggleWishlist(PropertyData property) async {
    if (!widget.enableWishlist) {
      widget.onLoginPressed();
      return;
    }

    final String id = _wishlistIdFor(property);
    if (id.isEmpty) {
      return;
    }

    final Set<String> previousIds = Set<String>.from(_wishlistIds);
    final List<PropertyData> previousProperties =
        List<PropertyData>.from(_wishlistProperties);
    final Set<String> nextIds = Set<String>.from(_wishlistIds);
    final bool removed = nextIds.remove(id);
    if (!removed) {
      nextIds.add(id);
    }

    setState(() {
      _wishlistIds = nextIds;
      if (_showWishlistOnly && removed) {
        _showWishlistOnly = nextIds.isNotEmpty;
      }
      if (removed) {
        _wishlistProperties = _wishlistProperties
            .where((PropertyData item) => _wishlistIdFor(item) != id)
            .toList();
      } else if (!_wishlistProperties.any(
        (PropertyData item) => _wishlistIdFor(item) == id,
      )) {
        _wishlistProperties = <PropertyData>[property, ..._wishlistProperties];
      }
    });
    await AuthStorage.setWishlistPropertyIds(nextIds);

    try {
      if (removed) {
        await PropertyWishlistService.removeProperty(id);
      } else {
        await PropertyWishlistService.addProperty(id);
      }
    } catch (_) {
      await AuthStorage.setWishlistPropertyIds(previousIds);
      if (!mounted) return;
      setState(() {
        _wishlistIds = previousIds;
        _wishlistProperties = previousProperties;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wishlist sync failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(removed ? 'Removed from wishlist' : 'Added to wishlist'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEnquirySheet(PropertyData property) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _EnquirySheet(property: property);
      },
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.fallbackImage,
    required this.onDetails,
    required this.onEnquiry,
  });

  final PropertyData property;
  final String fallbackImage;
  final VoidCallback onDetails;
  final VoidCallback onEnquiry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String imageUrl = _imagesFor(property, fallbackImage).first;
    final int? vacancy = property.noOfVacancy;
    final List<_QuickSpec> specs = _specsFor(property);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12111827),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.all(10),
            child: AspectRatio(
              aspectRatio: 16 / 11,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ImageFallback(),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x22000000),
                            Color(0x05000000),
                            Color(0xB0000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _GlassBadge(label: _subTypeLabel(property)),
                    ),
                    if (property.whetherVerifiedPlus == true)
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: _GlassBadge(
                          label: 'Verified+',
                          icon: Icons.verified_rounded,
                        ),
                      ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  property.title.isEmpty
                                      ? 'Property'
                                      : property.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _locationLabel(property),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              '${_money(property.rent)}/month',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: specs
                      .map((_QuickSpec spec) => _SpecPill(spec: spec))
                      .toList(),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _MiniStat(
                          label: 'Deposit',
                          value: _money(property.deposit),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: const Color(0xFFE5E7EB),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Availability',
                          value: _vacancyShortLabel(vacancy),
                          valueColor: (vacancy ?? 1) > 0
                              ? const Color(0xFF166534)
                              : _studioMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDetails,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Details'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEnquiry,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Enquiry'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyDetailsSheet extends StatefulWidget {
  const _PropertyDetailsSheet({
    required this.property,
    required this.fallbackImage,
    required this.wishlistEnabled,
    required this.isWishlisted,
    required this.onWishlistToggle,
    required this.onEnquiry,
  });

  final PropertyData property;
  final String fallbackImage;
  final bool wishlistEnabled;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;
  final VoidCallback onEnquiry;

  @override
  State<_PropertyDetailsSheet> createState() => _PropertyDetailsSheetState();
}

class _PropertyDetailsSheetState extends State<_PropertyDetailsSheet> {
  late final PageController _detailImageController;
  Timer? _detailImageTimer;
  int _imageIndex = 0;
  bool _aboutExpanded = false;

  @override
  void initState() {
    super.initState();
    _detailImageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDetailImageAutoScroll();
    });
  }

  @override
  void dispose() {
    _detailImageTimer?.cancel();
    _detailImageController.dispose();
    super.dispose();
  }

  void _startDetailImageAutoScroll() {
    final List<String> images = _imagesFor(
      widget.property,
      widget.fallbackImage,
    );
    if (images.length <= 1) return;

    _detailImageTimer?.cancel();
    _detailImageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_detailImageController.hasClients) return;
      final int nextIndex = (_imageIndex + 1) % images.length;
      _detailImageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openImageGallery(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullImageGallery(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> images = _imagesFor(
      widget.property,
      widget.fallbackImage,
    );
    final List<String> amenities = _amenitiesFor(widget.property);
    final int? vacancy = widget.property.noOfVacancy;
    final double heroHeight = (MediaQuery.sizeOf(context).height * 0.48)
        .clamp(340.0, 430.0)
        .toDouble();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.0,
        ),
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height,
        child: Material(
          color: Colors.white,
          child: ListView(
          padding: EdgeInsets.only(
            bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          children: <Widget>[
            SizedBox(
              height: heroHeight,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  PageView.builder(
                    controller: _detailImageController,
                    itemCount: images.length,
                    onPageChanged: (int index) {
                      setState(() {
                        _imageIndex = index;
                      });
                    },
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openImageGallery(images, index),
                        child: _DetailHeroImage(
                          imageUrl: images[index],
                        ),
                      );
                    },
                  ),
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0x22000000),
                            Color(0x08000000),
                            Color(0xD0000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 18,
                    left: 22,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF111827),
                        fixedSize: const Size(56, 56),
                        shape: const CircleBorder(),
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.18),
                      ),
                      icon: const Icon(Icons.chevron_left_rounded, size: 34),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 24,
                    right: 22,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (widget.wishlistEnabled) ...<Widget>[
                          _WishlistButton(
                            isSelected: widget.isWishlisted,
                            onTap: widget.onWishlistToggle,
                          ),
                          const SizedBox(width: 10),
                        ],
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openImageGallery(images, _imageIndex),
                          child: _GlassBadge(
                            label: images.length > 1
                                ? '${_imageIndex + 1}/${images.length} photos'
                                : 'View photo',
                            icon: Icons.photo_library_outlined,
                            rounded: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 16,
                      child: _HeroImageDots(
                        count: images.length,
                        activeIndex: _imageIndex,
                      ),
                    ),
                ],
              ),
            ),
            Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.property.title.isEmpty
                          ? 'Property details'
                          : widget.property.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: _studioInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 27,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFF5E6675),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _locationLabel(widget.property),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF5E6675),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _AirbnbPricePanel(
                      rent: _money(widget.property.rent),
                      deposit: _money(widget.property.deposit),
                    ),
                    const SizedBox(height: 18),
                    _AirbnbFactRow(
                      items: <_AirbnbFactItem>[
                        _AirbnbFactItem(
                          icon: Icons.home_work_outlined,
                          label: _subTypeLabel(widget.property),
                        ),
                        _AirbnbFactItem(
                          icon: Icons.meeting_room_outlined,
                          label: _vacancyLongLabel(vacancy),
                        ),
                        if (_pgSharingLabel(widget.property) != null)
                          _AirbnbFactItem(
                            icon: Icons.group_outlined,
                            label: _pgSharingLabel(widget.property)!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Stay Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _studioInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _OverviewCardGrid(
                      items: <_OverviewCardItem>[
                        _OverviewCardItem(
                          icon: Icons.construction_rounded,
                          label: 'Maintenance',
                          value: _money(widget.property.maintenance ?? 0),
                          tint: _studioAccent.withValues(alpha: 0.12),
                          iconColor: _studioAccent,
                        ),
                        _OverviewCardItem(
                          icon: Icons.meeting_room_outlined,
                          label: 'Vacancy',
                          value: _vacancyShortLabel(vacancy),
                          tint: const Color(0xFFE5E7EB),
                          iconColor: (vacancy ?? 1) > 0
                              ? _studioAccent
                              : _studioMuted,
                        ),
                        if (_pgSharingLabel(widget.property) != null)
                          _OverviewCardItem(
                            icon: Icons.group_outlined,
                            label: 'PG Sharing',
                            value: _pgSharingLabel(widget.property)!,
                            tint: _studioSecondary.withValues(alpha: 0.18),
                            iconColor: _studioPrimary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: _studioLine, height: 1),
                    const SizedBox(height: 18),
                    Text(
                      'About Property',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _studioInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ExpandableAboutText(
                      text: widget.property.description.trim().isEmpty
                          ? '${widget.property.title.isEmpty ? 'This property' : widget.property.title} offers comfortable accommodation with practical amenities in ${_locationLabel(widget.property)}.'
                          : widget.property.description.trim(),
                      expanded: _aboutExpanded,
                      onToggle: () {
                        setState(() {
                          _aboutExpanded = !_aboutExpanded;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Amenities',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _studioInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailAmenityStrip(
                      specs: _specsFor(widget.property),
                      amenities: amenities,
                    ),
                    const SizedBox(height: 22),
                    if (_hasMapLocation(widget.property)) ...<Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _MapIconAction(
                          onTap: () => _openMap(widget.property),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onEnquiry,
                        style: FilledButton.styleFrom(
                        backgroundColor: _studioPrimary,
                        foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Enquire Now'),
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

class _EnquirySheet extends StatefulWidget {
  const _EnquirySheet({required this.property});

  final PropertyData property;

  @override
  State<_EnquirySheet> createState() => _EnquirySheetState();
}

class _ExpandableAboutText extends StatelessWidget {
  const _ExpandableAboutText({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool canExpand = text.length > 180;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          text,
          maxLines: expanded ? null : 5,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF5E6675),
            height: 1.38,
            fontSize: 14,
          ),
        ),
        if (canExpand) ...<Widget>[
          const SizedBox(height: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                expanded ? 'Read less' : 'Read more',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _studioPrimary,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.4,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MapIconAction extends StatelessWidget {
  const _MapIconAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _studioSurface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _studioLine),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.map_outlined,
                color: _studioPrimary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Open in maps',
                style: TextStyle(
                  color: _studioInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullImageGallery extends StatefulWidget {
  const _FullImageGallery({
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<_FullImageGallery> createState() => _FullImageGalleryState();
}

class _FullImageGalleryState extends State<_FullImageGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (int value) {
              setState(() {
                _index = value;
              });
            },
            itemBuilder: (BuildContext context, int index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 42,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                foregroundColor: Colors.white,
                fixedSize: const Size(46, 46),
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.close_rounded, size: 28),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 18,
            right: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  '${_index + 1}/${widget.images.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeroImage extends StatelessWidget {
  const _DetailHeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _ImageFallback(),
        ),
      ),
    );
  }
}

class _HeroImageDots extends StatelessWidget {
  const _HeroImageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int index) {
        final bool active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : Colors.white.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _EnquirySheetState extends State<_EnquirySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isSubmitting = false;
  bool _otpSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await PublicPropertyService.generateUserOtp(_phoneController.text);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = _cleanException(e);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_otpController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Enter the OTP sent to your phone.';
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await PublicPropertyService.createPropertyEnquiry(
        propertyId: widget.property.propertyId,
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        otp: _otpController.text,
      );
      if (!mounted) return;
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Enquiry submitted. The owner will contact you soon.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = _cleanException(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Property enquiry',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                widget.property.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                enabled: !_otpSent,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  counterText: '',
                ),
                validator: (String? value) {
                  final String phone = value?.trim() ?? '';
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: _otpSent
                    ? TextInputAction.next
                    : TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (String? value) {
                  final String email = value?.trim() ?? '';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              if (_otpSent) ...<Widget>[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    prefixIcon: Icon(Icons.password_rounded),
                    counterText: '',
                  ),
                ),
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : (_otpSent ? _submit : _sendOtp),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _otpSent
                              ? Icons.check_circle_outline_rounded
                              : Icons.send_outlined,
                        ),
                  label: Text(_otpSent ? 'Submit enquiry' : 'Send OTP'),
                ),
              ),
              if (_otpSent) ...<Widget>[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isSubmitting ? null : _sendOtp,
                    child: const Text('Resend OTP'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: _studioSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _studioLine),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x146C5CE7),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: _studioPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _studioMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _PurpleGradientButton extends StatelessWidget {
  const _PurpleGradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.height,
    this.borderRadius,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool compact;
  final double? height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final double resolvedHeight = height ?? (compact ? 38 : 48);
    final double resolvedRadius = borderRadius ?? (compact ? 999 : 16);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(resolvedRadius),
      child: Ink(
        height: resolvedHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[_studioPrimary, _studioSecondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(resolvedRadius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _studioPrimary.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(resolvedRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, color: Colors.white, size: compact ? 17 : 18),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 13 : 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudioPropertyCard extends StatelessWidget {
  const _StudioPropertyCard({
    required this.property,
    required this.fallbackImage,
    required this.onDetails,
    required this.onEnquiry,
    required this.wishlistEnabled,
    required this.isWishlisted,
    required this.onWishlistToggle,
  });

  final PropertyData property;
  final String fallbackImage;
  final VoidCallback onDetails;
  final VoidCallback onEnquiry;
  final bool wishlistEnabled;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> images = _imagesFor(property, fallbackImage);
    final int? vacancy = property.noOfVacancy;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _studioLine),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F1F2937),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0x0FFFFFFF),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: _Airbnb3DImage(
              images: images,
              property: property,
              photoCount: images.length,
              rent: _money(property.rent),
              wishlistEnabled: wishlistEnabled,
              isWishlisted: isWishlisted,
              onWishlistToggle: onWishlistToggle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    property.title.isEmpty ? 'Property' : property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _studioInk,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _TinyRatingBadge(
                  label: _vacancyShortLabel(vacancy),
                  positive: (vacancy ?? 1) > 0,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.home_work_outlined,
                  size: 14,
                  color: _studioMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${_subTypeLabel(property)} • Deposit ${_money(property.deposit)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _studioMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDetails,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _studioInk,
                          side: const BorderSide(color: _studioLine),
                          backgroundColor: _studioSurface,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          minimumSize: const Size(0, 38),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text('Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PurpleGradientButton(
                        label: 'Enquire Now',
                        onPressed: onEnquiry,
                        height: 38,
                        borderRadius: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Airbnb3DImage extends StatefulWidget {
  const _Airbnb3DImage({
    required this.images,
    required this.property,
    required this.photoCount,
    required this.rent,
    required this.wishlistEnabled,
    required this.isWishlisted,
    required this.onWishlistToggle,
  });

  final List<String> images;
  final PropertyData property;
  final int photoCount;
  final String rent;
  final bool wishlistEnabled;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;

  @override
  State<_Airbnb3DImage> createState() => _Airbnb3DImageState();
}

class _Airbnb3DImageState extends State<_Airbnb3DImage> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _Airbnb3DImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length ||
        oldWidget.images.join('|') != widget.images.join('|')) {
      _autoScrollTimer?.cancel();
      _imageIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.images.length <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final int nextIndex = (_imageIndex + 1) % widget.images.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x241F2937),
                blurRadius: 22,
                offset: Offset(0, 13),
              ),
            ],
          ),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    onPageChanged: (int index) {
                      setState(() {
                        _imageIndex = index;
                      });
                    },
                    itemBuilder: (BuildContext context, int index) {
                      return Image.network(
                        widget.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ImageFallback(),
                      );
                    },
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0x18000000),
                          Color(0x00000000),
                          Color(0xC7000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _SoftLabel(label: _subTypeLabel(widget.property)),
                  ),
                  if (widget.wishlistEnabled)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _WishlistButton(
                        isSelected: widget.isWishlisted,
                        onTap: widget.onWishlistToggle,
                      ),
                    ),
                  if (_distanceLabel(widget.property) != null)
                    Positioned(
                      top: widget.wishlistEnabled ? 54 : 10,
                      right: 10,
                      child: _SoftLabel(
                        label: _distanceLabel(widget.property)!,
                        icon: Icons.near_me_rounded,
                      ),
                    ),
                  Positioned(
                    left: 12,
                    right: 92,
                    bottom: 12,
                    child: Text(
                      _locationLabel(widget.property),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        shadows: const <Shadow>[
                          Shadow(blurRadius: 10, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  if (widget.photoCount > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 9,
                      child: Center(
                        child: _MiniPhotoDots(
                          count: widget.photoCount,
                          activeIndex: _imageIndex,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x261F2937),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: RichText(
              text: TextSpan(
                text: widget.rent,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _studioInk,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '/mo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _studioMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniPhotoDots extends StatelessWidget {
  const _MiniPhotoDots({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final int visibleCount = count.clamp(1, 4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(visibleCount, (int index) {
        final bool isActive = index == activeIndex % visibleCount;
        return Container(
          width: isActive ? 12 : 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _TinyRatingBadge extends StatelessWidget {
  const _TinyRatingBadge({
    required this.label,
    required this.positive,
  });

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: positive ? _studioAccent.withValues(alpha: 0.12) : _studioLine,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: positive ? _studioAccent : _studioInk,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PropertySectionHeader extends StatelessWidget {
  const _PropertySectionHeader({
    required this.title,
    required this.onViewAll,
  });

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: _studioInk,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            foregroundColor: _studioPrimary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('View all'),
        ),
      ],
    );
  }
}

class _ViewAllHeader extends StatelessWidget {
  const _ViewAllHeader({
    required this.title,
    required this.count,
    required this.onBack,
  });

  final String title;
  final int count;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String countLabel = count <= 0 ? 'Properties' : '$count properties';

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _studioLine),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: _studioPrimary.withValues(alpha: 0.10),
              foregroundColor: _studioPrimary,
              fixedSize: const Size(42, 42),
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _studioInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  countLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _studioMuted,
                    fontWeight: FontWeight.w700,
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

class _SectionDots extends StatelessWidget {
  const _SectionDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int index) {
        final bool active = index == 0;
        return Container(
          width: active ? 17 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? _studioPrimary : _studioLine,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _HeroTypePill extends StatelessWidget {
  const _HeroTypePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _studioPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroPriceCard extends StatelessWidget {
  const _HeroPriceCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: _studioPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '/month',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5E6675),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AirbnbPricePanel extends StatelessWidget {
  const _AirbnbPricePanel({required this.rent, required this.deposit});

  final String rent;
  final String deposit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _studioSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _studioLine),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  rent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: _studioInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'per month',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _studioMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 42, color: _studioLine),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  deposit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _studioInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'deposit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _studioMuted,
                    fontWeight: FontWeight.w600,
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

class _AirbnbFactItem {
  const _AirbnbFactItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _AirbnbFactRow extends StatelessWidget {
  const _AirbnbFactRow({required this.items});

  final List<_AirbnbFactItem> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final _AirbnbFactItem item = items[index];
          return Container(
            width: 126,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _studioLine),
            ),
            child: Row(
              children: <Widget>[
                Icon(item.icon, size: 20, color: _studioInk),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _studioInk,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewCardItem {
  const _OverviewCardItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final Color iconColor;
}

class _OverviewCardGrid extends StatelessWidget {
  const _OverviewCardGrid({required this.items});

  final List<_OverviewCardItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double itemWidth = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: items
              .map(
                (_OverviewCardItem item) => SizedBox(
                  width: itemWidth,
                  child: _OverviewCard(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.item});

  final _OverviewCardItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _studioSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _studioLine),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.tint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 18),
              ),
              const Spacer(),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.34),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF77716A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _studioInk,
              fontWeight: FontWeight.w900,
              fontSize: item.label == 'Available' ? 12.5 : 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailAmenityStrip extends StatelessWidget {
  const _DetailAmenityStrip({required this.specs, required this.amenities});

  final List<_QuickSpec> specs;
  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    final List<_QuickSpec> items = <_QuickSpec>[
      ...specs,
      ...amenities.map(
            (String amenity) => _QuickSpec(
              icon: _amenityIcon(amenity),
              label: amenity,
            ),
          ),
    ];
    final List<_QuickSpec> values = items.isEmpty
        ? const <_QuickSpec>[
            _QuickSpec(icon: Icons.king_bed_outlined, label: 'Rooms'),
            _QuickSpec(icon: Icons.wifi_rounded, label: 'Wi-Fi'),
            _QuickSpec(icon: Icons.room_service_outlined, label: 'Food'),
            _QuickSpec(icon: Icons.security_rounded, label: 'Security'),
          ]
        : items;

    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _studioSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _studioLine),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final _QuickSpec spec = values[index];
          return SizedBox(
            width: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(spec.icon, size: 23, color: _studioInk),
                const SizedBox(height: 7),
                Text(
                  spec.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _studioInk,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

IconData _amenityIcon(String amenity) {
  final String value = amenity.toLowerCase();
  if (value.contains('wifi') ||
      value.contains('wi-fi') ||
      value.contains('internet')) {
    return Icons.wifi_rounded;
  }
  if (value.contains('food') ||
      value.contains('meal') ||
      value.contains('mess')) {
    return Icons.room_service_outlined;
  }
  if (value.contains('security') ||
      value.contains('cctv') ||
      value.contains('guard')) {
    return Icons.security_rounded;
  }
  if (value.contains('parking') || value.contains('car') || value.contains('bike')) {
    return Icons.local_parking_rounded;
  }
  if (value.contains('ac') || value.contains('air condition')) {
    return Icons.ac_unit_rounded;
  }
  if (value.contains('geyser') ||
      value.contains('hot water') ||
      value.contains('heater')) {
    return Icons.water_drop_outlined;
  }
  if (value.contains('wardrobe') ||
      value.contains('cupboard') ||
      value.contains('closet')) {
    return Icons.inventory_2_outlined;
  }
  if (value.contains('bed') ||
      value.contains('room') ||
      value.contains('sharing') ||
      value.contains('furnished')) {
    return Icons.king_bed_outlined;
  }
  if (value.contains('power') ||
      value.contains('backup') ||
      value.contains('electric')) {
    return Icons.bolt_rounded;
  }
  if (value.contains('lift') || value.contains('elevator')) {
    return Icons.elevator_rounded;
  }
  if (value.contains('laundry') || value.contains('washing')) {
    return Icons.local_laundry_service_outlined;
  }
  if (value.contains('tv') || value.contains('television')) {
    return Icons.tv_rounded;
  }
  if (value.contains('fridge') || value.contains('refrigerator')) {
    return Icons.kitchen_outlined;
  }
  if (value.contains('kitchen') || value.contains('cook')) {
    return Icons.soup_kitchen_outlined;
  }
  if (value.contains('housekeeping') ||
      value.contains('clean') ||
      value.contains('maid')) {
    return Icons.cleaning_services_outlined;
  }
  if (value.contains('water')) {
    return Icons.water_drop_rounded;
  }
  if (value.contains('gym') || value.contains('fitness')) {
    return Icons.fitness_center_rounded;
  }
  if (value.contains('pool') || value.contains('swim')) {
    return Icons.pool_rounded;
  }
  if (value.contains('pet')) {
    return Icons.pets_rounded;
  }
  if (value.contains('balcony')) {
    return Icons.balcony_rounded;
  }
  if (value.contains('garden') || value.contains('park')) {
    return Icons.park_rounded;
  }
  if (value.contains('study')) {
    return Icons.menu_book_rounded;
  }
  if (value.contains('desk') || value.contains('work')) {
    return Icons.desk_outlined;
  }
  if (value.contains('bath') || value.contains('toilet')) {
    return Icons.bathtub_outlined;
  }
  return Icons.check_circle_outline_rounded;
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({
    required this.specs,
    required this.property,
  });

  final List<_QuickSpec> specs;
  final PropertyData property;

  @override
  Widget build(BuildContext context) {
    final List<_QuickSpec> values = _cardSpecsFor(property, specs);
    return Row(
      children: values.map((_QuickSpec spec) {
        final bool isLast = spec == values.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(spec.icon, size: 16, color: _studioInk),
                const SizedBox(height: 1),
                Text(
                  spec.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _studioInk,
                        fontSize: 8.8,
                        height: 1.02,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ImageDots extends StatelessWidget {
  const _ImageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int index) {
        final bool active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? _studioInk : const Color(0xFFD8D4CE),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  const _DetailTabs();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Text(
          'Overview',
          style: theme.textTheme.labelLarge?.copyWith(
            color: _studioInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 26),
        Text(
          'Maps',
          style: theme.textTheme.labelLarge?.copyWith(color: _studioMuted),
        ),
        const SizedBox(width: 26),
        Text(
          'Preview',
          style: theme.textTheme.labelLarge?.copyWith(color: _studioMuted),
        ),
      ],
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);

  final String label;
  final String value;
}

class _DetailInfoStrip extends StatelessWidget {
  const _DetailInfoStrip({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _studioLine),
      ),
      child: Row(
        children: items.map((_InfoItem item) {
          final bool isLast = item == items.last;
          return Expanded(
            child: Container(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        right: BorderSide(color: _studioLine),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _studioMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _studioInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SoftLabel extends StatelessWidget {
  const _SoftLabel({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: _studioInk),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _studioInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x26111827),
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Icon(
          isSelected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: const Color(0xFFE11D48),
          size: 22,
        ),
      ),
    );
  }
}

class _QuickSpec {
  const _QuickSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _SpecPill extends StatelessWidget {
  const _SpecPill({required this.spec});

  final _QuickSpec spec;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEEA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _studioLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(spec.icon, size: 13, color: _studioMuted),
          const SizedBox(width: 5),
          Text(
            spec.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _studioInk,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({
    required this.label,
    this.icon,
    this.rounded = true,
  });

  final String label;
  final IconData? icon;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(rounded ? 999 : 8);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: rounded ? 12 : 10,
            vertical: rounded ? 8 : 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 42, color: AppTheme.textMuted),
            const SizedBox(height: 10),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 17, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text.isEmpty ? 'India' : text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.color = AppTheme.primarySoft,
    this.textColor = AppTheme.primaryHover,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceMuted,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppTheme.textMuted,
        size: 34,
      ),
    );
  }
}

enum _PriceRange {
  all('All'),
  low('Under 15k'),
  mid('15k to 30k'),
  high('30k+');

  const _PriceRange(this.label);

  final String label;
}

List<_QuickSpec> _specsFor(PropertyData property) {
  final List<_QuickSpec> specs = <_QuickSpec>[];
  if (property.area != null && property.area! > 0) {
    specs.add(
      _QuickSpec(
        icon: Icons.straighten_rounded,
        label: '${property.area!.round()} sq ft',
      ),
    );
  }
  if (property.bedrooms != null && property.bedrooms! > 0) {
    specs.add(
      _QuickSpec(icon: Icons.bed_outlined, label: '${property.bedrooms} beds'),
    );
  }
  if (property.bathrooms != null && property.bathrooms! > 0) {
    specs.add(
      _QuickSpec(
        icon: Icons.bathtub_outlined,
        label: '${property.bathrooms} baths',
      ),
    );
  }
  if (property.balconies != null && property.balconies! > 0) {
    specs.add(
      _QuickSpec(
        icon: Icons.deck_outlined,
        label: '${property.balconies} balcony',
      ),
    );
  }
  return specs.take(3).toList();
}

List<String> _imagesFor(PropertyData property, String fallbackImage) {
  final List<String> images = property.images ?? <String>[];
  final List<String> clean = images
      .where((String item) => item.trim().isNotEmpty)
      .toList();
  if (clean.isNotEmpty) return clean;
  if (property.imageUrl != null && property.imageUrl!.trim().isNotEmpty) {
    return <String>[property.imageUrl!];
  }
  return <String>[fallbackImage];
}

String _locationLabel(PropertyData property) {
  return property.ownerAddress ??
      property.locationAddress ??
      property.address ??
      property.locality ??
      property.city ??
      'India';
}

String? _distanceLabel(PropertyData property) {
  final double? distance = property.distanceKm;
  if (distance == null || distance <= 0 || !distance.isFinite) return null;
  if (distance < 1) return '${(distance * 1000).round()} m away';
  return '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} km away';
}

String _propertyTypeLabel(int type) {
  return switch (type) {
    1 => 'Apartment',
    2 => 'Villa',
    3 => 'PG',
    4 => 'Commercial',
    _ => 'Property',
  };
}

String _sectionTitleForType(int type) {
  return switch (type) {
    3 => 'PG (Paying Guest)',
    _ => _propertyTypeLabel(type),
  };
}

List<_QuickSpec> _cardSpecsFor(PropertyData property, List<_QuickSpec> specs) {
  if (property.propertyType == 3) {
    return const <_QuickSpec>[
      _QuickSpec(icon: Icons.bed_outlined, label: 'Sharing\nRooms'),
      _QuickSpec(icon: Icons.wifi_rounded, label: 'Wi-Fi\nAvailable'),
      _QuickSpec(icon: Icons.restaurant_outlined, label: 'Food\nIncluded'),
    ];
  }

  final List<_QuickSpec> result = <_QuickSpec>[
    ...specs,
    if (property.whetherParkingAvailable == true ||
        property.parkingSlots != null)
      const _QuickSpec(icon: Icons.directions_car_outlined, label: 'Parking'),
  ];

  if (result.length >= 3) return result.take(3).toList();

  return <_QuickSpec>[
    ...result,
    if (!result.any((_QuickSpec item) => item.icon == Icons.bed_outlined))
      const _QuickSpec(icon: Icons.bed_outlined, label: 'Bedrooms'),
    if (!result.any((_QuickSpec item) => item.icon == Icons.bathtub_outlined))
      const _QuickSpec(icon: Icons.bathtub_outlined, label: 'Bathrooms'),
    if (!result.any(
      (_QuickSpec item) => item.icon == Icons.directions_car_outlined,
    ))
      const _QuickSpec(icon: Icons.directions_car_outlined, label: 'Parking'),
  ].take(3).toList();
}

String _subTypeLabel(PropertyData property) {
  final int? subType = property.subType;
  if (subType == null) return _propertyTypeLabel(property.propertyType);
  return switch (property.propertyType) {
    1 => switch (subType) {
      1 => '1 BHK',
      2 => '2 BHK',
      3 => '3 BHK',
      4 => '4 BHK',
      5 => 'Studio',
      _ => 'Apartment',
    },
    2 => switch (subType) {
      1 => '2 BHK Villa',
      2 => '3 BHK Villa',
      3 => '4 BHK Villa',
      4 => 'Duplex Villa',
      _ => 'Villa',
    },
    3 => switch (subType) {
      1 => 'Mens PG',
      2 => 'Womens PG',
      3 => 'Coliving',
      _ => 'PG',
    },
    4 => switch (subType) {
      1 => 'Office',
      2 => 'Retail',
      3 => 'Warehouse',
      4 => 'Showroom',
      _ => 'Commercial',
    },
    _ => _propertyTypeLabel(property.propertyType),
  };
}

String? _pgSharingLabel(PropertyData property) {
  if (property.propertyType != 3) return null;
  return switch (property.pgSharingType) {
    1 => 'Single Sharing',
    2 => 'Double Sharing',
    3 => 'Triple Sharing',
    4 => 'Quad Sharing',
    5 => 'Dorm Sharing',
    _ => null,
  };
}

String _vacancyShortLabel(int? vacancy) {
  if (vacancy == null) return 'N/A';
  if (vacancy <= 0) return 'Sold out';
  return '$vacancy Vacancy';
}

String _vacancyLongLabel(int? vacancy) {
  if (vacancy == null) return 'Vacancy N/A';
  if (vacancy <= 0) return 'No Vacancy Available';
  if (vacancy == 1) return '1 Vacancy Available';
  return '$vacancy Vacancies Available';
}

String _wishlistIdFor(PropertyData property) {
  if (property.propertyId.trim().isNotEmpty) {
    return property.propertyId.trim();
  }
  return '${property.title}|${property.city ?? ''}|${property.rent}'.trim();
}

List<String> _amenitiesFor(PropertyData property) {
  const Map<int, String> amenityLabels = <int, String>{
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
    15: 'Children Play Area',
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
  };

  final List<int> ids = property.amenityIds ?? <int>[];
  if (ids.isNotEmpty) {
    return ids.map((int id) => amenityLabels[id] ?? 'Amenity $id').toList();
  }

  final String? amenities = property.amenities;
  if (amenities == null || amenities.trim().isEmpty) return <String>[];
  return amenities
      .split(',')
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList();
}

bool _hasMapLocation(PropertyData property) {
  final double? latitude = property.latitude;
  final double? longitude = property.longitude;
  return latitude != null &&
      longitude != null &&
      latitude != 0 &&
      longitude != 0;
}

Future<void> _openMap(PropertyData property) async {
  if (!_hasMapLocation(property)) return;
  final Uri uri = Uri.parse(
    'https://www.google.com/maps?q=${property.latitude},${property.longitude}',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _money(double value) {
  final String raw = value.round().toString();
  if (raw.length <= 3) {
    return 'Rs $raw';
  }
  String rest = raw.substring(0, raw.length - 3);
  final String last = raw.substring(raw.length - 3);
  final List<String> groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return 'Rs ${groups.join(',')},$last';
}

String _cleanException(Object error) {
  final String message = error.toString();
  return message.startsWith('Exception: ')
      ? message.substring('Exception: '.length)
      : message;
}
