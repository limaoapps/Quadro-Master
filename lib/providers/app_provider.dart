import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/projeto.dart';
import '../models/carga.dart';
import '../models/resultado_projeto.dart';
import '../models/perfil_usuario.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<Projeto> _projetos = [];
  Projeto? _projetoAtual;
  EmpresaExecutora _empresaExecutora = EmpresaExecutora();
  PerfilUsuario _perfilUsuario = PerfilUsuario();
  bool _carregando = false;
  int _tabIndex = 0;

  List<Projeto> get projetos => _projetos;
  Projeto? get projetoAtual => _projetoAtual;
  EmpresaExecutora get empresaExecutora => _empresaExecutora;
  PerfilUsuario get perfilUsuario => _perfilUsuario;
  bool get carregando => _carregando;
  int get tabIndex => _tabIndex;

  ResultadoProjeto? get resultado {
    if (_projetoAtual == null || _projetoAtual!.cargas.isEmpty) return null;
    return ResultadoProjeto.calcular(
      cargas: _projetoAtual!.cargas,
      numFases: _projetoAtual!.numFases.index,
      tensaoLinha: _projetoAtual!.tensao.valor,
      tensaoFase: _projetoAtual!.tensao.tensaoFase,
    );
  }

  Future<void> inicializar() async {
    _carregando = true;
    notifyListeners();
    _projetos = await StorageService.carregarProjetos();
    _empresaExecutora = await StorageService.carregarEmpresaExecutora();
    _perfilUsuario = await StorageService.carregarPerfilUsuario();
    _carregando = false;
    notifyListeners();
  }

  void setTabIndex(int idx) {
    _tabIndex = idx;
    notifyListeners();
  }

  // ── PROJETOS ──────────────────────────────────────────────
  Future<Projeto> novoProjeto() async {
    final p = Projeto(
      id: _uuid.v4(),
      nome: 'Novo Projeto',
      executora: _empresaExecutora,
    );
    _projetos.insert(0, p);
    await StorageService.salvarProjeto(p);
    notifyListeners();
    return p;
  }

  Future<void> abrirProjeto(Projeto p) async {
    _projetoAtual = p;
    _tabIndex = 1;
    notifyListeners();
  }

  Future<void> fecharProjeto() async {
    _projetoAtual = null;
    _tabIndex = 0;
    notifyListeners();
  }

  Future<void> salvarProjetoAtual() async {
    if (_projetoAtual == null) return;
    final idx = _projetos.indexWhere((p) => p.id == _projetoAtual!.id);
    if (idx >= 0) _projetos[idx] = _projetoAtual!;
    await StorageService.salvarProjeto(_projetoAtual!);
    notifyListeners();
  }

  Future<void> atualizarProjeto(Projeto p) async {
    _projetoAtual = p;
    final idx = _projetos.indexWhere((x) => x.id == p.id);
    if (idx >= 0) _projetos[idx] = p;
    await StorageService.salvarProjeto(p);
    notifyListeners();
  }

  Future<Projeto> duplicarProjeto(Projeto original) async {
    final novo = Projeto(
      id: _uuid.v4(),
      nome: '${original.nome} (Cópia)',
      tipoQuadro: original.tipoQuadro,
      tensao: original.tensao,
      numFases: original.numFases,
      fatorPotenciaGeral: original.fatorPotenciaGeral,
      observacoes: original.observacoes,
      executora: original.executora,
      contratante: original.contratante,
      cargas: original.cargas.map((c) => Carga.fromMap(c.toMap())).toList(),
    );
    _projetos.insert(0, novo);
    await StorageService.salvarProjeto(novo);
    notifyListeners();
    return novo;
  }

  Future<void> excluirProjeto(String id) async {
    _projetos.removeWhere((p) => p.id == id);
    if (_projetoAtual?.id == id) _projetoAtual = null;
    await StorageService.excluirProjeto(id);
    notifyListeners();
  }

  Future<void> atualizarStatus(String id, StatusProjeto status) async {
    final idx = _projetos.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      _projetos[idx] = _projetos[idx].copyWith(status: status);
      if (_projetoAtual?.id == id) {
        _projetoAtual = _projetos[idx];
      }
      await StorageService.salvarProjeto(_projetos[idx]);
      notifyListeners();
    }
  }

  // ── CARGAS ────────────────────────────────────────────────
  Future<void> adicionarCarga(Carga c) async {
    if (_projetoAtual == null) return;
    _projetoAtual!.cargas.add(c);
    _projetoAtual!.modificadoEm = DateTime.now();
    await salvarProjetoAtual();
  }

  Future<void> atualizarCarga(Carga c) async {
    if (_projetoAtual == null) return;
    final idx = _projetoAtual!.cargas.indexWhere((x) => x.id == c.id);
    if (idx >= 0) _projetoAtual!.cargas[idx] = c;
    _projetoAtual!.modificadoEm = DateTime.now();
    await salvarProjetoAtual();
  }

  Future<void> excluirCarga(String id) async {
    if (_projetoAtual == null) return;
    _projetoAtual!.cargas.removeWhere((c) => c.id == id);
    _projetoAtual!.modificadoEm = DateTime.now();
    await salvarProjetoAtual();
  }

  Future<void> toggleCargaAtiva(String id) async {
    if (_projetoAtual == null) return;
    final idx = _projetoAtual!.cargas.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      final c = _projetoAtual!.cargas[idx];
      _projetoAtual!.cargas[idx] = Carga.fromMap({...c.toMap(), 'ativo': !c.ativo});
    }
    await salvarProjetoAtual();
  }

  String get novaCargaId => _uuid.v4();

  // ── EMPRESA EXECUTORA ─────────────────────────────────────
  Future<void> atualizarEmpresaExecutora(EmpresaExecutora e) async {
    _empresaExecutora = e;
    await StorageService.salvarEmpresaExecutora(e);
    notifyListeners();
  }

  // ── PERFIL DO USUÁRIO ─────────────────────────────────────
  Future<void> atualizarPerfilUsuario(PerfilUsuario p) async {
    _perfilUsuario = p;
    await StorageService.salvarPerfilUsuario(p);
    notifyListeners();
  }
}
