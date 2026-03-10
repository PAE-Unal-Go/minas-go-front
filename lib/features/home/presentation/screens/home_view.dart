import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'category_points_view.dart';
import '../widgets/explore_fab.dart';
import '../widgets/poi_card.dart';

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

  // Mock categories that mirror the intended first release design.
  final List<Map<String, dynamic>> _mockPois = [
    {
      'name': 'Arte y Cultura',
      'categoryDescription': 'Espacios culturales, murales y puntos historicos',
      'imageUrl':
          'assets/images/arte_cultura.jpg',
      'points': [
        {
          'name': 'Esculturas Pedro Nel',
          'shortDescription': 'Coleccion patrimonial en espacio abierto.',
          'description':
              'Protegido por grandes árboles y entre un nacimiento de guadua enclavado en el campus de El Volador, en irónica alusión a los bosques colombianos, se encuentra el Tótem mítico de las selvas, una de las obras escultóricas que el maestro Pedro Nel Gómez produjo exclusivamente para su alma mater, la Universidad Nacional de Colombia Sede Medellín.',
          'imageUrl':
              'assets/images/esculturas_pedro.jpg',
          'discovered': true,
        },
        {
          'name': 'Aula Máxima',
          'shortDescription': 'Auditorio principal con los frescos de Pedro Nel.',
          'description':
              'La cúpula (1949-1953) es un conjunto que abarca 200 metros cuadrados pintados al fresco en la superficie curva. Se concibió para ser observada en movimiento. Es un fenómeno estético en el que mientras el observador deambula, ve la dimensión de todas las composiciones. La obra está dividida en ocho grupos en los cuales se plasmó el milenario espíritu del hombre: Amistad humana, Cooperación humana, La muerte, La vida, Espíritu mítico, Espíritu religioso, Espíritu científico y Las artes. Sus Laterales (1954-1970) están conformados por 6 secciones de 24 metros cuadrados cada una, que dan forma al cilindro del Aula Máxima. Son ellas: La patria, El hombre vence la gravedad, La explosión de la montaña, Choque de dos olas, Explosión de la flora y Los mineros de los organales.',
          'imageUrl':
              'assets/images/aula_maxima.jpg',
          'discovered': true,
        },
      ],
    },
    {
      'name': 'Deporte y Salud',
      'categoryDescription': 'Espacios para actividad fisica y bienestar',
      'imageUrl':
            'assets/images/deporte_salud.jpg',
      'points': [
        {
          'name': 'Cancha Multiproposito Facultad de Minas',
          'shortDescription': 'Zona activa para torneos estudiantiles.',
          'description':
              'Area deportiva de uso mixto para entrenamiento y torneos internos. Es uno de los puntos mas concurridos en actividades fisicas universitarias.',
          'imageUrl':
              'assets/images/cancha_multiproposito.jpg',
          'discovered': true,
        },
        {
          'name': 'Canchas de tennis',
          'shortDescription': 'Zona deportiva para practicar tenis.',
          'description':
              'Los estudiantes pueden solicitar el préstamo de las canchas de tenis de campo ubicadas frente al bloque M10, además de inscribirse a las clases para los diferentes niveles.',
          'imageUrl':
              'assets/images/canchas_tennis.jpg',
          'discovered': true,
        },
        {
          'name': 'Gimnasio M10',
          'shortDescription': 'Instalaciones deportivas para ejercicio y acondicionamiento físico.',
          'description':
              'Punto de orientacion para servicios de bienestar universitario, acompanamiento psicosocial y actividades de prevencion.',
          'imageUrl':
              'assets/images/deporte_salud.jpg',
          'discovered': false,
        },
      ],
    },
    {
      'name': 'Museos y Laboratorios',
      'categoryDescription':
          'Colecciones tecnicas y espacios de experimentacion',
      'imageUrl':
          'assets/images/museo_laboratorio.jpg',
      'points': [
        {
          'name': 'Museo de Geociencias',
          'shortDescription': 'Muestras geologicas de alto valor academico.',
          'description':
              'Coleccion de minerales y rocas usada en procesos formativos de geologia, minas y materiales. Incluye piezas historicas de la region.',
          'imageUrl':
              'https://images.unsplash.com/photo-1628595351029-c2bf17511435?auto=format&fit=crop&w=900&q=80',
          'discovered': true,
        },
        {
          'name': 'Laboratorio de Sistemas',
          'shortDescription': 'Ensayos y caracterizacion de materiales.',
          'description':
              'Espacio de analisis para pruebas mecanicas y fisicoquimicas. Permite validar propiedades y comportamiento de materiales en proyectos aplicados.',
          'imageUrl':
              'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?auto=format&fit=crop&w=900&q=80',
          'discovered': true,
        },
        {
          'name': 'Laboratorio de Hidráulica y Mecánica de Fluidos',
          'shortDescription': 'Ubicado en el primer piso del Bloque M7 - 101.',
          'description':
              'Zona equipada para simulacion numerica y analisis de datos en proyectos de investigacion y docencia.',
          'imageUrl':
              'https://images.unsplash.com/photo-1581093458791-9f3c3900df4b?auto=format&fit=crop&w=900&q=80',
          'discovered': true,
        },
      ],
    },
    {
      'name': 'Académico',
      'categoryDescription': 'Bloques, aulas y zonas de aprendizaje',
      'imageUrl':
          'assets/images/academico.jpg',
      'points': [
        {
          'name': 'Sala de estudio M3',
          'shortDescription': 'Espacio de trabajo colaborativo.',
          'description':
              'Bloque con salones para cursos de formacion basica. Cuenta con espacios de trabajo colaborativo y apoyo audiovisual.',
          'imageUrl':
              'https://images.unsplash.com/photo-1498243691581-b145c3f54a5a?auto=format&fit=crop&w=900&q=80',
          'discovered': false,
        },
      ],
    },
    {
      'name': 'Medio Ambiente',
      'categoryDescription': 'Zonas verdes y rutas ecologicas',
      'imageUrl':
          'assets/images/medio_ambiente.jpg',
      'points': [
        {
          'name': 'Huerta Unal',
          'shortDescription': 'Coleccion vegetal local.',
          'description':
              'Area de conservacion con especies de flora nativa usada en actividades de educacion ambiental y monitoreo de biodiversidad.',
          'imageUrl':
              'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?auto=format&fit=crop&w=900&q=80',
          'discovered': false,
        },
      ],
    },
    {
      'name': 'Servicios',
      'categoryDescription': 'Puntos de atencion para la vida universitaria',
      'imageUrl':
          'assets/images/servicio.jpg',
      'points': [
        {
          'name': 'Ágora',
          'shortDescription': 'Zona de comidas pricipal de la sede volador.',
          'description':
              'Punto principal para resolver tramites academicos y administrativos, con atencion personalizada para estudiantes.',
          'imageUrl':
              'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=900&q=80',
          'discovered': false,
        },
      ],
    },
  ];

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  User? get _currentUser => Supabase.instance.client.auth.currentUser;

  String get _userName {
    final meta = _currentUser?.userMetadata;
    return meta?['full_name'] ?? meta?['name'] ?? 'Explorador';
  }

  String? get _userAvatar {
    final meta = _currentUser?.userMetadata;
    return meta?['avatar_url'] ?? meta?['picture'];
  }

  //int get _discoveredCount =>
  //   _mockPois.where((p) => _getUnlockedPoints(p) > 0).length;

  int _getUnlockedPoints(Map<String, dynamic> category) {
    final points = category['points'] as List<Map<String, dynamic>>;
    return points.where((point) => point['discovered'] == true).length;
  }

  int _getTotalPoints(Map<String, dynamic> category) {
    final points = category['points'] as List<Map<String, dynamic>>;
    return points.length;
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
                        Expanded(child: _buildPoiGrid()),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
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
                  '¡Hola, $_userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
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
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explora las diferentes categorías',
            style: TextStyle(
              color: _neutralTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cada una tiene una ruta con puntos por descubrir',
            style: TextStyle(
              color: _neutralTextSecondary,
              fontSize: 14,
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
      itemCount: _mockPois.length,
      itemBuilder: (context, index) {
        final poi = _mockPois[index];
        final unlocked = _getUnlockedPoints(poi);
        final total = _getTotalPoints(poi);

        return PoiCard(
          name: poi['name'] as String,
          imageUrl: poi['imageUrl'] as String?,
          unlockedPoints: unlocked,
          totalPoints: total,
          surfaceColor: _neutralSurface,
          borderColor: _neutralBorder,
          progressColor: _secondaryMain,
          textColor: _neutralTextPrimary,
          subtitleColor: _neutralTextSecondary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryPointsView(
                  categoryName: poi['name'] as String,
                  categoryDescription: poi['categoryDescription'] as String,
                  categoryImageUrl: poi['imageUrl'] as String?,
                  points: poi['points'] as List<Map<String, dynamic>>,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
