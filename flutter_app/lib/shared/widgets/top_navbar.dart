// lib/shared/widgets/top_navbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/profile_service.dart';
import 'package:flutter_app/shared/widgets/text_action_button.dart';

/// TopNavbar genérico: ele mesmo consulta o ProfileService e se atualiza.
/// Basta usá-lo em qualquer Scaffold: appBar: const TopNavbar()
class TopNavbar extends StatefulWidget implements PreferredSizeWidget {
  /// Chamado quando o usuário clica em “Cadastrar box”
  final VoidCallback onRegisterBox;
  const TopNavbar({Key? key, required this.onRegisterBox}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  _TopNavbarState createState() => _TopNavbarState();
}

class _TopNavbarState extends State<TopNavbar> {
  final ProfileService _service = ProfileService();

  // estado local
  late bool _hasStudent, _hasCoach;
  late String _currentRole;
  late List<String> _coachBoxes;
  String? _currentBox;
  late int _unread;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    // MOCK por enquanto; quando tiver API, troque por chamadas async/await
    setState(() {
      _hasStudent = _service.hasRole('student');
      _hasCoach = _service.hasRole('coach');
      _currentRole = _service.currentRoleLabel;
      _coachBoxes = _service.coachBoxNames;
      _currentBox = _service.currentBoxName;
      _unread = _service.unreadCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return AppBar(
      backgroundColor: AppColors.offWhite,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16.0 * scale,
      title: Row(
        children: [
          // 1) Perfil: dropdown só se tiver ambos
          if (_hasStudent && _hasCoach)
            _buildMenu<String>(
              label: _currentRole,
              items: ['Aluno', 'Coach'],
              onSelected: (v) {
                // TODO BACKEND: setActiveRole(v)
                setState(() => _currentRole = v);
              },
              scale: scale,
            )
          else
            Text(
              _currentRole,
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
              ),
            ),

          SizedBox(width: 24 * scale),

          // 2) Boxes (coach only)
          if (_currentRole == 'Coach')
            _coachBoxes.isNotEmpty
                ? _buildMenu<String>(
                  label: _currentBox ?? 'Selecione box',
                  items: _coachBoxes,
                  onSelected: (v) {
                    // TODO BACKEND: setActiveBox(v)
                    setState(() => _currentBox = v);
                  },
                  scale: scale,
                )
                : TextActionButton(
                  icon: Icons.add, // ícone de “+”
                  text: 'Cadastrar box',
                  onPressed: widget.onRegisterBox,
                ),

          const Spacer(),

          // 3) Notificações
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  size: 24 * scale,
                  color: AppColors.darkText,
                ),
                onPressed: () {
                  // TODO: navegar para notificações
                },
              ),
              if (_unread > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: EdgeInsets.all(4 * scale),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16 * scale,
                      minHeight: 16 * scale,
                    ),
                    child: Text(
                      '$_unread',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10 * scale,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenu<T>({
    required String label,
    required List<T> items,
    required ValueChanged<String> onSelected,
    required double scale,
  }) {
    return PopupMenuButton<T>(
      initialValue: items.contains(label as T) ? label as T : null,
      onSelected: (value) => onSelected(value.toString()),
      itemBuilder:
          (_) =>
              items
                  .map(
                    (e) => PopupMenuItem<T>(
                      value: e,
                      child: Text(
                        e.toString(),
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.regular,
                          fontSize: 14 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  )
                  .toList(),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.regular,
              fontSize: 16 * scale,
              color: AppColors.darkText,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }
}
