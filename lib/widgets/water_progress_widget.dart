import 'package:flutter/material.dart';

class WaterProgressWidget extends StatelessWidget {

  final double intake;
  final double goal;

  const WaterProgressWidget({
    super.key,
    required this.intake,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {

    double progress = intake / goal;

    if (progress > 1) {
      progress = 1;
    }

    final percent =
    (progress * 100).toInt();

    String status = 'Poor';

    String emoji = '🥵';

    if (percent > 35) {

      status = 'Good';
      emoji = '🙂';
    }

    if (percent > 80) {

      status = 'Great';
      emoji = '🎉';
    }

    return Column(

      children: [

        Container(

          padding:
          const EdgeInsets.all(20),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius:
            BorderRadius.circular(28),

            boxShadow: [

              BoxShadow(
                color:
                Colors.black.withOpacity(
                    0.05),

                blurRadius: 20,
                offset:
                const Offset(0, 10),
              ),
            ],
          ),

          child: Column(

            children: [

              Align(

                alignment:
                Alignment.centerLeft,

                child: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Your hydration progress',

                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Your goal is ${goal.toStringAsFixed(1)} liters per day',

                      style: TextStyle(
                        color:
                        Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              AnimatedContainer(

                duration:
                const Duration(
                    milliseconds: 600),

                height: 90,
                width: 90,

                decoration: BoxDecoration(

                  color:
                  Colors.green.shade100,

                  shape: BoxShape.circle,
                ),

                child: Center(

                  child: Text(
                    emoji,

                    style:
                    const TextStyle(
                      fontSize: 40,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Stack(

                alignment:
                Alignment.center,

                children: [

                  Container(

                    height: 28,

                    decoration:
                    BoxDecoration(

                      borderRadius:
                      BorderRadius.circular(
                          40),

                      color:
                      Colors.grey.shade200,
                    ),
                  ),

                  AnimatedContainer(

                    duration:
                    const Duration(
                        milliseconds: 700),

                    height: 28,

                    width:
                    MediaQuery.of(context)
                        .size
                        .width *
                        progress *
                        0.65,

                    decoration:
                    BoxDecoration(

                      gradient:
                      const LinearGradient(

                        colors: [

                          Color(0xFF0066FF),
                          Color(0xFF4DA6FF),
                        ],
                      ),

                      borderRadius:
                      BorderRadius.circular(
                          40),
                    ),
                  ),

                  Text(
                    '$percent%',

                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(

                mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

                children: const [

                  Text('Poor'),

                  Text('Good'),

                  Text('Great'),
                ],
              ),

              const SizedBox(height: 26),

              Text(
                '${intake.toStringAsFixed(1)}L / ${goal.toStringAsFixed(1)}L',

                style: const TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                status,

                style: TextStyle(
                  color:
                  percent > 80
                      ? Colors.green
                      : Colors.orange,

                  fontWeight:
                  FontWeight.bold,

                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}