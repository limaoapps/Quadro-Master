// Serviço central de integração com o Google Mobile Ads SDK (AdMob).
//
// IMPORTANTE — Suporte de plataforma:
// O pacote `google_mobile_ads` NÃO possui implementação nativa para Flutter
// Web (apenas Android/iOS). Por isso, toda chamada ao SDK real é protegida
// por `kIsWeb`: no Android o banner é carregado e exibido normalmente; na
// Web o widget de banner exibe um placeholder discreto (sem quebrar o app
// e sem tentar inicializar um SDK que não existe nesse ambiente).
//
// IMPORTANTE — Prevenção de vazamento de memória / tela branca:
// O SDK nativo do AdMob para Android recarrega o banner automaticamente em
// intervalos periódicos (refresh automático, configurado no painel do
// AdMob). Cada recarga cria uma nova view nativa (PlatformView/WebView) por
// baixo dos panos. Se o app ficar aberto por muito tempo na mesma tela, essas
// recargas repetidas podem acumular consumo de memória nativa e, no final,
// causar lentidão severa/crash silencioso do processo (sintoma: app fica com
// tela branca e sem resposta depois de um tempo de uso).
//
// Para mitigar isso, o widget `AdMobBanner` abaixo:
//  1) Observa o ciclo de vida do app (WidgetsBindingObserver) e libera
//     (dispose) o BannerAd quando o app vai para segundo plano/é minimizado,
//     recriando-o apenas quando o app volta ao primeiro plano;
//  2) Garante que apenas UM BannerAd fique ativo por vez (evita chamadas de
//     load() duplicadas/concorrentes);
//  3) Ignora callbacks do SDK que chegam depois do widget já ter sido
//     destruído (proteção contra "callback após dispose").
//
// Recomendação adicional (configuração fora do código, no painel do AdMob):
// Reduzir a frequência de "Atualização automática" (Auto-refresh) da unidade
// de anúncio "banner Qd" para 60s ou mais (ou desativar), em:
// admob.google.com > Unidades de anúncio > banner Qd > Configurações avançadas.
// Isso reduz drasticamente a frequência de recriação de views nativas.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// IDs de unidades de anúncio configurados para o app "Quadro Master".
class AdMobIds {
  AdMobIds._();

  /// App ID do AdMob (declarado também no AndroidManifest.xml).
  static const String appId = 'ca-app-pub-8464114280669008~8698658769';

  /// Banner "banner Qd" — exibido nas telas principais do app.
  static const String bannerQd = 'ca-app-pub-8464114280669008/4859752036';
}

/// Inicializa o Google Mobile Ads SDK.
///
/// Deve ser chamado uma única vez, no início do app (main.dart), apenas
/// quando a plataforma for Android (a Web não é suportada pelo SDK nativo).
class AdMobService {
  AdMobService._();

  static bool _initialized = false;

  /// Indica se o SDK de anúncios está disponível na plataforma atual.
  static bool get isSupported => !kIsWeb;

  static Future<void> initialize() async {
    if (!isSupported) {
      if (kDebugMode) {
        debugPrint('[AdMobService] Plataforma Web detectada — '
            'google_mobile_ads não é inicializado (sem suporte nativo).');
      }
      return;
    }
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      if (kDebugMode) {
        debugPrint('[AdMobService] Mobile Ads SDK inicializado com sucesso.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AdMobService] Falha ao inicializar Mobile Ads SDK: $e');
      }
    }
  }
}

/// Widget de banner AdMob reutilizável, com carregamento assíncrono,
/// tratamento de erros, controle de ciclo de vida do app (pausa em segundo
/// plano) e liberação correta de recursos (dispose) — para evitar acúmulo
/// de memória nativa que pode levar a lentidão/tela branca após uso
/// prolongado.
///
/// Uso: `const AdMobBanner(adUnitId: AdMobIds.bannerQd)`
class AdMobBanner extends StatefulWidget {
  final String adUnitId;
  final AdSize adSize;

  const AdMobBanner({
    super.key,
    required this.adUnitId,
    this.adSize = AdSize.banner,
  });

  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _failed = false;
  bool _loading = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    if (AdMobService.isSupported) {
      WidgetsBinding.instance.addObserver(this);
      _loadBanner();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Libera o banner quando o app vai para segundo plano, evitando que o
    // refresh automático nativo continue consumindo memória enquanto o
    // usuário não está vendo o anúncio. Recarrega ao voltar ao app.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _disposeCurrentAd();
    } else if (state == AppLifecycleState.resumed) {
      if (_bannerAd == null && !_loading) {
        _loadBanner();
      }
    }
  }

  void _disposeCurrentAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    if (mounted) {
      setState(() {
        _isLoaded = false;
      });
    } else {
      _isLoaded = false;
    }
  }

  void _loadBanner() {
    // Evita carregamentos concorrentes/duplicados do mesmo banner.
    if (_loading) return;
    _loading = true;

    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _loading = false;
          // Ignora callback se o widget já foi destruído ou se este anúncio
          // não é mais o anúncio "atual" (evita vazamento/estado incorreto).
          if (_disposed || !mounted || ad != _bannerAd) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
            _failed = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          _loading = false;
          if (kDebugMode) {
            debugPrint('[AdMobBanner] Falha ao carregar anúncio: $error');
          }
          ad.dispose();
          if (_disposed || !mounted) return;
          if (ad == _bannerAd) _bannerAd = null;
          setState(() {
            _isLoaded = false;
            _failed = true;
          });
        },
        onAdOpened: (ad) {
          if (kDebugMode) debugPrint('[AdMobBanner] Anúncio aberto.');
        },
        onAdClosed: (ad) {
          if (kDebugMode) debugPrint('[AdMobBanner] Anúncio fechado.');
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Web: sem suporte nativo ao SDK — não ocupa espaço na tela.
    if (!AdMobService.isSupported) {
      return const SizedBox.shrink();
    }

    // Falha ao carregar ou app em segundo plano: não reserva espaço
    // (evita "buraco" na tela).
    if (_failed || _bannerAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
