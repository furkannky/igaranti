import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'notification_settings_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isGuest = user == null;

    final String userEmail = user?.email ?? "";
    String displayName = "Misafir Kullanıcı";

    if (!isGuest && userEmail.contains('@')) {
      displayName = userEmail.split('@')[0];
      displayName =
          displayName[0].toUpperCase() + displayName.substring(1).toLowerCase();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profil ve Ayarlar",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profil Özeti Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: isGuest
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.blueAccent.withValues(alpha: 0.1),
                      child: Icon(
                        isGuest ? Icons.person_outline : Icons.person,
                        size: 40,
                        color: isGuest ? Colors.grey : Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGuest ? "Hoş Geldiniz," : "Merhaba,",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isGuest)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D4FF),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Giriş Yap",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ayarlar Listesi
            _buildSettingsGroup(
              title: "Uygulama Ayarları",
              children: [
                _buildListTile(
                  icon: Icons.notifications_active,
                  iconColor: Colors.orange,
                  title: "Bildirim Ayarları",
                  subtitle: "Hatırlatma tercihleri, titreşim ve ses",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            // Hesap İşlemleri (Sadece giriş yapmış kullanıcılar için)
            if (!isGuest) ...[
              const SizedBox(height: 24),
              _buildSettingsGroup(
                title: "Hesap İşlemleri",
                children: [
                  _buildListTile(
                    icon: Icons.logout,
                    iconColor: Colors.redAccent,
                    title: "Çıkış Yap",
                    titleColor: Colors.redAccent,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Çıkış Yap"),
                          content: const Text(
                            "Hesabınızdan çıkış yapmak istediğinize emin misiniz?",
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("İptal"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Çıkış Yap"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await AuthService().signOut();
                        if (context.mounted) {
                          // main.dart'taki ValueKey sayesinde MainScreen zaten Panel'e sıfırlanacak,
                          // ama biz Navigator stack'ini temizleyerek en başa (ana ekrana) dönmeyi garantiliyoruz.
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white60,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor ?? Colors.white,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
