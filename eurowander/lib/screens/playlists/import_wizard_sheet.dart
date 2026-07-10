import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../services/api_service.dart';

class ImportWizardSheet extends StatefulWidget {
  final Playlist playlist;

  const ImportWizardSheet({super.key, required this.playlist});

  @override
  State<ImportWizardSheet> createState() => _ImportWizardSheetState();
}

class _ImportWizardSheetState extends State<ImportWizardSheet> {
  final ApiService _apiService = ApiService();
  int _step = 0; // 0: pick trip, 1: pick date, 2: preview, 3: success
  List<SavedTrip> _trips = [];
  bool _isLoading = true;
  SavedTrip? _selectedTrip;
  DateTime? _startDate;
  int _importedCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final trips = await _apiService.getTrips(token: token);
      if (mounted) setState(() { _trips = trips; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _doImport() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || _selectedTrip == null || _startDate == null) return;
    setState(() => _isLoading = true);
    try {
      final count = await context.read<PlaylistProvider>().importToTrip(
        token: token,
        playlistId: widget.playlist.id,
        tripId: _selectedTrip!.id,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
      );
      if (mounted) {
        setState(() { _importedCount = count; _step = 3; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text(
            _step == 3 ? '🎉 Import Complete!' : 'Import to Trip',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),
            const SizedBox(height: 12),
          ],
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          else
            _buildStep(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildPickTrip();
      case 1: return _buildPickDate();
      case 2: return _buildPreview();
      case 3: return _buildSuccess();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildPickTrip() {
    if (_trips.isEmpty) {
      return const Text('No trips found. Create a trip first.', style: TextStyle(color: AppTheme.textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select a trip:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        ...(_trips.map((trip) {
          String subtitle = trip.name;
          if (trip.outboundFlight != null && trip.outboundFlight!.legs.isNotEmpty) {
            final dep = trip.outboundFlight!.legs.first.departureTime;
            subtitle = dep.isNotEmpty ? dep.split('T').first : trip.name;
          }
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flight_takeoff_rounded, color: AppTheme.primaryColor),
            title: Text(trip.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() { _selectedTrip = trip; _step = 1; });
              // Default start date from flight departure
              try {
                if (trip.outboundFlight != null && trip.outboundFlight!.legs.isNotEmpty) {
                  final dep = trip.outboundFlight!.legs.first.departureTime;
                  _startDate = DateTime.parse(dep.replaceAll(' ', 'T'));
                } else {
                  _startDate = DateTime.now();
                }
              } catch (_) {
                _startDate = DateTime.now();
              }
            },
          );
        })),
      ],
    );
  }

  Widget _buildPickDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pick start date:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        if (_startDate != null)
          Text(
            'Starting: ${DateFormat('EEEE, MMM d, yyyy').format(_startDate!)}',
            style: const TextStyle(fontSize: 14),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Change Date'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 2),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildOverflowWarning(),
      ],
    );
  }

  Widget _buildOverflowWarning() {
    if (_selectedTrip == null || _startDate == null) return const SizedBox.shrink();
    // Try to determine trip end from return flight
    try {
      DateTime? tripEnd;
      if (_selectedTrip!.returnFlight != null && _selectedTrip!.returnFlight!.legs.isNotEmpty) {
        final arr = _selectedTrip!.returnFlight!.legs.last.arrivalTime;
        tripEnd = DateTime.parse(arr.replaceAll(' ', 'T'));
      }
      if (tripEnd != null) {
        final remainingDays = tripEnd.difference(_startDate!).inDays + 1;
        if (widget.playlist.totalDays > remainingDays) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This playlist has ${widget.playlist.totalDays} days but your trip only has $remainingDays days remaining. Extra items will be saved as unscheduled.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (_) {}
    return const SizedBox.shrink();
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preview:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('Trip: ${_selectedTrip?.name}', style: const TextStyle(fontSize: 13)),
        Text('Start: ${DateFormat('MMM d, yyyy').format(_startDate!)}', style: const TextStyle(fontSize: 13)),
        Text('Playlist: ${widget.playlist.title} (${widget.playlist.totalDays} days, ${widget.playlist.items.length} items)',
            style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        _buildOverflowWarning(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _doImport,
                child: const Text('Import'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 56),
        const SizedBox(height: 12),
        Text('Imported $_importedCount items!', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
