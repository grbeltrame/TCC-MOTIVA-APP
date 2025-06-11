// lib/shared/widgets/form_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Campo de texto para e-mail com validações de formato e backend.
class EmailInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool requireExists;

  const EmailInputField({
    Key? key,
    required this.controller,
    this.label = 'Email',
    this.hint = 'ex: usuario@dominio.com',
    this.requireExists = false,
  }) : super(key: key);

  @override
  _EmailInputFieldState createState() => _EmailInputFieldState();
}

class _EmailInputFieldState extends State<EmailInputField> {
  final _formKey = GlobalKey<FormFieldState<String>>();
  late FocusNode _focusNode;
  String? _backendError;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusLost);
  }

  void _onFocusLost() {
    if (!_focusNode.hasFocus && widget.requireExists) {
      final email = widget.controller.text;
      // TODO: chamar backend para verificar existência do e-mail
      // Exemplo:
      // final exists = await AuthService.checkEmailExists(email);
      // if (!exists) setState(() => _backendError = 'Email não cadastrado');
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusLost);
    _focusNode.dispose();
    super.dispose();
  }

  String? _validator(String? value) {
    if (value == null || value.isEmpty) return 'Informe seu email';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return 'Formato de email inválido';
    return _backendError;
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return TextFormField(
      key: _formKey,
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.light,
          fontSize: 12 * scale,
          color: AppColors.darkText,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: widget.hint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.regular,
          fontSize: 14 * scale,
          color: AppColors.mediumGray,
        ),
        filled: true,
        fillColor: AppColors.offWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4 * scale),
          borderSide: BorderSide(color: AppColors.mediumGray),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: 12 * scale,
          horizontal: 12 * scale,
        ),
        errorText: _backendError,
      ),
      validator: _validator,
    );
  }
}

/// Campo de texto para senha com regras de validação inline e backend.
class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final TextEditingController? confirmController;
  final String label;
  final String hint;
  final bool requireRules;
  final bool requireAssociation;

  const PasswordInputField({
    Key? key,
    required this.controller,
    this.confirmController,
    this.label = 'Senha',
    this.hint = '********',
    this.requireRules = false,
    this.requireAssociation = false,
  }) : super(key: key);

  @override
  _PasswordInputFieldState createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscure = true;
  final _formKey = GlobalKey<FormFieldState<String>>();
  String? _backendError;

  // Indicadores de regra
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;

  @override
  void initState() {
    super.initState();
    if (widget.requireRules) {
      widget.controller.addListener(_validateRules);
    }
  }

  void _validateRules() {
    final pwd = widget.controller.text;
    final minLen = pwd.length >= 8;
    final hasUp = pwd.contains(RegExp(r'[A-Z]'));
    final hasLow = pwd.contains(RegExp(r'[a-z]'));
    if (minLen != _hasMinLength ||
        hasUp != _hasUppercase ||
        hasLow != _hasLowercase) {
      setState(() {
        _hasMinLength = minLen;
        _hasUppercase = hasUp;
        _hasLowercase = hasLow;
      });
    }
  }

  @override
  void dispose() {
    if (widget.requireRules) widget.controller.removeListener(_validateRules);
    super.dispose();
  }

  String? _validator(String? value) {
    if (value == null || value.isEmpty) return 'Informe sua senha';
    if (widget.requireRules) {
      if (!_hasMinLength) return 'Mínimo 8 caracteres';
      if (!_hasUppercase) return 'Requer letra maiúscula';
      if (!_hasLowercase) return 'Requer letra minúscula';
    }
    if (widget.confirmController != null &&
        value != widget.confirmController!.text) {
      return 'Senhas não coincidem';
    }
    return _backendError;
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: _formKey,
          controller: widget.controller,
          obscureText: _obscure,
          onFieldSubmitted: (v) {
            if (widget.requireAssociation) {
              // TODO: chamar backend para associação e-mail+senha
            }
          },
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.light,
              fontSize: 12 * scale,
              color: AppColors.darkText,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.regular,
              fontSize: 14 * scale,
              color: AppColors.mediumGray,
            ),
            filled: true,
            fillColor: AppColors.offWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4 * scale),
              borderSide: BorderSide(color: AppColors.mediumGray),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: 12 * scale,
              horizontal: 12 * scale,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                color: AppColors.mediumGray,
                size: 24 * scale,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            errorText: _backendError,
          ),
          validator: _validator,
        ),
        if (widget.requireRules) ...[
          SizedBox(height: 12 * scale),
          Wrap(
            spacing: 16 * scale,
            runSpacing: 8 * scale,
            children: [
              _buildRuleItem('Mínimo 8 caracteres', _hasMinLength, scale),
              _buildRuleItem('Uma letra maiúscula', _hasUppercase, scale),
              _buildRuleItem('Uma letra minúscula', _hasLowercase, scale),
            ],
          ),
        ],
      ],
    );
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
}

/// Campo de texto para código OTP com validação local de 6 dígitos.
class CodeInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? backendError;

  const CodeInputField({
    Key? key,
    required this.controller,
    this.label = 'Código',
    this.hint = '000000',
    this.backendError,
  }) : super(key: key);

  String? _validator(String? value) {
    if (value == null || value.isEmpty) return 'Informe o código';
    if (value.length != 6) return 'Código deve ter 6 dígitos';
    return backendError;
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.light,
          fontSize: 12 * scale,
          color: AppColors.darkText,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.regular,
          fontSize: 14 * scale,
          color: AppColors.mediumGray,
        ),
        filled: true,
        fillColor: AppColors.offWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4 * scale),
          borderSide: BorderSide(color: AppColors.mediumGray),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: 12 * scale,
          horizontal: 12 * scale,
        ),
        errorText: backendError,
      ),
      validator: _validator,
    );
  }
}
