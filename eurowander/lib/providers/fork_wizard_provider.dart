import 'package:flutter/foundation.dart';
import '../models/template.dart';
import '../models/flight.dart';
import '../models/bus.dart';
import '../models/hotel.dart';
import '../services/template_service.dart';

class ForkWizardProvider extends ChangeNotifier {
  final TemplateService _service = TemplateService();

  // ─── State ────────────────────────────────────────────────────────
  ForkGuide? _forkGuide;
  int _currentStep = 0;
  DateTime? _startDate;
  bool _isLoading = false;
  String? _error;

  // Selections keyed by leg order
  final Map<int, FlightOffer?> _selectedFlights = {};
  final Map<int, BusOffer?> _selectedTransport = {};
  final Map<int, HotelOffer?> _selectedHotels = {};

  // Search results keyed by leg order
  final Map<int, List<FlightOffer>> _flightResults = {};
  final Map<int, List<BusOffer>> _transportResults = {};
  final Map<int, List<HotelOffer>> _hotelResults = {};
  final Map<int, Map<int, HotelOffer?>> _primaryPickAvailability = {};

  // Loading states per leg
  final Map<int, bool> _loadingFlights = {};
  final Map<int, bool> _loadingTransport = {};
  final Map<int, bool> _loadingHotels = {};

  // ─── Getters ──────────────────────────────────────────────────────
  ForkGuide? get forkGuide => _forkGuide;
  int get currentStep => _currentStep;
  DateTime? get startDate => _startDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<int, FlightOffer?> get selectedFlights => _selectedFlights;
  Map<int, BusOffer?> get selectedTransport => _selectedTransport;
  Map<int, HotelOffer?> get selectedHotels => _selectedHotels;

  Map<int, List<FlightOffer>> get flightResults => _flightResults;
  Map<int, List<BusOffer>> get transportResults => _transportResults;
  Map<int, List<HotelOffer>> get hotelResults => _hotelResults;
  Map<int, Map<int, HotelOffer?>> get primaryPickAvailability =>
      _primaryPickAvailability;

  bool isLoadingFlights(int legOrder) => _loadingFlights[legOrder] ?? false;
  bool isLoadingTransport(int legOrder) => _loadingTransport[legOrder] ?? false;
  bool isLoadingHotels(int legOrder) => _loadingHotels[legOrder] ?? false;

  int get totalSteps {
    if (_forkGuide == null) return 2; // date + review
    return _forkGuide!.legs.length + 2; // date + legs + review
  }

  // ─── Actions ──────────────────────────────────────────────────────

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
      // Fire & forget: register the fork
      _service.registerFork(templateId: templateId, userId: userId);

      // Get the fork guide
      _forkGuide = await _service.getForkGuide(
        templateId: templateId,
        startDate: startDate,
      );
      _currentStep = 1; // Move past date picker
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  // ─── Flight Search & Selection ────────────────────────────────────

  Future<void> searchFlightsForLeg(int legOrder) async {
    final leg = _forkGuide?.legs.firstWhere((l) => l.order == legOrder);
    if (leg?.flightSearch == null) return;

    _loadingFlights[legOrder] = true;
    notifyListeners();

    try {
      final search = leg!.flightSearch!;
      final results = await _service.searchFlightsByIata(
        originIata: search.originIata,
        destinationIata: search.destinationIata,
        outboundDate: search.date,
      );
      _flightResults[legOrder] = results;
    } catch (e) {
      _flightResults[legOrder] = [];
    } finally {
      _loadingFlights[legOrder] = false;
      notifyListeners();
    }
  }

  void selectFlight(int legOrder, FlightOffer? flight) {
    _selectedFlights[legOrder] = flight;
    notifyListeners();
  }

  /// Sort flight results into tiers based on author's preferences
  Map<String, List<FlightOffer>> getFlightTiers(int legOrder) {
    final leg = _forkGuide?.legs.firstWhere((l) => l.order == legOrder);
    final results = _flightResults[legOrder] ?? [];
    final preferred = leg?.flightSearch?.preferredAirlines ?? [];
    final preferredNumbers = leg?.flightSearch?.preferredFlightNumbers ?? [];

    final topPick = <FlightOffer>[];
    final recommended = <FlightOffer>[];
    final others = <FlightOffer>[];

    for (final flight in results) {
      final airlineName = _getAirlineName(flight);

      // Check exact flight number match first
      if (preferredNumbers.isNotEmpty &&
          _matchesFlightNumber(flight, preferredNumbers)) {
        topPick.add(flight);
      } else if (preferred.isNotEmpty &&
          airlineName.toLowerCase().contains(preferred[0].toLowerCase())) {
        topPick.add(flight);
      } else if (preferred.length > 1 &&
          preferred
              .skip(1)
              .any((a) => airlineName.toLowerCase().contains(a.toLowerCase()))) {
        recommended.add(flight);
      } else {
        others.add(flight);
      }
    }

    // Sort each tier by price
    topPick.sort((a, b) => a.price.compareTo(b.price));
    recommended.sort((a, b) => a.price.compareTo(b.price));
    others.sort((a, b) => a.price.compareTo(b.price));

    return {
      'top_pick': topPick,
      'recommended': recommended,
      'others': others,
    };
  }

  String _getAirlineName(FlightOffer flight) {
    if (flight.legs.isNotEmpty) {
      return flight.legs.first.airline;
    }
    return '';
  }

  bool _matchesFlightNumber(FlightOffer flight, List<String> numbers) {
    if (flight.legs.isNotEmpty) {
      final flightNum = flight.legs.first.flightNumber;
      return numbers.any(
          (n) => flightNum.toLowerCase().contains(n.toLowerCase()));
    }
    return false;
  }

  // ─── Transport Search & Selection ─────────────────────────────────

  Future<void> searchTransportForLeg(int legOrder) async {
    final leg = _forkGuide?.legs.firstWhere((l) => l.order == legOrder);
    if (leg?.transportSearch == null) return;

    _loadingTransport[legOrder] = true;
    notifyListeners();

    try {
      final search = leg!.transportSearch!;
      final results = await _service.searchBuses(
        fromCity: search.fromCity,
        toCity: search.toCity,
        date: search.date,
      );
      _transportResults[legOrder] = results;
    } catch (e) {
      _transportResults[legOrder] = [];
    } finally {
      _loadingTransport[legOrder] = false;
      notifyListeners();
    }
  }

  void selectTransport(int legOrder, BusOffer? bus) {
    _selectedTransport[legOrder] = bus;
    notifyListeners();
  }

  /// Sort transport results into tiers based on author's preferences
  Map<String, List<BusOffer>> getTransportTiers(int legOrder) {
    final leg = _forkGuide?.legs.firstWhere((l) => l.order == legOrder);
    final results = _transportResults[legOrder] ?? [];
    final preferred = leg?.transportSearch?.preferredProviders ?? [];

    final topPick = <BusOffer>[];
    final others = <BusOffer>[];

    for (final bus in results) {
      final providerName = bus.segments.isNotEmpty ? bus.segments.first.product : bus.depName;
      if (preferred.any(
          (p) => providerName.toLowerCase().contains(p.toLowerCase()))) {
        topPick.add(bus);
      } else {
        others.add(bus);
      }
    }

    topPick.sort((a, b) => a.price.compareTo(b.price));
    others.sort((a, b) => a.price.compareTo(b.price));

    return {
      'top_pick': topPick,
      'others': others,
    };
  }

  // ─── Hotel Search & Selection ─────────────────────────────────────

  Future<void> searchHotelsForLeg(int legOrder) async {
    final leg = _forkGuide?.legs.firstWhere((l) => l.order == legOrder);
    if (leg?.hotelSearch == null) return;

    _loadingHotels[legOrder] = true;
    notifyListeners();

    try {
      final search = leg!.hotelSearch!;

      // Check availability for each primary pick
      final pickAvailability = <int, HotelOffer?>{};
      for (final pick in search.primaryPicks) {
        final hotel = await _service.getHotelDetails(
          hotelId: pick.bookingHotelId,
          arrivalDate: search.checkin,
          departureDate: search.checkout,
        );
        pickAvailability[pick.bookingHotelId] = hotel;
      }
      _primaryPickAvailability[legOrder] = pickAvailability;

      // Get fallback results
      if (search.fallbackParams != null) {
        final fallbackResults = await _service.searchBuses(
          fromCity: search.city,
          toCity: '', // This will use hotel search - see note below
          date: search.checkin,
        );
        // Note: we'll use a dedicated hotel search for fallback
      }
    } catch (e) {
      debugPrint('Error searching hotels for leg $legOrder: $e');
    } finally {
      _loadingHotels[legOrder] = false;
      notifyListeners();
    }
  }

  void selectHotel(int legOrder, HotelOffer? hotel) {
    _selectedHotels[legOrder] = hotel;
    notifyListeners();
  }

  // ─── Summary Helpers ──────────────────────────────────────────────

  double get estimatedTotal {
    double total = 0;
    for (final flight in _selectedFlights.values) {
      if (flight != null) total += flight.price;
    }
    for (final bus in _selectedTransport.values) {
      if (bus != null) total += bus.price;
    }
    for (final hotel in _selectedHotels.values) {
      if (hotel != null) total += hotel.priceTotal;
    }
    return total;
  }

  List<int> get skippedLegs {
    if (_forkGuide == null) return [];
    final skipped = <int>[];
    for (final leg in _forkGuide!.legs) {
      final hasSelection = _selectedFlights[leg.order] != null ||
          _selectedTransport[leg.order] != null ||
          _selectedHotels[leg.order] != null;
      if (!hasSelection) skipped.add(leg.order);
    }
    return skipped;
  }

  // ─── Reset ────────────────────────────────────────────────────────

  void reset() {
    _forkGuide = null;
    _currentStep = 0;
    _startDate = null;
    _isLoading = false;
    _error = null;
    _selectedFlights.clear();
    _selectedTransport.clear();
    _selectedHotels.clear();
    _flightResults.clear();
    _transportResults.clear();
    _hotelResults.clear();
    _primaryPickAvailability.clear();
    _loadingFlights.clear();
    _loadingTransport.clear();
    _loadingHotels.clear();
    notifyListeners();
  }
}
