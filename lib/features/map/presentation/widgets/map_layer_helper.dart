import 'dart:convert';

String buildCircleLayerJson() {
  const categoryColors = {
    'arte_cultura':        '#7B2FBE', 
    'deporte_salud':       '#7B1034', 
    'museos_laboratorios': '#1A6FD4', 
    'academico':           '#F5C518', 
    'medio_ambiente':      '#27AE60', 
    'servicios':           '#D4006A', 
  };

  final colorMatchExpr = [
    'match',
    ['get', 'categoria'],
    ...categoryColors.entries.expand((e) => [e.key, e.value]),
    '#6A7587',
  ];

  final layer = {
    'id': 'puntos-circles',
    'type': 'circle',
    'source': 'puntos',
    'paint': {
      'circle-radius': 14,
      'circle-color': colorMatchExpr,
      'circle-stroke-color': [
        'case',
        ['get', 'visitado'],
        '#2DD4BF',
        '#FFFFFF',
      ],
      'circle-stroke-width': [
        'case',
        ['get', 'visitado'],
        3.5,
        2.0,
      ],
      'circle-opacity': 0.95,
    },
  };

  return json.encode(layer);
}

String buildGeoJson(List<Map<String, dynamic>> features) {
  return json.encode({
    'type': 'FeatureCollection',
    'features': features,
  });
}
