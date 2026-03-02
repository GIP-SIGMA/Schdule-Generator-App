import 'package:flutter/material.dart';
import '/services/gemini_service.dart';
import 'schedule_result_screen.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> allTasks = []; // Menyimpan semua task dengan ID unik
  List<Map<String, dynamic>> filteredTasks = [];

  final TextEditingController taskController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  String? priority;
  bool isLoading = false;

  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseController;

  final List<String> _priorities = ['Semua', 'Tinggi', 'Sedang', 'Rendah'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_filterTasks);

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  void _filterTasks() {
    setState(() {
      String selected = _priorities[_tabController.index];
      if (selected == 'Semua') {
        filteredTasks = List.from(allTasks);
      } else {
        filteredTasks = allTasks.where((t) => t['priority'] == selected).toList();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    taskController.dispose();
    durationController.dispose();
    super.dispose();
  }

  void _addTask() {
    if (taskController.text.isNotEmpty &&
        durationController.text.isNotEmpty &&
        priority != null) {
      final newTask = {
        'id': DateTime.now().millisecondsSinceEpoch + allTasks.length, // ID unik
        'name': taskController.text,
        'priority': priority!,
        'duration': int.tryParse(durationController.text) ?? 30,
      };
      setState(() {
        allTasks.add(newTask);
        _filterTasks(); // Perbarui filtered tasks
      });
      taskController.clear();
      durationController.clear();
      setState(() => priority = null);
    }
  }

  void _removeTask(Map<String, dynamic> task) {
    setState(() {
      allTasks.removeWhere((t) => t['id'] == task['id']);
      _filterTasks();
    });
  }

  void _generateSchedule() async {
    if (allTasks.isEmpty) {
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
      String schedule = await GeminiService.generateSchedule(allTasks);
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
          // Background bintang
          CustomPaint(
            painter: StarfieldPainter(_pulseController),
            child: Container(),
            size: Size.infinite,
          ),

          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                /// ===== HEADER =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF06B6D4)],
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
                      Text("AI SCHEDULER",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: Colors.white)),
                      SizedBox(height: 6),
                      Text("Futuristic Smart Planning System",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5)),
                    ],
                  ),
                ),

                /// ===== TAB BAR (NAVIGASI) =====
Container(
  margin: const EdgeInsets.only(top: 16, left: 18, right: 18),
  height: 48,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withOpacity(0.3), // indikator liquid glass
          ),
          indicatorSize: TabBarIndicatorSize.tab, // selebar tab
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Tinggi'),
            Tab(text: 'Sedang'),
            Tab(text: 'Rendah'),
          ],
        ),
      ),
    ),
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
                              _input(durationController, "Duration (Minutes)",
                                  Icons.timer, keyboard: TextInputType.number),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: priority,
                                dropdownColor: const Color(0xFF0B1229),
                                decoration:
                                    _inputDecoration("Priority", Icons.flag),
                                items: ["Tinggi", "Sedang", "Rendah"]
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e,
                                              style: const TextStyle(
                                                  color: Colors.white)),
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
                                        borderRadius: BorderRadius.circular(10)),
                                    elevation: 8,
                                    shadowColor:
                                        const Color(0xFF22C55E).withOpacity(0.5),
                                  ),
                                  child: const Text("ADD TASK",
                                      style: TextStyle(letterSpacing: 1)),
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
                              const Icon(Icons.list_alt,
                                  size: 42, color: Colors.cyanAccent),
                              const SizedBox(height: 10),
                              const Text("TOTAL TASKS",
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                      letterSpacing: 1)),
                              const SizedBox(height: 6),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                      scale: animation, child: child);
                                },
                                child: Text(
                                  "${filteredTasks.length} / ${allTasks.length}",
                                  key: ValueKey('${filteredTasks.length}-${allTasks.length}'),
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
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

                /// ===== TASK LIST =====
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.01),
                        ],
                      ),
                    ),
                    child: filteredTasks.isEmpty
                        ? Center(
                            child: Text(
                              allTasks.isEmpty
                                  ? "NO TASK AVAILABLE"
                                  : "NO TASK IN THIS CATEGORY",
                              style: const TextStyle(
                                  color: Colors.white54, letterSpacing: 1),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 120),
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = filteredTasks[index];
                              return Dismissible(
                                key: Key(task['id'].toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
                                    ),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (direction) {
                                  _removeTask(task);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
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
                                        color: _getColor(task['priority'])
                                            .withOpacity(0.2),
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
                                        style:
                                            const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(task['name'],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        "${task['duration']} min • ${task['priority']}",
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      /// ===== AI GENERATE BAR (FAB) =====
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

  /// ===== UI KOMPONEN =====

  Widget _panel(
      {required String title, required IconData icon, required Widget child}) {
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
              Text(title,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11, letterSpacing: 1)),
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

/// ===== BACKGROUND BINTANG =====
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