import 'package:flutter/foundation.dart';
import '../models/template.dart';
import '../models/hotel.dart';
import '../services/template_service.dart';

class ForkWizardProvider extends ChangeNotifier {
  final TemplateService _templateService = TemplateService();

  ForkGuide? _forkGuide;
  int _currentStep = 0;
  DateTime? _startDate;
  bool _isLoading = false;
  String? _error;

  // Hotel selection per leg order
  final Map<int, HotelOffer?> _selectedHotels = {};
  // Availability cache: booking_hotel_id → HotelOffer (null = unavailable)
  final Map<int, Map<int, HotelOffer?>> _pickAvailability = {};
  final Map<int, bool> _loadingHotels = {};

  ForkGuide? get forkGuide => _forkGuide;
  int get currentStep => _currentStep;
  DateTime? get startDate => _startDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<int, HotelOffer?> get selectedHotels => _selectedHotels;
  Map<int, Map<int, HotelOffer?>> get pickAvailability => _pickAvailability;
  bool isLoadingHotels(int legOrder) => _loadingHotels[legOrder] ?? false;

  int get totalSteps {
    if (_forkGuide == null) return 2;
    return _forkGuide!.legs.length + 2; // date + per-city hotel + review
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  Future<void> initializeFork({
    required String templateId,
    required String userId,
    required String startDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _templateService.registerFork(templateId: templateId, userId: userId);
      _forkGuide = await _templateService.getForkGuide(
        templateId: templateId, startDate: startDate,
      );
      _currentStep = 1;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void nextStep() { if (_currentStep < totalSteps - 1) { _currentStep++; notifyListeners(); } }
  void previousStep() { if (_currentStep > 0) { _currentStep--; notifyListeners(); } }

  // ─── Hotel availability check ─────────────────────────────────────

  Future<void> checkHotelsForLeg(int legOrder) async {
    final leg = _forkGuide?.legs.firstWhere((l) => l.order == legOrder);
    if (leg?.hotelSearch == null) return;

    _loadingHotels[legOrder] = true;
    notifyListeners();

    try {
      final search = leg!.hotelSearch!;
      final availability = <int, HotelOffer?>{};
      for (final pick in search.primaryPicks) {
        final hotel = await _templateService.getHotelDetails(
          hotelId: pick.bookingHotelId,
          arrivalDate: search.checkin,
          departureDate: search.checkout,
        );
        availability[pick.bookingHotelId] = hotel; // null = not available
      }
      _pickAvailability[legOrder] = availability;
    } catch (e) {
      debugPrint('Error checking hotels for leg $legOrder: $e');
    } finally {
      _loadingHotels[legOrder] = false;
      notifyListeners();
    }
  }

  void selectHotel(int legOrder, HotelOffer? hotel) {
    _selectedHotels[legOrder] = hotel;
    notifyListeners();
  }

  double get hotelsTotal {
    double total = 0;
    for (final hotel in _selectedHotels.values) {
      if (hotel != null) total += hotel.priceTotal;
    }
    return total;
  }

  void reset() {
    _forkGuide = null;
    _currentStep = 0;
    _startDate = null;
    _isLoading = false;
    _error = null;
    _selectedHotels.clear();
    _pickAvailability.clear();
    _loadingHotels.clear();
    notifyListeners();
  }
}
