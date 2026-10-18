// ignore_for_file: deprecated_member_use
// =============================================================================
// EduTanggap - Aplikasi Pembelajaran Kesiapsiagaan Bencana (Prototipe Desktop)
// Konsep   : offline-first (data disimpan lokal, antrean sinkronisasi simulasi)
// Platform : Flutter Desktop (Windows / macOS / Linux) - responsif
// State    : ValueNotifier + StatefulWidget (tanpa paket tambahan)
// Cara pakai: salin file ini ke lib/main.dart pada proyek Flutter desktop.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EduTanggapApp());
}

// -----------------------------------------------------------------------------
// 1. TEMA & KONSTANTA
// -----------------------------------------------------------------------------
class AppColors {
  static const forest = Color(0xFF1B4D3E); // hijau utama
  static const mint = Color(0xFFE8F5E9); // aksen hijau muda
  static const text = Color(0xFF2D3748); // teks gelap
  static const bg = Color(0xFFF4F8F5); // latar terang
  static const muted = Color(0xFF6B7A72);
  static const border = Color(0xFFD9E4DD);
  static const orange = Color(0xFFE8890C);
  static const orangeBg = Color(0xFFFFF3E0);
}

/// Pintasan pembuat TextStyle.
TextStyle ts(double size,
        {FontWeight w = FontWeight.w400,
        Color color = AppColors.text,
        double? height}) =>
    TextStyle(fontSize: size, fontWeight: w, color: color, height: height);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.forest,
    primary: AppColors.forest,
    surface: Colors.white,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c),
      );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: Color(0xFF9AA7A0), fontSize: 14),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.forest),
      errorBorder: border(const Color(0xFFD64545)),
      focusedErrorBorder: border(const Color(0xFFD64545)),
    ),
  );
}

// -----------------------------------------------------------------------------
// 2. MODEL DATA
// -----------------------------------------------------------------------------
enum Screen {
  welcome,
  login,
  register,
  dashboard,
  materials,
  quizzes,
  sync,
  addMaterial,
  addQuiz,
  goodbye,
}

enum Role { student, teacher }

/// Layar yang tampil di dalam "shell" (sidebar + topbar).
bool isShellScreen(Screen s) => const [
      Screen.dashboard,
      Screen.materials,
      Screen.quizzes,
      Screen.sync,
      Screen.addMaterial,
      Screen.addQuiz,
    ].contains(s);

/// Satu entri antrean sinkronisasi.
class SyncItem {
  final String title;
  final String subtitle;
  final String time;
  final bool done;
  const SyncItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.done,
  });
  SyncItem asDone() =>
      SyncItem(title: title, subtitle: subtitle, time: time, done: true);
}

class LearningModule {
  final String title;
  final String subject;
  final int minutes;
  final int? score;
  final double progress;
  final IconData icon;
  const LearningModule({
    required this.title,
    required this.subject,
    required this.minutes,
    required this.score,
    required this.progress,
    required this.icon,
  });
}

class MaterialItem {
  final String title;
  final String description;
  final String subject;
  final String kelas;
  final String fileName;
  final bool shared;
  const MaterialItem({
    required this.title,
    required this.description,
    required this.subject,
    required this.kelas,
    required this.fileName,
    required this.shared,
  });
}

class QuizQuestion {
  final String text;
  final List<String> options;
  final int correct;
  const QuizQuestion(this.text, this.options, this.correct);
}

class QuizItem {
  final String title;
  final String subject;
  final String duration;
  final String deadline;
  final bool published;
  final List<QuizQuestion> questions;
  const QuizItem({
    required this.title,
    required this.subject,
    required this.duration,
    required this.deadline,
    required this.published,
    required this.questions,
  });
}

// -----------------------------------------------------------------------------
// 3. STATE GLOBAL SEDERHANA (ValueNotifier)
// -----------------------------------------------------------------------------
String two(int n) => n.toString().padLeft(2, '0');

class AppState {
  AppState._();
  static final AppState I = AppState._();

  /// Routing: layar yang sedang aktif.
  final screen = ValueNotifier<Screen>(Screen.welcome);

  /// Peran pengguna (Siswa / Guru) - juga dipakai sebagai pemilih peran prototipe.
  final role = ValueNotifier<Role>(Role.student);

  /// Simulasi koneksi: true = luring (offline).
  final offline = ValueNotifier<bool>(true);

  /// Sedang menyinkronkan?
  final syncing = ValueNotifier<bool>(false);

  final lastSync = ValueNotifier<String>('2 hari lalu, 06:14');
  final userName = ValueNotifier<String>('Ayu Lestari');

  /// Antrean sinkronisasi (terbaru di atas).
  final queue = ValueNotifier<List<SyncItem>>(const [
    SyncItem(
        title: 'Hasil kuis: Siklus Air',
        subtitle: 'Kuis Sains IPA Kelas 6',
        time: 'Hari ini, 10:30',
        done: false),
    SyncItem(
        title: 'Hasil kuis: Pecahan',
        subtitle: 'Latihan Matematika',
        time: 'Kemarin, 14:15',
        done: false),
    SyncItem(
        title: 'Catatan Jurnal Refleksi Mandiri',
        subtitle: 'Aktivitas Belajar Harian',
        time: 'Kemarin, 09:00',
        done: false),
    SyncItem(
        title: 'Materi terunduh',
        subtitle: 'Modul Pembelajaran Interaktif',
        time: '2 hari lalu, 06:14',
        done: true),
    SyncItem(
        title: 'Pembaruan profil',
        subtitle: 'Perubahan Nama & Foto Profil',
        time: '3 hari lalu, 15:30',
        done: true),
  ]);

  /// Materi yang dibuat guru selama sesi ini.
  final materials = ValueNotifier<List<MaterialItem>>(const [
    MaterialItem(
        title: 'Banjir: Kenali Tanda dan Cara Aman',
        description: 'Mengenali tanda banjir dan langkah evakuasi.',
        subject: 'Kesiapsiagaan Bencana',
        kelas: 'Kelas 5A',
        fileName: 'banjir_cara_aman.pdf',
        shared: true),
    MaterialItem(
        title: 'Mengenal Siklus Air',
        description: 'Video penjelasan siklus air (6:20).',
        subject: 'IPA',
        kelas: 'Kelas 5A',
        fileName: 'siklus_air.mp4',
        shared: true),
  ]);

  /// Kuis yang tersedia.
  final quizzes = ValueNotifier<List<QuizItem>>(const [
    QuizItem(
      title: 'Kuis Kesiapsiagaan Gempa',
      subject: 'Kesiapsiagaan Bencana',
      duration: '15 Menit',
      deadline: '25 Oktober 2026 · 23.59 WIB',
      published: true,
      questions: [
        QuizQuestion(
            'Apa yang sebaiknya kamu lakukan saat gempa terjadi di dalam kelas?',
            [
              'Berlari ke arah lift',
              'Berlindung di bawah meja yang kokoh',
              'Berdiri dekat jendela',
              'Berteriak di koridor'
            ],
            1),
        QuizQuestion(
            'Ke mana kita berkumpul setelah gempa berhenti dan keadaan aman?',
            [
              'Titik kumpul',
              'Ruang kelas lantai atas',
              'Gudang sekolah',
              'Perpustakaan'
            ],
            0),
        QuizQuestion('Apa isi yang wajib ada di tas siaga bencana?', [
          'Mainan',
          'Senter, air minum, dan P3K',
          'Buku cerita saja',
          'Kembang api'
        ], 1),
      ],
    ),
  ]);

  /// Daftar modul pembelajaran siswa.
  final List<LearningModule> modules = const [
    LearningModule(
        title: 'Struktur Kalimat',
        subject: 'Bahasa Indonesia',
        minutes: 25,
        score: 88,
        progress: 1.0,
        icon: Icons.menu_book_rounded),
    LearningModule(
        title: 'Banjir: Kenali Tanda dan Cara Aman',
        subject: 'Kesiapsiagaan Bencana',
        minutes: 20,
        score: null,
        progress: 0.4,
        icon: Icons.flood_rounded),
    LearningModule(
        title: 'Mengenal Siklus Air (Video 6:20)',
        subject: 'IPA',
        minutes: 30,
        score: 92,
        progress: 1.0,
        icon: Icons.water_drop_rounded),
    LearningModule(
        title: 'Pecahan',
        subject: 'Matematika',
        minutes: 35,
        score: 76,
        progress: 1.0,
        icon: Icons.calculate_rounded),
    LearningModule(
        title: 'Gempa: Lindungi Dirimu',
        subject: 'Kesiapsiagaan Bencana',
        minutes: 15,
        score: null,
        progress: 0.0,
        icon: Icons.health_and_safety_rounded),
    LearningModule(
        title: 'Peta Wilayah Rawan Bencana',
        subject: 'IPS',
        minutes: 25,
        score: null,
        progress: 0.0,
        icon: Icons.map_rounded),
  ];

  // ---- Aksi -----------------------------------------------------------------
  int get pending => queue.value.where((e) => !e.done).length;

  void go(Screen s) => screen.value = s;

  String _now() {
    final n = DateTime.now();
    return 'Hari ini, ${two(n.hour)}:${two(n.minute)}';
  }

  /// Simpan perubahan secara lokal -> masuk antrean sinkronisasi.
  void enqueue(String title, String subtitle) {
    queue.value = [
      SyncItem(title: title, subtitle: subtitle, time: _now(), done: false),
      ...queue.value,
    ];
  }

  /// Ubah status koneksi (simulasi). Saat online, sinkronisasi otomatis jalan.
  void setOffline(bool v) {
    offline.value = v;
    if (!v) syncNow();
  }

  /// Simulasi pengiriman antrean ke server.
  Future<void> syncNow() async {
    if (offline.value || syncing.value || pending == 0) return;
    syncing.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (offline.value) {
      // Koneksi terputus di tengah jalan -> antrean tetap tersimpan.
      syncing.value = false;
      return;
    }
    queue.value = [for (final e in queue.value) e.asDone()];
    final n = DateTime.now();
    lastSync.value = 'Hari ini, ${two(n.hour)}:${two(n.minute)}';
    syncing.value = false;
  }
}

final app = AppState.I;

// -----------------------------------------------------------------------------
// 4. UTILITAS UI
// -----------------------------------------------------------------------------
void toast(BuildContext c, String msg) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text(msg),
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.forest,
  ));
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final a = parts.first[0];
  final b = parts.length > 1 ? parts[1][0] : '';
  return (a + b).toUpperCase();
}

/// Dialog konfirmasi keluar -> layar penutup.
Future<void> confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Keluar dari EduTanggap?',
          style: ts(20, w: FontWeight.w700)),
      content: Text('Apakah Anda yakin ingin keluar dari EduTanggap?',
          style: ts(15, color: AppColors.muted)),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.forest,
            side: const BorderSide(color: AppColors.border),
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.forest,
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );
  if (ok == true) app.go(Screen.goodbye);
}

/// Dialog pemutar materi (mock) - membuka materi dari penyimpanan lokal.
Future<void> openModule(BuildContext context, LearningModule m) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(m.title, style: ts(18, w: FontWeight.w700)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 170,
              decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(14)),
              child: const Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    size: 64, color: AppColors.forest),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.download_done_rounded,
                    color: AppColors.forest, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Siap dibuka luring. Materi sudah tersimpan di perangkat ini. Progres dikirim saat ada sinyal.',
                      style: ts(13, color: AppColors.forest)),
                ),
              ]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
          onPressed: () {
            app.enqueue('Aktivitas belajar', m.title);
            Navigator.pop(ctx);
            toast(context, 'Progres disimpan di perangkat (menunggu sinkronisasi).');
          },
          child: const Text('Tandai selesai'),
        ),
      ],
    ),
  );
}

// -----------------------------------------------------------------------------
// 5. KOMPONEN UMUM
// -----------------------------------------------------------------------------
class AppCard extends StatelessWidget {
  const AppCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.color});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.light = false, this.size = 36});
  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: light ? Colors.white : AppColors.forest,
              borderRadius: BorderRadius.circular(size * 0.28),
            ),
            child: Text('E',
                style: ts(size * 0.58,
                    w: FontWeight.w800,
                    color: light ? AppColors.forest : Colors.white)),
          ),
          const SizedBox(width: 10),
          Text('EduTanggap',
              style: ts(size * 0.62,
                  w: FontWeight.w600,
                  color: light ? Colors.white : AppColors.forest)),
        ],
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.expand = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final btn = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFBFCFC6),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.expand = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.forest,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.text, {super.key, required this.fg, required this.bg});
  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: ts(12, w: FontWeight.w600, color: fg)),
      );
}

/// Label + TextFormField.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.obscure = false,
    this.keyboard,
    this.maxLines = 1,
    this.maxLength,
    this.suffix,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final bool obscure;
  final TextInputType? keyboard;
  final int maxLines;
  final int? maxLength;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ts(13, w: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            maxLines: maxLines,
            maxLength: maxLength,
            validator: validator,
            decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
          ),
        ],
      );
}

class DropdownField extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    this.validator,
  });
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ts(13, w: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            hint: hint == null ? null : Text(hint!),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            validator: validator,
          ),
        ],
      );
}

/// Pemilih peran Siswa / Guru.
class RoleToggle extends StatelessWidget {
  const RoleToggle({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Role>(
        valueListenable: app.role,
        builder: (_, current, __) => Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            _seg('Siswa', Role.student, current),
            _seg('Guru', Role.teacher, current),
          ]),
        ),
      );

  Widget _seg(String label, Role r, Role current) {
    final sel = r == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => app.role.value = r,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppColors.forest : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label,
              style: ts(14,
                  w: FontWeight.w600,
                  color: sel ? Colors.white : AppColors.forest)),
        ),
      ),
    );
  }
}

/// Ilustrasi hero sederhana (tanpa aset gambar).
class HeroIllustration extends StatelessWidget {
  const HeroIllustration({super.key, this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final icons = <IconData>[
      Icons.menu_book_rounded,
      Icons.health_and_safety_rounded,
      Icons.school_rounded,
      Icons.flood_rounded,
    ];
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF265F4D) : AppColors.mint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final i in icons)
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dark ? const Color(0xFF357A63) : Colors.white,
              ),
              child: Icon(i,
                  size: 30, color: dark ? Colors.white : AppColors.forest),
            ),
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader(
      {super.key, required this.title, this.subtitle, this.overline, this.action});
  final String title;
  final String? subtitle;
  final String? overline;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          spacing: 16,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (overline != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(overline!,
                          style: ts(13,
                              w: FontWeight.w600, color: AppColors.muted)),
                    ),
                  Text(title, style: ts(28, w: FontWeight.w800)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(subtitle!,
                          style: ts(14, color: AppColors.muted, height: 1.4)),
                    ),
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
      );
}

/// Grid responsif sederhana berbasis Wrap.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid(
      {super.key,
      required this.children,
      this.colsWide = 4,
      this.colsNarrow = 2,
      this.spacing = 16});
  final List<Widget> children;
  final int colsWide;
  final int colsNarrow;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 640 ? colsWide : colsNarrow;
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      });
}

class StatCard extends StatelessWidget {
  const StatCard(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      required this.caption});
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.forest),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ts(12, color: AppColors.muted)),
                Text(value, style: ts(26, w: FontWeight.w800)),
                Text(caption,
                    style: ts(11, color: AppColors.forest, w: FontWeight.w600)),
              ],
            ),
          ),
        ]),
      );
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 110});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: size * 0.1,
              backgroundColor: AppColors.mint,
              valueColor: const AlwaysStoppedAnimation(AppColors.forest),
            ),
          ),
          Text('${(value * 100).round()}%',
              style:
                  ts(size * 0.24, w: FontWeight.w800, color: AppColors.forest)),
        ]),
      );
}

class QuickTile extends StatelessWidget {
  const QuickTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.forest, size: 22),
              ),
              const SizedBox(height: 12),
              Text(title, style: ts(15, w: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: ts(12.5, color: AppColors.muted, height: 1.35)),
            ],
          ),
        ),
      );
}

/// Banner indikator offline-sync: "N Item Menunggu".
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable:
            Listenable.merge([app.queue, app.offline, app.syncing, app.lastSync]),
        builder: (context, _) {
          final p = app.pending;
          final off = app.offline.value;
          final busy = app.syncing.value;
          final title = busy
              ? 'Menyinkronkan...'
              : p > 0
                  ? '$p Item Menunggu'
                  : 'Semua Data Tersinkron';
          final sub = off
              ? 'Tersimpan aman di perangkat ini. Dikirim otomatis saat internet tersambung.'
              : p > 0
                  ? 'Koneksi tersedia. Data siap dikirim.'
                  : 'Tidak ada data yang menunggu.';
          final canSync = !off && p > 0 && !busy;
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: off ? AppColors.orangeBg : AppColors.mint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: off ? const Color(0xFFFFD9A0) : AppColors.border),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: busy
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: AppColors.forest))
                          : Icon(
                              off
                                  ? Icons.cloud_off_rounded
                                  : (p > 0
                                      ? Icons.cloud_upload_rounded
                                      : Icons.cloud_done_rounded),
                              color: off ? AppColors.orange : AppColors.forest),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: ts(17, w: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(sub,
                              style: ts(12.5,
                                  color: AppColors.muted, height: 1.35)),
                          if (!compact)
                            Text('Terakhir sinkron: ${app.lastSync.value}',
                                style: ts(12, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ]),
                ),
                Tooltip(
                  message: off
                      ? 'Tombol belum dapat digunakan karena kamu sedang luring.'
                      : '',
                  child: PrimaryButton(
                    label: 'Sinkronkan sekarang',
                    icon: Icons.sync_rounded,
                    onPressed: canSync ? app.syncNow : null,
                  ),
                ),
              ],
            ),
          );
        },
      );
}

// -----------------------------------------------------------------------------
// 6. APLIKASI & ROUTER
// -----------------------------------------------------------------------------
class EduTanggapApp extends StatelessWidget {
  const EduTanggapApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'EduTanggap',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const RootRouter(),
      );
}

/// Router sederhana: mendengarkan app.screen dan menampilkan layar terkait.
class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  Widget _pick(Screen s) {
    switch (s) {
      case Screen.welcome:
        return const WelcomeScreen();
      case Screen.login:
        return const AuthScreen(register: false);
      case Screen.register:
        return const AuthScreen(register: true);
      case Screen.goodbye:
        return const GoodbyeScreen();
      default:
        return AppShell(screen: s);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Screen>(
        valueListenable: app.screen,
        builder: (context, s, _) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            // Semua layar di dalam shell memakai key yang sama agar sidebar tidak berkedip.
            key: ValueKey<String>(isShellScreen(s) ? 'shell' : s.name),
            child: _pick(s),
          ),
        ),
      );
}

// -----------------------------------------------------------------------------
// 7. LANDING & WELCOME
// -----------------------------------------------------------------------------
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mint,
      body: Stack(children: [
        // Ornamen sudut
        Positioned(
            top: -90,
            left: -90,
            child: _blob(240)),
        Positioned(
            bottom: -110,
            right: -90,
            child: _blob(280)),
        Positioned(
            bottom: -60,
            left: -60,
            child: _blob(160)),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth >= 860;
                final hero = _hero();
                final card = _welcomeCard(context);
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 6, child: hero),
                          const SizedBox(width: 40),
                          Expanded(flex: 4, child: card),
                        ],
                      )
                    : Column(children: [hero, const SizedBox(height: 28), card]);
              }),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _blob(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            color: AppColors.forest, shape: BoxShape.circle),
      );

  /// Header / banner: judul + tagline + ilustrasi.
  Widget _hero() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(size: 44),
          const SizedBox(height: 28),
          Text('Belajar siap, tetap tenang.',
              style: ts(38, w: FontWeight.w800, color: AppColors.forest, height: 1.15)),
          const SizedBox(height: 10),
          Text('Belajar menghadapi bencana dengan lebih siap.',
              style: ts(17, color: AppColors.text)),
          const SizedBox(height: 28),
          const HeroIllustration(),
        ],
      );

  Widget _welcomeCard(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selamat datang', style: ts(26, w: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Masuk atau buat akun untuk mulai belajar kesiapsiagaan bencana.',
                style: ts(14, color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 22),
            Text('Mode uji prototipe: pilih peran',
                style: ts(12, w: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 8),
            const RoleToggle(),
            const SizedBox(height: 22),
            PrimaryButton(
                label: 'Masuk',
                expand: true,
                onPressed: () => app.go(Screen.login)),
            const SizedBox(height: 10),
            GhostButton(
                label: 'Daftar',
                expand: true,
                onPressed: () => app.go(Screen.register)),
            const SizedBox(height: 18),
            Text(
                'Dengan melanjutkan, kamu menyetujui Syarat & Ketentuan dan Kebijakan Privasi EduTanggap.',
                textAlign: TextAlign.center,
                style: ts(11, color: AppColors.muted, height: 1.4)),
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// 8. AUTH (MASUK & DAFTAR - SISWA / GURU)
// -----------------------------------------------------------------------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.register});
  final bool register;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _id = TextEditingController();
  final _schoolText = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String? _school;
  bool _hidePass = true;

  static const _schools = [
    'SD Negeri Harapan 01',
    'SDN 02 Cilangkap',
    'SDN 1 Aceh',
  ];

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    _schoolText.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  bool get _teacher => app.role.value == Role.teacher;

  String? _req(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  String? _idValidator(String? v) {
    final value = v?.trim() ?? '';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Hanya angka yang diperbolehkan';
    if (_teacher) {
      final ok = widget.register
          ? (value.length == 16 || value.length == 18)
          : value.length == 16;
      return ok ? null : 'NUPTK harus 16 digit angka (NIP 18 digit)';
    }
    return value.length == 10 ? null : 'NIS harus 10 digit angka';
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    // Simulasi autentikasi: akun "tersimpan di perangkat" (tanpa server).
    if (widget.register && _name.text.trim().isNotEmpty) {
      app.userName.value = _name.text.trim();
    } else {
      app.userName.value = _teacher ? 'Ibu Dewi Putri' : 'Ayu Lestari';
    }
    app.go(Screen.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        return Row(children: [
          if (wide) const Expanded(flex: 5, child: _HeroPanel()),
          Expanded(
            flex: 5,
            child: Container(
              color: AppColors.bg,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: ValueListenableBuilder<Role>(
                      valueListenable: app.role,
                      builder: (context, role, _) => _card(role),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _card(Role role) {
    final teacher = role == Role.teacher;
    final reg = widget.register;
    return AppCard(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RoleToggle(),
            const SizedBox(height: 22),
            Text(
                reg
                    ? 'Daftar Sebagai ${teacher ? 'Guru' : 'Siswa'}'
                    : 'Masuk ke EduTanggap',
                style: ts(24, w: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
                reg
                    ? (teacher
                        ? 'Buat akun untuk membuat kelas dan memantau kesiapan siswa.'
                        : 'Buat akun untuk belajar siaga bencana bersama gurumu.')
                    : 'Pilih peranmu, pilih sekolah, lalu masuk dengan identitas yang sesuai.',
                style: ts(13.5, color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 20),
            if (reg) ...[
              LabeledField(
                  label: 'Nama lengkap',
                  controller: _name,
                  hint: 'Masukkan nama lengkap',
                  validator: (v) => _req(v, 'Nama wajib diisi')),
              const SizedBox(height: 14),
              LabeledField(
                  label: teacher ? 'NIP / NUPTK' : 'NIS',
                  controller: _id,
                  hint: teacher ? 'Nomor Induk Guru' : '10 digit NIS',
                  keyboard: TextInputType.number,
                  validator: _idValidator),
              const SizedBox(height: 14),
              LabeledField(
                  label: 'Nama sekolah',
                  controller: _schoolText,
                  hint: 'Contoh: SDN 1 Aceh',
                  validator: (v) => _req(v, 'Sekolah wajib diisi')),
              const SizedBox(height: 14),
              LabeledField(
                  label: 'Email',
                  controller: _email,
                  hint: 'nama@gmail.com',
                  keyboard: TextInputType.emailAddress,
                  validator: (v) =>
                      (v != null && v.contains('@')) ? null : 'Email tidak valid'),
            ] else ...[
              DropdownField(
                label: 'Sekolah',
                hint: 'Pilih sekolah',
                items: _schools,
                value: _school,
                onChanged: (v) => setState(() => _school = v),
                validator: (v) => v == null ? 'Sekolah wajib dipilih' : null,
              ),
              const SizedBox(height: 14),
              LabeledField(
                  label: teacher
                      ? 'NUPTK (16 digit angka)'
                      : 'Nomor Induk Siswa (NIS) (10 digit angka)',
                  controller: _id,
                  hint: teacher ? 'Contoh: 1234567890123456' : 'Contoh: 0123456789',
                  keyboard: TextInputType.number,
                  validator: _idValidator),
            ],
            const SizedBox(height: 14),
            LabeledField(
              label: 'Kata Sandi',
              controller: _pass,
              hint: 'Minimal 8 karakter',
              obscure: _hidePass,
              validator: (v) =>
                  (v != null && v.length >= 8) ? null : 'Minimal 8 karakter',
              suffix: IconButton(
                icon: Icon(_hidePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _hidePass = !_hidePass),
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
                label: reg ? 'Daftar' : 'Masuk', expand: true, onPressed: _submit),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.offline_pin_rounded,
                    color: AppColors.forest, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Setelah berhasil masuk, akun akan tersimpan di perangkat. Materi, kuis, dan modul tetap bisa dibuka meski sinyal hilang.',
                      style: ts(12, color: AppColors.forest, height: 1.4)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(
                onPressed: () => app.go(Screen.welcome),
                child: const Text('← Kembali'),
              ),
              TextButton(
                onPressed: () =>
                    app.go(reg ? Screen.login : Screen.register),
                child: Text(reg ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Panel hijau di sisi kiri layar auth / logout.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({this.title, this.showFooter = true});
  final String? title;
  final bool showFooter;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.forest,
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandLogo(light: true),
            const Spacer(),
            const HeroIllustration(dark: true),
            const SizedBox(height: 28),
            Text(title ?? 'Belajar siap, tetap tenang.',
                style: ts(34, w: FontWeight.w800, color: Colors.white, height: 1.2)),
            const SizedBox(height: 10),
            Text('Belajar menghadapi bencana dengan lebih siap.',
                style: ts(15, color: const Color(0xFFCFE6D8))),
            const Spacer(),
            if (showFooter)
              Text(
                  'Offline-first: materi, kuis, dan progres tersimpan di perangkat dan disinkronkan saat ada internet.',
                  style: ts(12, color: const Color(0xFFA9CDB8), height: 1.4)),
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// 9. SHELL (SIDEBAR + TOPBAR) UNTUK GURU & SISWA
// -----------------------------------------------------------------------------
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.screen});
  final Screen screen;

  Widget _page() {
    final teacher = app.role.value == Role.teacher;
    switch (screen) {
      case Screen.dashboard:
        return teacher ? const TeacherDashboard() : const StudentDashboard();
      case Screen.materials:
        return teacher ? const TeacherMaterialsPage() : const StudentModulesPage();
      case Screen.quizzes:
        return const QuizzesPage();
      case Screen.sync:
        return const SyncPage();
      case Screen.addMaterial:
        return const AddMaterialPage();
      case Screen.addQuiz:
        return const AddQuizPage();
      default:
        return const SizedBox.shrink();
    }
  }

  String get _title {
    switch (screen) {
      case Screen.dashboard:
        return 'Beranda';
      case Screen.materials:
      case Screen.addMaterial:
        return 'Materi Pembelajaran';
      case Screen.quizzes:
      case Screen.addQuiz:
        return 'Kuis';
      case Screen.sync:
        return 'Sinkronisasi';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      return Scaffold(
        drawer: wide
            ? null
            : Drawer(
                backgroundColor: Colors.white,
                child: Sidebar(screen: screen, inDrawer: true)),
        body: Row(children: [
          if (wide) Sidebar(screen: screen),
          Expanded(
            child: Column(children: [
              _TopBar(title: _title, showMenu: !wide),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(wide ? 32 : 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: _page(),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.showMenu});
  final String title;
  final bool showMenu;

  @override
  Widget build(BuildContext context) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          if (showMenu)
            Builder(
              builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(ctx).openDrawer()),
            ),
          Text(title, style: ts(17, w: FontWeight.w700)),
          const Spacer(),
          // Saklar simulasi koneksi (untuk menguji alur offline-first).
          ValueListenableBuilder<bool>(
            valueListenable: app.offline,
            builder: (context, off, _) => Row(children: [
              StatusChip(off ? 'Luring' : 'Daring',
                  fg: off ? AppColors.orange : AppColors.forest,
                  bg: off ? AppColors.orangeBg : AppColors.mint),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Simulasi koneksi internet',
                child: Switch(
                  value: !off,
                  activeTrackColor: AppColors.forest,
                  onChanged: (v) => app.setOffline(!v),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<String>(
            valueListenable: app.userName,
            builder: (_, name, __) => CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.forest,
              child: Text(initials(name),
                  style: ts(13, w: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      );
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key, required this.screen, this.inDrawer = false});
  final Screen screen;
  final bool inDrawer;

  int get _index {
    switch (screen) {
      case Screen.materials:
      case Screen.addMaterial:
        return 1;
      case Screen.quizzes:
      case Screen.addQuiz:
        return 2;
      case Screen.sync:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String, Screen)>[
      (Icons.home_rounded, 'Beranda', Screen.dashboard),
      (Icons.menu_book_rounded, 'Materi', Screen.materials),
      (Icons.quiz_rounded, 'Kuis', Screen.quizzes),
      (Icons.sync_rounded, 'Sinkronisasi', Screen.sync),
    ];
    return ValueListenableBuilder<Role>(
      valueListenable: app.role,
      builder: (context, role, _) => Container(
        width: inDrawer ? null : 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: inDrawer
              ? null
              : const Border(right: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const BrandLogo(size: 34),
            const SizedBox(height: 28),
            Text(role == Role.teacher ? 'RUANG GURU' : 'RUANG SISWA',
                style: ts(11, w: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 10),
            for (var i = 0; i < items.length; i++)
              _navTile(context, items[i].$1, items[i].$2, items[i].$3, i == _index),
            const Spacer(),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: app.userName,
              builder: (_, name, __) => Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.mint,
                  child: Text(initials(name),
                      style: ts(13, w: FontWeight.w700, color: AppColors.forest)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(role == Role.teacher ? 'Ibu Dewi Putri' : name,
                            overflow: TextOverflow.ellipsis,
                            style: ts(13.5, w: FontWeight.w700)),
                        Text(role == Role.teacher ? 'Guru · Kelas 5A' : 'Siswa · Kelas 5A',
                            style: ts(12, color: AppColors.muted)),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Keluar'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFB83A3A)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String label, Screen s,
      bool selected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.mint : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (inDrawer) Navigator.of(context).pop();
            app.go(s);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(children: [
              Icon(icon,
                  size: 20,
                  color: selected ? AppColors.forest : AppColors.muted),
              const SizedBox(width: 12),
              Text(label,
                  style: ts(14,
                      w: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.forest : AppColors.text)),
            ]),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 10. DASHBOARD GURU
// -----------------------------------------------------------------------------
class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([app.materials, app.quizzes]),
        builder: (context, _) {
          final materi = 6 + app.materials.value.where((m) => m.shared).length;
          final kuis = 4 + app.quizzes.value.where((q) => q.published).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                overline: 'SDN 02 Cilangkap · Kelas 5A',
                title: 'Halo, Ibu Dewi 👋',
                subtitle: 'Selamat pagi, Bu Dewi. Berikut ringkasan kelas hari ini.',
              ),
              ResponsiveGrid(children: [
                const StatCard(
                    icon: Icons.groups_rounded,
                    label: 'Siswa aktif',
                    value: '32',
                    caption: 'Semua terdaftar'),
                StatCard(
                    icon: Icons.menu_book_rounded,
                    label: 'Materi',
                    value: '$materi',
                    caption: '2 baru minggu ini'),
                StatCard(
                    icon: Icons.quiz_rounded,
                    label: 'Kuis',
                    value: '$kuis',
                    caption: '1 perlu dinilai'),
                const StatCard(
                    icon: Icons.trending_up_rounded,
                    label: 'Rata-rata progres',
                    value: '87%',
                    caption: 'Naik 4% bulan ini'),
              ]),
              const SizedBox(height: 16),
              const SyncBanner(),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth >= 820;
                final left = _activityCard();
                final right = _progressCard(context);
                return wide
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(flex: 3, child: left),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: right),
                      ])
                    : Column(children: [left, const SizedBox(height: 16), right]);
              }),
            ],
          );
        },
      );

  Widget _activityCard() => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Aktivitas terkini', style: ts(17, w: FontWeight.w800)),
          const SizedBox(height: 14),
          _activity(Icons.menu_book_rounded, 'Materi dibagikan', 'IPA · Siklus air',
              '10 menit lalu'),
          _activity(Icons.check_circle_rounded, 'Kuis selesai',
              'Matematika · Pecahan', 'Kemarin, 14.20'),
          _activity(Icons.how_to_reg_rounded, 'Kehadiran diperbarui',
              '28 hadir · 4 izin', 'Kemarin, 07.45'),
          const Divider(height: 28, color: AppColors.border),
          Text('Progres per mata pelajaran',
              style: ts(14, w: FontWeight.w700)),
          const SizedBox(height: 12),
          _bar('Matematika', 0.75, '6 dari 8 topik'),
          _bar('Bahasa Indonesia', 0.71, '5 dari 7 topik'),
          _bar('IPA', 0.5, '4 dari 8 topik'),
        ]),
      );

  Widget _activity(IconData i, String t, String s, String time) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
            child: Icon(i, size: 20, color: AppColors.forest),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: ts(14, w: FontWeight.w700)),
              Text(s, style: ts(12.5, color: AppColors.muted)),
            ]),
          ),
          Text(time, style: ts(12, color: AppColors.muted)),
        ]),
      );

  Widget _bar(String label, double v, String caption) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: ts(13, w: FontWeight.w600)),
            Text(caption, style: ts(12, color: AppColors.muted)),
          ]),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: v,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: AppColors.mint,
            color: AppColors.forest,
          ),
        ]),
      );

  Widget _progressCard(BuildContext context) => Column(children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Progres pembelajaran', style: ts(17, w: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(children: [
              const ProgressRing(value: 0.68),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                    'Progres keseluruhan kelas. Sedikit lagi! Dorong siswa menuntaskan satu materi hari ini.',
                    style: ts(13, color: AppColors.muted, height: 1.45)),
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.orangeBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.orange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Siaga banjir: bagikan materi "Banjir: Kenali Tanda dan Cara Aman".',
                      style: ts(12.5, color: const Color(0xFF8A5200), height: 1.35)),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aksi cepat', style: ts(17, w: FontWeight.w800)),
            const SizedBox(height: 14),
            PrimaryButton(
                label: 'Tambah Materi Baru',
                icon: Icons.add_rounded,
                expand: true,
                onPressed: () => app.go(Screen.addMaterial)),
            const SizedBox(height: 10),
            PrimaryButton(
                label: 'Buat Kuis Baru',
                icon: Icons.edit_note_rounded,
                expand: true,
                onPressed: () => app.go(Screen.addQuiz)),
            const SizedBox(height: 10),
            GhostButton(
                label: 'Kelola siswa',
                icon: Icons.groups_rounded,
                expand: true,
                onPressed: () => toast(context, 'Fitur kelola siswa belum tersedia pada prototipe.')),
          ]),
        ),
      ]);
}

// -----------------------------------------------------------------------------
// 11. HALAMAN GURU: DAFTAR MATERI
// -----------------------------------------------------------------------------
class TeacherMaterialsPage extends StatelessWidget {
  const TeacherMaterialsPage({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<MaterialItem>>(
        valueListenable: app.materials,
        builder: (context, list, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Materi Pembelajaran',
              subtitle: 'Kelola bahan belajar yang dibagikan ke siswa.',
              action: PrimaryButton(
                  label: 'Tambah Materi Baru',
                  icon: Icons.add_rounded,
                  onPressed: () => app.go(Screen.addMaterial)),
            ),
            for (final m in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(
                          m.fileName.endsWith('.mp4')
                              ? Icons.play_circle_rounded
                              : Icons.picture_as_pdf_rounded,
                          color: AppColors.forest),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.title, style: ts(15, w: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text('${m.subject} · ${m.kelas} · ${m.fileName}',
                                style: ts(12.5, color: AppColors.muted)),
                          ]),
                    ),
                    StatusChip(m.shared ? 'Dibagikan' : 'Draf',
                        fg: m.shared ? AppColors.forest : AppColors.orange,
                        bg: m.shared ? AppColors.mint : AppColors.orangeBg),
                  ]),
                ),
              ),
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// 12. FORM TAMBAH MATERI BARU (GURU)
// -----------------------------------------------------------------------------
class AddMaterialPage extends StatefulWidget {
  const AddMaterialPage({super.key});

  @override
  State<AddMaterialPage> createState() => _AddMaterialPageState();
}

class _AddMaterialPageState extends State<AddMaterialPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String? _subject;
  String? _kelas;
  String? _file; // nama file (mock)
  bool _offlineSave = true;

  static const _subjects = [
    'Kesiapsiagaan Bencana',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Matematika',
    'IPA',
    'IPS',
  ];
  static const _classes = ['Kelas 5A', 'Kelas 5B', 'Kelas 6A'];

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _pick(bool video) {
    // Mock: pada versi produksi gunakan paket file_picker.
    setState(() => _file = video ? 'materi_video_baru.mp4' : 'materi_baru.pdf');
  }

  void _save({required bool share}) {
    if (!_form.currentState!.validate()) return;
    if (_file == null) {
      toast(context, 'Konten materi wajib diunggah (PDF atau MP4).');
      return;
    }
    final item = MaterialItem(
      title: _title.text.trim(),
      description: _desc.text.trim(),
      subject: _subject!,
      kelas: _kelas!,
      fileName: _file!,
      shared: share,
    );
    app.materials.value = [item, ...app.materials.value];
    // Perubahan disimpan lokal -> masuk antrean sinkronisasi.
    if (share) app.enqueue('Materi baru dibagikan', item.title);
    toast(context,
        share ? 'Materi dibagikan. Menunggu sinkronisasi.' : 'Draf materi disimpan.');
    app.go(Screen.materials);
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => app.go(Screen.materials),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Kembali ke Materi'),
            ),
          ),
          const PageHeader(
              title: 'Tambah Materi Baru',
              subtitle: 'Siapkan bahan belajar dan bagikan kepada siswa Anda.',
              action: StatusChip('Belum dibagikan',
                  fg: AppColors.orange, bg: AppColors.orangeBg)),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Informasi Materi', style: ts(17, w: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Lengkapi detail agar materi mudah ditemukan siswa.',
                  style: ts(13, color: AppColors.muted)),
              const SizedBox(height: 18),
              LabeledField(
                  label: 'Judul Materi *',
                  controller: _title,
                  hint: 'Contoh: Mengenal Sistem Tata Surya',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null),
              const SizedBox(height: 14),
              LabeledField(
                  label: 'Deskripsi / Catatan Tambahan (opsional)',
                  controller: _desc,
                  hint: 'Tuliskan ringkasan materi, tujuan pembelajaran, atau petunjuk untuk siswa...',
                  maxLines: 4,
                  maxLength: 1000),
              const SizedBox(height: 8),
              LayoutBuilder(builder: (context, c) {
                final subj = DropdownField(
                  label: 'Mata Pelajaran *',
                  hint: 'Pilih mata pelajaran',
                  items: _subjects,
                  value: _subject,
                  onChanged: (v) => setState(() => _subject = v),
                  validator: (v) => v == null ? 'Wajib dipilih' : null,
                );
                final kls = DropdownField(
                  label: 'Kelas *',
                  hint: 'Pilih kelas',
                  items: _classes,
                  value: _kelas,
                  onChanged: (v) => setState(() => _kelas = v),
                  validator: (v) => v == null ? 'Wajib dipilih' : null,
                );
                return c.maxWidth >= 560
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: subj),
                        const SizedBox(width: 16),
                        Expanded(child: kls),
                      ])
                    : Column(children: [subj, const SizedBox(height: 14), kls]);
              }),
            ]),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Konten Materi *', style: ts(17, w: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Unggah dokumen, video, atau tambahkan tautan bahan belajar.',
                  style: ts(13, color: AppColors.muted)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  const Icon(Icons.cloud_upload_rounded,
                      size: 38, color: AppColors.forest),
                  const SizedBox(height: 8),
                  Text('Seret dan lepas file di sini, atau pilih file',
                      style: ts(14, w: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('PDF atau Video MP4 • Maksimal 100 MB per file',
                      style: ts(12, color: AppColors.muted)),
                  const SizedBox(height: 14),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    GhostButton(
                        label: 'Unggah PDF',
                        icon: Icons.picture_as_pdf_rounded,
                        onPressed: () => _pick(false)),
                    GhostButton(
                        label: 'Unggah Video',
                        icon: Icons.videocam_rounded,
                        onPressed: () => _pick(true)),
                  ]),
                ]),
              ),
              if (_file != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.attach_file_rounded,
                        size: 18, color: AppColors.forest),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_file!,
                            style: ts(13.5, w: FontWeight.w600, color: AppColors.forest))),
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _file = null)),
                  ]),
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.forest,
                value: _offlineSave,
                onChanged: (v) => setState(() => _offlineSave = v),
                title: Text('Izinkan disimpan otomatis di perangkat siswa untuk mode offline',
                    style: ts(14, w: FontWeight.w600)),
                subtitle: Text(
                    'Siswa dapat mengakses file materi tanpa koneksi internet. Tidak berlaku untuk link.',
                    style: ts(12, color: AppColors.muted)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Hanya siswa di kelas terpilih yang dapat mengakses.',
                  style: ts(12.5, color: AppColors.muted)),
            ),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 12, runSpacing: 12, children: [
            GhostButton(label: 'Simpan Draft', onPressed: () => _save(share: false)),
            PrimaryButton(
                label: 'Bagikan ke Siswa',
                icon: Icons.send_rounded,
                onPressed: () => _save(share: true)),
          ]),
        ]),
      );
}

// -----------------------------------------------------------------------------
// 13. KUIS: DAFTAR (GURU & SISWA) + FORM BUAT KUIS BARU (GURU)
// -----------------------------------------------------------------------------
class QuizzesPage extends StatelessWidget {
  const QuizzesPage({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([app.quizzes, app.role]),
        builder: (context, _) {
          final teacher = app.role.value == Role.teacher;
          final list = teacher
              ? app.quizzes.value
              : app.quizzes.value.where((q) => q.published).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PageHeader(
              title: 'Kuis',
              subtitle: teacher
                  ? 'Susun pertanyaan dan uji pemahaman siswa Anda.'
                  : 'Uji pemahamanmu. Hasil kuis tersimpan di perangkat meski luring.',
              action: teacher
                  ? PrimaryButton(
                      label: 'Buat Kuis Baru',
                      icon: Icons.add_rounded,
                      onPressed: () => app.go(Screen.addQuiz))
                  : null,
            ),
            if (list.isEmpty)
              AppCard(
                  child: Text('Belum ada kuis.',
                      style: ts(14, color: AppColors.muted))),
            for (final q in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.quiz_rounded,
                                color: AppColors.forest),
                          ),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.title, style: ts(15, w: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text(
                                      '${q.subject} · ${q.questions.length} soal · ${q.duration}',
                                      style: ts(12.5, color: AppColors.muted)),
                                  Text('Batas: ${q.deadline}',
                                      style: ts(12, color: AppColors.muted)),
                                ]),
                          ),
                        ]),
                      ),
                      if (teacher)
                        StatusChip(q.published ? 'Diterbitkan' : 'Draf',
                            fg: q.published ? AppColors.forest : AppColors.orange,
                            bg: q.published ? AppColors.mint : AppColors.orangeBg)
                      else
                        PrimaryButton(
                            label: 'Mulai',
                            icon: Icons.play_arrow_rounded,
                            onPressed: () => showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => QuizDialog(quiz: q))),
                    ],
                  ),
                ),
              ),
          ]);
        },
      );
}

/// Pemutar kuis untuk siswa (dialog).
class QuizDialog extends StatefulWidget {
  const QuizDialog({super.key, required this.quiz});
  final QuizItem quiz;

  @override
  State<QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<QuizDialog> {
  int _i = 0;
  int? _selected;
  bool _answered = false;
  int _correct = 0;
  bool _finished = false;

  QuizQuestion get _q => widget.quiz.questions[_i];
  int get _total => widget.quiz.questions.length;

  void _answer(int idx) {
    if (_answered) return;
    setState(() {
      _selected = idx;
      _answered = true;
      if (idx == _q.correct) _correct++;
    });
  }

  void _next() {
    if (_i + 1 >= _total) {
      setState(() => _finished = true);
    } else {
      setState(() {
        _i++;
        _selected = null;
        _answered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: SingleChildScrollView(
                child: _finished ? _result() : _question()),
          ),
        ),
      );

  Widget _question() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KUIS: ${widget.quiz.title.toUpperCase()}  ·  Soal ${_i + 1} dari $_total',
              style: ts(11.5, w: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_i + 1) / _total,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: AppColors.mint,
            color: AppColors.forest,
          ),
          const SizedBox(height: 18),
          Text(_q.text, style: ts(18, w: FontWeight.w700, height: 1.35)),
          const SizedBox(height: 16),
          for (var k = 0; k < _q.options.length; k++) _option(k),
          if (_answered) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
              child: Text(
                  'Pembahasan: jawaban yang benar adalah "${_q.options[_q.correct]}".',
                  style: ts(13, color: AppColors.forest, height: 1.4)),
            ),
          ],
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
                label: _i + 1 >= _total ? 'Lihat Hasil' : 'Selanjutnya',
                onPressed: _answered ? _next : null),
          ),
        ],
      );

  Widget _option(int k) {
    final isCorrect = _answered && k == _q.correct;
    final isWrong = _answered && k == _selected && k != _q.correct;
    final color = isCorrect
        ? AppColors.forest
        : isWrong
            ? const Color(0xFFD64545)
            : AppColors.border;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _answer(k),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCorrect ? AppColors.mint : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: isCorrect || isWrong ? 1.6 : 1),
          ),
          child: Row(children: [
            Text('${String.fromCharCode(65 + k)}.',
                style: ts(14, w: FontWeight.w700, color: AppColors.forest)),
            const SizedBox(width: 10),
            Expanded(child: Text(_q.options[k], style: ts(14.5))),
            if (isCorrect)
              const Icon(Icons.check_circle_rounded, color: AppColors.forest, size: 20),
            if (isWrong)
              const Icon(Icons.cancel_rounded, color: Color(0xFFD64545), size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _result() {
    final score = (_correct * 100 / _total).round();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Hasil Kuis Anda', style: ts(14, color: AppColors.muted)),
      const SizedBox(height: 4),
      Text(widget.quiz.title, style: ts(18, w: FontWeight.w800)),
      const SizedBox(height: 18),
      ProgressRing(value: score / 100, size: 130),
      const SizedBox(height: 10),
      Text(score >= 70 ? 'Kerja bagus!' : 'Ayo belajar lagi!',
          style: ts(17, w: FontWeight.w700, color: AppColors.forest)),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _stat('$_correct', 'Benar', AppColors.mint, AppColors.forest),
        const SizedBox(width: 12),
        _stat('${_total - _correct}', 'Salah', const Color(0xFFFDECEC),
            const Color(0xFFD64545)),
      ]),
      const SizedBox(height: 16),
      ValueListenableBuilder<bool>(
        valueListenable: app.offline,
        builder: (_, off, __) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: off ? AppColors.orangeBg : AppColors.mint,
              borderRadius: BorderRadius.circular(10)),
          child: Text(
              off
                  ? 'Hasil belum disinkronkan. Data akan dikirim saat perangkat terhubung ke internet.'
                  : 'Hasil disimpan dan siap dikirim ke server.',
              style: ts(12.5,
                  color: off ? const Color(0xFF8A5200) : AppColors.forest,
                  height: 1.4)),
        ),
      ),
      const SizedBox(height: 18),
      PrimaryButton(
        label: 'Selesai',
        expand: true,
        onPressed: () {
          app.enqueue('Hasil kuis: ${widget.quiz.title}', 'Nilai $score/100');
          Navigator.of(context).pop();
          app.syncNow(); // otomatis jika sedang daring
        },
      ),
    ]);
  }

  Widget _stat(String v, String l, Color bg, Color fg) => Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(v, style: ts(22, w: FontWeight.w800, color: fg)),
          Text(l, style: ts(12, color: fg)),
        ]),
      );
}

/// Form buat kuis baru (guru). Satu draf pertanyaan memegang controller-nya sendiri.
class _QDraft {
  final question = TextEditingController();
  final options = List.generate(4, (_) => TextEditingController());
  int correct = 0;
  void dispose() {
    question.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

class AddQuizPage extends StatefulWidget {
  const AddQuizPage({super.key});

  @override
  State<AddQuizPage> createState() => _AddQuizPageState();
}

class _AddQuizPageState extends State<AddQuizPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _deadline = TextEditingController(text: '22 Oktober 2026 · 23.59 WIB');
  String? _subject;
  String _duration = '30 Menit';
  final List<_QDraft> _qs = [_QDraft()];

  static const _subjects = [
    'Kesiapsiagaan Bencana',
    'Bahasa Indonesia',
    'Matematika',
    'IPA',
    'IPS',
  ];
  static const _durations = ['15 Menit', '30 Menit', '45 Menit', '60 Menit'];

  @override
  void dispose() {
    _title.dispose();
    _deadline.dispose();
    for (final q in _qs) {
      q.dispose();
    }
    super.dispose();
  }

  void _save({required bool publish}) {
    if (!_form.currentState!.validate()) return;
    final quiz = QuizItem(
      title: _title.text.trim(),
      subject: _subject!,
      duration: _duration,
      deadline: _deadline.text.trim(),
      published: publish,
      questions: [
        for (final q in _qs)
          QuizQuestion(q.question.text.trim(),
              [for (final o in q.options) o.text.trim()], q.correct),
      ],
    );
    app.quizzes.value = [quiz, ...app.quizzes.value];
    if (publish) app.enqueue('Kuis baru diterbitkan', quiz.title);
    toast(context,
        publish ? 'Kuis diterbitkan. Menunggu sinkronisasi.' : 'Draf kuis disimpan.');
    app.go(Screen.quizzes);
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => app.go(Screen.quizzes),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Kembali ke Kuis'),
            ),
          ),
          const PageHeader(
              title: 'Buat Kuis Baru',
              subtitle: 'Susun pertanyaan dan uji pemahaman siswa Anda.',
              action: StatusChip('Belum diterbitkan',
                  fg: AppColors.orange, bg: AppColors.orangeBg)),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pengaturan Kuis', style: ts(17, w: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Lengkapi informasi dan atur waktu pengerjaan kuis.',
                  style: ts(13, color: AppColors.muted)),
              const SizedBox(height: 18),
              LayoutBuilder(builder: (context, c) {
                final title = LabeledField(
                    label: 'Judul Kuis *',
                    controller: _title,
                    hint: 'Contoh: Kuis Sistem Tata Surya',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null);
                final subj = DropdownField(
                  label: 'Mata Pelajaran *',
                  hint: 'Pilih mata pelajaran',
                  items: _subjects,
                  value: _subject,
                  onChanged: (v) => setState(() => _subject = v),
                  validator: (v) => v == null ? 'Wajib dipilih' : null,
                );
                final dur = DropdownField(
                  label: 'Durasi Pengerjaan *',
                  items: _durations,
                  value: _duration,
                  onChanged: (v) => setState(() => _duration = v ?? _duration),
                );
                final dl = LabeledField(
                    label: 'Batas Waktu *',
                    controller: _deadline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null);
                if (c.maxWidth >= 640) {
                  return Column(children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: title),
                      const SizedBox(width: 16),
                      Expanded(child: subj),
                    ]),
                    const SizedBox(height: 14),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: dur),
                      const SizedBox(width: 16),
                      Expanded(child: dl),
                    ]),
                  ]);
                }
                return Column(children: [
                  title,
                  const SizedBox(height: 14),
                  subj,
                  const SizedBox(height: 14),
                  dur,
                  const SizedBox(height: 14),
                  dl,
                ]);
              }),
            ]),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Pertanyaan Kuis', style: ts(17, w: FontWeight.w800)),
                const SizedBox(width: 10),
                StatusChip('${_qs.length} pertanyaan',
                    fg: AppColors.forest, bg: AppColors.mint),
              ]),
              const SizedBox(height: 4),
              Text(
                  'Tambahkan pertanyaan dan tentukan satu jawaban yang benar (ketuk lingkaran).',
                  style: ts(13, color: AppColors.muted)),
              const SizedBox(height: 16),
              for (var i = 0; i < _qs.length; i++) _questionCard(i),
              GhostButton(
                label: 'Tambah Pertanyaan',
                icon: Icons.add_rounded,
                expand: true,
                onPressed: () => setState(() => _qs.add(_QDraft())),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Hanya siswa di kelas terpilih yang dapat mengakses.',
                  style: ts(12.5, color: AppColors.muted)),
            ),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 12, runSpacing: 12, children: [
            GhostButton(label: 'Simpan Draf', onPressed: () => _save(publish: false)),
            PrimaryButton(
                label: 'Terbitkan Kuis',
                icon: Icons.send_rounded,
                onPressed: () => _save(publish: true)),
          ]),
        ]),
      );

  Widget _questionCard(int i) {
    final q = _qs[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Pertanyaan ${i + 1}', style: ts(14.5, w: FontWeight.w800)),
          const SizedBox(width: 8),
          const StatusChip('Pilihan ganda', fg: AppColors.forest, bg: AppColors.mint),
          const Spacer(),
          if (_qs.length > 1)
            IconButton(
              tooltip: 'Hapus pertanyaan',
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: () => setState(() {
                _qs.removeAt(i).dispose();
              }),
            ),
        ]),
        const SizedBox(height: 10),
        LabeledField(
          label: 'Teks pertanyaan',
          controller: q.question,
          hint: 'Contoh: Planet manakah yang dikenal sebagai Planet Merah?',
          maxLines: 3,
          maxLength: 1000,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Pertanyaan wajib diisi' : null,
        ),
        const SizedBox(height: 4),
        Text('Pilihan Jawaban', style: ts(13, w: FontWeight.w600)),
        const SizedBox(height: 8),
        for (var k = 0; k < 4; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 10),
                child: Tooltip(
                  message: 'Tandai sebagai kunci jawaban',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => q.correct = k),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: q.correct == k ? AppColors.forest : Colors.white,
                        border: Border.all(
                            color: q.correct == k
                                ? AppColors.forest
                                : AppColors.border,
                            width: 1.6),
                      ),
                      child: q.correct == k
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: q.options[k],
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Pilihan wajib diisi'
                      : null,
                  decoration: InputDecoration(
                    hintText: 'Pilihan ${String.fromCharCode(65 + k)}',
                    prefixText: '${String.fromCharCode(65 + k)}.  ',
                    suffixText: q.correct == k ? 'Kunci jawaban' : null,
                    suffixStyle: ts(11.5, w: FontWeight.w700, color: AppColors.forest),
                  ),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

// -----------------------------------------------------------------------------
// 14. DASHBOARD SISWA
// -----------------------------------------------------------------------------
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: app.userName,
        builder: (context, name, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              overline: '$name — Kelas 5A',
              title: 'Halo, ${name.split(' ').first}! 👋',
              subtitle: 'Yuk lanjutkan belajar kesiapsiagaan bencana hari ini.',
            ),
            const SyncBanner(),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 820;
              final progress = AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Progres belajarmu', style: ts(17, w: FontWeight.w800)),
                  const SizedBox(height: 14),
                  Row(children: [
                    const ProgressRing(value: 0.68),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('3 dari 5 materi selesai',
                                style: ts(14, w: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('Sedikit lagi! Lanjutkan satu materi hari ini.',
                                style: ts(13, color: AppColors.muted, height: 1.4)),
                          ]),
                    ),
                  ]),
                ]),
              );
              final tiles = ResponsiveGrid(
                colsWide: 2,
                colsNarrow: 1,
                children: [
                  QuickTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Lanjutkan materi',
                      subtitle: 'Banjir: Kenali Tanda dan Cara Aman.',
                      onTap: () => openModule(context, app.modules[1])),
                  QuickTile(
                      icon: Icons.quiz_rounded,
                      title: 'Kuis singkat',
                      subtitle: 'Uji pemahamanmu dalam 5 pertanyaan.',
                      onTap: () => app.go(Screen.quizzes)),
                  QuickTile(
                      icon: Icons.download_done_rounded,
                      title: 'Materi tersimpan',
                      subtitle: 'Belajar kapan saja tanpa koneksi internet.',
                      onTap: () => app.go(Screen.materials)),
                  QuickTile(
                      icon: Icons.ondemand_video_rounded,
                      title: 'Video pembelajaran',
                      subtitle: 'Pahami materi lewat video.',
                      onTap: () => openModule(context, app.modules[2])),
                ],
              );
              return wide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 2, child: progress),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: tiles),
                    ])
                  : Column(children: [progress, const SizedBox(height: 16), tiles]);
            }),
            const SizedBox(height: 24),
            Text('Daftar Modul Pembelajaran', style: ts(19, w: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final m in app.modules.take(4)) _ModuleTile(module: m),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                  onPressed: () => app.go(Screen.materials),
                  child: const Text('Lihat semua modul →')),
            ),
          ],
        ),
      );
}

class StudentModulesPage extends StatelessWidget {
  const StudentModulesPage({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
              title: 'Mata Pelajaran',
              subtitle: 'Semua modul sudah tersimpan di perangkat ini dan bisa dibuka luring.'),
          for (final m in app.modules) _ModuleTile(module: m),
        ],
      );
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module});
  final LearningModule module;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
              child: Icon(module.icon, color: AppColors.forest),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(module.title, style: ts(15, w: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.schedule_rounded, size: 14, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text('${module.subject} · ± ${module.minutes} menit',
                      style: ts(12.5, color: AppColors.muted)),
                ]),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: module.progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                  backgroundColor: AppColors.mint,
                  color: AppColors.forest,
                ),
              ]),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              module.score == null
                  ? const StatusChip('Belum ada nilai',
                      fg: AppColors.muted, bg: Color(0xFFEFF2F0))
                  : StatusChip('Nilai ${module.score}',
                      fg: AppColors.forest, bg: AppColors.mint),
              const SizedBox(height: 8),
              GhostButton(
                  label: 'Buka',
                  onPressed: () => openModule(context, module)),
            ]),
          ]),
        ),
      );
}

// -----------------------------------------------------------------------------
// 15. HALAMAN SINKRONISASI
// -----------------------------------------------------------------------------
class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable:
            Listenable.merge([app.queue, app.offline, app.syncing, app.lastSync]),
        builder: (context, _) {
          final off = app.offline.value;
          final items = app.queue.value;
          final shown = _showAll ? items : items.take(5).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const PageHeader(
              title: 'Sinkronisasi Aplikasi',
              subtitle:
                  'EduTanggap menyimpan progres belajarmu dengan aman meskipun tanpa internet.',
            ),
            const SyncBanner(),
            const SizedBox(height: 16),
            AppCard(
              child: Row(children: [
                Icon(off ? Icons.shield_moon_rounded : Icons.verified_rounded,
                    color: AppColors.forest),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      off
                          ? 'Jangan khawatir! Semua hasil belajar, kuis, dan latihanmu tetap tersimpan utuh di perangkat ini. Pembaruan otomatis berjalan segera setelah komputer ini terhubung kembali ke internet.'
                          : 'Perangkat terhubung. Data baru akan dikirim otomatis, atau tekan "Sinkronkan sekarang".',
                      style: ts(13.5, color: AppColors.text, height: 1.45)),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Text('Riwayat & Antrean Aktivitas', style: ts(19, w: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
                'Daftar kuis dan materi terunduh yang sedang menunggu jaringan atau telah berhasil disimpan.',
                style: ts(13, color: AppColors.muted)),
            const SizedBox(height: 14),
            for (final it in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: it.done ? AppColors.mint : AppColors.orangeBg,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(
                          it.done
                              ? Icons.cloud_done_rounded
                              : Icons.schedule_rounded,
                          size: 20,
                          color: it.done ? AppColors.forest : AppColors.orange),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.title, style: ts(14, w: FontWeight.w700)),
                            Text(it.subtitle,
                                style: ts(12.5, color: AppColors.muted)),
                          ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      StatusChip(it.done ? 'Selesai Tersimpan' : 'Menunggu Koneksi',
                          fg: it.done ? AppColors.forest : AppColors.orange,
                          bg: it.done ? AppColors.mint : AppColors.orangeBg),
                      const SizedBox(height: 4),
                      Text(it.time, style: ts(11.5, color: AppColors.muted)),
                    ]),
                  ]),
                ),
              ),
            if (items.length > 5)
              TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(_showAll ? 'Tampilkan lebih sedikit' : 'Tampilkan Semua'),
              ),
          ]);
        },
      );
}

// -----------------------------------------------------------------------------
// 16. LAYAR PENUTUP LOGOUT
// -----------------------------------------------------------------------------
class GoodbyeScreen extends StatelessWidget {
  const GoodbyeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 900;
          return Row(children: [
            if (wide)
              const Expanded(
                flex: 5,
                child: _HeroPanel(
                    title: 'Terima kasih telah menggunakan EduTanggap',
                    showFooter: false),
              ),
            Expanded(
              flex: 5,
              child: Container(
                color: AppColors.bg,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: AppCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                                color: AppColors.mint, shape: BoxShape.circle),
                            child: const Icon(Icons.waving_hand_rounded,
                                size: 34, color: AppColors.forest),
                          ),
                          const SizedBox(height: 18),
                          Text('Terima kasih telah menggunakan EduTanggap',
                              textAlign: TextAlign.center,
                              style: ts(22, w: FontWeight.w800, height: 1.25)),
                          const SizedBox(height: 10),
                          Text(
                              'Kamu sudah keluar. Data belajarmu tetap tersimpan di perangkat dan akan disinkronkan saat ada internet.',
                              textAlign: TextAlign.center,
                              style: ts(13.5, color: AppColors.muted, height: 1.45)),
                          const SizedBox(height: 24),
                          PrimaryButton(
                              label: 'Kembali ke Beranda',
                              expand: true,
                              onPressed: () => app.go(Screen.welcome)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        }),
      );
}
