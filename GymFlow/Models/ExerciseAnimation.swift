import Foundation
import CoreGraphics

// MARK: - Pose de figura articulada
//
// Coordenadas normalizadas (0…1) sobre un lienzo cuadrado, origen
// arriba-izquierda (convención de SwiftUI).
// "Far" = extremidad del lado lejano (se dibuja atenuada, da profundidad).
// "Near" = extremidad del lado cercano al espectador.

struct StickPose {
    var head: CGPoint
    var neck: CGPoint
    var hip: CGPoint
    var elbowFar: CGPoint
    var handFar: CGPoint
    var elbowNear: CGPoint
    var handNear: CGPoint
    var kneeFar: CGPoint
    var footFar: CGPoint
    var kneeNear: CGPoint
    var footNear: CGPoint

    /// Init posicional compacto — mismo orden que las propiedades.
    init(_ head: (Double, Double), _ neck: (Double, Double), _ hip: (Double, Double),
         _ elbowFar: (Double, Double), _ handFar: (Double, Double),
         _ elbowNear: (Double, Double), _ handNear: (Double, Double),
         _ kneeFar: (Double, Double), _ footFar: (Double, Double),
         _ kneeNear: (Double, Double), _ footNear: (Double, Double)) {
        self.head = CGPoint(x: head.0, y: head.1)
        self.neck = CGPoint(x: neck.0, y: neck.1)
        self.hip = CGPoint(x: hip.0, y: hip.1)
        self.elbowFar = CGPoint(x: elbowFar.0, y: elbowFar.1)
        self.handFar = CGPoint(x: handFar.0, y: handFar.1)
        self.elbowNear = CGPoint(x: elbowNear.0, y: elbowNear.1)
        self.handNear = CGPoint(x: handNear.0, y: handNear.1)
        self.kneeFar = CGPoint(x: kneeFar.0, y: kneeFar.1)
        self.footFar = CGPoint(x: footFar.0, y: footFar.1)
        self.kneeNear = CGPoint(x: kneeNear.0, y: kneeNear.1)
        self.footNear = CGPoint(x: footNear.0, y: footNear.1)
    }

    /// Intercambia extremidades lejanas y cercanas. Para movimientos
    /// alternados (marcha, curl alterno, dead bug) basta definir un lado.
    var mirroredSides: StickPose {
        var out = self
        out.elbowFar = elbowNear; out.handFar = handNear
        out.elbowNear = elbowFar; out.handNear = handFar
        out.kneeFar = kneeNear; out.footFar = footNear
        out.kneeNear = kneeFar; out.footNear = footFar
        return out
    }

    static func lerp(_ a: StickPose, _ b: StickPose, _ t: Double) -> StickPose {
        func mix(_ p: CGPoint, _ q: CGPoint) -> CGPoint {
            CGPoint(x: p.x + (q.x - p.x) * t, y: p.y + (q.y - p.y) * t)
        }
        var out = a
        out.head = mix(a.head, b.head)
        out.neck = mix(a.neck, b.neck)
        out.hip = mix(a.hip, b.hip)
        out.elbowFar = mix(a.elbowFar, b.elbowFar)
        out.handFar = mix(a.handFar, b.handFar)
        out.elbowNear = mix(a.elbowNear, b.elbowNear)
        out.handNear = mix(a.handNear, b.handNear)
        out.kneeFar = mix(a.kneeFar, b.kneeFar)
        out.footFar = mix(a.footFar, b.footFar)
        out.kneeNear = mix(a.kneeNear, b.kneeNear)
        out.footNear = mix(a.footNear, b.footNear)
        return out
    }
}

// MARK: - Familia de movimiento
//
// Las claves de técnica van por FAMILIA, no por ejercicio: las indicaciones
// de una sentadilla valen igual para todas sus variantes. Las animaciones,
// en cambio, son específicas de cada ejercicio.

enum MovementFamily {
    case squat, hinge, lunge, push, pull, curl
    case isometric, flexion, rotation, gait, cyclic, jump, stretch, striking, carry

    var cues: [String] {
        let english = AppLanguage.current == .english
        switch self {
        case .squat:
            return english
                ? ["Feet shoulder-width, toes slightly out",
                   "Push hips back and down, chest up",
                   "Knees track over your toes",
                   "Drive through the heels to stand"]
                : ["Pies al ancho de hombros, puntas algo abiertas",
                   "Cadera atrás y abajo, pecho arriba",
                   "Las rodillas siguen la línea de los pies",
                   "Empuja con los talones para subir"]
        case .hinge:
            return english
                ? ["Hinge at the hips, not the lower back",
                   "Keep the load close to your legs",
                   "Neutral spine the whole way",
                   "Squeeze the glutes to finish standing"]
                : ["Flexiona la cadera, no la espalda baja",
                   "Mantén la carga pegada a las piernas",
                   "Columna neutra en todo el recorrido",
                   "Aprieta glúteos al terminar de pie"]
        case .lunge:
            return english
                ? ["Step forward, torso upright",
                   "Back knee drops toward the floor",
                   "Front knee stays over the ankle",
                   "Push off the front heel to return"]
                : ["Da un paso al frente, torso erguido",
                   "La rodilla trasera baja hacia el suelo",
                   "La rodilla delantera sobre el tobillo",
                   "Empuja con el talón delantero para volver"]
        case .push:
            return english
                ? ["Elbows at ~45°, not flared wide",
                   "Lower under control, don't bounce",
                   "Shoulders down and back",
                   "Full extension without locking hard"]
                : ["Codos a ~45°, no abiertos del todo",
                   "Baja controlado, sin rebotar",
                   "Hombros abajo y atrás",
                   "Extiende completo sin bloquear de golpe"]
        case .pull:
            return english
                ? ["Lead with the elbows, not the hands",
                   "Squeeze the shoulder blades together",
                   "No torso swing for momentum",
                   "Lower slowly — that's half the work"]
                : ["Tira con los codos, no con las manos",
                   "Junta los omóplatos al final",
                   "Sin balanceo del torso para tomar impulso",
                   "Baja lento — ahí está la mitad del trabajo"]
        case .curl:
            return english
                ? ["Elbows pinned at your sides",
                   "No swinging — move only the forearm",
                   "Full squeeze at the top",
                   "Control the way down"]
                : ["Codos pegados al cuerpo",
                   "Sin impulso — solo mueve el antebrazo",
                   "Aprieta arriba",
                   "Controla la bajada"]
        case .isometric:
            return english
                ? ["Straight line: head, hips, heels",
                   "Brace the abs, tuck the hips slightly",
                   "Don't let the hips sag or spike",
                   "Breathe — don't hold your breath"]
                : ["Línea recta: cabeza, cadera, talones",
                   "Aprieta el abdomen, retrovierte la pelvis",
                   "La cadera no se hunde ni se levanta",
                   "Respira — no aguantes el aire"]
        case .flexion:
            return english
                ? ["Curl the spine, don't yank the neck",
                   "Chin off the chest, eyes up",
                   "Exhale as you lift",
                   "Lower with control, don't drop"]
                : ["Enrolla la columna, no tires del cuello",
                   "Barbilla separada del pecho, mirada arriba",
                   "Exhala al subir",
                   "Baja controlado, no te dejes caer"]
        case .rotation:
            return english
                ? ["Rotate from the ribcage, not the arms",
                   "Keep the chest tall",
                   "Move slow — speed hides the work",
                   "Keep the lower back glued down"]
                : ["Gira desde las costillas, no con los brazos",
                   "Mantén el pecho alto",
                   "Ve lento — la velocidad esconde el trabajo",
                   "La espalda baja pegada al suelo"]
        case .gait:
            return english
                ? ["Land under your hips, not ahead",
                   "Short, quick steps",
                   "Relaxed shoulders, arms at ~90°",
                   "Breathe in a steady rhythm"]
                : ["Aterriza bajo la cadera, no por delante",
                   "Pasos cortos y rápidos",
                   "Hombros sueltos, brazos a ~90°",
                   "Respira en un ritmo constante"]
        case .cyclic:
            return english
                ? ["Keep cadence steady, not jerky",
                   "Push and pull through the whole circle",
                   "Relaxed grip, long back",
                   "Slight bend in the knee at full reach"]
                : ["Cadencia estable, sin tirones",
                   "Empuja y tira en todo el círculo",
                   "Agarre suelto, espalda larga",
                   "Rodilla algo flexionada en la extensión"]
        case .jump:
            return english
                ? ["Land soft, on the balls of your feet",
                   "Knees bend on impact to absorb",
                   "Stay tall, minimal ground time",
                   "Quality over speed — stop when form breaks"]
                : ["Cae suave, sobre la punta de los pies",
                   "Flexiona rodillas al caer para amortiguar",
                   "Mantente erguido, poco tiempo en el suelo",
                   "Calidad antes que velocidad — para si pierdes la técnica"]
        case .stretch:
            return english
                ? ["Ease in — never bounce",
                   "Hold 30–60 s per side",
                   "Breathe deep, relax into it",
                   "Stretch to tension, never to pain"]
                : ["Entra de a poco — nunca rebotes",
                   "Sostén 30–60 s por lado",
                   "Respira hondo y relájate",
                   "Estira hasta la tensión, nunca al dolor"]
        case .striking:
            return english
                ? ["Hands up, chin tucked",
                   "Rotate the hip into each strike",
                   "Retract fast — the guard comes back",
                   "Stay light on your feet"]
                : ["Manos arriba, barbilla escondida",
                   "Gira la cadera en cada golpe",
                   "Recoge rápido — la guardia vuelve",
                   "Mantente ligero de pies"]
        case .carry:
            return english
                ? ["Stand tall, shoulders back and down",
                   "Brace the core, ribs down",
                   "Short controlled steps",
                   "Grip hard, don't rush"]
                : ["Erguido, hombros atrás y abajo",
                   "Aprieta el core, costillas abajo",
                   "Pasos cortos y controlados",
                   "Agarra fuerte, sin apurarte"]
        }
    }
}

// MARK: - Patrones de movimiento (uno por ejercicio, salvo variantes idénticas)

enum MovementPattern: String, CaseIterable {
    // Piernas
    case squat, legExtension, lunge, wallBall, boxJump
    // Cadena posterior
    case deadlift, legCurl, hipThrust, kettlebellSwing, turkishGetUp
    // Empuje
    case pushUp, benchPress, inclinePress, closeGripPress
    case overheadPress, arnoldPress, dip, chestFly, reverseFly, tricepExtension
    // Tracción
    case pullUp, latPulldown, barbellRow, cableRow, oneArmRow, facePull
    // Brazos
    case bicepCurl, hammerCurl
    // Core isométrico
    case plank, hollowHold, deadBug, birdDog, superman, abWheel
    // Core dinámico
    case sitUp, crunch, vUp, legRaise, russianTwist, windshieldWiper, mountainClimber
    // Marcha y cardio
    case run, sprint, walk, stairClimb, stepUp, highKnees
    case cycle, elliptical, rowing
    // Pliometría
    case jumpRope, burpee, jumpingJack
    // Otros
    case swim, shadowBox, battleRopes, farmersWalk
    // Flexibilidad
    case yoga, foamRoll, hipFlexorStretch, backStretch, pigeonPose

    var family: MovementFamily {
        switch self {
        case .squat, .legExtension, .wallBall:                      return .squat
        case .lunge:                                                return .lunge
        case .boxJump, .jumpRope, .burpee, .jumpingJack:            return .jump
        case .deadlift, .legCurl, .hipThrust,
             .kettlebellSwing, .turkishGetUp:                       return .hinge
        case .pushUp, .benchPress, .inclinePress, .closeGripPress,
             .overheadPress, .arnoldPress, .dip, .chestFly,
             .reverseFly, .tricepExtension:                         return .push
        case .pullUp, .latPulldown, .barbellRow,
             .cableRow, .oneArmRow, .facePull:                      return .pull
        case .bicepCurl, .hammerCurl:                               return .curl
        case .plank, .hollowHold, .deadBug,
             .birdDog, .superman, .abWheel:                         return .isometric
        case .sitUp, .crunch, .vUp, .legRaise:                      return .flexion
        case .russianTwist, .windshieldWiper:                       return .rotation
        case .run, .sprint, .walk, .stairClimb,
             .stepUp, .highKnees, .mountainClimber:                 return .gait
        case .cycle, .elliptical, .rowing:                          return .cyclic
        case .swim:                                                 return .cyclic
        case .shadowBox, .battleRopes:                              return .striking
        case .farmersWalk:                                          return .carry
        case .yoga, .foamRoll, .hipFlexorStretch,
             .backStretch, .pigeonPose:                             return .stretch
        }
    }

    var cues: [String] { family.cues }

    /// Duración de un ciclo completo, en segundos.
    var cycleDuration: Double {
        switch self {
        case .sprint, .highKnees, .shadowBox, .battleRopes: return 0.6
        case .run, .mountainClimber, .jumpRope:             return 0.7
        case .jumpingJack, .cycle, .elliptical:             return 0.9
        case .walk, .stairClimb, .farmersWalk, .swim:       return 1.1
        case .crunch, .bicepCurl, .hammerCurl,
             .tricepExtension, .legExtension, .legCurl:     return 1.5
        case .russianTwist, .windshieldWiper, .vUp,
             .legRaise, .sitUp, .deadBug, .facePull:        return 1.7
        case .burpee, .boxJump, .stepUp, .wallBall,
             .kettlebellSwing:                              return 2.2
        case .turkishGetUp:                                 return 3.2
        case .plank, .hollowHold, .superman, .birdDog:      return 3.4
        case .yoga, .foamRoll, .backStretch:                return 3.6
        case .hipFlexorStretch, .pigeonPose:                return 4.2
        default:                                            return 2.0
        }
    }

    /// Nombre del movimiento, para la ficha del ejercicio.
    var displayName: String {
        let en = AppLanguage.current == .english
        switch self {
        case .squat:            return en ? "Bodyweight squat"    : "Sentadilla"
        case .legExtension:     return en ? "Seated leg extension": "Extensión sentado"
        case .lunge:            return en ? "Forward lunge"       : "Zancada al frente"
        case .wallBall:         return en ? "Squat to throw"      : "Sentadilla con lanzamiento"
        case .boxJump:          return en ? "Box jump"            : "Salto al cajón"
        case .deadlift:         return en ? "Hip hinge pull"      : "Bisagra de cadera"
        case .legCurl:          return en ? "Prone leg curl"      : "Curl femoral tumbado"
        case .hipThrust:        return en ? "Hip thrust"          : "Empuje de cadera"
        case .kettlebellSwing:  return en ? "Kettlebell swing"    : "Swing de kettlebell"
        case .turkishGetUp:     return en ? "Turkish get-up"      : "Turkish get-up"
        case .pushUp:           return en ? "Push-up"             : "Flexión de brazos"
        case .benchPress:       return en ? "Supine press"        : "Press tumbado"
        case .inclinePress:     return en ? "Incline press"       : "Press inclinado"
        case .closeGripPress:   return en ? "Close-grip press"    : "Press agarre cerrado"
        case .overheadPress:    return en ? "Overhead press"      : "Press sobre cabeza"
        case .arnoldPress:      return en ? "Rotating press"      : "Press con rotación"
        case .dip:              return en ? "Parallel bar dip"    : "Fondo en paralelas"
        case .chestFly:         return en ? "Chest fly arc"       : "Apertura de pecho"
        case .reverseFly:       return en ? "Bent-over rear fly"  : "Apertura posterior"
        case .tricepExtension:  return en ? "Overhead extension"  : "Extensión sobre cabeza"
        case .pullUp:           return en ? "Pull-up"             : "Dominada"
        case .latPulldown:      return en ? "Lat pulldown"        : "Jalón al pecho"
        case .barbellRow:       return en ? "Bent-over row"       : "Remo inclinado"
        case .cableRow:         return en ? "Seated cable row"    : "Remo sentado"
        case .oneArmRow:        return en ? "Single-arm row"      : "Remo a una mano"
        case .facePull:         return en ? "High face pull"      : "Face pull alto"
        case .bicepCurl:        return en ? "Biceps curl"         : "Curl de bíceps"
        case .hammerCurl:       return en ? "Alternating curl"    : "Curl alterno"
        case .plank:            return en ? "Forearm plank"       : "Plancha con antebrazos"
        case .hollowHold:       return en ? "Hollow body hold"    : "Sostén hollow"
        case .deadBug:          return en ? "Dead bug"            : "Dead bug"
        case .birdDog:          return en ? "Bird dog"            : "Bird dog"
        case .superman:         return en ? "Prone extension"     : "Extensión en prono"
        case .abWheel:          return en ? "Ab wheel roll-out"   : "Rueda abdominal"
        case .sitUp:            return en ? "Full sit-up"         : "Abdominal completo"
        case .crunch:           return en ? "Short crunch"        : "Crunch corto"
        case .vUp:              return en ? "V-up"                : "V-up"
        case .legRaise:         return en ? "Lying leg raise"      : "Elevación de piernas"
        case .russianTwist:     return en ? "Seated twist"        : "Giro sentado"
        case .windshieldWiper:  return en ? "Windshield wiper"    : "Limpiaparabrisas"
        case .mountainClimber:  return en ? "Mountain climber"    : "Mountain climber"
        case .run:              return en ? "Running gait"        : "Trote"
        case .sprint:           return en ? "Sprint"              : "Sprint"
        case .walk:             return en ? "Brisk walk"          : "Caminata rápida"
        case .stairClimb:       return en ? "Stair climb"         : "Subida de escalones"
        case .stepUp:           return en ? "Step-up"             : "Subida al step"
        case .highKnees:        return en ? "High knees"          : "Rodillas altas"
        case .cycle:            return en ? "Seated pedaling"     : "Pedaleo sentado"
        case .elliptical:       return en ? "Elliptical stride"   : "Zancada elíptica"
        case .rowing:           return en ? "Rowing stroke"       : "Remada completa"
        case .jumpRope:         return en ? "Rope hop"            : "Salto de cuerda"
        case .burpee:           return en ? "Burpee sequence"     : "Secuencia de burpee"
        case .jumpingJack:      return en ? "Jumping jack"        : "Salto de tijera"
        case .swim:             return en ? "Front crawl"         : "Crol"
        case .shadowBox:        return en ? "Punch combo"         : "Combinación de golpes"
        case .battleRopes:      return en ? "Rope waves"          : "Ondas con cuerdas"
        case .farmersWalk:      return en ? "Loaded carry"        : "Transporte con carga"
        case .yoga:             return en ? "Down dog flow"       : "Flujo perro boca abajo"
        case .foamRoll:         return en ? "Foam rolling"        : "Rodillo de espuma"
        case .hipFlexorStretch: return en ? "Kneeling hip stretch": "Estiramiento de cadera"
        case .backStretch:      return en ? "Child's pose to cat" : "Postura del niño a gato"
        case .pigeonPose:       return en ? "Pigeon pose"         : "Postura de la paloma"
        }
    }
}

// MARK: - Mapeo ejercicio → patrón

struct ExerciseAnimationCatalog {
    private static let byExerciseId: [String: MovementPattern] = [
        // Cardio
        "trote": .run, "cinta": .run, "sprints": .sprint, "caminata": .walk,
        "escaladora": .stairClimb, "step": .stepUp, "hiit": .highKnees,
        "aerobicos": .jumpingJack, "bici": .cycle, "elip": .elliptical,
        "remar": .rowing, "remo_erg": .rowing, "cuerda": .jumpRope,
        "nata": .swim, "box": .shadowBox,

        // Fuerza — empuje
        "flex": .pushUp, "bench": .benchPress, "manc": .benchPress,
        "press_inclinado": .inclinePress, "press_cerrado": .closeGripPress,
        "shoulder": .overheadPress, "arnold": .arnoldPress, "dips": .dip,
        "aperturas": .chestFly, "reverse_fly": .reverseFly, "tricep": .tricepExtension,

        // Fuerza — tracción
        "pull": .pullUp, "jalon": .latPulldown, "remo": .barbellRow,
        "polea": .cableRow, "remo_un_brazo": .oneArmRow, "face_pull": .facePull,

        // Fuerza — brazos
        "bicep": .bicepCurl, "curl_martillo": .hammerCurl,

        // Fuerza — piernas y cadena posterior
        "squat": .squat, "ext_quad": .legExtension, "lunge": .lunge,
        "peso": .deadlift, "femoral": .legCurl, "hip_thrust": .hipThrust,

        // Core
        "abs": .sitUp, "crunches": .crunch, "v_ups": .vUp,
        "elevacion": .legRaise, "rueda": .abWheel, "plancha": .plank,
        "hollow": .hollowHold, "dead_bug": .deadBug, "bird_dog": .birdDog,
        "supman": .superman, "russian": .russianTwist,
        "windshield": .windshieldWiper, "mtn": .mountainClimber,
        "burpee": .burpee,

        // Funcional
        "kettlebell": .kettlebellSwing, "get_up": .turkishGetUp,
        "battle_ropes": .battleRopes, "wall_ball": .wallBall,
        "box_jump": .boxJump, "farmers_walk": .farmersWalk,

        // Flexibilidad
        "yoga": .yoga, "foam_roll": .foamRoll, "hip_flexor": .hipFlexorStretch,
        "espalda_str": .backStretch, "pigeon": .pigeonPose,
    ]

    private static let byCategory: [String: MovementPattern] = [
        "Cardio": .run, "Fuerza": .pushUp, "Core": .crunch,
        "Funcional": .squat, "Flexibilidad": .backStretch,
    ]

    /// Patrón para un ejercicio. Cae a la categoría si el id no está mapeado
    /// (p. ej. ejercicios importados de la PWA con ids desconocidos).
    static func pattern(forId id: String, category: String) -> MovementPattern {
        byExerciseId[id] ?? byCategory[category] ?? .squat
    }
}
