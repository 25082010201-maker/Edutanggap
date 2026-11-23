package edutanggap;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.PiePlot;
import org.jfree.data.category.DefaultCategoryDataset;
import org.jfree.data.general.DefaultPieDataset;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.*;

/**
 * Dashboard EduTanggap (Kelompok 6) - Java Swing + JFreeChart + MySQL.
 * Menampilkan 3 chart (Bar, Line, Pie), filter data, dan tabel laporan.
 */
public class DashboardApp extends JFrame {

    // ====== KONEKSI DATABASE (bisa diubah lewat environment variable) ======
    static final String DB_URL = env("DB_URL",
            "jdbc:mariadb://localhost:3306/db_edutanggap");
    static final String DB_USER = env("DB_USER", "edu_app");
    static final String DB_PASS = env("DB_PASS", "GANTI_PASSWORD_APP");

    static String env(String key, String def) {
        String v = System.getenv(key);
        return (v == null || v.isBlank()) ? def : v;
    }

    // ====== QUERY SQL ======
    static final String Q_CARD = """
            SELECT (SELECT COUNT(*) FROM siswa),
                   (SELECT ROUND(AVG(skor),1) FROM hasil_kuis_lokal),
                   (SELECT ROUND(AVG(persentase_kehadiran),1) FROM kehadiran),
                   (SELECT COUNT(*) FROM antrean_sync WHERE status_antrean='Pending')
            """;

    // BAR CHART (kategori): rata-rata progres belajar per mata pelajaran
    static final String Q_BAR = """
            SELECT mp.nama_mapel AS label, ROUND(AVG(pb.persentase_progres),1) AS nilai
            FROM progres_belajar pb
            JOIN materi m ON m.id_materi = pb.id_materi
            JOIN mata_pelajaran mp ON mp.id_mapel = m.id_mapel
            WHERE (? IS NULL OR pb.id_siswa = ?) AND (? IS NULL OR mp.id_mapel = ?)
            GROUP BY mp.id_mapel, mp.nama_mapel
            ORDER BY mp.nama_mapel
            """;

    // LINE CHART (time series): jumlah aktivitas sinkronisasi per hari
    static final String Q_LINE = """
            SELECT DATE_FORMAT(a.waktu_dibuat, '%Y-%m-%d') AS label, COUNT(*) AS nilai
            FROM antrean_sync a
            JOIN siswa s ON s.id_user = a.id_user
            WHERE (? IS NULL OR s.id_siswa = ?) AND (? IS NULL OR a.status_antrean = ?)
            GROUP BY DATE_FORMAT(a.waktu_dibuat, '%Y-%m-%d')
            ORDER BY label
            """;

    // PIE CHART: komposisi jawaban Benar vs Salah
    static final String Q_PIE = """
            SELECT CASE WHEN d.is_benar = 1 THEN 'Benar' ELSE 'Salah' END AS label,
                   COUNT(*) AS nilai
            FROM detail_jawaban d
            JOIN hasil_kuis_lokal h ON h.id_hasil = d.id_hasil
            JOIN kuis k ON k.id_kuis = h.id_kuis
            WHERE (? IS NULL OR h.id_siswa = ?) AND (? IS NULL OR k.id_mapel = ?)
            GROUP BY d.is_benar
            ORDER BY d.is_benar DESC
            """;

    // TABEL: grouping per hasil kuis memakai VIEW vw_detail_hasil_kuis
    static final String Q_TABEL = """
            SELECT v.nama_siswa, v.judul_kuis, v.skor,
                   SUM(v.status_jawaban = 'Benar') AS benar,
                   SUM(v.status_jawaban = 'Salah') AS salah,
                   v.status_sync
            FROM vw_detail_hasil_kuis v
            WHERE (? IS NULL OR v.nama_siswa =
                   (SELECT u.nama_lengkap FROM siswa s JOIN user u ON u.id_user = s.id_user
                    WHERE s.id_siswa = ?))
            GROUP BY v.id_hasil, v.nama_siswa, v.judul_kuis, v.skor, v.status_sync
            ORDER BY v.id_hasil
            """;

    // ====== KOMPONEN TAMPILAN ======
    record Item(Integer id, String nama) {
        @Override
        public String toString() {
            return nama;
        }
    }

    final JComboBox<Item> cbSiswa = new JComboBox<>();
    final JComboBox<Item> cbMapel = new JComboBox<>();
    final JComboBox<String> cbStatus = new JComboBox<>(new String[] { "Semua", "Pending", "Synced", "Failed" });
    final JLabel[] nilaiCard = { new JLabel("-"), new JLabel("-"), new JLabel("-"), new JLabel("-") };
    final ChartPanel barPanel = new ChartPanel(null);
    final ChartPanel linePanel = new ChartPanel(null);
    final ChartPanel piePanel = new ChartPanel(null);
    final DefaultTableModel model = new DefaultTableModel(
            new String[] { "Siswa", "Kuis", "Skor", "Benar", "Salah", "Sync" }, 0) {
        @Override
        public boolean isCellEditable(int r, int c) {
            return false;
        }
    };

    public DashboardApp() {
        super("Dashboard EduTanggap - Kelompok 6");
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(1350, 820);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout(8, 8));
        ((JComponent) getContentPane()).setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        // --- Bagian atas: filter + kartu ringkasan ---
        JPanel atas = new JPanel(new GridLayout(2, 1, 0, 8));

        JPanel filter = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 5));
        filter.setBorder(BorderFactory.createTitledBorder("Filter Data"));
        filter.add(new JLabel("Siswa:"));
        filter.add(cbSiswa);
        filter.add(new JLabel("Mata Pelajaran:"));
        filter.add(cbMapel);
        filter.add(new JLabel("Status Sync:"));
        filter.add(cbStatus);
        JButton btn = new JButton("Terapkan Filter");
        btn.addActionListener(e -> loadData());
        filter.add(btn);
        atas.add(filter);

        JPanel kartu = new JPanel(new GridLayout(1, 4, 10, 0));
        String[] judul = { "Total Siswa", "Rata-rata Skor Kuis", "Rata-rata Kehadiran (%)", "Antrean Sync Pending" };
        for (int i = 0; i < 4; i++)
            kartu.add(buatKartu(judul[i], nilaiCard[i]));
        atas.add(kartu);
        add(atas, BorderLayout.NORTH);

        // --- Bagian tengah: 3 chart + tabel ---
        JPanel tengah = new JPanel(new GridLayout(2, 1, 0, 8));
        JPanel charts = new JPanel(new GridLayout(1, 3, 8, 0));
        charts.add(barPanel);
        charts.add(linePanel);
        charts.add(piePanel);
        tengah.add(charts);

        JScrollPane sp = new JScrollPane(new JTable(model));
        sp.setBorder(BorderFactory.createTitledBorder("Detail Hasil Kuis (VIEW vw_detail_hasil_kuis)"));
        tengah.add(sp);
        add(tengah, BorderLayout.CENTER);

        loadFilter();
        loadData();
    }

    JPanel buatKartu(String judul, JLabel nilai) {
        JPanel p = new JPanel(new GridLayout(2, 1));
        p.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(203, 213, 225)),
                BorderFactory.createEmptyBorder(8, 12, 8, 12)));
        JLabel t = new JLabel(judul);
        t.setForeground(Color.GRAY);
        nilai.setFont(nilai.getFont().deriveFont(Font.BOLD, 24f));
        p.add(t);
        p.add(nilai);
        return p;
    }

    // ====== KONEKSI & BANTUAN QUERY ======
    static Connection conn() throws SQLException {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }

    static PreparedStatement prep(Connection c, String sql, Object... p) throws SQLException {
        PreparedStatement ps = c.prepareStatement(sql);
        for (int i = 0; i < p.length; i++)
            ps.setObject(i + 1, p[i]);
        return ps;
    }

    static String nz(String s) {
        return s == null ? "0" : s;
    }

    // ====== ISI DROPDOWN FILTER ======
    void loadFilter() {
        cbSiswa.addItem(new Item(null, "Semua"));
        cbMapel.addItem(new Item(null, "Semua"));
        try (Connection c = conn()) {
            try (Statement st = c.createStatement();
                    ResultSet rs = st.executeQuery(
                            "SELECT s.id_siswa, u.nama_lengkap FROM siswa s " +
                                    "JOIN user u ON u.id_user = s.id_user ORDER BY u.nama_lengkap")) {
                while (rs.next())
                    cbSiswa.addItem(new Item(rs.getInt(1), rs.getString(2)));
            }
            try (Statement st = c.createStatement();
                    ResultSet rs = st.executeQuery(
                            "SELECT id_mapel, nama_mapel FROM mata_pelajaran ORDER BY nama_mapel")) {
                while (rs.next())
                    cbMapel.addItem(new Item(rs.getInt(1), rs.getString(2)));
            }
        } catch (SQLException e) {
            error(e);
        }
    }

    // ====== AMBIL DATA & GAMBAR CHART ======
    void loadData() {
        Integer siswa = ((Item) cbSiswa.getSelectedItem()).id();
        Integer mapel = ((Item) cbMapel.getSelectedItem()).id();
        String status = cbStatus.getSelectedIndex() == 0 ? null : (String) cbStatus.getSelectedItem();

        try (Connection c = conn()) {
            // Kartu ringkasan
            try (PreparedStatement ps = c.prepareStatement(Q_CARD); ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    for (int i = 0; i < 4; i++)
                        nilaiCard[i].setText(nz(rs.getString(i + 1)));
            }

            // Bar chart
            DefaultCategoryDataset bar = new DefaultCategoryDataset();
            try (PreparedStatement ps = prep(c, Q_BAR, siswa, siswa, mapel, mapel);
                    ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    bar.addValue(rs.getDouble("nilai"), "Progres", rs.getString("label"));
            }
            JFreeChart barChart = ChartFactory.createBarChart(
                    "Rata-rata Progres per Mapel (%)", "Mata Pelajaran", "Progres (%)", bar);
            barChart.removeLegend();
            barPanel.setChart(barChart);

            // Line chart
            DefaultCategoryDataset line = new DefaultCategoryDataset();
            try (PreparedStatement ps = prep(c, Q_LINE, siswa, siswa, status, status);
                    ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    line.addValue(rs.getInt("nilai"), "Aktivitas", rs.getString("label"));
            }
            JFreeChart lineChart = ChartFactory.createLineChart(
                    "Aktivitas Sinkronisasi per Hari", "Tanggal", "Jumlah", line);
            lineChart.removeLegend();
            linePanel.setChart(lineChart);

            // Pie chart
            DefaultPieDataset pie = new DefaultPieDataset();
            try (PreparedStatement ps = prep(c, Q_PIE, siswa, siswa, mapel, mapel);
                    ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    pie.setValue(rs.getString("label"), rs.getInt("nilai"));
            }
            JFreeChart pieChart = ChartFactory.createPieChart("Komposisi Jawaban Kuis", pie, true, true, false);
            PiePlot plot = (PiePlot) pieChart.getPlot();
            plot.setSectionPaint("Benar", new Color(34, 197, 94));
            plot.setSectionPaint("Salah", new Color(239, 68, 68));
            piePanel.setChart(pieChart);

            // Tabel
            model.setRowCount(0);
            try (PreparedStatement ps = prep(c, Q_TABEL, siswa, siswa); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    model.addRow(new Object[] {
                            rs.getString("nama_siswa"), rs.getString("judul_kuis"), rs.getInt("skor"),
                            rs.getInt("benar"), rs.getInt("salah"), rs.getString("status_sync") });
                }
            }
        } catch (SQLException e) {
            error(e);
        }
    }

    void error(SQLException e) {
        JOptionPane.showMessageDialog(this,
                "Gagal terhubung / mengambil data dari database:\n" + e.getMessage(),
                "Error Database", JOptionPane.ERROR_MESSAGE);
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new DashboardApp().setVisible(true));
    }
}
