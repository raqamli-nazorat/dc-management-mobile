import 'package:dcmanagement/colors/app_colors.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/image.png"),
            fit: BoxFit.cover,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Padding(
            padding: EdgeInsetsGeometry.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  textAlign: TextAlign.start,
                  "Raqamli boshqaruv tizimiga xush kelibsiz",
                  style: TextStyle(
                    height: 1.2,
                    leadingDistribution: TextLeadingDistribution.even,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  textAlign: TextAlign.start,
                  "Loyihalar, vazifalar va moliyani bitta platformada boshqaring",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEEF2),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B6EF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                "R",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Raqamli Nazorat",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 🔵 Title
                      const Text(
                        "Kirish",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🔵 Login input
                      _inputField("Login"),

                      const SizedBox(height: 12),

                      // 🔵 Password input
                      _inputField("Parol", isPassword: true),

                      const SizedBox(height: 20),

                      // 🔵 Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.dark().accentStrong,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            "Kirish",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 reusable input
  Widget _inputField(String hint, {bool isPassword = false}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4E6EB),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
      ),
    );
  }
}
