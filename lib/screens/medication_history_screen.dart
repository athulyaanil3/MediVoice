import 'package:flutter/material.dart';

import '../services/local_store.dart';
import '../widgets/medi_background.dart';

class MedicationHistoryScreen extends StatefulWidget {
  const MedicationHistoryScreen({
    super.key,
  });

  @override
  State<MedicationHistoryScreen> createState() =>
      _MedicationHistoryScreenState();
}

class _MedicationHistoryScreenState
    extends State<MedicationHistoryScreen> {

  String selectedFilter = 'Today';
  String search = '';

  String dayLabel(DateTime date) {
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }

    final yesterday =
    now.subtract(
      const Duration(days: 1),
    );

    if (date.year ==
        yesterday.year &&
        date.month ==
            yesterday.month &&
        date.day ==
            yesterday.day) {
      return 'Yesterday';
    }

    return
      '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {

    final allLogs =
    LocalStore.readMedicineLogs();

    final now =
    DateTime.now();

    final logs =
    allLogs.where((log) {

      if (search.isNotEmpty &&
          !log.medicineName
              .toLowerCase()
              .contains(
            search.toLowerCase(),
          )) {
        return false;
      }

      switch (selectedFilter) {

        case 'Today':
          return log.time.year ==
              now.year &&
              log.time.month ==
                  now.month &&
              log.time.day ==
                  now.day;

        case 'Yesterday':

          final yesterday =
          now.subtract(
            const Duration(
              days: 1,
            ),
          );

          return log.time.year ==
              yesterday.year &&
              log.time.month ==
                  yesterday.month &&
              log.time.day ==
                  yesterday.day;

        case 'Last 7 Days':
          return now
              .difference(log.time)
              .inDays <=
              7;

        case 'Last 30 Days':
          return now
              .difference(log.time)
              .inDays <=
              30;

        default:
          return true;
      }
    }).toList();

    return MediBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,

          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Medication History',
            ),
          ),
      body: Column(
        children: [

          Padding(
            padding:
            const EdgeInsets.all(12),
            child: TextField(
              decoration:
              InputDecoration(
                hintText:
                'Search medicine',
                prefixIcon:
                const Icon(
                  Icons.search,
                ),
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
            ),
          ),

          SingleChildScrollView(
            scrollDirection:
            Axis.horizontal,
            child: Row(
              children: [

                _filterChip(
                  'Today',
                ),

                _filterChip(
                  'Yesterday',
                ),

                _filterChip(
                  'Last 7 Days',
                ),

                _filterChip(
                  'Last 30 Days',
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Expanded(

            child: logs.isEmpty

                ? const Center(
              child: Text(
                'No records found',
              ),
            )

                : ListView.builder(

              itemCount:
              logs.length,

              itemBuilder:
                  (
                  context,
                  index,
                  ) {

                final reversedLogs =
                logs.reversed
                    .toList();

                final log =
                reversedLogs[index];

                final current =
                dayLabel(
                  log.time,
                );

                String? previous;

                if (index > 0) {

                  previous =
                      dayLabel(
                        reversedLogs[
                        index - 1]
                            .time,
                      );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    if (current != previous)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          current,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        leading: Icon(
                          log.status.name == 'taken'
                              ? Icons.check_circle
                              : log.status.name == 'skipped'
                              ? Icons.cancel
                              : Icons.access_time,
                          color: log.status.name == 'taken'
                              ? Colors.green
                              : log.status.name == 'skipped'
                              ? Colors.red
                              : Colors.orange,
                        ),
                        title: Text(
                          log.medicineName.isEmpty
                              ? 'Medicine'
                              : log.medicineName,
                        ),
                        subtitle: Text(
                          '${log.time.hour}:${log.time.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                );
                  },
            ),
          ),
        ],
      ),
        ),
    );
  }

  Widget _filterChip(
      String label,
      ) {


    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      child: ChoiceChip(
        label: Text(
          label,
        ),
        selected:
        selectedFilter ==
            label,
        onSelected: (_) {
          setState(() {
            selectedFilter =
                label;
          });
        },
      ),
    );
  }
}