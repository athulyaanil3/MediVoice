import 'package:flutter/material.dart';
import '../services/adherence_service.dart';

class AdherenceScreen
    extends StatelessWidget {

  const AdherenceScreen({
    super.key,
  });

  @override
  Widget build(
      BuildContext context) {

    final percent =
    AdherenceService
        .adherencePercent();

    final taken =
    AdherenceService
        .takenCount();

    final skipped =
    AdherenceService
        .skippedCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medicine Adherence',
        ),
      ),
      body: Padding(
        padding:
        const EdgeInsets.all(
          16,
        ),
        child: Column(
          children: [

            Text(
              '${percent.toStringAsFixed(1)}%',
              style:
              const TextStyle(
                fontSize: 36,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            LinearProgressIndicator(
              value: percent / 100,
            ),

            const SizedBox(
              height: 20,
            ),

            ListTile(
              title:
              const Text(
                'Taken',
              ),
              trailing:
              Text(
                '$taken',
              ),
            ),

            ListTile(
              title:
              const Text(
                'Skipped',
              ),
              trailing:
              Text(
                '$skipped',
              ),
            ),
          ],
        ),
      ),
    );
  }
}