import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';

/// Tela de Login com inputs de email e senha, botões de ação e opções de login social.
class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // FRONT-END: FormKey para validação dos campos (habilitar validators)
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage; // Mensagem de erro do backend

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// BACKEND TODO: Chamar API de login, obter resultado e role
  Future<void> _performLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // BACKEND TODO: Descomente e implemente
      // final result = await AuthService.login(
      //   email: _emailController.text,
      //   password: _passwordController.text,
      // );
      // if (!result.success) throw Exception(result.message);
      // FRONT-END: navegação condicional por profile:
      // if (result.role == UserRole.athlete) Navigator.pushReplacementNamed(context, '/athlete_home');
      // else Navigator.pushReplacementNamed(context, '/coach_home');

      // Simulação de delay e erro
      await Future.delayed(const Duration(seconds: 1));
      throw Exception('Usuário ou senha inválidos');
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375.0;
    double vSpace(double value) => value * scale;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        // -----LOGIN FORM-----
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: vSpace(80)), // margem topo
                // Título principal
                Text(
                  'MOTIVA',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 30 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: vSpace(4)),
                Text(
                  'Treine. Registre. Evolua',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.regular,
                    fontSize: 20 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: vSpace(32)),

                // ---------------EMAIL FIELD-----------------
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: 'ex:maria@gmail.com',
                    filled: true,
                    fillColor: AppColors.offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.mediumGray),
                    ),
                    errorText: _errorMessage, // mostra erro backend
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Informe seu e-mail';
                    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!regex.hasMatch(value))
                      return 'Formato de e-mail inválido';
                    return null;
                  },
                ),
                SizedBox(height: vSpace(16)),

                // ---------------PASSWORD FIELD------------------
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: '********',
                    filled: true,
                    fillColor: AppColors.offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.mediumGray),
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
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Senha deve ter ao menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: vSpace(8)),

                // FRONT-END TODO: Descomentar exibição de erro após integrar backend
                // if (_errorMessage != null) ...[
                //   Text(_errorMessage!, style: TextStyle(color: Colors.red, fontSize: 12 * scale)),
                //   SizedBox(height: vSpace(8)),
                // ],

                // -------------------FORGOT PASSWORD-------------------
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        ),
                    child: Text(
                      'Esqueci minha senha',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 14 * scale,
                        color: AppColors.baseBlue,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: vSpace(56)),

                // ---------------LOGIN BUTTON----------------
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(color: AppColors.darkBlue),
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
                      onPressed: () {
                        // FRONT-END: habilitar validação ao integrar
                        if (_formKey.currentState!.validate()) {
                          _performLogin(); // chama backend
                        }
                        //// BACK-END: descomentar lógica de navegação após implementar _performLogin
                      },
                      child: Text(
                        'Entrar',
                        style: TextStyle(
                          fontFamily: AppFonts.montserrat,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 16 * scale,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: vSpace(8)),

                // --------------------LGPD TEXT----------------------
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'Ao continuar, você concorda com nossos ',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.light,
                      fontSize: 8 * scale,
                      color: AppColors.darkText,
                    ),
                    children: [
                      TextSpan(
                        text: 'Termos de Serviço',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 8 * scale,
                          color: AppColors.darkText,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap =
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.terms,
                                  ),
                      ),
                      const TextSpan(text: ' e '),
                      TextSpan(
                        text: 'Política de Privacidade',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 8 * scale,
                          color: AppColors.darkText,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap =
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.privacyPolicy,
                                  ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: vSpace(16)),

                // -------------------------SIGN UP----------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não tem uma conta? ',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.regular,
                        fontSize: 14 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.signup,
                          ),
                      child: Text(
                        'Cadastre-se',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 14 * scale,
                          color: AppColors.baseBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: vSpace(40)),

                // ------------------------------SOCIAL LOGIN-----------------------
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppColors.mediumGray, thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0 * scale),
                      child: Text(
                        'OU',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.regular,
                          fontSize: 12 * scale,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppColors.mediumGray, thickness: 1),
                    ),
                  ],
                ),
                SizedBox(height: vSpace(16)),
                SizedBox(
                  width: double.infinity,
                  height: vSpace(48),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.mediumGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      width: 24 * scale,
                      height: 24 * scale,
                    ),
                    label: Text(
                      'Entrar com Google',
                      style: TextStyle(
                        fontFamily: AppFonts.montserrat,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 16 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                    onPressed: () {
                      // BACKEND TODO: implementar login via Google
                    },
                  ),
                ),
                SizedBox(height: vSpace(32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
