import '../models/challenge_question.dart';

const challengeQuestionsMock = <ChallengeQuestion>[
  ChallengeQuestion(
    id: 'jardin_botanico',
    pointName: 'Jardín Botánico',
    pointLabel: 'Punto relacionado',
    pointImage: 'assets/images/medio_ambiente.jpg',
    question:
        '¿Qué tipo de árbol es el más común en el Jardín Botánico de la universidad?',
    rewardPoints: 10,
    options: ['Pino', 'Ceiba', 'Roble', 'Palma'],
    correctIndex: 1,
    correctAnswerText:
        'La ceiba es uno de los árboles más comunes en el Jardín Botánico.',
  ),
  ChallengeQuestion(
    id: 'aula_maxima',
    pointName: 'Aula Máxima',
    pointLabel: 'Punto relacionado',
    pointImage: 'assets/images/aula_maxima.jpg',
    question: '¿A qué categoría pertenece el Aula Máxima?',
    rewardPoints: 10,
    options: ['Académico', 'Servicios', 'Deporte', 'Medio ambiente'],
    correctIndex: 0,
    correctAnswerText: 'El Aula Máxima pertenece a la categoría académica.',
  ),
  ChallengeQuestion(
    id: 'canchas',
    pointName: 'Cancha Múltiple',
    pointLabel: 'Punto relacionado',
    pointImage: 'assets/images/cancha_multiproposito.jpg',
    question: '¿Qué categoría describe mejor una cancha múltiple?',
    rewardPoints: 10,
    options: [
      'Arte y cultura',
      'Deporte y salud',
      'Servicios',
      'Museos y laboratorios',
    ],
    correctIndex: 1,
    correctAnswerText:
        'Las canchas múltiples pertenecen a la categoría de deporte y salud.',
  ),
  ChallengeQuestion(
    id: 'museo',
    pointName: 'Museo y Laboratorio',
    pointLabel: 'Punto relacionado',
    pointImage: 'assets/images/museo_laboratorio.jpg',
    question: '¿Qué espacio se relaciona con investigación y aprendizaje?',
    rewardPoints: 10,
    options: ['Museos y laboratorios', 'Retos', 'Servicios', 'Inicio'],
    correctIndex: 0,
    correctAnswerText:
        'Los museos y laboratorios se relacionan con investigación y aprendizaje.',
  ),
];
