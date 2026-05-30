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

    final sessionDays = <DateTime>[];
    for (final ssn in state.sessions) {
      final d = DateTime(ssn.sessionDate.year, ssn.sessionDate.month, ssn.sessionDate.day);
      if (!sessionDays.contains(d)) sessionDays.add(d);
    }

    return Column(
      children: [
        Text(s.calendar, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: _focusedDay,
          selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
          calendarFormat: _format,
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
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                  ),
                );
              }
              return null;
            },
          ),
        ),
        const Divider(),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedDay == null
                  ? Center(child: Text(s.selectFile))
                  : Builder(
                      builder: (_) {
                        final daySessions = state.sessions.where((s) {
                          return s.sessionDate.year == _selectedDay!.year &&
                              s.sessionDate.month == _selectedDay!.month &&
                              s.sessionDate.day == _selectedDay!.day;
                        }).toList();
                        if (daySessions.isEmpty) {
                          return Center(child: Text(s.noSessions));
                        }
                        return ListView.builder(
                          itemCount: daySessions.length,
                          itemBuilder: (_, i) {
                            final ssn = daySessions[i];
                            return ListTile(
                              leading: const Icon(Icons.event),
                              title: Text(ssn.sessionDate.toString().split('.')[0]),
                              subtitle: Text('${s.result}: ${ssn.result ?? '-'}'),
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
