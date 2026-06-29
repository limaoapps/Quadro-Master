import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/perfil_usuario.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PerfilScreen — dados do profissional responsável
// ─────────────────────────────────────────────────────────────────────────────
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeCtrl;
  late TextEditingController _cpfCtrl;
  late TextEditingController _registroCtrl;
  late String _cargo;
  String? _fotoBase64;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final perfil = context.read<AppProvider>().perfilUsuario;
    _nomeCtrl     = TextEditingController(text: perfil.nome);
    _cpfCtrl      = TextEditingController(text: perfil.cpf);
    _registroCtrl = TextEditingController(text: perfil.registro);
    _cargo        = perfil.cargo;
    _fotoBase64   = perfil.fotoBase64.isNotEmpty ? perfil.fotoBase64 : null;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _registroCtrl.dispose();
    super.dispose();
  }

  String get _registroLabel {
    switch (_cargo) {
      case 'tecnico':      return 'CRT';
      case 'profissional': return 'CPF Profissional';
      default:             return 'CREA';
    }
  }

  String get _registroHint {
    switch (_cargo) {
      case 'tecnico':      return 'Ex: 000.000.000-00';
      case 'profissional': return 'Ex: 000.000.000-00';
      default:             return 'Ex: 123456-7/SP';
    }
  }

  Future<void> _selecionarFoto() async {
    // Mostra opções: câmera ou galeria
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Escolher foto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                ),
                title: const Text('Galeria de fotos', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Selecionar imagem existente'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (!kIsWeb)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.secondary),
                  ),
                  title: const Text('Câmera', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tirar nova foto agora'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() => _fotoBase64 = base64Encode(bytes));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kIsWeb
              ? 'Selecione uma imagem da galeria.'
              : 'Erro ao acessar câmera/galeria. Verifique as permissões.'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final perfil = PerfilUsuario(
      nome: _nomeCtrl.text.trim(),
      cpf: _cpfCtrl.text.trim(),
      registro: _registroCtrl.text.trim(),
      cargo: _cargo,
      fotoBase64: _fotoBase64 ?? '',
    );

    await context.read<AppProvider>().atualizarPerfilUsuario(perfil);
    setState(() => _salvando = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil salvo com sucesso!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: _salvando ? null : _salvar,
            icon: _salvando
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, color: Colors.white, size: 18),
            label: const Text('Salvar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewPadding.bottom + 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Área da foto ─────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _selecionarFoto,
                      child: Stack(
                        children: [
                          _buildAvatar(110),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Toque para alterar a foto',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Cargo ────────────────────────────────────────────────
              _sectionLabel('Função / Cargo'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _cargoTile('engenheiro', 'Engenheiro Eletricista', Icons.engineering, 'CREA'),
                    const Divider(height: 1),
                    _cargoTile('tecnico', 'Técnico Eletricista', Icons.build_circle_outlined, 'CRT'),
                    const Divider(height: 1),
                    _cargoTile('profissional', 'Profissional Habilitado', Icons.verified_outlined, 'CPF'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Nome ─────────────────────────────────────────────────
              _sectionLabel('Nome Completo'),
              const SizedBox(height: 8),
              _buildField(
                controller: _nomeCtrl,
                hint: 'Ex: João da Silva',
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),

              const SizedBox(height: 16),

              // ── CPF ──────────────────────────────────────────────────
              _sectionLabel('CPF'),
              const SizedBox(height: 8),
              _buildField(
                controller: _cpfCtrl,
                hint: '000.000.000-00',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CpfFormatter(),
                ],
              ),

              const SizedBox(height: 16),

              // ── Registro (CREA / CRT / CPF) ──────────────────────────
              _sectionLabel(_registroLabel),
              const SizedBox(height: 8),
              _buildField(
                controller: _registroCtrl,
                hint: _registroHint,
                icon: Icons.workspace_premium_outlined,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers de UI ──────────────────────────────────────────────────────────

  Widget _buildAvatar(double size) {
    if (_fotoBase64 != null && _fotoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(_fotoBase64!);
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(bytes),
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      child: Icon(Icons.person, size: size * 0.55, color: AppColors.primary),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: AppColors.textSecondary,
      letterSpacing: 1.1,
    ),
  );

  Widget _cargoTile(String value, String label, IconData icon, String registroTipo) {
    final selected = _cargo == value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() {
        _cargo = value;
        _registroCtrl.clear();
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (selected ? AppColors.primary : AppColors.textSecondary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text('Registro: $registroTipo',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Formatter CPF ─────────────────────────────────────────────────────────────
class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue neo) {
    final digits = neo.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}
