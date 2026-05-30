import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../providers/calendar_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedDay.year, _focusedDay.month);
  }

  void _loadMonth(int year, int month) {
    ref.read(calendarProvider.notifier).load(year, month);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = ref.watch(calendarProvider);
    final cs = Theme.of(context).colorScheme;

    final sessionDays = <DateTime>[];
    for (final ssn in state.sessions) {
      final d = DateTime(ssn.sessionDate.year, ssn.sessionDate.month, ssn.sessionDate.day);
      if (!sessionDays.contains(d)) sessionDays.add(d);
    }

    return Column(
      children: [
        Text(s.calendar, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              calendarFormat: _format,
              headerStyle: HeaderStyle(formatButtonVisible: false, titleTextStyle: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                todayTextStyle: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
              ),
              onFormatChanged: (f) => setState(() => _format = f),
              onPageChanged: (d) {
                _focusedDay = d;
                _loadMonth(d.year, d.month);
              },
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              eventLoader: (d) => sessionDays.contains(d) ? [1] : [],
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 1,
                      child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary)),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedDay == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, size: 48, color: cs.outlineVariant),
                          const SizedBox(height: 12),
                          Text(Directionality.of(context) == TextDirection.rtl ? 'الرجاء اختيار يوم لعرض الجلسات' : 'Please select a day to view sessions',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : Builder(
                      builder: (_) {
                        final daySessions = state.sessions.where((s) {
                          return s.sessionDate.year == _selectedDay!.year &&
                              s.sessionDate.month == _selectedDay!.month &&
                              s.sessionDate.day == _selectedDay!.day;
                        }).toList();
                        if (daySessions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_busy, size: 48, color: cs.outlineVariant),
                                const SizedBox(height: 12),
                                Text(s.noSessions, style: TextStyle(color: cs.onSurfaceVariant)),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: daySessions.length,
                          itemBuilder: (_, i) {
                            final ssn = daySessions[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: cs.primaryContainer,
                                  child: Icon(Icons.event, color: cs.onPrimaryContainer, size: 20),
                                ),
                                title: Text(
                                  '${ssn.sessionDate.hour.toString().padLeft(2, '0')}:${ssn.sessionDate.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text('${s.result}: ${ssn.result ?? '-'}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
