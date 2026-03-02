import 'package:flutter/material.dart';
import '/services/gemini_service.dart';
import 'schedule_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> tasks = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final TextEditingController taskController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  String? priority;
  bool isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    taskController.dispose();
    durationController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _addTask() {
    if (taskController.text.isNotEmpty &&
        durationController.text.isNotEmpty &&
        priority != null) {
      final newTask = {
        "name": taskController.text,
        "priority": priority!,
        "duration": int.tryParse(durationController.text) ?? 30,
      };
      setState(() {
        tasks.add(newTask);
      });
      _listKey.currentState?.insertItem(tasks.length - 1,
          duration: const Duration(milliseconds: 400));
      taskController.clear();
      durationController.clear();
      setState(() => priority = null);
    }
  }

  void _removeTask(int index) {
    final removed = tasks[index];
    setState(() {
      tasks.removeAt(index);
    });
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildTaskItem(removed, animation),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              _getColor(task['priority']).withOpacity(0.7),
              const Color(0xFF0B1229),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _getColor(task['priority']).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.black26,
            child: Text(
              task['name'][0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            task['name'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "${task['duration']} min • ${task['priority']}",
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _removeTask(tasks.indexOf(task)),
          ),
        ),
      ),
    );
  }

  void _generateSchedule() async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠ Tambahkan tugas dulu!"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      String schedule = await GeminiService.generateSchedule(tasks);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScheduleResultScreen(scheduleResult: schedule),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Stack(
        children: [
          // Starfield Background
          CustomPaint(
            painter: StarfieldPainter(_pulseController),
            child: Container(),
            size: Size.infinite,
          ),

          // Main Content
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                /// ===== HEADER =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFF2563EB),
                        Color(0xFF06B6D4),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "AI SCHEDULER",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Futuristic Smart Planning System",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// ===== CONTROL PANEL =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      /// INPUT PANEL
                      Expanded(
                        flex: 4,
                        child: _panel(
                          title: "TASK INPUT",
                          icon: Icons.edit_note,
                          child: Column(
                            children: [
                              _input(taskController, "Task Name", Icons.task),
                              const SizedBox(height: 10),
                              _input(
                                durationController,
                                "Duration (Minutes)",
                                Icons.timer,
                                keyboard: TextInputType.number,
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: priority,
                                dropdownColor: const Color(0xFF0B1229),
                                decoration: _inputDecoration(
                                    "Priority", Icons.flag),
                                items: ["Tinggi", "Sedang", "Rendah"]
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e,
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => priority = val),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: _addTask,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22C55E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                  // Glow effect on button
                                    elevation: 8,
                                    shadowColor:
                                        const Color(0xFF22C55E).withOpacity(0.5),
                                  ),
                                  child: const Text(
                                    "ADD TASK",
                                    style: TextStyle(letterSpacing: 1),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// STATS PANEL
                      Expanded(
                        flex: 2,
                        child: _panel(
                          title: "STATUS",
                          icon: Icons.analytics,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.list_alt,
                                size: 42,
                                color: Colors.cyanAccent,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "TOTAL TASKS",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: Text(
                                  "${tasks.length}",
                                  key: ValueKey(tasks.length),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                /// ===== TASK LIST PANEL =====
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.08)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.01),
                        ],
                      ),
                    ),
                    child: tasks.isEmpty
                        ? const Center(
                            child: Text(
                              "NO TASK AVAILABLE",
                              style: TextStyle(
                                  color: Colors.white54, letterSpacing: 1),
                            ),
                          )
                        : AnimatedList(
                            key: _listKey,
                            initialItemCount: tasks.length,
                            itemBuilder: (context, index, animation) {
                              return _buildTaskItem(tasks[index], animation);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      /// ===== AI GENERATE BAR =====
      floatingActionButton: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: size.width * 0.92,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent
                      .withOpacity(0.3 + _pulseController.value * 0.3),
                  blurRadius: 18 + _pulseController.value * 10,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: isLoading ? null : _generateSchedule,
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.auto_awesome),
              label: Text(
                isLoading ? "PROCESSING AI..." : "GENERATE AI SCHEDULE",
                style: const TextStyle(letterSpacing: 1),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// ===== UI COMPONENTS =====

  Widget _panel({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.015),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child
        ],
      ),
    );
  }

  Widget _input(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.white60),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
      ),
    );
  }
}

/// ===== PRIORITY COLOR =====
Color _getColor(String priority) {
  if (priority == "Tinggi") return const Color(0xFFEF4444);
  if (priority == "Sedang") return const Color(0xFFF59E0B);
  return const Color(0xFF22C55E);
}

/// ===== CUSTOM PAINTER UNTUK BACKGROUND BINTANG =====
class StarfieldPainter extends CustomPainter {
  final Animation<double> animation;
  StarfieldPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5);
    final random = DateTime.now().millisecond.toDouble();

    for (int i = 0; i < 100; i++) {
      double x = (i * 37) % size.width;
      double y = (i * 73 + random * animation.value * 20) % size.height;
      double radius = (i % 4) * 0.5 + 0.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}