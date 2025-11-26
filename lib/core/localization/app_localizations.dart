import 'package:flutter/material.dart';
import 'app_localizations_id.dart';
import 'app_localizations_en.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
  ];
  static const List<Locale> supportedLocales = [
    Locale('id', 'ID'),
    Locale('en', 'US'),
  ];

  // Common
  String get appName;
  String get loading;
  String get error;
  String get success;
  String get cancel;
  String get ok;
  String get save;
  String get search;
  String get back;
  String get next;
  String get previous;
  String get close;
  String get share;

  // Common Actions
  String get simpan;
  String get hapus;
  String get delete;
  String get edit;
  String get tambah;
  String get pilih;
  String get cari;
  String get filter;
  String get refresh;
  String get muat;
  String get kirim;
  String get bagikan;
  String get salin;
  String get tutup;
  String get buka;
  String get lihat;
  String get unduh;
  String get upload;
  String get ganti;
  String get kembali;
  
  // Greetings
  String get assalamualaikum;
  String get greeting;
  
  // Navigation
  String get menu;
  String get status;
  String get beranda;
  String get aktivitas;
  String get akun;
  String get profile;
  
  // Beranda/Dashboard
  String get semua;
  String get keuangan;
  String get kesantrian;
  String get akademik;
  String get statistika;
  String get totalTagihanAktif;
  String get saldoUangSaku;
  String get saldoWallet;
  String get lunas;
  String get kurang;
  String get totalHafalan;
  String get semesterIni;
  String get totalAbsen;
  String get rataRataNilai;
  String get perkembanganNilai;
  
  // Student Selection
  String get pilihSantri;
  String get cariSantri;
  
  // Financial
  String get pembayaran;
  String get tagihan;
  String get uangSaku;
  String get dompet;
  String get saldo;
  String get bayar;
  String get topUp;
  String get riwayat;
  String get transaksi;
  String get detailPembayaran;
  String get statusPembayaran;
  String get menungguPembayaran;
  String get pembayaranBerhasil;
  
  // Payment Types
  String get uangTahunan;
  String get sppSantri;
  String get seragam;
  String get uangPembangunan;
  String get uangSumbangan;
  
  // Payment Labels
  String get namaSantri;
  String get nominalBayar;
  String get tenggatBayar;
  String get dikonfirmasi;
  
  // Activities
  String get detailAktivitas;
  String get jenisAktivitas;
  String get tanggal;
  String get waktu;
  String get dicatatOleh;
  String get keterangan;
  String get lihatDetail;
  String get pelanggaran;
  String get perizinan;
  String get kesehatan;
  String get statusKesehatan;
  String get statusPerizinan;
  String get statusPelanggaran;
  String get semuaStatus;
  
  // Academic
  String get nilai;
  String get absensi;
  String get tahfidz;
  String get tahsin;
  String get mutabaah;
  String get infoAkademik;
  
  // Profile
  String get editProfile;
  String get ubahKataSandi;
  String get keamanan;
  String get bantuan;
  String get tentangAplikasi;
  String get ketentuanLayanan;
  String get logout;
  
  // Settings
  String get pengaturan;
  String get bahasa;
  String get bahasaIndonesia;
  String get bahasaInggris;
  String get pilihBahasa;
  String get ubahBahasa;
  
  // Additional Profile Strings
  String get daftarAnak;
  String get pusatKeamanan;
  String get informasiAplikasi;
  String get anakYangDipilih;
  
  // Time & Date
  String get hari;
  String get bulan;
  String get tahun;
  String get jam;
  String get menit;
  String get detik;
  String get wib;
  
  // Messages
  String get tidakAdaData;
  String get gagalMemuatData;
  String get berhasilDisimpan;
  String get gagalMenyimpan;
  String get konfirmasiHapus;
  String get yakinInginMenghapus;
  
  // News
  String get berita;
  String get terbaru;
  String get bulanLalu;
  String get bacaSelengkapnya;
  
  // Facilities
  String get fasilitas;
  String get informasiFasilitas;
  
  // Dashboard Content
  String get lihatSemua;
  String get rp;
  String get bulanIni;
  String get tahunIni;
  String get semester;
  String get minggu;
  String get persen;
  String get dari;
  String get ke;
  
  // Financial Content
  String get totalTagihan;
  String get belumLunas;
  String get sudahLunas;
  String get jatuhTempo;
  String get terlambat;
  String get cicilan;
  String get lunasPenuh;
  String get metodePembayaran;
  String get nomorRekening;
  String get namaBank;
  String get atasNama;
  String get jumlahPembayaran;
  String get biayaAdmin;
  String get totalBayar;
  
  // Activity Content
  String get aktivitasTerbaru;
  String get tidakAdaAktivitas;
  String get muatLebihBanyak;
  String get kategoriAktivitas;
  String get filterTanggal;
  String get urutkanBerdasarkan;
  String get terlama;
  
  // Activity Sample Data
  String get terlambatApel;
  String get tidakSeragam;
  String get meninggalkanKelas;
  String get keributan;
  String get izinPulang;
  String get izinSakit;
  String get izinKeluar;
  String get pemeriksaanRutin;
  String get sakitDemam;
  String get konsultasiKesehatan;
  
  // Academic Content
  String get nilaiRataRata;
  String get kehadiran;
  String get tugasDikumpulkan;
  String get ujianMendatang;
  String get prestasi;
  String get peringkatKelas;
  String get mataPelajaran;
  String get guru;
  String get jadwalPelajaran;
  
  // Islamic Studies Content
  String get hafalanQuran;
  String get bacaanQuran;
  String get doaHarian;
  String get akhlakMulia;
  String get ibadahHarian;
  String get kajianIslam;
  String get surat;
  String get ayat;
  String get juz;
  String get halaman;
  
  // Navigation
  String get notifikasi;
  
  // Actions
  String get cetak;
  
  // Status
  String get aktif;
  String get nonaktif;
  String get diproses;
  String get selesai;
  String get dibatalkan;
  
  // Empty States
  String get tidakAdaTagihan;
  String get tidakAdaPembayaran;
  String get tidakAdaDataKesehatan;
  String get tidakAdaDataPerizinan;
  String get tidakAdaDataPelanggaran;
  String get tidakAdaFasilitas;
  String get tidakAdaJadwal;
  String get tidakAdaDataCocok;
  String get cobaUbahFilter;
  String get cobaUbahKategori;
  
  // Detail Labels
  String get keteranganLengkap;
  String get keteranganAlpa;
  String get alasanIzin;
  String get nominalPembayaran;
  String get saldoSetelahTransaksi;
  String get jumlahBaris;
  String get ustadPembimbing;
  String get pencatat;

  // Kesantrian Content
  String get totalIzin;
  String get totalSetoran;
  String get setoranSetoran;
  String get setoranTerakhir;
  String get perkembanganSetoran;
  String get mutabaahHarian;
  String get skorHariIni;
  String get aktivitasKesehatan;
  String get perihal;
  String get terapiKesehatan;
  String get totalSakitSemesterIni;
  String get jenisPelanggaran;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['id', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return AppLocalizationsEn();
      case 'id':
      default:
        return AppLocalizationsId();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
