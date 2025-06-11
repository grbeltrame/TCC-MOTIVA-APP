// lib/features/auth/presentation/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/app_dialog.dart';

/// -----FORGOT PASSWORD FLOW - STEP 3-----
/// Tela para o usuário inserir e confirmar a nova senha após verificar o código.
class ResetPasswordScreen extends StatefulWidget {
  static const String routeName = '/resetPassword';

  /// E-mail recebido na etapa anterior.
  final String email;
  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Regras de senha
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordRules);
  }

  void _validatePasswordRules() {
    final pwd = _passwordController.text;
    setState(() {
      _hasMinLength = pwd.length >= 8;
      _hasUppercase = pwd.contains(RegExp(r'[A-Z]'));
      _hasLowercase = pwd.contains(RegExp(r'[a-z]'));
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePasswordRules);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// BACKEND TODO: implementar reset de senha via API
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // BACKEND TODO: chamar resetPassword(email, newPassword)
      await Future.delayed(const Duration(seconds: 1)); // simula delay

      // Sucesso: mostra diálogo antes de navegar
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AppDialog(
              icon: Icons.check_sharp,
              title: 'Sua senha foi alterada',
              message: 'Você será redirecionado para a página de login.',
              primaryAction: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkBlue,
                ),
                child: Text('OK'),
              ),
            ),
      );

      // Volta para a tela de login
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (_) {
      setState(() => _errorMessage = 'Falha ao redefinir senha');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRuleItem(String text, bool passed, double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: passed ? Colors.green : AppColors.mediumGray,
          size: 16 * scale,
        ),
        SizedBox(width: 4 * scale),
        Text(
          text,
          style: TextStyle(
            fontSize: 12 * scale,
            color: passed ? Colors.green : AppColors.mediumGray,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375.0;
    double vSpace(double val) => val * scale;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: vSpace(32)),
              // Voltar para Login
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  size: 20 * scale,
                  color: AppColors.darkBlue,
                ),
                label: Text(
                  'Voltar',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 14 * scale,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
              SizedBox(height: vSpace(48)),

              // Título
              Text(
                'Nova senha',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 26 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: vSpace(8)),
              Text(
                'Redefina sua senha para:',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.regular,
                  fontSize: 16 * scale,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                widget.email,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 16 * scale,
                  color: AppColors.darkBlue,
                ),
              ),
              SizedBox(height: vSpace(24)),

              // Formulário de senhas
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nova senha
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Nova senha',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8 * scale),
                          borderSide: BorderSide(color: AppColors.mediumGray),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: vSpace(12),
                          horizontal: vSpace(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 24 * scale,
                          ),
                          onPressed:
                              () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null ||
                            !_hasMinLength ||
                            !_hasUppercase ||
                            !_hasLowercase) {
                          return 'Senha não atende aos requisitos';
                        }
                        return null;
                      },
                    ),

                    // Regras de senha lado a lado
                    SizedBox(height: vSpace(12)),
                    Wrap(
                      spacing: vSpace(16),
                      runSpacing: vSpace(8),
                      children: [
                        _buildRuleItem(
                          'Mínimo 8 caracteres',
                          _hasMinLength,
                          scale,
                        ),
                        _buildRuleItem(
                          'Uma letra maiúscula',
                          _hasUppercase,
                          scale,
                        ),
                        _buildRuleItem(
                          'Uma letra minúscula',
                          _hasLowercase,
                          scale,
                        ),
                      ],
                    ),
                    SizedBox(height: vSpace(24)),

                    // Confirmar senha
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirmar senha',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8 * scale),
                          borderSide: BorderSide(color: AppColors.mediumGray),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: vSpace(12),
                          horizontal: vSpace(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 24 * scale,
                          ),
                          onPressed:
                              () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'As senhas devem ser iguais';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: vSpace(16)),

                    // Erro do backend
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12 * scale,
                        ),
                      ),
                      SizedBox(height: vSpace(8)),
                    ],

                    // Botão trocar senha
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: AppColors.darkBlue,
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: vSpace(48),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8 * scale),
                            ),
                          ),
                          onPressed: _resetPassword,
                          child: Text(
                            'Trocar senha',
                            style: TextStyle(
                              fontFamily: AppFonts.montserrat,
                              fontWeight: AppFontWeight.bold,
                              fontSize: 16 * scale,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: vSpace(32)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
