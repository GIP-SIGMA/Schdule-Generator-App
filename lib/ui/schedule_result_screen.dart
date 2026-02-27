import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ScheduleResultScreen extends StatelessWidget {
  final String scheduleResult;
  const ScheduleResultScreen({super.key, required this.scheduleResult});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // dark navy base

      /// ===== FUTURISTIC APPBAR =====
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("AI Schedule Result"),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              tooltip: "Salin Jadwal",
              onPressed: () {
                Clipboard.setData(ClipboardData(text: scheduleResult));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("📋 Jadwal berhasil disalin!"),
                    backgroundColor: Color(0xFF22C55E),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [

            /// ===== COLOR HEADER =====
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF06B6D4),
                    Color(0xFF22C55E),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Jadwal ini dibuat otomatis oleh AI berdasarkan prioritas & durasi tugasmu.",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            /// ===== RESULT CONTAINER =====
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Markdown(
                    data: scheduleResult,
                    selectable: true,
                    padding: const EdgeInsets.all(20),

                    /// ===== MARKDOWN STYLE =====
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Colors.white70,
                      ),
                      h1: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                      h2: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF06B6D4),
                      ),
                      h3: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF22C55E),
                      ),
                      strong: const TextStyle(color: Colors.white),
                      em: const TextStyle(color: Colors.white70),

                      /// TABLE STYLE
                      tableBorder: TableBorder.all(
                        color: Colors.white24,
                        width: 1,
                      ),
                      tableHeadAlign: TextAlign.center,
                      tablePadding: const EdgeInsets.all(10),
                      tableCellsPadding:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ===== ACTION BUTTONS =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  /// BACK BUTTON
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.refresh),
                        label: const Text("Buat Ulang"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  /// COPY BUTTON
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: scheduleResult));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("📋 Jadwal berhasil disalin!"),
                              backgroundColor: Color(0xFF22C55E),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text("Salin Jadwal"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}