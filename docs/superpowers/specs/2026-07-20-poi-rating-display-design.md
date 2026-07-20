# Mostrar calificación promedio de puntos de interés

## Contexto

Cada punto de interés (POI) tiene ya en backend una calificación promedio asignada por usuarios, en el campo `calificacion_promedio` de la tabla `puntos_de_interes`. Actualmente el frontend no consume ni muestra este dato en ningún lugar.

## Objetivo

Mostrar la calificación promedio de un punto:
1. En la tarjeta de desbloqueo (`PoiUnlockCard`), al momento en que el usuario descubre el punto.
2. En la vista de detalle del punto (`PoiDetailView`), solo cuando el punto ya está visitado/desbloqueado.

No se muestra en el estado bloqueado (card de "Bloqueado"), porque el punto todavía no fue descubierto.

## Modelo de datos

`PuntoDeInteres` (lib/features/map/domain/entities/punto_de_interes.dart) gana un campo nuevo:

```dart
final double? calificacionPromedio;
```

- Parseado en `fromMap` desde `map['calificacion_promedio']`, tolerando `int`, `double` o `null`:
  ```dart
  calificacionPromedio: (map['calificacion_promedio'] as num?)?.toDouble(),
  ```
- Es opcional (default `null`), no rompe otros constructores existentes en el código (home_view, map_screen, etc. usan named args).

## Presentación

Formato: número + icono de estrella. Ej: `★ 4.5`.

- Si `calificacionPromedio` es `null` o `0`: mostrar texto "Sin calificar" en gris apagado, mismo lugar donde iría el rating (no se oculta el bloque completo, para mantener el layout consistente).
- Si tiene valor > 0: icono `Icons.star_rounded` color ámbar (`Color(0xFFF59E0B)`, consistente con el color usado para puntos/badges en el resto de la UI) + texto del número con un decimal (`toStringAsFixed(1)`).

Se crea un widget pequeño y reutilizable `PoiRatingBadge` en un archivo nuevo `lib/core/widgets/poi_rating_badge.dart`, que recibe `double? rating` y produce el chip descrito arriba. Se reutiliza en ambos lugares para evitar duplicar estilos.

## Ubicación exacta

### `PoiUnlockCard` (lib/features/map/presentation/widgets/poi_unlock_card.dart)

Dentro de `_buildCard()`, en la sección de info (`Padding` en línea ~458), justo después de `_buildRarityRow(punto.rarity, widget.pointsEarned)` (línea 493) y antes del bloque de descripción. Se agrega con `SizedBox(height: 8)` de separación, como una fila adicional con el `PoiRatingBadge`.

### `PoiDetailView` (lib/features/home/presentation/screens/poi_detail_view.dart)

Se muestra únicamente cuando `widget.punto.visitado == true` (ya excluye `_lockedCard()`, que no se toca).

- `_basicCard()`: junto al texto de categoría (línea ~350), debajo del nombre.
- `_importantCard()`: junto al texto de categoría (línea ~467).
- `_legendaryCard()` → `_legendaryInfoOverlay()`: junto al texto de categoría (línea ~733).

En los tres casos se añade el `PoiRatingBadge` en la misma fila o inmediatamente debajo de la categoría, adaptando el color de texto al tema oscuro/claro de cada variante (el widget acepta un parámetro opcional de color base para adaptarse a fondos oscuros).

## Fuera de alcance

- No se toca `poi_bottom_sheet.dart` ni `category_points_view.dart` (grid de puntos): el usuario solo pidió unlock card y detail view.
- No se agrega funcionalidad para que el usuario califique (solo lectura del promedio ya calculado por backend).
- No se cambia el repository/mapper de red más allá de leer el campo nuevo si ya viene en la respuesta del backend (se asume que el backend ya lo retorna en el mismo payload de puntos de interés, dado que el usuario indica que el campo existe en `puntos_de_interes`).
