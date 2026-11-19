import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/calendar_event.dart';
import '../services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEvent> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getCalendarEvents();
      if (!mounted) return;
      setState(() {
        _events = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat kalender. Silakan coba lagi.';
      });
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final date = DateTime.utc(day.year, day.month, day.day);
    return _events.where((e) {
      if (!e.isApproved) return false;
      final start = e.parsedStartDate;
      final end = e.parsedEndDate ?? start;
      if (start == null || end == null) return false;
      final first = DateTime.utc(start.year, start.month, start.day);
      final last = DateTime.utc(end.year, end.month, end.day);
      return !date.isBefore(first) && !date.isAfter(last);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : <CalendarEvent>[];
    final currentYear = DateTime.now().year;
    final firstYear = currentYear < 2020 ? currentYear : 2020;
    final lastYear = currentYear + 5 > 2035 ? currentYear + 5 : 2035;

    return Scaffold(
      backgroundColor: AppConstants.surfaceLight,
      appBar: AppBar(
        title: const Text(
          'Kalender Akademik UMRAH',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _fetchEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _fetchEvents,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Calendar Card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppConstants.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TableCalendar<CalendarEvent>(
                    firstDay: DateTime.utc(firstYear, 1, 1),
                    lastDay: DateTime.utc(lastYear, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    rowHeight: 42,
                    daysOfWeekHeight: 22,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppConstants.textDark,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left_rounded,
                        color: AppConstants.primaryBlue,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right_rounded,
                        color: AppConstants.primaryBlue,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppConstants.softBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      todayTextStyle: const TextStyle(
                        color: AppConstants.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppConstants.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppConstants.accentGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                ),

                // Selected Day Events Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _selectedDay != null
                              ? 'Jadwal: ${DateFormat('d MMMM yyyy').format(_selectedDay!)}'
                              : 'Pilih Tanggal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Events or Empty State
                if (selectedEvents.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.borderLight),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 34,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tidak ada jadwal kegiatan pada tanggal ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      children: selectedEvents.map((ev) {
                        Color catColor = AppConstants.primaryBlue;
                        final catLower = ev.category.toLowerCase();
                        if (catLower.contains('ujian') ||
                            catLower.contains('evaluasi')) {
                          catColor = AppConstants.errorRed;
                        } else if (catLower.contains('registrasi') ||
                            catLower.contains('krs') ||
                            catLower.contains('lirs')) {
                          catColor = AppConstants.successGreen;
                        } else if (catLower.contains('libur') ||
                            catLower.contains('wisuda')) {
                          catColor = AppConstants.accentGold;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppConstants.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: catColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ev.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppConstants.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      ev.description ??
                                          'Jadwal resmi kalender akademik UMRAH',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppConstants.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        ev.category.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: catColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_active_outlined,
                                  size: 19,
                                  color: AppConstants.textMuted,
                                ),
                                tooltip: 'Pengingat belum tersedia',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Fitur pengingat kalender belum tersedia.',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
    );
  }
}
