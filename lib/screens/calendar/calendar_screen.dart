import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../providers/calendar_provider.dart';
import '../../theme/app_theme.dart';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.calendar, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),

        // Styled Table Calendar Wrapper
        GlassCard(
          padding: const EdgeInsets.all(8),
          child: TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            calendarFormat: _format,
            locale: Localizations.localeOf(context).languageCode,
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
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
              todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              defaultTextStyle: const TextStyle(color: AppColors.onSurface),
              weekendTextStyle: const TextStyle(color: AppColors.onSurfaceDim),
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primary),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedDay == null
                  ? Center(
                      child: Text(
                        Directionality.of(context) == TextDirection.rtl
                            ? 'الرجاء اختيار يوم لعرض الجلسات'
                            : 'Please select a day to view sessions',
                        style: const TextStyle(color: AppColors.onSurfaceDim),
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
                            child: Text(s.noSessions, style: const TextStyle(color: AppColors.onSurfaceDim)),
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: daySessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final ssn = daySessions[i];
                            return GlassCard(
                              accentColor: AppColors.primary,
                              child: Row(
                                children: [
                                  const Icon(Icons.event, color: AppColors.primary),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ssn.sessionDate.toString().split('.')[0],
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${s.result}: ${ssn.result ?? '-'}',
                                          style: const TextStyle(color: AppColors.onSurfaceDim),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
