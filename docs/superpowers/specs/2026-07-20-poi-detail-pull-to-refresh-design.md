# Pull-to-refresh en el detalle de un punto de interés

## Contexto

Los puntos de interés se cargan una sola vez al iniciar la app (`MapRepositoryImpl.getPuntosConVisita`) y quedan en memoria. Si un valor calculado por el backend cambia después (por ejemplo `calificacion_promedio`, cuando otros usuarios califican el punto), la app no lo refleja hasta el próximo reinicio: `PoiDetailView` siempre muestra los datos que tenía cacheados desde el arranque.

## Objetivo

Permitir refrescar los datos de un único punto desde `PoiDetailView`, mediante el gesto estándar de "pull-to-refresh" (jalar hacia abajo estando en la parte superior del scroll), sin tener que recargar todos los puntos de la app.

## Alcance

Al refrescar se vuelve a consultar la fila completa del punto en `puntos_de_interes` (no solo la calificación) y se reemplazan en pantalla nombre, descripción, imágenes, rareza y calificación. `visitado` no se refresca desde backend: se asume `true` siempre, porque a esta vista solo se llega para puntos ya desbloqueados (ver `category_points_view.dart` — el tile solo es tappable si `isVisitado`, y `PoiUnlockCard` navega aquí tras desbloquear).

## Cambios

### `MapRepository` (lib/features/map/domain/repositories/map_repository.dart)

Nuevo método:

```dart
/// Refetches a single punto de interés by id (used for pull-to-refresh on
/// the detail view). Always returns visitado = true, since this is only
/// called for points the user has already unlocked.
Future<PuntoDeInteres> getPuntoById(int id);
```

### `MapRepositoryImpl` (lib/features/map/data/repositories/map_repository_impl.dart)

```dart
@override
Future<PuntoDeInteres> getPuntoById(int id) async {
  try {
    final res = await _supabase
        .from('puntos_de_interes')
        .select()
        .eq('id', id)
        .single();
    final map = Map<String, dynamic>.from(res);
    map['visitado'] = true;
    return PuntoDeInteres.fromMap(map);
  } catch (e) {
    return Future.error('Error fetching punto by id: $e');
  }
}
```

### `PoiDetailView` (lib/features/home/presentation/screens/poi_detail_view.dart)

- Se instancia `final _repo = MapRepositoryImpl();` en el State, siguiendo el mismo patrón ya usado en `home_view.dart`, `map_screen.dart`, etc. (no hay contenedor de DI en este proyecto).
- Se agrega `late PuntoDeInteres _punto;`, inicializado en `initState()` desde `widget.punto`.
- Todas las referencias a `widget.punto` dentro de la clase (getters `_rarity`, `_isVisitado`, `_displayDescription`, `_images`, y los builders de las tarjetas) pasan a usar `_punto`.
- El `Expanded(child: SingleChildScrollView(...))` del body se envuelve en un `RefreshIndicator`:

```dart
Expanded(
  child: RefreshIndicator(
    onRefresh: _onRefresh,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, topContentPadding, 20, 80),
      child: Column(
        children: [
          _buildCard(),
          if (_displayDescription != null && _displayDescription!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildDescriptionBox(_displayDescription!),
          ],
        ],
      ),
    ),
  ),
),
```

  (`AlwaysScrollableScrollPhysics` is required — `RefreshIndicator` needs the scroll view to always allow overscroll to trigger the pull gesture, even when content is shorter than the viewport.)

- Nuevo método:

```dart
Future<void> _onRefresh() async {
  try {
    final fresh = await _repo.getPuntoById(_punto.id);
    if (!mounted) return;
    setState(() => _punto = fresh);
  } catch (_) {
    // Silently keep showing the previously loaded data; the pull-to-refresh
    // spinner simply stops. No error UI needed for a background refresh.
  }
}
```

## Fuera de alcance

- No se agrega refresco automático/periódico ni websockets: solo el gesto manual de pull-to-refresh.
- No se modifica `CategoryPointsView` ni el grid de puntos — el refresco es exclusivo del detalle de un punto individual.
- No se muestra un mensaje de error visible si el refresh falla; se degrada silenciosamente a los datos previos (evita interrumpir al usuario por un fallo de red transitorio).
