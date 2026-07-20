# Calificar un punto al desbloquearlo

## Contexto

El backend expone la RPC `registrar_visita(p_usuario uuid, p_punto bigint, p_calificacion integer)`. `p_calificacion` es opcional (nullable): si viene, valida que esté entre 1 y 5; si el usuario ya tiene una visita registrada para ese punto (`ya_existe`), la función rechaza la operación entera con `{success: false, message: 'ya visitado'}` y no toca nada — es un INSERT-once, no sirve para actualizar una calificación después.

El frontend ya llama a `registrar_visita` en `MapRepositoryImpl.unlockPoi` (lib/features/map/data/repositories/map_repository_impl.dart:186), pero sin enviar `p_calificacion`.

## Objetivo

Permitir que el usuario califique el punto de 1 a 5 estrellas en el momento de desbloquearlo. La calificación es opcional — el usuario puede desbloquear sin calificar.

## Alcance

- Solo se cubre la calificación **al momento de desbloqueo** (vía `PoiBottomSheet`, antes de invocar `registrar_visita`).
- **Fuera de alcance:** calificar desde `PoiDetailView` un punto que ya fue desbloqueado anteriormente. `registrar_visita` no sirve para eso (ver arriba); se necesitaría una RPC de `UPDATE` sobre `visitas` que hoy no existe. Se retoma cuando esa función exista.
- No se muestra la calificación elegida en `PoiUnlockCard` tras desbloquear (ya existe `PoiRatingBadge` con el promedio del punto, que es un dato distinto: promedio de todos los usuarios vs. la calificación individual que este usuario acaba de dar).

## Cambios

### Selector de estrellas — `PoiBottomSheet` (lib/features/map/presentation/widgets/poi_bottom_sheet.dart)

- Nuevo widget privado `_RatingSelector` (`StatelessWidget`, recibe `selected: int?` y `onChanged: ValueChanged<int?>`): fila de 5 iconos de estrella tocables (`Icons.star_rounded` relleno hasta `selected`, `Icons.star_border_rounded` el resto). Tocar la estrella `n` ya seleccionada la deselecciona (vuelve a `null`, permite "saltar" la calificación); tocar otra estrella la selecciona.
- `_PoiBottomSheetState` gana `int? _selectedRating` (default `null`).
- Se muestra el `_RatingSelector` con una etiqueta "¿Deseas calificar este punto? Esto le ayudará a otros usuarios a decidir si visitarlo" **solo cuando `!isVisitado && _inRange`** (justo encima del botón "Desbloquear", dentro del mismo bloque condicional que hoy renderiza `_UnlockButton`).
- `widget.onUnlock` cambia de firma: de `Future<void> Function()` a `Future<void> Function(int? calificacion)`. `_triggerUnlock` pasa `_selectedRating`.

### `MapScreen` (lib/features/map/presentation/screens/map_screen.dart)

- `_showPoiBottomSheet`: `onUnlock: (calificacion) => _handleUnlock(punto, calificacion)`.
- `_handleUnlock` gana el parámetro `int? calificacion` y lo reenvía: `await _unlockPoi(userId, punto.id, calificacion: calificacion)`.

### `UnlockPoi` usecase (lib/features/map/domain/usecases/unlock_poi.dart)

```dart
Future<int> call(String userId, int puntoId, {int? calificacion}) {
  return repository.unlockPoi(userId, puntoId, calificacion: calificacion);
}
```

### `MapRepository` / `MapRepositoryImpl`

- `Future<int> unlockPoi(String userId, int puntoId, {int? calificacion});` en la interfaz.
- En la implementación, se agrega `'p_calificacion': calificacion` a los `params` del `rpc('registrar_visita', ...)`. El resto de la función (parseo de `puntos_ganados`, manejo de errores) no cambia.

## Fuera de alcance

- No se agrega ninguna RPC nueva de actualización de `visitas.calificacion`.
- No se modifica `PoiDetailView` ni `PoiUnlockCard`.
- No se valida el rango 1-5 en el frontend más allá de que el selector solo permite tocar 5 posiciones fijas (la validación real de rango ya la hace `registrar_visita` en el backend).
