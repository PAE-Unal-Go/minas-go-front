import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'category_points_view.dart';
import '../widgets/explore_fab.dart';
import '../widgets/poi_card.dart';
import '../../../map/data/repositories/map_repository_impl.dart';
import '../../../map/domain/usecases/get_categorias.dart';
import '../../../map/domain/usecases/get_puntos_con_visita.dart';
import '../../../map/domain/entities/categoria.dart';
import '../../../map/domain/entities/punto_de_interes.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  static const Color _primaryMain = Color(0xFF171C8F);
  static const Color _secondaryMain = Color(0xFF37C8BE);
  static const Color _neutralBackground = Color(0xFFE7E8EE);
  static const Color _neutralSurface = Color(0xFFF7F8FB);
  static const Color _neutralBorder = Color(0xFFD2D6DF);
  static const Color _neutralTextPrimary = Color(0xFF091436);
  static const Color _neutralTextSecondary = Color(0xFF6A7587);

  final _repo = MapRepositoryImpl();
  late final GetCategorias _getCategorias;
  late final GetPuntosConVisita _getPuntosConVisita;

  List<Categoria> _categorias = [];
  Map<String, List<PuntoDeInteres>> _puntosPorCategoria = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _getCategorias = GetCategorias(_repo);
    _getPuntosConVisita = GetPuntosConVisita(_repo);

    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final [cats, puntos] = await Future.wait([
        _getCategorias(userId),
        _getPuntosConVisita(userId),
      ]);

      final grouped = <String, List<PuntoDeInteres>>{};
      for (final p in puntos as List<PuntoDeInteres>) {
        grouped.putIfAbsent(p.categoria, () => []).add(p);
      }

      if (mounted) {
        setState(() {
          _categorias = cats as List<Categoria>;
          _puntosPorCategoria = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  User? get _currentUser => Supabase.instance.client.auth.currentUser;

  String get _userName {
    final meta = _currentUser?.userMetadata;
    return meta?['full_name'] ?? meta?['name'] ?? 'Explorador';
  }

  String get _firstName {
    final trimmedName = _userName.trim();
    if (trimmedName.isEmpty) return 'Explorador';
    return trimmedName.split(RegExp(r'\s+')).first;
  }

  String? get _userAvatar {
    final meta = _currentUser?.userMetadata;
    return meta?['avatar_url'] ?? meta?['picture'];
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _primaryMain,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: _neutralBackground,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSectionTitle(),
                        Expanded(child: _buildBody()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: const ExploreFab(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF171C8F)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF6A7587)),
              const SizedBox(height: 12),
              Text(
                'Error cargando datos',
                style: TextStyle(color: _neutralTextPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextButton(onPressed: _loadData, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (_categorias.isEmpty) {
      return const Center(child: Text('No hay categorías disponibles.'));
    }
    return _buildPoiGrid();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 14, 26, 26),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFC84E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: _userAvatar != null
                  ? Image.network(
                      _userAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildAvatarFallback(),
                    )
                  : _buildAvatarFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $_firstName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFFFC84E),
      child: Center(
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: _neutralTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Explora las diferentes categorías',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _neutralTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cada una tiene una ruta con puntos por descubrir',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _neutralTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildPoiGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 108),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: _categorias.length,
      itemBuilder: (context, index) {
        final cat = _categorias[index];
        final puntos = _puntosPorCategoria[cat.key] ?? [];

        return PoiCard(
          name: cat.nombre,
          imageUrl: cat.imageUrl,
          unlockedPoints: cat.visitados,
          totalPoints: cat.totalPuntos,
          surfaceColor: _neutralSurface,
          borderColor: _neutralBorder,
          progressColor: _secondaryMain,
          textColor: _neutralTextPrimary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryPointsView(
                  categoryName: cat.nombre,
                  categoryDescription: _getCategoryDescription(cat.key),
                  categoryImageUrl: cat.imageUrl,
                  puntos: puntos,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getCategoryDescription(String key) {
    const map = {
      'arte_cultura': 'Espacios culturales, murales y puntos históricos',
      'deporte_salud': 'Espacios para actividad física y bienestar',
      'museos_laboratorios': 'Colecciones técnicas y espacios de experimentación',
      'academico': 'Bloques, aulas y zonas de aprendizaje',
      'medio_ambiente': 'Zonas verdes y rutas ecológicas',
      'servicios': 'Puntos de atención para la vida universitaria',
    };
    return map[key] ?? 'Puntos de interés del campus';
  }
}
