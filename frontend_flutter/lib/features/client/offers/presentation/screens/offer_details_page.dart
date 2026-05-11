import 'package:cadife_smart_travel/core/cache/isar_cache_manager.dart';
import 'package:cadife_smart_travel/core/cache/isar_schemas/isar_schemas.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

// ── Internal mock data structures ────────────────────────

class _ItineraryDay {
  final int day;
  final String title;
  final String description;
  final IconData icon;

  const _ItineraryDay({
    required this.day,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _Highlight {
  final IconData icon;
  final String label;
  const _Highlight(this.icon, this.label);
}

class _OfferMockDetails {
  final int durationDays;
  final int durationNights;
  final double rating;
  final int reviewCount;
  final List<String> photoSeeds;
  final List<_ItineraryDay> itinerary;
  final List<String> included;
  final List<String> notIncluded;
  final List<_Highlight> highlights;
  final String departureCity;
  final int maxGroupSize;
  final String bestSeason;
  final String suggestedDates;

  const _OfferMockDetails({
    required this.durationDays,
    required this.durationNights,
    required this.rating,
    required this.reviewCount,
    required this.photoSeeds,
    required this.itinerary,
    required this.included,
    required this.notIncluded,
    required this.highlights,
    required this.departureCity,
    required this.maxGroupSize,
    required this.bestSeason,
    required this.suggestedDates,
  });
}

// ── Mock data generator ───────────────────────────────────

_OfferMockDetails _mockDetailsFor(Offer offer) {
  final idx = int.tryParse(offer.id.replaceAll('offer-', '')) ?? 0;

  return switch (offer.category) {
    'Sol & Praia' => _OfferMockDetails(
        durationDays: 7 + (idx % 4),
        durationNights: 6 + (idx % 4),
        rating: 4.5 + (idx % 3) * 0.1,
        reviewCount: 128 + idx * 7,
        suggestedDates: 'Jan – Abr | Jul – Out',
        photoSeeds: [
          'beach$idx', 'sea${idx + 1}', 'sunset${idx + 2}',
          'resort${idx + 3}', 'pool${idx + 4}',
        ],
        highlights: const [
          _Highlight(LucideIcons.waves, 'Praias paradisíacas'),
          _Highlight(LucideIcons.sun, 'Clima tropical'),
          _Highlight(LucideIcons.hotel, 'Resort 5 estrelas'),
          _Highlight(LucideIcons.utensils, 'All-inclusive'),
        ],
        included: const [
          'Passagem aérea (ida e volta)',
          'Transfer aeroporto / hotel',
          'Hospedagem em resort 5★',
          'Café da manhã e jantar',
          'Passeio de snorkel',
          'Seguro viagem',
        ],
        notIncluded: const [
          'Almoços avulsos',
          'Passeios extras opcionais',
          'Despesas pessoais',
          'Gorjetas',
        ],
        itinerary: [
          const _ItineraryDay(
            day: 1,
            title: 'Chegada e Check-in',
            description:
                'Receptivo no aeroporto, transfer ao resort e acomodação. Noite de boas-vindas com jantar na praia ao pôr do sol.',
            icon: LucideIcons.planeLanding,
          ),
          const _ItineraryDay(
            day: 2,
            title: 'Dia de Praia Livre',
            description:
                'Dia inteiramente livre para aproveitar as praias de areia branca e as águas cristalinas. À tarde, opção de snorkel com instrutores credenciados.',
            icon: LucideIcons.umbrella,
          ),
          const _ItineraryDay(
            day: 3,
            title: 'Passeio de Barco',
            description:
                'Excursão de barco pelas ilhas vizinhas com paradas para mergulho e almoço a bordo. Vista deslumbrante dos corais coloridos.',
            icon: LucideIcons.ship,
          ),
          const _ItineraryDay(
            day: 4,
            title: 'Spa & Relaxamento',
            description:
                'Dia de descanso total com acesso ao spa do resort. Massagem relaxante de 60 min incluída. Piscinas infinitas com vista para o mar.',
            icon: LucideIcons.sparkles,
          ),
          const _ItineraryDay(
            day: 5,
            title: 'Gastronomia Local',
            description:
                'Tour gastronômico pela vila pesqueira com degustação de frutos do mar frescos. Jantar especial com culinária típica do destino.',
            icon: LucideIcons.utensils,
          ),
          const _ItineraryDay(
            day: 6,
            title: 'Esportes Aquáticos',
            description:
                'Tarde de aventura com windsurf, stand-up paddle e caiaque. Equipamentos e instrutor inclusos. Fotos profissionais do passeio.',
            icon: LucideIcons.waves,
          ),
          const _ItineraryDay(
            day: 7,
            title: 'Retorno',
            description:
                'Café da manhã especial de despedida, check-out com late check-out até as 14h e transfer ao aeroporto para o voo de retorno.',
            icon: LucideIcons.planeTakeoff,
          ),
        ],
        departureCity: 'São Paulo (GRU)',
        maxGroupSize: 2 + idx % 5,
        bestSeason: 'Mar – Nov',
      ),

    'Neve & Frio' => _OfferMockDetails(
        durationDays: 8 + (idx % 3),
        durationNights: 7 + (idx % 3),
        rating: 4.6 + (idx % 3) * 0.1,
        reviewCount: 95 + idx * 5,
        suggestedDates: 'Nov – Mar',
        photoSeeds: [
          'snow$idx', 'ski${idx + 1}', 'mountain${idx + 2}',
          'chalet${idx + 3}', 'alps${idx + 4}',
        ],
        highlights: const [
          _Highlight(LucideIcons.snowflake, 'Neve garantida'),
          _Highlight(LucideIcons.mountain, 'Esqui e snowboard'),
          _Highlight(LucideIcons.flame, 'Chalé aconchegante'),
          _Highlight(LucideIcons.wine, 'Fondue e vinhos'),
        ],
        included: const [
          'Passagem aérea (ida e volta)',
          'Transfer aeroporto / chalé',
          'Hospedagem em chalé premium',
          'Café da manhã e jantar',
          'Skipass 5 dias',
          'Equipamentos de esqui',
          'Seguro viagem com cobertura neve',
        ],
        notIncluded: const [
          'Aulas de esqui avulsas',
          'Roupas de neve (aluguel disponível)',
          'Almoços',
          'Passeios extras',
        ],
        itinerary: [
          const _ItineraryDay(
            day: 1,
            title: 'Chegada e Acomodação',
            description:
                'Chegada ao destino nevado, instalação no chalé e jantar de fondue tradicional com vinhos da região.',
            icon: LucideIcons.planeLanding,
          ),
          const _ItineraryDay(
            day: 2,
            title: 'Primeiro Dia nas Pistas',
            description:
                'Pistas para iniciantes e intermediários. Instrutores certificados disponíveis. Tarde livre para explorar.',
            icon: LucideIcons.mountain,
          ),
          const _ItineraryDay(
            day: 3,
            title: 'Ski Avançado',
            description:
                'Pistas intermediárias e avançadas com vistas panorâmicas. Tarde livre para snowboard ou trenó.',
            icon: LucideIcons.chevronDown,
          ),
          const _ItineraryDay(
            day: 4,
            title: 'Vila e Gastronomia',
            description:
                'Passeio pela vila típica, lojas de artesanato e degustação de queijos e vinhos locais.',
            icon: LucideIcons.mapPin,
          ),
          const _ItineraryDay(
            day: 5,
            title: 'Descida Panorâmica',
            description:
                'Descida panorâmica guiada com vista para os Alpes. Fotos profissionais incluídas.',
            icon: LucideIcons.camera,
          ),
          const _ItineraryDay(
            day: 6,
            title: 'Spa de Montanha',
            description:
                'Relaxamento no spa com sauna, banho de vapor e massagem sueca de 60 min.',
            icon: LucideIcons.sparkles,
          ),
          const _ItineraryDay(
            day: 7,
            title: 'Trilha na Neve',
            description:
                'Caminhada guiada com snowshoes pelos bosques nevados. Chocolate quente e brunch ao final.',
            icon: LucideIcons.footprints,
          ),
          const _ItineraryDay(
            day: 8,
            title: 'Retorno',
            description:
                'Café da manhã de despedida no chalé e transfer ao aeroporto para o voo de retorno.',
            icon: LucideIcons.planeTakeoff,
          ),
        ],
        departureCity: 'São Paulo (GRU)',
        maxGroupSize: 2 + idx % 4,
        bestSeason: 'Dez – Mar',
      ),

    'Urbano & Cultura' => _OfferMockDetails(
        durationDays: 6 + (idx % 4),
        durationNights: 5 + (idx % 4),
        rating: 4.4 + (idx % 4) * 0.1,
        reviewCount: 210 + idx * 9,
        suggestedDates: 'Mar – Jun | Set – Nov',
        photoSeeds: [
          'city$idx', 'museum${idx + 1}', 'street${idx + 2}',
          'architecture${idx + 3}', 'restaurant${idx + 4}',
        ],
        highlights: const [
          _Highlight(LucideIcons.landmark, 'Museus e monumentos'),
          _Highlight(LucideIcons.utensils, 'Gastronomia premiada'),
          _Highlight(LucideIcons.map, 'Roteiro exclusivo'),
          _Highlight(LucideIcons.micVocal, 'Shows e eventos'),
        ],
        included: const [
          'Passagem aérea (ida e volta)',
          'Transfer aeroporto / hotel',
          'Hospedagem em hotel boutique 4★',
          'Café da manhã',
          'City tour guiado (2 dias)',
          'Ingressos para 3 museus',
          'Seguro viagem',
        ],
        notIncluded: const [
          'Almoços e jantares avulsos',
          'Transporte local (metrô)',
          'Compras e souvenirs',
          'Shows e eventos extras',
        ],
        itinerary: [
          const _ItineraryDay(
            day: 1,
            title: 'Chegada e Orientação',
            description:
                'Check-in no hotel boutique no coração da cidade. Passeio a pé pelo bairro histórico ao entardecer.',
            icon: LucideIcons.planeLanding,
          ),
          const _ItineraryDay(
            day: 2,
            title: 'Museus e Arte',
            description:
                'Visita guiada aos principais museus da cidade. Tarde livre para galerias de arte independentes.',
            icon: LucideIcons.landmark,
          ),
          const _ItineraryDay(
            day: 3,
            title: 'Gastronomia Local',
            description:
                'Tour gastronômico pelos melhores restaurantes e mercados locais com chef consultor.',
            icon: LucideIcons.utensils,
          ),
          const _ItineraryDay(
            day: 4,
            title: 'Arquitetura e História',
            description:
                'City tour de ônibus panorâmico com paradas nos principais pontos históricos.',
            icon: LucideIcons.building,
          ),
          const _ItineraryDay(
            day: 5,
            title: 'Dia Livre',
            description:
                'Dia completamente livre para explorar, fazer compras ou relaxar em parques urbanos.',
            icon: LucideIcons.map,
          ),
          const _ItineraryDay(
            day: 6,
            title: 'Retorno',
            description:
                'Última manhã para passeio livre, almoço no restaurante favorito e transfer ao aeroporto.',
            icon: LucideIcons.planeTakeoff,
          ),
        ],
        departureCity: 'São Paulo (GRU)',
        maxGroupSize: 2 + idx % 6,
        bestSeason: 'Abr – Jun / Set – Nov',
      ),

    'Aventura & Natureza' => _OfferMockDetails(
        durationDays: 9 + (idx % 3),
        durationNights: 8 + (idx % 3),
        rating: 4.7 + (idx % 2) * 0.1,
        reviewCount: 73 + idx * 6,
        suggestedDates: 'Abr – Set',
        photoSeeds: [
          'trek$idx', 'wildlife${idx + 1}', 'forest${idx + 2}',
          'waterfall${idx + 3}', 'camping${idx + 4}',
        ],
        highlights: const [
          _Highlight(LucideIcons.treeDeciduous, 'Trilhas exclusivas'),
          _Highlight(LucideIcons.binoculars, 'Fauna nativa'),
          _Highlight(LucideIcons.tent, 'Acampamento premium'),
          _Highlight(LucideIcons.camera, 'Fotografia de natureza'),
        ],
        included: const [
          'Passagem aérea (ida e volta)',
          'Transfer e traslados internos',
          'Acampamento / lodge ecológico',
          'Todas as refeições',
          'Guia especialista em fauna',
          'Equipamentos de trekking',
          'Seguro viagem aventura',
        ],
        notIncluded: const [
          'Equipamentos pessoais',
          'Bebidas alcoólicas',
          'Gorjetas para guias',
          'Passeios extras',
        ],
        itinerary: [
          const _ItineraryDay(
            day: 1,
            title: 'Chegada na Natureza',
            description:
                'Receptivo no aeroporto e traslado até o lodge ecológico. Briefing de segurança e jantar com produtos locais.',
            icon: LucideIcons.planeLanding,
          ),
          const _ItineraryDay(
            day: 2,
            title: 'Trilha das Cachoeiras',
            description:
                'Trilha guiada até as cachoeiras com banho natural. Nível moderado, 8km de percurso.',
            icon: LucideIcons.waves,
          ),
          const _ItineraryDay(
            day: 3,
            title: 'Observação de Fauna',
            description:
                'Saída ao amanhecer para observar a fauna nativa com binóculos profissionais e guia especializado.',
            icon: LucideIcons.binoculars,
          ),
          const _ItineraryDay(
            day: 4,
            title: 'Canoagem',
            description:
                'Descida de canoa pelo rio principal com paradas para nadar. Piquenique nas margens.',
            icon: LucideIcons.anchor,
          ),
          const _ItineraryDay(
            day: 5,
            title: 'Acampamento na Mata',
            description:
                'Noite de acampamento com fogueira, contação de histórias e observação de estrelas.',
            icon: LucideIcons.tent,
          ),
          const _ItineraryDay(
            day: 6,
            title: 'Rapel e Tirolesa',
            description:
                'Atividades de rapel em cachoeiras e tirolesa sobre o dossel da floresta com monitores certificados.',
            icon: LucideIcons.mountain,
          ),
          const _ItineraryDay(
            day: 7,
            title: 'Fotografia na Natureza',
            description:
                'Workshop de fotografia de natureza com profissional. Trilha fotográfica ao amanhecer.',
            icon: LucideIcons.camera,
          ),
          const _ItineraryDay(
            day: 8,
            title: 'Dia Livre no Lodge',
            description:
                'Relaxamento no lodge. Opção de spa natural, massagem e banho de ofurô.',
            icon: LucideIcons.sparkles,
          ),
          const _ItineraryDay(
            day: 9,
            title: 'Retorno',
            description:
                'Café da manhã especial de despedida e traslado ao aeroporto.',
            icon: LucideIcons.planeTakeoff,
          ),
        ],
        departureCity: 'São Paulo (GRU)',
        maxGroupSize: 2 + idx % 4,
        bestSeason: 'Mai – Set',
      ),

    _ /* Cruzeiro e outros */ => _OfferMockDetails(
        durationDays: 10 + (idx % 3),
        durationNights: 9 + (idx % 3),
        rating: 4.5 + (idx % 3) * 0.1,
        reviewCount: 156 + idx * 8,
        suggestedDates: 'Out – Mar',
        photoSeeds: [
          'cruise$idx', 'port${idx + 1}', 'deck${idx + 2}',
          'ocean${idx + 3}', 'island${idx + 4}',
        ],
        highlights: const [
          _Highlight(LucideIcons.ship, 'Navio de luxo'),
          _Highlight(LucideIcons.utensils, 'Buffet premium'),
          _Highlight(LucideIcons.music, 'Shows a bordo'),
          _Highlight(LucideIcons.anchor, 'Portos exclusivos'),
        ],
        included: const [
          'Passagem aérea (ida e volta)',
          'Transfer aeroporto / porto',
          'Cabine oceanview no navio',
          'Todas as refeições a bordo',
          'Entretenimento e shows',
          'Taxas portuárias',
          'Seguro viagem',
        ],
        notIncluded: const [
          'Excursões em terra (opcionais)',
          'Bebidas premium',
          'Spa e tratamentos',
          'Gorjetas de serviço',
        ],
        itinerary: [
          const _ItineraryDay(
            day: 1,
            title: 'Embarque',
            description:
                'Embarque no porto, exploração do navio e jantar de gala de boas-vindas no restaurante principal.',
            icon: LucideIcons.ship,
          ),
          const _ItineraryDay(
            day: 2,
            title: 'Dia no Mar',
            description:
                'Dia de navegação com atividades a bordo: piscinas, shows, academia e degustação de vinhos.',
            icon: LucideIcons.waves,
          ),
          const _ItineraryDay(
            day: 3,
            title: '1ª Parada: Porto',
            description:
                'Primeira escala. Excursão opcional pela cidade histórica com guia local. Retorno ao navio às 18h.',
            icon: LucideIcons.anchor,
          ),
          const _ItineraryDay(
            day: 4,
            title: '2ª Parada: Ilha',
            description:
                'Parada em ilha paradisíaca. Praias de águas cristalinas e vila colorida de pescadores.',
            icon: LucideIcons.mapPin,
          ),
          const _ItineraryDay(
            day: 5,
            title: 'Dia de Cruzeiro',
            description:
                'Navegação com torneio de atividades esportivas no deck e show de comédia à noite.',
            icon: LucideIcons.gamepad2,
          ),
          const _ItineraryDay(
            day: 6,
            title: '3ª Parada: Capital',
            description:
                'Escala na capital com city tour guiado e tarde livre para compras em shoppings locais.',
            icon: LucideIcons.landmark,
          ),
          const _ItineraryDay(
            day: 7,
            title: 'Noite de Gala',
            description:
                'Jantar de gala temático com música ao vivo e show de circo contemporâneo.',
            icon: LucideIcons.music,
          ),
          const _ItineraryDay(
            day: 8,
            title: '4ª Parada: Arquipélago',
            description:
                'Visita a arquipélago protegido. Snorkel com tartarugas e golfinhos. Retorno ao pôr do sol.',
            icon: LucideIcons.sun,
          ),
          const _ItineraryDay(
            day: 9,
            title: 'Último Dia no Mar',
            description:
                'Navegação de retorno com brunch especial e festa de encerramento no deck panorâmico.',
            icon: LucideIcons.partyPopper,
          ),
          const _ItineraryDay(
            day: 10,
            title: 'Desembarque',
            description:
                'Café da manhã a bordo, desembarque organizado e transfer ao aeroporto.',
            icon: LucideIcons.planeTakeoff,
          ),
        ],
        departureCity: 'Santos (SP)',
        maxGroupSize: 2 + idx % 6,
        bestSeason: 'Nov – Mar',
      ),
  };
}

// ── Service icon helper ───────────────────────────────────

IconData _iconForService(String service) {
  final s = service.toLowerCase();
  if (s.contains('passagem') || s.contains('aérea') || s.contains('aéreo')) {
    return LucideIcons.planeTakeoff;
  }
  if (s.contains('transfer') || s.contains('traslado')) return LucideIcons.car;
  if (s.contains('resort') || s.contains('hotel') || s.contains('hospedagem') || s.contains('chalé')) {
    return LucideIcons.hotel;
  }
  if (s.contains('lodge') || s.contains('acampamento')) return LucideIcons.tent;
  if (s.contains('navio') || s.contains('cabine') || s.contains('porto')) return LucideIcons.ship;
  if (s.contains('café') || s.contains('refeição') || s.contains('refeições') ||
      s.contains('jantar') || s.contains('almoço')) {
    return LucideIcons.utensils;
  }
  if (s.contains('skipass') || s.contains('ingresso') || s.contains('ingressos') ||
      s.contains('show') || s.contains('entretenimento')) {
    return LucideIcons.tag;
  }
  if (s.contains('equipamento')) return LucideIcons.package;
  if (s.contains('guia') || s.contains('tour') || s.contains('city')) return LucideIcons.map;
  if (s.contains('taxa')) return LucideIcons.receipt;
  if (s.contains('seguro')) return LucideIcons.shield;
  return LucideIcons.circleCheck;
}

// ── Page ─────────────────────────────────────────────────

class OfferDetailsPage extends ConsumerStatefulWidget {
  final String offerId;
  final Offer? offer;

  const OfferDetailsPage({
    required this.offerId,
    super.key,
    this.offer,
  });

  @override
  ConsumerState<OfferDetailsPage> createState() => _OfferDetailsPageState();
}

class _OfferDetailsPageState extends ConsumerState<OfferDetailsPage> {
  late final _OfferMockDetails _details;
  final List<bool> _expandedDays = [];
  late final PageController _pageController;
  int _galleryPage = 0;
  bool _isDescriptionExpanded = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.offer != null) {
      _details = _mockDetailsFor(widget.offer!);
      _expandedDays.addAll(List.filled(_details.itinerary.length, false));
      WidgetsBinding.instance.addPostFrameCallback((_) => _cacheOffer());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cacheOffer() async {
    final offer = widget.offer;
    if (offer == null) return;
    final cache = OfferCache(
      serverId: offer.id,
      title: offer.title,
      destination: offer.destination,
      category: offer.category,
      description: offer.description,
      estimatedPrice: offer.estimatedPrice,
      imageUrl: offer.imageUrl,
      updatedAt: DateTime.now(),
    );
    await sl<IsarCacheManager>().putOffer(cache);
  }

  void _shareOffer(Offer offer) {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Confira esta oferta da Cadife Tour:\n\n${offer.title} — ${offer.destination}\nA partir de R\$ ${offer.estimatedPrice.toStringAsFixed(2)} por pessoa.',
        subject: offer.title,
      ),
    );
  }

  Future<void> _submitInterest(Offer offer) async {
    setState(() => _isSubmitting = true);
    try {
      // POST /leads { origem: "oferta", oferta_id: offer.id }
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interesse registrado! Um consultor entrará em contato em breve.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.offer == null) {
      return _buildNotFound(theme);
    }

    final offer = widget.offer!;
    final priceFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.zinc950 : AppColors.white,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildSliverAppBar(offer, isDark),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(offer, theme, isDark),
                      _buildPhotoGallery(offer, isDark),
                      _buildPriceSection(offer, theme, priceFormatter, isDark),
                      _buildHighlights(theme, isDark),
                      _buildIncluded(theme, isDark),
                      _buildItinerary(theme, isDark),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
            _buildBottomCTA(offer, theme, priceFormatter, isDark),
          ],
        ),
      ),
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────

  Widget _buildSliverAppBar(Offer offer, bool isDark) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.zinc950 : AppColors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black45,
          child: IconButton(
            icon: const Icon(LucideIcons.arrowLeft,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black45,
            child: IconButton(
              icon: const Icon(LucideIcons.share2,
                  color: Colors.white, size: 18),
              onPressed: () => _shareOffer(offer),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Hero(
          tag: 'offer_hero_${offer.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                offer.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, _) => Container(
                  color: AppColors.zinc800,
                  child: const Icon(LucideIcons.imageOff,
                      size: 48, color: AppColors.zinc600),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          offer.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        titlePadding:
            const EdgeInsetsDirectional.only(start: 56, bottom: 16),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────

  Widget _buildHeader(Offer offer, dynamic theme, bool isDark) {
    final borderColor = isDark ? AppColors.zinc800 : AppColors.zinc200;
    final textSecondary = isDark ? AppColors.zinc400 : AppColors.zinc600;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              offer.category,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            offer.title,
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Destination row
          Row(
            children: [
              const Icon(LucideIcons.mapPin,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                offer.destination,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row 1: rating + duration
          Row(
            children: [
              _buildStatChip(
                icon: LucideIcons.star,
                label:
                    '${_details.rating.toStringAsFixed(1)} (${_details.reviewCount} avaliações)',
                iconColor: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: LucideIcons.calendarDays,
                label:
                    '${_details.durationDays}D / ${_details.durationNights}N',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stats row 2: group size + departure city
          Row(
            children: [
              _buildStatChip(
                icon: LucideIcons.users,
                label: 'Até ${_details.maxGroupSize} pessoas',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: LucideIcons.planeTakeoff,
                label: _details.departureCity,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stats row 3: suggested dates + best season
          Row(
            children: [
              _buildStatChip(
                icon: LucideIcons.calendarRange,
                label: 'Datas: ${_details.suggestedDates}',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: LucideIcons.sun,
                label: _details.bestSeason,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: borderColor),
          const SizedBox(height: 20),

          // Description with collapsible "Ver mais"
          Text(
            'Sobre o pacote',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            firstChild: Text(
              offer.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textSecondary,
                height: 1.6,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              offer.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textSecondary,
                height: 1.6,
              ),
            ),
            crossFadeState: _isDescriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () =>
                setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
            child: Text(
              _isDescriptionExpanded ? 'Ver menos' : 'Ver mais',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? iconColor,
  }) {
    final bg = isDark ? AppColors.zinc900 : AppColors.zinc100;
    final text = isDark ? AppColors.zinc300 : AppColors.zinc700;
    final effectiveIconColor =
        iconColor ?? (isDark ? AppColors.zinc400 : AppColors.zinc600);

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: effectiveIconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(color: text),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photo Gallery (PageView + dots) ────────────────────

  Widget _buildPhotoGallery(Offer offer, bool isDark) {
    final allPhotos = [
      offer.imageUrl,
      ..._details.photoSeeds
          .map((s) => 'https://picsum.photos/seed/$s/600/400'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Galeria de Fotos',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _galleryPage = i),
              itemCount: allPhotos.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    allPhotos[i],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, _) => Container(
                      color: AppColors.zinc700,
                      child: const Icon(LucideIcons.imageOff,
                          color: AppColors.zinc500),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(allPhotos.length, (i) {
              final isActive = i == _galleryPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? AppColors.zinc600 : AppColors.zinc300),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Price Section ──────────────────────────────────────

  Widget _buildPriceSection(
    Offer offer,
    dynamic theme,
    NumberFormat formatter,
    bool isDark,
  ) {
    final cardBg = isDark ? AppColors.zinc900 : AppColors.zinc50;
    final borderColor = isDark ? AppColors.zinc800 : AppColors.zinc200;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valor estimado',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? AppColors.zinc400 : AppColors.zinc600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(offer.estimatedPrice),
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'por pessoa',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.zinc500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.tag,
                  color: AppColors.primary, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  // ── Highlights ─────────────────────────────────────────

  Widget _buildHighlights(dynamic theme, bool isDark) {
    final cardBg = isDark ? AppColors.zinc900 : AppColors.zinc50;
    final borderColor = isDark ? AppColors.zinc800 : AppColors.zinc200;
    final textColor = isDark ? AppColors.zinc200 : AppColors.zinc800;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destaques',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: _details.highlights.map((h) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(h.icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        h.label,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: textColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Included / Not Included ────────────────────────────

  Widget _buildIncluded(dynamic theme, bool isDark) {
    final borderColor = isDark ? AppColors.zinc800 : AppColors.zinc200;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O que está incluído',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._details.included
              .map((item) => _buildServiceItem(item, true, isDark)),
          const SizedBox(height: 20),
          Divider(color: borderColor),
          const SizedBox(height: 20),
          Text(
            'Não incluído',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._details.notIncluded
              .map((item) => _buildServiceItem(item, false, isDark)),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String text, bool included, bool isDark) {
    final icon = included ? _iconForService(text) : LucideIcons.circleX;
    final color = included ? AppColors.primary : AppColors.zinc500;
    final textColor = isDark ? AppColors.zinc300 : AppColors.zinc700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Itinerary ──────────────────────────────────────────

  Widget _buildItinerary(dynamic theme, bool isDark) {
    final borderColor = isDark ? AppColors.zinc800 : AppColors.zinc200;
    final cardBg = isDark ? AppColors.zinc900 : AppColors.zinc50;
    final textSecondary = isDark ? AppColors.zinc400 : AppColors.zinc600;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Roteiro Dia a Dia',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ..._details.itinerary.asMap().entries.map((entry) {
            final i = entry.key;
            final day = entry.value;
            final isExpanded = _expandedDays[i];

            return GestureDetector(
              onTap: () =>
                  setState(() => _expandedDays[i] = !isExpanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isExpanded
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExpanded
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : borderColor,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.zinc800
                                      : AppColors.zinc200),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                day.icon,
                                size: 16,
                                color: isExpanded
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.zinc400
                                        : AppColors.zinc600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dia ${day.day}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isExpanded
                                        ? AppColors.primary
                                        : textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  day.title,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 18,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(62, 0, 14, 14),
                        child: Text(
                          day.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Bottom CTA ─────────────────────────────────────────

  Widget _buildBottomCTA(
    Offer offer,
    dynamic theme,
    NumberFormat formatter,
    bool isDark,
  ) {
    final bg = isDark ? AppColors.zinc950 : AppColors.white;
    final borderColor = isDark ? AppColors.zinc800 : AppColors.zinc200;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A partir de',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? AppColors.zinc400 : AppColors.zinc600,
                    ),
                  ),
                  Text(
                    formatter.format(offer.estimatedPrice),
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: CadifeButton(
                label: 'Tenho interesse',
                icon: LucideIcons.heart,
                onPressed: _isSubmitting
                    ? null
                    : () => _onTenhoInteresse(offer, formatter, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTenhoInteresse(Offer offer, NumberFormat formatter, bool isDark) {
    final sheetBg = isDark ? AppColors.zinc900 : AppColors.white;
    final sheetBorder = isDark ? AppColors.zinc800 : AppColors.zinc200;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: sheetBorder)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.zinc400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Confirmar interesse',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Um consultor especializado da Cadife Tour entrará em contato para elaborar uma proposta personalizada para ${offer.destination}.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.zinc400 : AppColors.zinc600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Offer summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mapPin,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title,
                            style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            offer.destination,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.zinc500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'A partir de\n${formatter.format(offer.estimatedPrice)}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _submitInterest(offer);
                      },
                      child: const Text(
                        'Confirmar interesse',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Not Found Fallback ─────────────────────────────────

  Widget _buildNotFound(dynamic theme) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Detalhes da Oferta'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.packageSearch,
                  size: 64, color: AppColors.zinc400),
              SizedBox(height: 16),
              Text(
                'Oferta não encontrada',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Não foi possível carregar os detalhes desta oferta. Volte e tente novamente.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
