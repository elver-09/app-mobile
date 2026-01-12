import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';

class AuthController {
  final OdooClient client;
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  AuthController({required this.client});

  Future<OdooAuthResult?> login() async {
    loading = true;
    try {
      return await client.login(
        login: userCtrl.text.trim(),
        password: passCtrl.text,
      );
    } finally {
      loading = false;
    }
  }

  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
  }
}
