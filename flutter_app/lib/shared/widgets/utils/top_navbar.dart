// lib/shared/widgets/top_navbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/users/profile_service.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';

/// TopNavbar genérico: ele mesmo consulta o ProfileService e se atualiza.
/// Use em qualquer Scaffold: appBar: TopNavbar(onRegisterBox: ..., [showSystemBack:false])
class TopNavbar extends StatefulWidget implements PreferredSizeWidget {
  /// Chamado quando o usuário clica em “Cadastrar box”
  final VoidCallback onRegisterBox;

  /// Se true, mostra a seta **nativa** do AppBar (rara necessidade).
  /// Por padrão deixamos **false** porque você já usa o AppBackButton no corpo.
  final bool showSystemBack;

  const TopNavbar({
    Key? key,
    required this.onRegisterBox,
    this.showSystemBack = false,
  }) : super(key: key);

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
      // 🔧 Impede o Flutter de injetar a seta automaticamente
      automaticallyImplyLeading: false,
      // Se você QUISER a seta nativa em alguma tela específica, habilite:
      leading: widget.showSystemBack ? const BackButton() : null,

      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16.0 * scale,

      // “borda” inferior
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(0.5 * scale),
        child: Container(height: 0.5 * scale, color: AppColors.mediumGray),
      ),

      title: Row(
        children: [
          // 1) Perfil: dropdown só se tiver ambos
          if (_hasStudent && _hasCoach)
            _buildMenu<String>(
              label: _currentRole,
              items: const ['Aluno', 'Coach'],
              onSelected: (v) {
                // TODO BACKEND: setActiveRole(v)
                setState(() => _currentRole = v);
              },
              scale: scale,
            )
          else
            Text(
              _currentRole,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18 * scale,
                color: Theme.of(context).colorScheme.onSurface,
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
                  icon: Icons.add,
                  text: 'Cadastrar box',
                  onPressed:
                      () => showAppBottomSheet(context, const BoxSignupCoach()),
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
                  color: Theme.of(context).colorScheme.onBackground,
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
      initialValue:
          items.whereType<String>().contains(label) ? (label as T?) : null,
      onSelected: (value) => onSelected(value.toString()),
      itemBuilder:
          (_) =>
              items
                  .map(
                    (e) => PopupMenuItem<T>(
                      value: e,
                      child: Text(
                        e.toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ),
                  )
                  .toList(),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }
}
