import 'package:flutter/material.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';
import 'package:parking_app/views/reservation/reservation_detail_screen.dart';
import 'package:parking_app/core/services/parking_search_service.dart';
import 'package:parking_app/core/api/parking/parking_search_api.dart';
import 'package:parking_app/core/models/parking_search_model.dart';

class ParkingSearchScreen extends StatefulWidget {
  const ParkingSearchScreen({super.key});

  @override
  State<ParkingSearchScreen> createState() => _ParkingSearchScreenState();
}

class _ParkingSearchScreenState extends State<ParkingSearchScreen>
    with TickerProviderStateMixin {
  // Controllers and Focus
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Services
  late final ParkingSearchService _parkingSearchService;

  // Animation Controllers
  late AnimationController _expansionController;
  late Animation<double> _expansionAnimation;

  // Search State
  bool _isExpanded = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Search Parameters
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedCarType = 'unspecified';
  String _selectedReserveType = 'hourlyRate';
  bool _showMap = false;

  // Search Results
  List<ParkingLot> _searchResults = [];
  int _totalResults = 0;

  @override
  void initState() {
    super.initState();
    _parkingSearchService = ParkingSearchService(ParkingSearchApi());
    _setupAnimations();
    _setupListeners();
    _loadInitialData();
  }

  void _setupAnimations() {
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    );
  }

  void _setupListeners() {
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && !_isExpanded) {
        _expandSearchArea();
      }
    });
  }

  void _loadInitialData() {
    // Initialize with current time + 1 hour
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _startTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
    _endTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 5)));

    // Load initial search results
    _performSearch();
  }

  void _expandSearchArea() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
      _expansionController.forward();
    }
  }

  void _collapseSearchArea() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
      });
      _expansionController.reverse();
      _searchFocusNode.unfocus();
    }
  }

  Future<void> _selectDateTime() async {
    final result = await showBoardDateTimePicker(
      context: context,
      pickerType: DateTimePickerType.datetime,
      initialDate: _selectedDate,
      minimumDate: DateTime.now(),
      maximumDate: DateTime.now().add(const Duration(days: 365)),
      options: BoardDateTimeOptions(
        languages: BoardPickerLanguages.ja(),
        pickerFormat: PickerFormat.ymd,
        boardTitle: AppLocalizations.of(context).selectDateTime,
        boardTitleTextStyle: TextStyles.titleMedium,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDate = result;
        _startTime = TimeOfDay.fromDateTime(result);
        _endTime = TimeOfDay.fromDateTime(result.add(const Duration(hours: 4)));
      });
    }
  }

  String _formatDateTime() {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      return '';
    }

    final date = _selectedDate!;
    final start = _startTime!;
    final end = _endTime!;

    return '${date.year}年${date.month}月${date.day}日 ${start.format(context)}〜${end.format(context)}';
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create search request model
      final searchRequest = ParkingSearchRequestModel(
        keyword:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        startDateTime:
            _selectedDate != null && _startTime != null
                ? DateTime(
                  _selectedDate!.year,
                  _selectedDate!.month,
                  _selectedDate!.day,
                  _startTime!.hour,
                  _startTime!.minute,
                )
                : null,
        endDateTime:
            _selectedDate != null && _endTime != null
                ? DateTime(
                  _selectedDate!.year,
                  _selectedDate!.month,
                  _selectedDate!.day,
                  _endTime!.hour,
                  _endTime!.minute,
                )
                : null,
        vehicleType:
            _selectedCarType != 'unspecified' ? _selectedCarType : null,
        rentalType:
            _selectedReserveType != 'unspecified' ? _selectedReserveType : null,
        page: 1,
        perPage: 20,
      );

      // Call the API through the service
      await _parkingSearchService.searchParkingLots(searchRequest);

      // Get results from the service
      final results = _parkingSearchService.searchResults;

      // Convert API models to UI models
      final uiResults =
          results.map((apiModel) => _convertToUiModel(apiModel)).toList();

      setState(() {
        _searchResults = uiResults;
        _totalResults = _parkingSearchService.totalCount;
        _isLoading = false;
      });

      _collapseSearchArea();
    } catch (e) {
      setState(() {
        _errorMessage = 'search_error';
        _isLoading = false;
      });
    }
  }

  /// Convert API model to UI model
  ParkingLot _convertToUiModel(ParkingLotModel apiModel) {
    return ParkingLot(
      id: apiModel.parkingLotId,
      name: apiModel.parkingLotName,
      address:
          '${apiModel.prefecture}${apiModel.city}${apiModel.addressDetail}',
      hourlyRate: apiModel.hourlyRate ?? 500, // Default rate if not provided
      features: [
        if (apiModel.featuresTip != null) apiModel.featuresTip!,
        if (apiModel.rentalType != null) apiModel.rentalType!,
        '予約可',
      ],
      walkingMinutes:
          apiModel.distance?.round() ??
          5, // Convert km to walking minutes approximation
      isFavorite: apiModel.isFavorite,
      hasRoof: apiModel.featuresTip?.contains('屋根') ?? false,
      is24Hours: apiModel.featuresTip?.contains('24時間') ?? false,
    );
  }

  void _toggleFavorite(ParkingLot lot) async {
    try {
      if (lot.isFavorite) {
        await _parkingSearchService.removeFromFavorites(lot.id);
      } else {
        await _parkingSearchService.addToFavorites(lot.id);
      }

      setState(() {
        lot.isFavorite = !lot.isFavorite;
      });
    } catch (e) {
      // Handle error - maybe show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('お気に入りの更新に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _parkingSearchService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.parkingSearch,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            icon: const Icon(Icons.map, color: Colors.white),
            label: Text(
              l10n.mapView,
              style: TextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(l10n),
          _buildResultsCount(l10n),
          Expanded(child: _buildContent(l10n)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(l10n),
    );
  }

  Widget _buildSearchSection(AppLocalizations l10n) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: l10n.searchPlaceholder,
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch();
                          },
                        )
                        : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
            ),
          ),

          // Expandable Search Filters
          AnimatedBuilder(
            animation: _expansionAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _expansionAnimation,
                child: _buildSearchFilters(l10n),
              );
            },
          ),

          // Search Button
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _performSearch,
                  icon:
                      _isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Icon(Icons.search),
                  label: Text(l10n.searchButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchFilters(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          // Date Time Picker
          _buildDateTimeSelector(l10n),
          const SizedBox(height: 12),

          // Car Type and Reservation Type
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: l10n.carType,
                  value: _selectedCarType,
                  items: [
                    DropdownMenuItem(
                      value: 'unspecified',
                      child: Text(l10n.unspecified),
                    ),
                    DropdownMenuItem(
                      value: 'compact',
                      child: Text(l10n.compactCar),
                    ),
                    DropdownMenuItem(
                      value: 'regular',
                      child: Text(l10n.regularCar),
                    ),
                    DropdownMenuItem(
                      value: 'large',
                      child: Text(l10n.largeCar),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCarType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: l10n.reservationType,
                  value: _selectedReserveType,
                  items: [
                    DropdownMenuItem(
                      value: 'hourlyRate',
                      child: Text(l10n.hourlyRate),
                    ),
                    DropdownMenuItem(
                      value: 'dailyRate',
                      child: Text(l10n.dailyRate),
                    ),
                    DropdownMenuItem(
                      value: 'monthlyRate',
                      child: Text(l10n.monthlyRate),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedReserveType = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector(AppLocalizations l10n) {
    return InkWell(
      onTap: _selectDateTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatDateTime().isNotEmpty
                    ? _formatDateTime()
                    : l10n.selectDateTime,
                style: TextStyles.bodyMedium,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      dropdownColor: Colors.white,
    );
  }

  Widget _buildResultsCount(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.background,
      child: Text(
        l10n.searchResultsCount(_totalResults),
        style: TextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.unexpectedError,
              style: TextStyles.bodyMedium.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _performSearch, child: const Text('再試行')),
          ],
        ),
      );
    }

    if (_showMap) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 80, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              l10n.mapPlaceholder,
              style: TextStyles.bodyMedium.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.noSearchResults,
              style: TextStyles.bodyMedium.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildParkingCard(_searchResults[index], l10n);
      },
    );
  }

  Widget _buildParkingCard(ParkingLot lot, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and favorite
            Row(
              children: [
                Expanded(
                  child: Text(
                    lot.name,
                    style: TextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    lot.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: lot.isFavorite ? Colors.red : AppColors.primary,
                  ),
                  onPressed: () => _toggleFavorite(lot),
                  tooltip:
                      lot.isFavorite
                          ? l10n.removeFromFavorites
                          : l10n.addToFavorites,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lot.address,
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Rate and distance
            Row(
              children: [
                Text(
                  '¥${lot.hourlyRate}/時間',
                  style: TextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.directions_walk, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '駅から${lot.walkingMinutes}分',
                  style: TextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Features
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children:
                  lot.features.map((feature) {
                    return Chip(
                      label: Text(feature, style: TextStyles.bodySmall),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
            ),

            const SizedBox(height: 16),

            // Reserve button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReservationDetailScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.reserveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(AppLocalizations l10n) {
    return BottomNavigationBar(
      currentIndex: 1,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: l10n.homeTab,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.search),
          label: l10n.searchTab,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: l10n.historyTab,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: l10n.accountTab,
        ),
      ],
      onTap: (index) {
        // Handle navigation
      },
    );
  }
}

// Model class for parking lot data
class ParkingLot {
  final String id;
  final String name;
  final String address;
  final int hourlyRate;
  final List<String> features;
  final int walkingMinutes;
  bool isFavorite;
  final bool hasRoof;
  final bool is24Hours;

  ParkingLot({
    required this.id,
    required this.name,
    required this.address,
    required this.hourlyRate,
    required this.features,
    required this.walkingMinutes,
    this.isFavorite = false,
    this.hasRoof = false,
    this.is24Hours = false,
  });
}
