import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/app_styles.dart';

class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.greyColor,
      body: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppStyles.primaryColor,
                  AppStyles.secondaryColor,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Bantuan',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: AppStyles.getResponsiveFontSize(context, 
                          small: 18.0, medium: 19.0, large: 20.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // FAQ List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16), 
              children: [
          _buildFAQItem(
            context,
            'Bagaimana cara mendapatkan akun aplikasi ini?',
            'Untuk mendapatkan akun aplikasi Alhamra, Anda perlu menghubungi pihak sekolah atau admin. Akun akan diberikan setelah santri terdaftar di sistem.',
          ),
          _buildFAQItem(
            context,
            'Saya lupa password akun saya, bagaimana cara mengatasinya?',
            'Jika Anda lupa password, silakan hubungi admin sekolah. Admin akan membantu mereset password Anda.',
          ),
          _buildFAQItem(
            context,
            'Saya tidak bisa login ke aplikasi, apa penyebabnya?',
            'Beberapa kemungkinan penyebab:\n1. Username atau password salah\n2. Koneksi internet bermasalah\n3. Akun belum diaktifkan\n4. Server sedang maintenance\n\nSilakan periksa koneksi internet Anda dan pastikan username/password benar. Jika masih bermasalah, hubungi admin.',
          ),
          _buildFAQItem(
            context,
            'Aplikasi tidak bisa dibuka atau force close (keluar sendiri)?',
            'Coba lakukan langkah berikut:\n1. Restart aplikasi\n2. Clear cache aplikasi\n3. Update aplikasi ke versi terbaru\n4. Restart smartphone Anda\n5. Reinstall aplikasi jika masih bermasalah\n\nJika masalah berlanjut, hubungi tim support.',
          ),
          _buildFAQItem(
            context,
            'Apakah saya bisa mengganti atau membuat akun sendiri?',
            'Tidak. Akun hanya dapat dibuat dan dikelola oleh admin sekolah. Ini untuk menjaga keamanan data dan memastikan setiap akun terhubung dengan data santri yang benar.',
          ),
          _buildFAQItem(
            context,
            'Apakah aplikasi bisa digunakan tanpa koneksi internet?',
            'Sebagian besar fitur memerlukan koneksi internet untuk mengakses data terbaru. Namun, beberapa data yang sudah di-cache mungkin masih bisa dilihat secara offline.',
          ),
          _buildFAQItem(
            context,
            'Apakah saya boleh login di beberapa perangkat sekaligus?',
            'Ya, Anda dapat login di beberapa perangkat. Namun, untuk keamanan, pastikan Anda logout dari perangkat yang tidak digunakan.',
          ),
          _buildFAQItem(
            context,
            'Saya mengalami kendala lain yang tidak disebutkan di atas. Apa yang harus saya lakukan?',
            'Silakan hubungi kami melalui:\n\nTelepon: 0812-xxxx-xxxx\nEmail: info@ibsalhamra.sch.id\nWhatsApp: 0812-xxxx-xxxx\n\nTim support kami siap membantu Anda.',
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: AppStyles.getResponsiveFontSize(context, 
                small: 13.0, medium: 14.0, large: 15.0),
              fontWeight: FontWeight.w500,
              color: AppStyles.darkGreyColor,
              height: 1.4,
            ),
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down,
            color: AppStyles.primaryColor,
            size: 24,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: GoogleFonts.poppins(
                  fontSize: AppStyles.getResponsiveFontSize(context, 
                    small: 12.0, medium: 13.0, large: 14.0),
                  color: AppStyles.mediumGreyColor,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}