import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lawyer_app_flutter/i18n/messages.dart';
import '../../providers/calendar_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loader.dart';

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Court Schedule', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
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
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
                todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                weekendTextStyle: const TextStyle(color: AppColors.onSurfaceDim),
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primary),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
              ),
            ),
          ),
        ),
        
        Expanded(
          child: state.isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (_, __) => const ShimmerLoader(width: double.infinity, height: 80, borderRadius: 16),
                )
              : _selectedDay == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_outlined, size: 48, color: AppColors.border),
                          const SizedBox(height: 16),
                          Text(
                            Directionality.of(context) == TextDirection.rtl
                                ? 'الرجاء اختيار يوم لعرض الجلسات'
                                : 'Select a date to inspect sessions',
                            style: const TextStyle(color: AppColors.onSurfaceDim),
                          ),
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
                            child: Text(s.noSessions, style: const TextStyle(color: AppColors.onSurfaceDim)),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: daySessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final ssn = daySessions[i];
                            return GlassCard(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                leading: const Icon(Icons.gavel_outlined, color: AppColors.primary),
                                title: Text(ssn.sessionDate.toString().split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${s.result}: ${ssn.result ?? '-'}'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.border),
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
