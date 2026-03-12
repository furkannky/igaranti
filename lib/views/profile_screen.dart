import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Current user info (Mocked for now since auth service might not expose details directly,
    // though we can get email from Firebase Auth if needed)
    final String userEmail = AuthService().currentUser?.email ?? "Kullanıcı";

    // Extract name from email (take part before @)
    String displayName = "Kullanıcı";
    if (userEmail != "Kullanıcı" && userEmail.contains('@')) {
      displayName = userEmail.split('@')[0];
      // Capitalize first letter
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
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Merhaba,",
                            style: TextStyle(
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
            const SizedBox(height: 24),

            // Hesap İşlemleri
            _buildSettingsGroup(
              title: "Hesap İşlemleri",
              children: [
                _buildListTile(
                  icon: Icons.logout,
                  iconColor: Colors.redAccent,
                  title: "Çıkış Yap",
                  titleColor: Colors.redAccent,
                  onTap: () async {
                    // Kullanıcıya onay sorabiliriz
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
                      // SignOut yapıldığında auth wrapper otomatik olarak login ekranına atacaktır.
                      // Navigator.pop() gerek yok, auth state changes yönlendirme yapar
                    }
                  },
                ),
              ],
            ),
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
    required VoidCallback onTap,
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
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.white54,
      ),
      onTap: onTap,
    );
  }
}
