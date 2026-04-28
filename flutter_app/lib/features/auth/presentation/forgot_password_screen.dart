import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/utils/form_fields.dart';
import 'package:flutter_app/shared/widgets/utils/primary_button.dart';

/// Solicita o email do usuario e envia o link de redefinicao pelo Firebase.
class ForgotPasswordScreen extends StatefulWidget {
  static const String routeName = '/forgotPassword';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String _submittedEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _messageForError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Informe um email valido para continuar.';
      case 'network-request-failed':
        return 'Nao foi possivel conectar. Verifique sua internet e tente novamente.';
      case 'too-many-requests':
        return 'Muitas tentativas em pouco tempo. Aguarde um pouco e tente novamente.';
      default:
        return 'Nao foi possivel enviar o email agora. Tente novamente em instantes.';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.sendPasswordResetEmail(email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
        _submittedEmail = email;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showSnackBar(_messageForError(error));
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        'Nao foi possivel enviar o email agora. Tente novamente em instantes.',
      );
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetFlow() {
    setState(() {
      _emailSent = false;
      _submittedEmail = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    double vSpace(double value) => value * scale;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 32 * scale,
            left: 24 * scale,
            right: 24 * scale,
            bottom: 24 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackButton(),
              SizedBox(height: vSpace(64)),
              if (_emailSent) ...[
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 52 * scale,
                  color: AppColors.darkBlue,
                ),
                SizedBox(height: vSpace(20)),
                Text(
                  'Verifique seu email',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 26 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: vSpace(8)),
                Text(
                  'Se existir uma conta vinculada a $_submittedEmail, enviamos um link para redefinir sua senha.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.regular,
                    fontSize: 16 * scale,
                    color: AppColors.darkText,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: vSpace(12)),
                Text(
                  'Confira tambem a pasta de spam ou lixo eletronico.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.regular,
                    fontSize: 14 * scale,
                    color: AppColors.mediumGray,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: vSpace(32)),
                PrimaryButton(label: 'Usar outro email', onPressed: _resetFlow),
                SizedBox(height: vSpace(12)),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      'Voltar',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 14 * scale,
                        color: AppColors.darkBlue,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Esqueceu sua senha?',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 26 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: vSpace(8)),
                Text(
                  'Informe seu email e enviaremos um link para redefinir sua senha.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.regular,
                    fontSize: 16 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: vSpace(53)),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      EmailInputField(
                        controller: _emailController,
                        requireExists: false,
                      ),
                      SizedBox(height: vSpace(32)),
                      PrimaryButton(
                        label: 'Enviar email',
                        isLoading: _isLoading,
                        onPressed: _sendResetEmail,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: vSpace(16)),
                Text(
                  'Se o email estiver cadastrado, voce recebera as instrucoes para redefinir sua senha.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.regular,
                    fontSize: 13 * scale,
                    color: AppColors.mediumGray,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
