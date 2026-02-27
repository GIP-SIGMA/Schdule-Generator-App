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
  final TextEditingController taskController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  String? priority;
  bool isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    taskController.dispose();
    durationController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _addTask() {
    if (taskController.text.isNotEmpty &&
        durationController.text.isNotEmpty &&
        priority != null) {
      setState(() {
        tasks.add({
          "name": taskController.text,
          "priority": priority!,
          "duration": int.tryParse(durationController.text) ?? 30,
        });
      });
      taskController.clear();
      durationController.clear();
      setState(() => priority = null);
    }
  }

  void _generateSchedule() async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Tambahkan tugas dulu!")),
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
          builder: (context) =>
              ScheduleResultScreen(scheduleResult: schedule),
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

      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [

            /// ===== HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF2563EB),
                    Color(0xFF06B6D4),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
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
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 0.5)),
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
                            child: Text(
                              "${tasks.length}",
                              key: ValueKey(tasks.length),
                              style: const TextStyle(
                                  fontSize: 32,
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

            /// ===== TASK LIST PANEL =====
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
                child: tasks.isEmpty
                    ? const Center(
                        child: Text("NO TASK AVAILABLE",
                            style: TextStyle(
                                color: Colors.white54,
                                letterSpacing: 1)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Container(
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
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.black26,
                                child: Text(task['name'][0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white)),
                              ),
                              title: Text(task['name'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  "${task['duration']} min • ${task['priority']}",
                                  style: const TextStyle(
                                      color: Colors.white70)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () =>
                                    setState(() => tasks.removeAt(index)),
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

      /// ===== AI GENERATE BAR =====
      floatingActionButton: Container(
        width: size.width * 0.92,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.45),
              blurRadius: 18,
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
          label: Text(isLoading ? "PROCESSING AI..." : "GENERATE AI SCHEDULE",
              style: const TextStyle(letterSpacing: 1)),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  /// ===== UI COMPONENTS =====

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
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1)),
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
        borderSide: const BorderSide(color: Colors.cyanAccent),
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