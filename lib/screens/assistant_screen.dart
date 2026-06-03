import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import '../services/assistant_service.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';
import '../widgets/medi_background.dart';
import '../widgets/ui_kit.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _Msg {
  _Msg({
    required this.user,
    required this.text,
  });

  final bool user;
  final String text;
}

class _AssistantScreenState extends State<AssistantScreen> {

  final _ctrl = TextEditingController();

  final _scroll = ScrollController();

  final _coach = AssistantService();

  bool _busy = false;

  // ALLOWED HEALTH TOPICS

  final List<String> allowedTopics = [

    // MEDICINE
    'today',
    'summary',
    'score',
    'weekly',
    'report',
    'coach',
    'missed',
    'medicine',
    'tablet',
    'pill',
    'doctor',
    'medication',
    'dose',
    'fever',
    'cold',
    'headache',
    'pain',
    'reminder',

    // FOOD
    'food',
    'nutrition',
    'protein',
    'calories',
    'diet',
    'water',
    'meal',
    'eat',
    'drink',
    'sugar',

    // EXERCISE
    'exercise',
    'workout',
    'fitness',
    'gym',
    'walk',
    'running',
    'breathing',
    'yoga',
    'meditation',

    // HEALTH
    'health',
    'sleep',
    'stress',
    'wellness',
  ];

  final _msgs = <_Msg>[
    _Msg(
      user: false,
      text:
      'Hi! I\'m MediCoach — ask about medicines, food, nutrition, exercise, breathing, or wellness.',
    ),
  ];

  // CHECK IF MESSAGE IS HEALTH RELATED

  bool isHealthQuestion(String message) {

    final text = message.toLowerCase();

    for (String topic in allowedTopics) {

      if (text.contains(topic)) {
        return true;
      }
    }

    return false;
  }

  @override
  void dispose() {

    _ctrl.dispose();

    _scroll.dispose();

    super.dispose();
  }

  // SEND MESSAGE FUNCTION

  Future<void> _send(String text) async {

    final t = text.trim();

    if (t.isEmpty || _busy) return;

    setState(() {

      _msgs.add(
        _Msg(
          user: true,
          text: t,
        ),
      );

      _busy = true;
    });

    _ctrl.clear();

    String reply;

    // VALIDATE QUESTION

    bool validQuestion = isHealthQuestion(t);

    if (validQuestion) {

      // AI RESPONSE

      reply = await _coach.reply(t);

    } else {

      // BLOCK NON HEALTH QUESTIONS

      reply =
      "I can only assist with medicine, nutrition, exercise, breathing, and wellness related topics.";
    }

    if (!mounted) return;

    setState(() {

      _msgs.add(
        _Msg(
          user: false,
          text: reply,
        ),
      );

      _busy = false;
    });

    // SPEAK RESPONSE

    context.read<VoiceService>().speak(reply);

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (_scroll.hasClients) {

        _scroll.jumpTo(
          _scroll.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    final voice = context.watch<VoiceService>();

    return MediBackground(
      child: Column(
        children: [

          const PageHeader(
            title: 'MediCoach',
            subtitle:
            'Wellness assistant — voice enabled, app topics only.',
          ),

          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [

                  // CHAT AREA

                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                      _msgs.length + (_busy ? 1 : 0),

                      itemBuilder: (_, i) {

                        if (_busy && i == _msgs.length) {

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),

                            child: Row(
                              children: [

                                SizedBox.square(
                                  dimension: 28,

                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppTheme.deepTeal
                                        .withValues(alpha: 0.7),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                const Text(
                                  'Thinking…',
                                  style: TextStyle(
                                    color:
                                    AppTheme.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final m = _msgs[i];

                        return Align(
                          alignment: m.user
                              ? Alignment.centerRight
                              : Alignment.centerLeft,

                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                            ),

                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),

                            constraints: BoxConstraints(
                              maxWidth:
                              MediaQuery.sizeOf(context)
                                  .width *
                                  0.78,
                            ),

                            decoration: BoxDecoration(

                              gradient: m.user
                                  ? AppTheme.heroGradient
                                  : LinearGradient(
                                colors: [

                                  AppTheme.mintGlow
                                      .withValues(
                                    alpha: 0.9,
                                  ),

                                  AppTheme.surfaceLight,
                                ],
                              ),

                              borderRadius:
                              BorderRadius.only(

                                topLeft:
                                const Radius.circular(20),

                                topRight:
                                const Radius.circular(20),

                                bottomLeft:
                                Radius.circular(
                                  m.user ? 20 : 4,
                                ),

                                bottomRight:
                                Radius.circular(
                                  m.user ? 4 : 20,
                                ),
                              ),

                              boxShadow: [

                                BoxShadow(
                                  color: AppTheme.deepTeal
                                      .withValues(
                                    alpha: 0.06,
                                  ),

                                  blurRadius: 8,

                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),

                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [

                                Text(
                                  m.text,

                                  style: TextStyle(
                                    color: m.user
                                        ? Colors.white
                                        : AppTheme.ink,

                                    height: 1.4,

                                    fontSize: 15,
                                  ),
                                ),

                                // SPEAKER BUTTON

                                if (!m.user)

                                  Align(
                                    alignment:
                                    Alignment.centerLeft,

                                    child: IconButton(

                                      visualDensity:
                                      VisualDensity.compact,

                                      icon: const Icon(
                                        Icons.volume_up_rounded,
                                        size: 20,
                                        color:
                                        AppTheme.deepTeal,
                                      ),

                                      onPressed: () {

                                        context
                                            .read<VoiceService>()
                                            .speak(m.text);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // INPUT AREA

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [

                          ActionChip(
                            label: const Text('📊 Summary'),
                            onPressed: () =>
                                _send('Today Summary'),
                          ),

                          const SizedBox(width: 8),

                          ActionChip(
                            label: const Text('❤️ Score'),
                            onPressed: () =>
                                _send('Health Score'),
                          ),

                          const SizedBox(width: 8),

                          ActionChip(
                            label: const Text('📈 Weekly'),
                            onPressed: () =>
                                _send('Weekly Report'),
                          ),

                          const SizedBox(width: 8),

                          ActionChip(
                            label: const Text('💧 Water'),
                            onPressed: () =>
                                _send('Water Coach'),
                          ),

                          const SizedBox(width: 8),

                          ActionChip(
                            label: const Text('🍎 Calories'),
                            onPressed: () =>
                                _send('Calories Today'),
                          ),

                          const SizedBox(width: 8),

                          ActionChip(
                            label: const Text('💊 Missed'),
                            onPressed: () =>
                                _send('Did I miss any medicines?'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      8,
                      12,
                      12,
                    ),

                    decoration: BoxDecoration(

                      color: AppTheme.surfaceLight
                          .withValues(alpha: 0.6),

                      border: Border(
                        top: BorderSide(
                          color: AppTheme.deepTeal
                              .withValues(alpha: 0.08),
                        ),
                      ),
                    ),

                    child: Row(
                      children: [

                        // MIC BUTTON

                        Material(
                          color: voice.listening
                              ? AppTheme.accentCoral
                              .withValues(alpha: 0.15)
                              : AppTheme.mintGlow,

                          borderRadius:
                          BorderRadius.circular(14),

                          child: IconButton(

                            onPressed: voice.sttAvailable
                                ? () {

                              if (voice.listening) {

                                voice.stopListen();

                              } else {

                                voice.startListen(
                                  onFinal: _send,
                                );
                              }
                            }
                                : null,

                            icon: Icon(

                              voice.listening
                                  ? Icons.mic_off_rounded
                                  : Icons.mic_rounded,

                              color: AppTheme.deepTeal,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // TEXTFIELD

                        Expanded(
                          child: TextField(
                            controller: _ctrl,

                            decoration: InputDecoration(

                              hintText: voice.interim.isEmpty
                                  ? 'Ask MediVoice…'
                                  : voice.interim,

                              filled: true,

                              fillColor: Colors.white,

                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(16),
                              ),

                              contentPadding:
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),

                            onSubmitted: _send,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // SEND BUTTON

Material(
color: AppTheme.deepTeal,
borderRadius: BorderRadius.circular(14),
child: IconButton(
onPressed: _busy
? null
: () => _send(_ctrl.text),
icon: const Icon(
Icons.send_rounded,
color: Colors.white,
),
),
),
],
),
),
],
),
),
),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}