import 'package:flutter/foundation.dart';
import '../models/template.dart';
import '../models/hotel.dart';
import '../models/flight.dart';
import '../models/bus.dart';
import '../models/city.dart';
import '../services/template_service.dart';

class ForkWizardProvider extends ChangeNotifier {
  final TemplateService _templateService = TemplateService();

  ForkGuide? _forkGuide;
  DateTime? _startDate;
  City? _originCity;
  bool _isLoading = false;
  String? _error;

  // Flight selections
  FlightOffer? _outboundFlight;
  FlightOffer? _returnFlight;

  // Hotel selection per leg order
  final Map<int, HotelOffer?> _selectedHotels = {};
  // Availability cache: booking_hotel_id → HotelOffer (null = unavailable)
  final Map<int, Map<int, HotelOffer?>> _pickAvailability = {};
  final Map<int, bool> _loadingHotels = {};

  // Bus/transport selection per segment index (0 = between leg 0 and leg 1, etc.)
  final Map<int, BusOffer?> _selectedBuses = {};

  // ─── Getters ──────────────────────────────────────────────────────

  ForkGuide? get forkGuide => _forkGuide;
  DateTime? get startDate => _startDate;
  City? get originCity => _originCity;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FlightOffer? get outboundFlight => _outboundFlight;
  FlightOffer? get returnFlight => _returnFlight;
  Map<int, HotelOffer?> get selectedHotels => _selectedHotels;
  Map<int, BusOffer?> get selectedBuses => _selectedBuses;
  Map<int, Map<int, HotelOffer?>> get pickAvailability => _pickAvailability;
  bool isLoadingHotels(int legOrder) => _loadingHotels[legOrder] ?? false;

  // ─── Setters ──────────────────────────────────────────────────────

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  void setOriginCity(City city) {
    _originCity = city;
    notifyListeners();
  }

  void setOutboundFlight(FlightOffer? flight) {
    _outboundFlight = flight;
    notifyListeners();
  }

  void setReturnFlight(FlightOffer? flight) {
    _returnFlight = flight;
    notifyListeners();
  }

  void selectBus(int segmentIndex, BusOffer? bus) {
    _selectedBuses[segmentIndex] = bus;
    notifyListeners();
  }

  // ─── Initialize ───────────────────────────────────────────────────

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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
        availability[pick.bookingHotelId] = hotel;
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

  // ─── Date helpers ─────────────────────────────────────────────────

  int daysBeforeLeg(int legOrder) {
    if (_forkGuide == null) return 0;
    int days = 0;
    for (final leg in _forkGuide!.legs) {
      if (leg.order >= legOrder) break;
      days += leg.days;
    }
    return days;
  }

  DateTime? legStartDate(int legOrder) {
    if (_startDate == null) return null;
    return _startDate!.add(Duration(days: daysBeforeLeg(legOrder)));
  }

  DateTime? legEndDate(int legOrder) {
    if (_startDate == null || _forkGuide == null) return null;
    final leg = _forkGuide!.legs.firstWhere((l) => l.order == legOrder);
    return legStartDate(legOrder)!.add(Duration(days: leg.days));
  }

  // ─── Totals ───────────────────────────────────────────────────────

  double get hotelsTotal {
    double total = 0;
    for (final hotel in _selectedHotels.values) {
      if (hotel != null) total += hotel.priceTotal;
    }
    return total;
  }

  double get flightsTotal {
    double total = 0;
    if (_outboundFlight != null) total += _outboundFlight!.price;
    if (_returnFlight != null) total += _returnFlight!.price;
    return total;
  }

  double get busesTotal {
    double total = 0;
    for (final bus in _selectedBuses.values) {
      if (bus != null) total += (bus.totalPrice ?? bus.price);
    }
    return total;
  }

  double get grandTotal => hotelsTotal + flightsTotal + busesTotal;

  // ─── Reset ────────────────────────────────────────────────────────

  void reset() {
    _forkGuide = null;
    _startDate = null;
    _originCity = null;
    _isLoading = false;
    _error = null;
    _outboundFlight = null;
    _returnFlight = null;
    _selectedHotels.clear();
    _selectedBuses.clear();
    _pickAvailability.clear();
    _loadingHotels.clear();
    notifyListeners();
  }
}
