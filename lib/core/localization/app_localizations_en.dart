import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  // Common
  @override
  String get appName => 'Alhamra App';
  @override
  String get loading => 'Loading...';
  @override
  String get error => 'Error Occurred';
  @override
  String get success => 'Success';
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'OK';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get search => 'Search';
  @override
  String get filter => 'Filter';
  @override
  String get refresh => 'Refresh';
  @override
  String get back => 'Back';
  @override
  String get next => 'Next';
  @override
  String get previous => 'Previous';
  @override
  String get close => 'Close';
  @override
  String get share => 'Share';

  // Common Actions
  @override
  String get simpan => 'Save';
  @override
  String get hapus => 'Delete';
  @override
  String get tambah => 'Add';
  @override
  String get pilih => 'Select';
  @override
  String get cari => 'Search';
  @override
  String get muat => 'Load';
  @override
  String get kirim => 'Send';
  @override
  String get bagikan => 'Share';
  @override
  String get salin => 'Copy';
  @override
  String get tutup => 'Close';
  @override
  String get buka => 'Open';
  @override
  String get lihat => 'View';
  @override
  String get unduh => 'Download';
  @override
  String get upload => 'Upload';
  @override
  String get ganti => 'Change';
  @override
  String get kembali => 'Back';
  
  // Greetings
  @override
  String get assalamualaikum => 'Assalamualaikum';
  @override
  String get greeting => 'Welcome';
  
  // Navigation
  @override
  String get menu => 'Menu';
  @override
  String get status => 'Status';
  @override
  String get beranda => 'Dashboard';
  @override
  String get aktivitas => 'Activities';
  @override
  String get akun => 'Account';
  @override
  String get profile => 'Profile';
  
  // Beranda/Dashboard
  @override
  String get semua => 'All';
  @override
  String get keuangan => 'Finance';
  @override
  String get kesantrian => 'Islamic Studies';
  @override
  String get akademik => 'Academic';
  @override
  String get statistika => 'Statistics';
  @override
  String get totalTagihanAktif => 'Total Active Bills';
  @override
  String get saldoUangSaku => 'Pocket Money Balance';
  @override
  String get saldoWallet => 'Wallet Balance';
  @override
  String get lunas => 'Paid';
  @override
  String get kurang => 'Outstanding';
  @override
  String get totalHafalan => 'Total Memorization';
  @override
  String get semesterIni => 'This Semester';
  @override
  String get totalAbsen => 'Total Absence';
  @override
  String get rataRataNilai => 'Average Score';
  @override
  String get perkembanganNilai => 'Score Development (6 Months)';
  
  // Student Selection
  @override
  String get pilihSantri => 'Select Student';
  @override
  String get cariSantri => 'Search student...';
  
  // Financial
  @override
  String get pembayaran => 'Payment';
  @override
  String get tagihan => 'Bills';
  @override
  String get uangSaku => 'Pocket Money';
  @override
  String get dompet => 'Wallet';
  @override
  String get saldo => 'Balance';
  @override
  String get bayar => 'Pay';
  @override
  String get topUp => 'Top Up';
  @override
  String get riwayat => 'History';
  @override
  String get transaksi => 'Transaction';
  @override
  String get detailPembayaran => 'Payment Details';
  @override
  String get statusPembayaran => 'Payment Status';
  @override
  String get menungguPembayaran => 'Waiting for Payment';
  @override
  String get pembayaranBerhasil => 'Payment Successful';
  
  // Payment Types
  @override
  String get uangTahunan => 'Annual Fee';
  @override
  String get sppSantri => 'Monthly Tuition';
  @override
  String get seragam => 'Uniform';
  @override
  String get uangPembangunan => 'Development Fee';
  @override
  String get uangSumbangan => 'Donation';
  
  // Payment Labels
  @override
  String get namaSantri => 'Student Name';
  @override
  String get nominalBayar => 'Payment Amount';
  @override
  String get tenggatBayar => 'Due Date';
  @override
  String get dikonfirmasi => 'Confirmed';
  
  // Activities
  @override
  String get detailAktivitas => 'Activity Details';
  @override
  String get jenisAktivitas => 'Activity Type';
  @override
  String get tanggal => 'Date';
  @override
  String get waktu => 'Time';
  @override
  String get dicatatOleh => 'Recorded by';
  @override
  String get keterangan => 'Description';
  @override
  String get lihatDetail => 'View Details';
  @override
  String get pelanggaran => 'Violation';
  @override
  String get perizinan => 'Permission';
  @override
  String get kesehatan => 'Health';
  @override
  String get statusKesehatan => 'Health Status';
  @override
  String get statusPerizinan => 'Permission Status';
  @override
  String get statusPelanggaran => 'Violation Status';
  @override
  String get semuaStatus => 'All Status';
  
  // Academic
  @override
  String get nilai => 'Grades';
  @override
  String get absensi => 'Attendance';
  @override
  String get tahfidz => 'Quran Memorization';
  @override
  String get tahsin => 'Quran Recitation';
  @override
  String get mutabaah => 'Daily Activities';
  @override
  String get infoAkademik => 'Academic Info';
  
  // Profile
  @override
  String get editProfile => 'Edit Profile';
  @override
  String get ubahKataSandi => 'Change Password';
  @override
  String get keamanan => 'Security';
  @override
  String get bantuan => 'Help';
  @override
  String get tentangAplikasi => 'About App';
  @override
  String get ketentuanLayanan => 'Terms of Service';
  @override
  String get logout => 'Logout';
  
  // Settings
  @override
  String get pengaturan => 'Settings';
  @override
  String get bahasa => 'Language';
  @override
  String get bahasaIndonesia => 'Indonesian';
  @override
  String get bahasaInggris => 'English';
  @override
  String get pilihBahasa => 'Select Language';
  @override
  String get ubahBahasa => 'Change Language';
  
  // Additional Profile Strings
  @override
  String get daftarAnak => 'Children List';
  @override
  String get pusatKeamanan => 'Security Center';
  @override
  String get informasiAplikasi => 'App Information';
  @override
  String get anakYangDipilih => 'Selected child';
  
  // Time & Date
  @override
  String get hari => 'Day';
  @override
  String get bulan => 'Month';
  @override
  String get tahun => 'Year';
  @override
  String get jam => 'Hour';
  @override
  String get menit => 'Minute';
  @override
  String get detik => 'Second';
  @override
  String get wib => 'WIB';
  
  // Messages
  @override
  String get tidakAdaData => 'No data available';
  @override
  String get gagalMemuatData => 'Failed to load data';
  @override
  String get berhasilDisimpan => 'Successfully saved';
  @override
  String get gagalMenyimpan => 'Failed to save';
  @override
  String get konfirmasiHapus => 'Delete Confirmation';
  @override
  String get yakinInginMenghapus => 'Are you sure you want to delete?';
  
  // News
  @override
  String get berita => 'News';
  @override
  String get terbaru => 'Latest';
  @override
  String get bulanLalu => 'Last Month';
  @override
  String get bacaSelengkapnya => 'Read More';
  
  // Facilities
  @override
  String get fasilitas => 'Facilities';
  @override
  String get informasiFasilitas => 'Facility Information';
  
  // Dashboard Content
  @override
  String get lihatSemua => 'View All';
  @override
  String get rp => 'IDR';
  @override
  String get bulanIni => 'This Month';
  @override
  String get tahunIni => 'This Year';
  @override
  String get semester => 'Semester';
  @override
  String get minggu => 'Week';
  @override
  String get persen => '%';
  @override
  String get dari => 'from';
  @override
  String get ke => 'to';
  
  // Financial Content
  @override
  String get totalTagihan => 'Total Bills';
  @override
  String get belumLunas => 'Unpaid';
  @override
  String get sudahLunas => 'Paid';
  @override
  String get jatuhTempo => 'Due Date';
  @override
  String get terlambat => 'Overdue';
  @override
  String get cicilan => 'Installment';
  @override
  String get lunasPenuh => 'Fully Paid';
  @override
  String get metodePembayaran => 'Payment Method';
  @override
  String get nomorRekening => 'Account Number';
  @override
  String get namaBank => 'Bank Name';
  @override
  String get atasNama => 'Account Holder';
  @override
  String get jumlahPembayaran => 'Payment Amount';
  @override
  String get biayaAdmin => 'Admin Fee';
  @override
  String get totalBayar => 'Total Payment';
  
  // Activity Content
  @override
  String get aktivitasTerbaru => 'Recent Activities';
  @override
  String get tidakAdaAktivitas => 'No Activities';
  @override
  String get muatLebihBanyak => 'Load More';
  @override
  String get kategoriAktivitas => 'Activity Category';
  @override
  String get filterTanggal => 'Date Filter';
  @override
  String get urutkanBerdasarkan => 'Sort By';
  @override
  String get terlama => 'Oldest';
  
  // Activity Sample Data
  @override
  String get terlambatApel => 'Late for morning assembly';
  @override
  String get tidakSeragam => 'Not wearing complete uniform';
  @override
  String get meninggalkanKelas => 'Leaving class without permission';
  @override
  String get keributan => 'Making noise in dormitory';
  @override
  String get izinPulang => 'Permission to go home (family event)';
  @override
  String get izinSakit => 'Permission to skip activity (sick)';
  @override
  String get izinKeluar => 'Permission to go out for shopping';
  @override
  String get pemeriksaanRutin => 'Routine clinic examination';
  @override
  String get sakitDemam => 'Sick (fever and cough)';
  @override
  String get konsultasiKesehatan => 'Health consultation';
  
  // Academic Content
  @override
  String get nilaiRataRata => 'Average Score';
  @override
  String get kehadiran => 'Attendance';
  @override
  String get tugasDikumpulkan => 'Assignments Submitted';
  @override
  String get ujianMendatang => 'Upcoming Exams';
  @override
  String get prestasi => 'Achievements';
  @override
  String get peringkatKelas => 'Class Rank';
  @override
  String get mataPelajaran => 'Subject';
  @override
  String get guru => 'Teacher';
  @override
  String get jadwalPelajaran => 'Class Schedule';
  
  // Islamic Studies Content
  @override
  String get hafalanQuran => 'Quran Memorization';
  @override
  String get bacaanQuran => 'Quran Reading';
  @override
  String get doaHarian => 'Daily Prayers';
  @override
  String get akhlakMulia => 'Noble Character';
  @override
  String get ibadahHarian => 'Daily Worship';
  @override
  String get kajianIslam => 'Islamic Studies';
  @override
  String get surat => 'Chapter';
  @override
  String get ayat => 'Verse';
  @override
  String get juz => 'Juz';
  @override
  String get halaman => 'Page';
  
  // Navigation
  @override
  String get notifikasi => 'Notifications';
  
  // Actions
  @override
  String get cetak => 'Print';
  
  // Status
  @override
  String get aktif => 'Active';
  @override
  String get nonaktif => 'Inactive';
  @override
  String get diproses => 'Processing';
  @override
  String get selesai => 'Completed';
  @override
  String get dibatalkan => 'Cancelled';
  
  // Empty States
  @override
  String get tidakAdaTagihan => 'No bills';
  @override
  String get tidakAdaPembayaran => 'No payments';
  @override
  String get tidakAdaDataKesehatan => 'No health data';
  @override
  String get tidakAdaDataPerizinan => 'No permission data';
  @override
  String get tidakAdaDataPelanggaran => 'No violation data';
  @override
  String get tidakAdaFasilitas => 'No facilities';
  @override
  String get tidakAdaJadwal => 'No schedule for today';
  @override
  String get tidakAdaDataCocok => 'No matching data';
  @override
  String get cobaUbahFilter => 'Try changing filter or period';
  @override
  String get cobaUbahKategori => 'Try changing category or refresh page';
  
  // Detail Labels
  @override
  String get keteranganLengkap => 'Full Description';
  @override
  String get keteranganAlpa => 'Absence Note';
  @override
  String get alasanIzin => 'Permission Reason';
  @override
  String get nominalPembayaran => 'Payment Amount';
  @override
  String get saldoSetelahTransaksi => 'Balance After Transaction';
  @override
  String get jumlahBaris => 'Number of Lines';
  @override
  String get ustadPembimbing => 'Supervising Teacher';
  @override
  String get pencatat => 'Recorder';

  // Kesantrian Content
  @override
  String get totalIzin => 'Total Permission';
  @override
  String get totalSetoran => 'Total Submission';
  @override
  String get setoranSetoran => 'Submission';
  @override
  String get setoranTerakhir => 'Last Submission';
  @override
  String get perkembanganSetoran => 'Submission Progress';
  @override
  String get mutabaahHarian => 'Daily Mutabaah';
  @override
  String get skorHariIni => 'Today\'s Score';
  @override
  String get aktivitasKesehatan => 'Activities & Health';
  @override
  String get perihal => 'Issue';
  @override
  String get terapiKesehatan => 'Health Therapy';
  @override
  String get totalSakitSemesterIni => 'Total Sick Days This Semester';
  @override
  String get jenisPelanggaran => 'Type of Violation';
}
