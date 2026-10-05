import 'dart:convert';

String buildCircleLayerJson() {
  final layer = {
    'id': 'puntos-circles',
    'type': 'circle',
    'source': 'puntos',
    'paint': {
      'circle-radius': [
        'case',
        ['get', 'visitado'],
        5.0,
        4.0,
      ],
      'circle-color': [
        'case',
        ['get', 'visitado'],
        '#2DD4BF',
        '#FFFFFF',
      ],
      'circle-stroke-color': [
        'case',
        ['get', 'visitado'],
        '#2DD4BF',
        '#FFFFFF',
      ],
      'circle-stroke-width': [
        'case',
        ['get', 'visitado'],
        1.6,
        1.0,
      ],
      'circle-opacity': 0.16,
    },
  };

  return json.encode(layer);
}

String buildSymbolLayerJson() {
  final colorIconMatchExpr = [
    'match',
    ['get', 'categoria'],
    'arte_cultura',
    'icon-arte_cultura',
    'deporte_salud',
    'icon-deporte_salud',
    'museos_laboratorios',
    'icon-museos_laboratorios',
    'academico',
    'icon-academico',
    'medio_ambiente',
    'icon-medio_ambiente',
    'servicios',
    'icon-servicios',
    'icon-default',
  ];

  final grayIconMatchExpr = [
    'match',
    ['get', 'categoria'],
    'arte_cultura',
    'icon-arte_cultura-gray',
    'deporte_salud',
    'icon-deporte_salud-gray',
    'museos_laboratorios',
    'icon-museos_laboratorios-gray',
    'academico',
    'icon-academico-gray',
    'medio_ambiente',
    'icon-medio_ambiente-gray',
    'servicios',
    'icon-servicios-gray',
    'icon-default-gray',
  ];

  final layer = {
    'id': 'puntos-symbols',
    'type': 'symbol',
    'source': 'puntos',
    'layout': {
      'icon-image': [
        'coalesce',
        [
          'image',
          [
            'case',
            [
              '==',
              [
                'coalesce',
                ['get', 'visitado'],
                false
              ],
              true
            ],
            colorIconMatchExpr,
            grayIconMatchExpr,
          ],
        ],
        ['image', 'icon-default-gray'],
      ],
      'icon-size': 0.35,
      'icon-allow-overlap': true,
      'icon-ignore-placement': true,
      'icon-anchor': 'bottom',
      'icon-offset': [0, -2],
    },
    'paint': {
      'icon-opacity': [
        'case',
        [
          '==',
          [
            'coalesce',
            ['get', 'visitado'],
            false
          ],
          true
        ],
        1.0,
        0.9,
      ],
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
