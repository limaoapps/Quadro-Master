import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/projeto.dart';
import '../models/perfil_usuario.dart';

class StorageService {
  static const _keyProjetos = 'quadro_master_projetos';
  static const _keyEmpresaExecutora = 'quadro_master_empresa_executora';
  static const _keyPerfilUsuario = 'quadro_master_perfil_usuario';

  static Future<List<Projeto>> carregarProjetos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProjetos);
    if (raw == null) return [];
    try {
      final lista = jsonDecode(raw) as List<dynamic>;
      return lista.map((m) => Projeto.fromMap(m as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.modificadoEm.compareTo(a.modificadoEm));
    } catch (_) {
      return [];
    }
  }

  static Future<void> salvarProjetos(List<Projeto> projetos) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(projetos.map((p) => p.toMap()).toList());
    await prefs.setString(_keyProjetos, raw);
  }

  static Future<void> salvarProjeto(Projeto projeto) async {
    final lista = await carregarProjetos();
    final idx = lista.indexWhere((p) => p.id == projeto.id);
    if (idx >= 0) {
      lista[idx] = projeto;
    } else {
      lista.add(projeto);
    }
    await salvarProjetos(lista);
  }

  static Future<void> excluirProjeto(String id) async {
    final lista = await carregarProjetos();
    lista.removeWhere((p) => p.id == id);
    await salvarProjetos(lista);
  }

  static Future<EmpresaExecutora> carregarEmpresaExecutora() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyEmpresaExecutora);
    if (raw == null) return EmpresaExecutora();
    try {
      return EmpresaExecutora.fromMap(jsonDecode(raw));
    } catch (_) {
      return EmpresaExecutora();
    }
  }

  static Future<void> salvarEmpresaExecutora(EmpresaExecutora empresa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmpresaExecutora, jsonEncode(empresa.toMap()));
  }

  static Future<PerfilUsuario> carregarPerfilUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPerfilUsuario);
    if (raw == null) return PerfilUsuario();
    try {
      return PerfilUsuario.fromMap(jsonDecode(raw));
    } catch (_) {
      return PerfilUsuario();
    }
  }

  static Future<void> salvarPerfilUsuario(PerfilUsuario perfil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPerfilUsuario, jsonEncode(perfil.toMap()));
  }
}
