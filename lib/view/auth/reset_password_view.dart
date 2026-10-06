import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/services/auth_service.dart';

class ResetPasswordView extends StatefulWidget {
  final String email;
  const ResetPasswordView({super.key, required this.email});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _codeCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePw = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    final pw = _pwCtrl.text;
    final confirm = _confirmPwCtrl.text;

    if (code.isEmpty || pw.isEmpty) {
      Fluttertoast.showToast(msg: 'Please fill in all fields');
      return;
    }
    if (pw != confirm) {
      Fluttertoast.showToast(msg: 'Passwords do not match');
      return;
    }
    if (pw.length < 8) {
      Fluttertoast.showToast(msg: 'Password must be at least 8 characters');
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService.confirmNewPassword(
      email: widget.email,
      code: code,
      newPassword: pw,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: 'Password reset successful. Please log in.');
      Get.until((route) => route.isFirst);
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? 'Reset failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Enter the code sent to ${widget.email}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                hintText: '6-digit code',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pwCtrl,
              obscureText: _obscurePw,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePw ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPwCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Reset Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
