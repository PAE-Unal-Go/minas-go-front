import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_design_system.dart';
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
        backgroundColor: AppColors.primaryMain,
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
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xl),
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
        child: CircularProgressIndicator(color: AppColors.primaryMain),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: AppSpacing.s7,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(
                'Error cargando datos',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: AppTypography.weightBold,
                ),
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
              color: AppColors.secondaryLight,
              boxShadow: [
                AppShadows.shadowSm,
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
                    fontSize: AppTypography.fontSizeLg,
                    fontWeight: AppTypography.weightBold,
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
      color: AppColors.secondaryLight,
      child: Center(
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.fontSizeLg,
            fontWeight: AppTypography.weightBold,
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
              color: AppColors.textPrimary,
              fontSize: AppTypography.fontSizeLg,
              fontWeight: AppTypography.weightBold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Cada una tiene una ruta con puntos por descubrir',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppTypography.fontSizeXs,
              fontWeight: AppTypography.weightMedium,
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
        final cardImageUrl = switch (cat.key) {
          'arte_cultura' => 'assets/images/aula_maxima.jpg',
          'academico' => 'assets/images/museo_laboratorio.jpg',
          _ => cat.imageUrl,
        };

        return PoiCard(
          name: cat.nombre,
          imageUrl: cardImageUrl,
          unlockedPoints: cat.visitados,
          totalPoints: cat.totalPuntos,
          surfaceColor: AppColors.surface,
          borderColor: AppColors.border,
          progressColor: AppColors.secondaryMain,
          textColor: AppColors.textPrimary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryPointsView(
                  categoryName: cat.nombre,
                  categoryDescription: _getCategoryDescription(cat.key),
                  categoryImageUrl: cardImageUrl,
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
      'arte_cultura':
          'Explora los espacios donde el arte y la creatividad hacen parte de la vida universitaria. Descubre salas de exhibición, auditorios, murales, esculturas y lugares donde estudiantes y artistas comparten sus obras y expresiones culturales.',
      'deporte_salud':
          'Recorre los espacios dedicados al bienestar físico y mental de la comunidad universitaria. Encuentra canchas, zonas deportivas y actividades que promueven el deporte, la actividad física y la vida saludable dentro del campus.',
      'museos_laboratorios':
          'Descubre los espacios donde se genera conocimiento e innovación. Visita laboratorios, centros de investigación y lugares donde estudiantes y científicos desarrollan experimentos, proyectos y nuevas tecnologías.',
      'academico':
          'Conoce los lugares donde se desarrolla la formación académica de la universidad. Explora facultades, aulas, auditorios y bibliotecas donde miles de estudiantes construyen conocimiento en diferentes áreas del saber.',
      'medio_ambiente':
          'La sede Medellín se caracteriza por su riqueza natural y espacios verdes. Recorre jardines, zonas ecológicas y áreas naturales del campus donde la biodiversidad y el cuidado ambiental hacen parte de la experiencia universitaria.',
      'servicios':
          'Descubre los lugares que hacen posible el funcionamiento del campus. Encuentra transporte interno, cafeterías, espacios administrativos y servicios que apoyan la vida diaria de estudiantes, profesores y visitantes.',
    };
    return map[key] ?? 'Puntos de interés del campus';
  }
}
