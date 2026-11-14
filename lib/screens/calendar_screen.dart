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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEvents();
  }

  void _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getCalendarEvents();
      setState(() {
        _events = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    return _events.where((e) {
      if (e.startDate == dayStr) return true;
      if (e.endDate != null && e.parsedStartDate != null && e.parsedEndDate != null) {
        return day.isAfter(e.parsedStartDate!.subtract(const Duration(days: 1))) &&
               day.isBefore(e.parsedEndDate!.add(const Duration(days: 1)));
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: AppConstants.surfaceLight,
      appBar: AppBar(
        title: const Text('Kalender Akademik UMRAH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar Card
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: TableCalendar<CalendarEvent>(
                    firstDay: DateTime.utc(2025, 1, 1),
                    lastDay: DateTime.utc(2027, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      leftChevronIcon: const Icon(Icons.chevron_left, color: AppConstants.primaryBlue),
                      rightChevronIcon: const Icon(Icons.chevron_right, color: AppConstants.primaryBlue),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppConstants.primaryBlue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(color: AppConstants.primaryBlue, fontWeight: FontWeight.bold),
                      selectedDecoration: const BoxDecoration(
                        color: AppConstants.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppConstants.accentGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                ),

                // Selected Day Events List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.event_note_rounded, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text(
                        _selectedDay != null
                            ? 'Jadwal: ${DateFormat('d MMMM yyyy').format(_selectedDay!)}'
                            : 'Pilih Tanggal',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: selectedEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy_outlined, size: 36, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              const Text('Tidak ada jadwal kegiatan pada tanggal ini.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: selectedEvents.length,
                          itemBuilder: (ctx, idx) {
                            final ev = selectedEvents[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryBlue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ev.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 3),
                                        Text(
                                          ev.description ?? 'Jadwal resmi kalender akademik UMRAH',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppConstants.primaryBlue.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            ev.category.toUpperCase(),
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppConstants.primaryBlue),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.notifications_active_outlined, size: 20, color: AppConstants.accentGold),
                                    tooltip: 'Ingatkan Saya',
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Pengingat diatur untuk ${ev.title}! 🔔'), duration: const Duration(seconds: 2)),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
