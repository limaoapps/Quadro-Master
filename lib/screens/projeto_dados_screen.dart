import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/projeto.dart';
import '../models/cliente.dart';
import '../theme/app_theme.dart';
import '../utils/masks.dart';
import '../services/cep_service.dart';
import 'clientes_screen.dart';

class ProjetoDadosScreen extends StatefulWidget {
  final Projeto projeto;
  final VoidCallback? onSaved;
  const ProjetoDadosScreen({super.key, required this.projeto, this.onSaved});

  @override
  State<ProjetoDadosScreen> createState() => _ProjetoDadosScreenState();
}

// GlobalKey tipada para acesso externo (usado pelo disquete na AppBar)
typedef ProjetoDadosKey = GlobalKey<_ProjetoDadosScreenState>;

class _ProjetoDadosScreenState extends State<ProjetoDadosScreen> {
  // projeto
  late TextEditingController _nomeCtrl;
  late TextEditingController _obsCtrl;
  late TipoQuadro _tipo;
  late TensaoAlimentacao _tensao;
  late NumeroFases _fases;
  late StatusProjeto _status;

  // contratante
  TipoPessoa _tipoPessoa = TipoPessoa.juridica;
  TipoDocumentoART _tipoArt = TipoDocumentoART.art;
  late TextEditingController _razaoCtrl;
  late TextEditingController _docCtrl;
  late TextEditingController _respCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _artCtrl;
  late TextEditingController _cepCtrl;
  late TextEditingController _ruaCtrl;
  late TextEditingController _numCtrl;
  late TextEditingController _bairroCtrl;
  late TextEditingController _cidadeCtrl;
  late TextEditingController _estadoCtrl;

  bool _dirty = false;
  bool _buscandoCep = false;

  @override
  void initState() {
    super.initState();
    final p = widget.projeto;
    final c = p.contratante;
    _nomeCtrl   = TextEditingController(text: p.nome);
    _obsCtrl    = TextEditingController(text: p.observacoes);
    _tipo       = p.tipoQuadro;
    _tensao     = p.tensao;
    _fases      = p.numFases;
    _status     = p.status;

    _tipoPessoa  = c.tipoPessoa == 'fisica' ? TipoPessoa.fisica : TipoPessoa.juridica;
    _tipoArt     = c.tipoArt;
    _razaoCtrl   = TextEditingController(text: c.razaoSocial);
    _docCtrl     = TextEditingController(text: c.documento);
    _respCtrl    = TextEditingController(text: c.responsavel);
    _telCtrl     = TextEditingController(text: c.telefone);
    _emailCtrl   = TextEditingController(text: c.email);
    _artCtrl     = TextEditingController(text: c.art);
    _cepCtrl     = TextEditingController(text: c.cep);
    _ruaCtrl     = TextEditingController(text: c.rua);
    _numCtrl     = TextEditingController(text: c.numero);
    _bairroCtrl  = TextEditingController(text: c.bairro);
    _cidadeCtrl  = TextEditingController(text: c.cidade);
    _estadoCtrl  = TextEditingController(text: c.estado);
  }

  void _mark() => setState(() => _dirty = true);
  bool get _isPF => _tipoPessoa == TipoPessoa.fisica;

  Future<void> _buscarCep(String cep) async {
    if (!Validators.cepValido(cep)) return;
    setState(() => _buscandoCep = true);
    final end = await CepService.buscarCep(cep);
    setState(() => _buscandoCep = false);
    if (!mounted) return;
    if (end == null || end.erro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP não encontrado'), backgroundColor: AppColors.error),
      );
      return;
    }
    _ruaCtrl.text    = end.logradouro;
    _bairroCtrl.text = end.bairro;
    _cidadeCtrl.text = end.cidade;
    _estadoCtrl.text = end.estado.toUpperCase();
    _mark();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, Color(0xFF2A2A4E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.electrical_services, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Parâmetros da Instalação', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(
                        '${_tensao.label} · 60 Hz · ${_fases.label.split('–').first.trim()}',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                DropdownButton<StatusProjeto>(
                  value: _status,
                  dropdownColor: AppColors.secondary,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.expand_more, color: Colors.white60, size: 18),
                  items: StatusProjeto.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.label, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (v) => setState(() { _status = v!; _dirty = true; }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Identificação do Projeto ─────────────────────
          _sectionCard(
            title: 'Identificação do Projeto',
            icon: Icons.folder_open,
            children: [
              _field(_nomeCtrl, 'Nome / Identificação do Projeto', Icons.edit_note, onChange: _mark),
              const SizedBox(height: 12),
              DropdownButtonFormField<TipoQuadro>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de Quadro', prefixIcon: Icon(Icons.electrical_services)),
                items: TipoQuadro.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) { setState(() { _tipo = v!; _dirty = true; }); },
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<TensaoAlimentacao>(
                    value: _tensao,
                    decoration: const InputDecoration(labelText: 'Tensão de Alimentação', prefixIcon: Icon(Icons.flash_on)),
                    items: TensaoAlimentacao.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                    onChanged: (v) { setState(() { _tensao = v!; _dirty = true; }); },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<NumeroFases>(
                    value: _fases,
                    decoration: const InputDecoration(labelText: 'Nº de Fases'),
                    items: NumeroFases.values.map((f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.label.split('–').first.trim()),
                    )).toList(),
                    onChanged: (v) { setState(() { _fases = v!; _dirty = true; }); },
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Frequência: 60 Hz (padrão Brasil) · Norma: ABNT NBR 5410',
                        style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _field(_obsCtrl, 'Observações Técnicas Gerais', Icons.note_alt, maxLines: 3, onChange: _mark),
            ],
          ),
          const SizedBox(height: 16),

          // ── Empresa Contratante ──────────────────────────
          _sectionCard(
            title: 'Empresa Contratante',
            icon: Icons.business,
            children: [

              // Botão preencher a partir de cliente cadastrado
              _buildBotaoSelecionarCliente(),
              const SizedBox(height: 12),

              // Tipo de pessoa
              DropdownButtonFormField<TipoPessoa>(
                value: _tipoPessoa,
                decoration: const InputDecoration(labelText: 'Tipo de Pessoa', prefixIcon: Icon(Icons.person_outline)),
                items: TipoPessoa.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) => setState(() { _tipoPessoa = v!; _docCtrl.clear(); _dirty = true; }),
              ),
              const SizedBox(height: 12),

              // Razão Social
              _field(_razaoCtrl, _isPF ? 'Nome Completo' : 'Razão Social / Nome Fantasia', Icons.business, onChange: _mark),
              const SizedBox(height: 12),

              // CPF / CNPJ dinâmico
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _docCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_isPF ? CpfInputFormatter() : CnpjInputFormatter()],
                    onChanged: (_) => _mark(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      return Validators.validarCpfOuCnpj(v, _isPF);
                    },
                    decoration: InputDecoration(
                      labelText: _isPF ? 'CPF' : 'CNPJ',
                      hintText: _isPF ? '000.000.000-00' : '00.000.000/0000-00',
                      prefixIcon: const Icon(Icons.badge, size: 18),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // ── ART / RRT ─────────────────────────────────
              _buildArtRrtRow(),
              const SizedBox(height: 12),

              // Responsável + telefone + e-mail
              _field(_respCtrl, 'Responsável pela Contratação', Icons.person, onChange: _mark),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _telCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [TelefoneInputFormatter()],
                    onChanged: (_) => _mark(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: Validators.validarTelefone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      hintText: '(00) 00000-0000',
                      prefixIcon: Icon(Icons.phone, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_emailCtrl, 'E-mail', Icons.email, onChange: _mark),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Endereço ──────────────────────────────────
              _subHeader('Endereço da Instalação'),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _cepCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CepInputFormatter()],
                    onChanged: (v) { _mark(); if (Validators.cepValido(v)) _buscarCep(v); },
                    decoration: InputDecoration(
                      labelText: 'CEP (opcional)',
                      hintText: '00000-000',
                      prefixIcon: const Icon(Icons.pin_drop, size: 18),
                      suffixIcon: _buscandoCep
                          ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(icon: const Icon(Icons.search), onPressed: () => _buscarCep(_cepCtrl.text)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _field(_ruaCtrl, 'Logradouro / Rua', Icons.location_on, onChange: _mark),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _numCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _mark(),
                    decoration: const InputDecoration(labelText: 'Número', prefixIcon: Icon(Icons.tag, size: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _field(_bairroCtrl, 'Bairro', Icons.map_outlined, onChange: _mark),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  flex: 3,
                  child: _field(_cidadeCtrl, 'Cidade', Icons.location_city, onChange: _mark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _estadoCtrl,
                    onChanged: (_) => _mark(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: const InputDecoration(labelText: 'UF'),
                  ),
                ),
              ]),
            ],
          ),

          const SizedBox(height: 20),
          if (_dirty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Dados do Projeto'),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 40),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _subHeader(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, VoidCallback? onChange}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      onChanged: (_) => onChange?.call(),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18)),
    );
  }

  // ── Botão para preencher a partir de cliente cadastrado ──
  Widget _buildBotaoSelecionarCliente() {
    final prov = context.read<AppProvider>();
    final temClientes = prov.clientes.isNotEmpty;

    if (!temClientes) {
      return GestureDetector(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientesScreen()));
          setState(() {}); // rebuid após retornar
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sem clientes cadastrados — toque para cadastrar',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final cliente = await showModalBottomSheet<Cliente>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          builder: (_) => const ClienteSeletorSheet(),
        );
        if (cliente == null) return;
        // Preenche todos os campos com os dados do cliente
        setState(() {
          _tipoPessoa       = cliente.tipoPessoa == 'fisica' ? TipoPessoa.fisica : TipoPessoa.juridica;
          _tipoArt          = cliente.tipoArtEnum;
          _razaoCtrl.text   = cliente.razaoSocial;
          _docCtrl.text     = cliente.documento;
          _respCtrl.text    = cliente.responsavel;
          _telCtrl.text     = cliente.telefone;
          _emailCtrl.text   = cliente.email;
          _artCtrl.text     = cliente.art;
          _cepCtrl.text     = cliente.cep;
          _ruaCtrl.text     = cliente.rua;
          _numCtrl.text     = cliente.numero;
          _bairroCtrl.text  = cliente.bairro;
          _cidadeCtrl.text  = cliente.cidade;
          _estadoCtrl.text  = cliente.estado;
          _dirty = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dados de "${cliente.razaoSocial}" preenchidos!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.people_outlined, size: 16, color: AppColors.primary.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Preencher a partir de cliente cadastrado',
                style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.primary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  // ── Linha ART / RRT dinâmica ─────────────────────────────
  Widget _buildArtRrtRow() {
    final isRRT = _tipoArt == TipoDocumentoART.rrt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seletor ART | RRT
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: TipoDocumentoART.values.map((t) {
              final sel = t == _tipoArt;
              return GestureDetector(
                onTap: () => setState(() {
                  _tipoArt = t;
                  _artCtrl.clear();
                  _mark();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(sel ? 6 : 0),
                  ),
                  child: Text(
                    t.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _artCtrl,
            keyboardType: isRRT ? TextInputType.text : TextInputType.number,
            inputFormatters: isRRT ? [RrtInputFormatter()] : [ArtInputFormatter()],
            onChanged: (_) => _mark(),
            decoration: InputDecoration(
              labelText: '${_tipoArt.label} nº',
              hintText: _tipoArt.hint,
              prefixIcon: const Icon(Icons.assignment_outlined, size: 18),
              helperText: 'Emissão: ${_tipoArt.orgaoEmissor}',
              helperStyle: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  /// Chamado externamente pelo disquete na AppBar de ProjetoScreen
  Future<void> salvarExterno() => _salvar();

  Future<void> _salvar() async {
    final prov = context.read<AppProvider>();
    final contratante = EmpresaContratante(
      razaoSocial: _razaoCtrl.text,
      documento:   _docCtrl.text,
      tipoPessoa:  _tipoPessoa.name,
      responsavel: _respCtrl.text,
      telefone:    _telCtrl.text,
      email:       _emailCtrl.text,
      art:         _artCtrl.text,
      tipoArt:     _tipoArt,
      cep:         _cepCtrl.text,
      rua:         _ruaCtrl.text,
      numero:      _numCtrl.text,
      bairro:      _bairroCtrl.text,
      cidade:      _cidadeCtrl.text,
      estado:      _estadoCtrl.text,
    );
    final updated = widget.projeto.copyWith(
      nome: _nomeCtrl.text.isEmpty ? widget.projeto.nome : _nomeCtrl.text,
      tipoQuadro: _tipo, tensao: _tensao, numFases: _fases,
      observacoes: _obsCtrl.text, contratante: contratante, status: _status,
    );
    await prov.atualizarProjeto(updated);
    setState(() => _dirty = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Projeto atualizado!'), duration: Duration(seconds: 1)),
      );
      widget.onSaved?.call();
    }
  }
}
