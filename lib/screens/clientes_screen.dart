import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/cliente.dart';
import '../models/projeto.dart';
import '../theme/app_theme.dart';
import '../utils/masks.dart';
import '../services/cep_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ClientesScreen — cadastro de clientes/contratantes reutilizáveis
// Acessível via engrenagem na tela inicial (HistoricoScreen)
// ─────────────────────────────────────────────────────────────────────────────
class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clientes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Cadastro de contratantes', style: TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Colors.white),
            tooltip: 'Novo Cliente',
            onPressed: () => _abrirFormCliente(context, null),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, prov, _) {
          final clientes = prov.clientes;

          if (clientes.isEmpty) {
            return _buildEmpty(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: clientes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _ClienteCard(
              cliente: clientes[i],
              onEdit: () => _abrirFormCliente(context, clientes[i]),
              onDelete: () => _confirmarExclusao(context, prov, clientes[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormCliente(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Novo Cliente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Nenhum cliente cadastrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Cadastre clientes para preencher\nautomaticamente nos projetos',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _abrirFormCliente(context, null),
            icon: const Icon(Icons.person_add),
            label: const Text('Cadastrar primeiro cliente'),
          ),
        ],
      ),
    );
  }

  void _abrirFormCliente(BuildContext context, Cliente? cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      builder: (_) => _ClienteFormSheet(cliente: cliente),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context, AppProvider prov, Cliente c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir cliente?'),
        content: Text('"${c.razaoSocial}" será removido do cadastro.\nOs projetos vinculados não serão afetados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) await prov.excluirCliente(c.id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de cliente na lista
// ─────────────────────────────────────────────────────────────────────────────
class _ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClienteCard({
    required this.cliente,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPF = cliente.tipoPessoa == 'fisica';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar com iniciais
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  cliente.iniciais,
                  style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Dados principais
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cliente.razaoSocial.isNotEmpty ? cliente.razaoSocial : 'Sem nome',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  if (cliente.documento.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${isPF ? 'CPF' : 'CNPJ'}: ${cliente.documento}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  if (cliente.responsavel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          cliente.responsavel,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (cliente.cidade.isNotEmpty)
                        _chip(Icons.location_city, cliente.cidade),
                      if (cliente.telefone.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _chip(Icons.phone, cliente.telefone),
                      ],
                      if (cliente.art.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _chip(Icons.assignment_outlined, '${cliente.tipoArtEnum.label}: ${cliente.art}'),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Ações
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Editar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Excluir',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: AppColors.textSecondary),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulário de criação / edição de cliente
// ─────────────────────────────────────────────────────────────────────────────
class _ClienteFormSheet extends StatefulWidget {
  final Cliente? cliente;
  const _ClienteFormSheet({this.cliente});

  @override
  State<_ClienteFormSheet> createState() => _ClienteFormSheetState();
}

class _ClienteFormSheetState extends State<_ClienteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  TipoPessoa _tipoPessoa = TipoPessoa.juridica;
  TipoDocumentoART _tipoArt = TipoDocumentoART.art;
  bool _buscandoCep = false;

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
  late TextEditingController _obsCtrl;

  bool get _isPF => _tipoPessoa == TipoPessoa.fisica;
  bool get _isEdicao => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _tipoPessoa = c?.tipoPessoa == 'fisica' ? TipoPessoa.fisica : TipoPessoa.juridica;
    _tipoArt    = c?.tipoArtEnum ?? TipoDocumentoART.art;
    _razaoCtrl  = TextEditingController(text: c?.razaoSocial  ?? '');
    _docCtrl    = TextEditingController(text: c?.documento    ?? '');
    _respCtrl   = TextEditingController(text: c?.responsavel  ?? '');
    _telCtrl    = TextEditingController(text: c?.telefone     ?? '');
    _emailCtrl  = TextEditingController(text: c?.email        ?? '');
    _artCtrl    = TextEditingController(text: c?.art          ?? '');
    _cepCtrl    = TextEditingController(text: c?.cep          ?? '');
    _ruaCtrl    = TextEditingController(text: c?.rua          ?? '');
    _numCtrl    = TextEditingController(text: c?.numero       ?? '');
    _bairroCtrl = TextEditingController(text: c?.bairro       ?? '');
    _cidadeCtrl = TextEditingController(text: c?.cidade       ?? '');
    _estadoCtrl = TextEditingController(text: c?.estado       ?? '');
    _obsCtrl    = TextEditingController(text: c?.observacoes  ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _razaoCtrl, _docCtrl, _respCtrl, _telCtrl, _emailCtrl,
      _artCtrl, _cepCtrl, _ruaCtrl, _numCtrl, _bairroCtrl,
      _cidadeCtrl, _estadoCtrl, _obsCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

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
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                ),
              ),
              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(_isEdicao ? Icons.edit_outlined : Icons.person_add_outlined,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      _isEdicao ? 'Editar Cliente' : 'Novo Cliente',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Tipo de Pessoa ──────────────────────────────
                      _label('Dados Principais'),
                      DropdownButtonFormField<TipoPessoa>(
                        value: _tipoPessoa,
                        decoration: const InputDecoration(labelText: 'Tipo de Pessoa', prefixIcon: Icon(Icons.person_outline)),
                        items: TipoPessoa.values.map((t) => DropdownMenuItem(
                          value: t, child: Text(t.label),
                        )).toList(),
                        onChanged: (v) => setState(() { _tipoPessoa = v!; _docCtrl.clear(); }),
                      ),
                      const SizedBox(height: 10),

                      // Razão Social / Nome
                      TextFormField(
                        controller: _razaoCtrl,
                        decoration: InputDecoration(
                          labelText: _isPF ? 'Nome Completo' : 'Razão Social / Nome Fantasia',
                          prefixIcon: const Icon(Icons.business, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 10),

                      // CPF / CNPJ
                      TextFormField(
                        controller: _docCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_isPF ? CpfInputFormatter() : CnpjInputFormatter()],
                        decoration: InputDecoration(
                          labelText: _isPF ? 'CPF' : 'CNPJ',
                          hintText: _isPF ? '000.000.000-00' : '00.000.000/0000-00',
                          prefixIcon: const Icon(Icons.badge, size: 18),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return Validators.validarCpfOuCnpj(v, _isPF);
                        },
                      ),
                      const SizedBox(height: 10),

                      // Responsável
                      TextFormField(
                        controller: _respCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Responsável / Contato',
                          prefixIcon: Icon(Icons.person, size: 18),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Telefone + Email
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _telCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [TelefoneInputFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Telefone',
                              hintText: '(00) 00000-0000',
                              prefixIcon: Icon(Icons.phone, size: 18),
                            ),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: Validators.validarTelefone,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.email, size: 18),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── ART / RRT ──────────────────────────────────
                      _label('Documento de Responsabilidade Técnica'),
                      _buildArtRrtRow(),
                      const SizedBox(height: 16),

                      // ── Endereço ────────────────────────────────────
                      _label('Endereço'),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cepCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CepInputFormatter()],
                            onChanged: (v) { if (Validators.cepValido(v)) _buscarCep(v); },
                            decoration: InputDecoration(
                              labelText: 'CEP (opcional)',
                              hintText: '00000-000',
                              prefixIcon: const Icon(Icons.pin_drop, size: 18),
                              suffixIcon: _buscandoCep
                                  ? const Padding(padding: EdgeInsets.all(12),
                                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                                  : IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: () => _buscarCep(_cepCtrl.text),
                                    ),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _ruaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Logradouro / Rua',
                          prefixIcon: Icon(Icons.location_on, size: 18),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _numCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Número',
                              prefixIcon: Icon(Icons.tag, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _bairroCtrl,
                            decoration: const InputDecoration(labelText: 'Bairro'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _cidadeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Cidade',
                              prefixIcon: Icon(Icons.location_city, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _estadoCtrl,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: const InputDecoration(labelText: 'UF'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── Observações ─────────────────────────────────
                      TextFormField(
                        controller: _obsCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          prefixIcon: Icon(Icons.note_alt, size: 18),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Botão salvar ────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _salvar,
                          icon: Icon(_isEdicao ? Icons.save : Icons.person_add),
                          label: Text(_isEdicao ? 'Salvar Alterações' : 'Cadastrar Cliente'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Seletor ART | RRT + campo dinâmico ──────────────────
  Widget _buildArtRrtRow() {
    final isRRT = _tipoArt == TipoDocumentoART.rrt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle ART / RRT
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
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
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
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
            decoration: InputDecoration(
              labelText: '${_tipoArt.label} nº',
              hintText: _tipoArt.hint,
              prefixIcon: const Icon(Icons.assignment_outlined, size: 18),
              helperText: _tipoArt.labelCompleto,
              helperStyle: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
  );

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<AppProvider>();

    final c = Cliente(
      id:          widget.cliente?.id ?? prov.novoClienteId,
      razaoSocial: _razaoCtrl.text.trim(),
      documento:   _docCtrl.text,
      tipoPessoa:  _tipoPessoa.name,
      responsavel: _respCtrl.text.trim(),
      telefone:    _telCtrl.text,
      email:       _emailCtrl.text.trim(),
      art:         _artCtrl.text.trim(),
      tipoArt:     _tipoArt.name,
      cep:         _cepCtrl.text,
      rua:         _ruaCtrl.text.trim(),
      numero:      _numCtrl.text.trim(),
      bairro:      _bairroCtrl.text.trim(),
      cidade:      _cidadeCtrl.text.trim(),
      estado:      _estadoCtrl.text.toUpperCase().trim(),
      observacoes: _obsCtrl.text.trim(),
      criadoEm:    widget.cliente?.criadoEm,
    );

    if (_isEdicao) {
      await prov.atualizarCliente(c);
    } else {
      await prov.adicionarCliente(c);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdicao ? 'Cliente atualizado!' : 'Cliente cadastrado!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seletor de cliente (para usar em outros formulários)
// Retorna o Cliente selecionado via Navigator.pop
// ─────────────────────────────────────────────────────────────────────────────
class ClienteSeletorSheet extends StatefulWidget {
  const ClienteSeletorSheet({super.key});

  @override
  State<ClienteSeletorSheet> createState() => _ClienteSeletorSheetState();
}

class _ClienteSeletorSheetState extends State<ClienteSeletorSheet> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final clientes = prov.clientes
        .where((c) =>
            c.razaoSocial.toLowerCase().contains(_busca.toLowerCase()) ||
            c.documento.contains(_busca) ||
            c.cidade.toLowerCase().contains(_busca.toLowerCase()))
        .toList();

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.people_outline, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  const Text('Selecionar Cliente',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancelar'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Campo de busca
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _busca = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, CNPJ ou cidade...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            if (clientes.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text(
                      prov.clientes.isEmpty
                          ? 'Nenhum cliente cadastrado\nAdicione clientes em Configurações → Clientes'
                          : 'Nenhum resultado para "$_busca"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  shrinkWrap: true,
                  itemCount: clientes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) {
                    final c = clientes[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: AppColors.background,
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(c.iniciais,
                            style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ),
                      ),
                      title: Text(c.razaoSocial,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        [
                          if (c.documento.isNotEmpty) c.documento,
                          if (c.cidade.isNotEmpty) c.cidade,
                        ].join(' · '),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
