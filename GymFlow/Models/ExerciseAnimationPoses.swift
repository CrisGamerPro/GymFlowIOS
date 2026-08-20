import Foundation

// MARK: - Poses clave de cada patrón
//
// Archivo separado de ExerciseAnimation.swift a propósito: son ~60 tablas de
// datos y mantenerlas aparte evita que el type-checker se ahogue.
//
// Convenciones de lectura:
//   · Vista lateral mirando a la DERECHA, salvo donde se indique vista frontal.
//   · Con 2 fotogramas el ciclo es ida y vuelta (una repetición completa).
//   · Con 3+ fotogramas el ciclo es continuo y vuelve al primero.
//   · `.mirroredSides` intercambia lados: sirve para movimientos alternados.

extension MovementPattern {

    var keyframes: [StickPose] {
        switch self {
        // Piernas
        case .squat:            return Poses.squat
        case .legExtension:     return Poses.legExtension
        case .lunge:            return Poses.lunge
        case .wallBall:         return Poses.wallBall
        case .boxJump:          return Poses.boxJump
        // Cadena posterior
        case .deadlift:         return Poses.deadlift
        case .legCurl:          return Poses.legCurl
        case .hipThrust:        return Poses.hipThrust
        case .kettlebellSwing:  return Poses.kettlebellSwing
        case .turkishGetUp:     return Poses.turkishGetUp
        // Empuje
        case .pushUp:           return Poses.pushUp
        case .benchPress:       return Poses.benchPress
        case .inclinePress:     return Poses.inclinePress
        case .closeGripPress:   return Poses.closeGripPress
        case .overheadPress:    return Poses.overheadPress
        case .arnoldPress:      return Poses.arnoldPress
        case .dip:              return Poses.dip
        case .chestFly:         return Poses.chestFly
        case .reverseFly:       return Poses.reverseFly
        case .tricepExtension:  return Poses.tricepExtension
        // Tracción
        case .pullUp:           return Poses.pullUp
        case .latPulldown:      return Poses.latPulldown
        case .barbellRow:       return Poses.barbellRow
        case .cableRow:         return Poses.cableRow
        case .oneArmRow:        return Poses.oneArmRow
        case .facePull:         return Poses.facePull
        // Brazos
        case .bicepCurl:        return Poses.bicepCurl
        case .hammerCurl:       return Poses.hammerCurl
        // Core isométrico
        case .plank:            return Poses.plank
        case .hollowHold:       return Poses.hollowHold
        case .deadBug:          return Poses.deadBug
        case .birdDog:          return Poses.birdDog
        case .superman:         return Poses.superman
        case .abWheel:          return Poses.abWheel
        // Core dinámico
        case .sitUp:            return Poses.sitUp
        case .crunch:           return Poses.crunch
        case .vUp:              return Poses.vUp
        case .legRaise:         return Poses.legRaise
        case .russianTwist:     return Poses.russianTwist
        case .windshieldWiper:  return Poses.windshieldWiper
        case .mountainClimber:  return Poses.mountainClimber
        // Marcha y cardio
        case .run:              return Poses.run
        case .sprint:           return Poses.sprint
        case .walk:             return Poses.walk
        case .stairClimb:       return Poses.stairClimb
        case .stepUp:           return Poses.stepUp
        case .highKnees:        return Poses.highKnees
        case .cycle:            return Poses.cycle
        case .elliptical:       return Poses.elliptical
        case .rowing:           return Poses.rowing
        // Pliometría
        case .jumpRope:         return Poses.jumpRope
        case .burpee:           return Poses.burpee
        case .jumpingJack:      return Poses.jumpingJack
        // Otros
        case .swim:             return Poses.swim
        case .shadowBox:        return Poses.shadowBox
        case .battleRopes:      return Poses.battleRopes
        case .farmersWalk:      return Poses.farmersWalk
        // Flexibilidad
        case .yoga:             return Poses.yoga
        case .foamRoll:         return Poses.foamRoll
        case .hipFlexorStretch: return Poses.hipFlexorStretch
        case .backStretch:      return Poses.backStretch
        case .pigeonPose:       return Poses.pigeonPose
        }
    }
}

// MARK: - Tablas de poses

enum Poses {

    // ══════════════════ PIERNAS ══════════════════

    /// De pie → cadera atrás y abajo, torso inclinado.
    static let squat: [StickPose] = [
        StickPose((0.50, 0.13), (0.50, 0.25), (0.50, 0.53),
                  (0.56, 0.36), (0.62, 0.30), (0.57, 0.37), (0.63, 0.31),
                  (0.48, 0.74), (0.47, 0.94), (0.52, 0.74), (0.53, 0.94)),
        StickPose((0.42, 0.29), (0.44, 0.40), (0.37, 0.64),
                  (0.54, 0.45), (0.63, 0.43), (0.55, 0.46), (0.64, 0.44),
                  (0.55, 0.75), (0.46, 0.94), (0.58, 0.76), (0.52, 0.94)),
    ]

    /// Sentado en máquina: la rodilla se extiende, el torso no se mueve.
    static let legExtension: [StickPose] = [
        StickPose((0.32, 0.26), (0.35, 0.37), (0.30, 0.60),
                  (0.24, 0.48), (0.20, 0.62), (0.42, 0.48), (0.44, 0.62),
                  (0.58, 0.62), (0.60, 0.86), (0.60, 0.64), (0.62, 0.88)),
        StickPose((0.32, 0.26), (0.35, 0.37), (0.30, 0.60),
                  (0.24, 0.48), (0.20, 0.62), (0.42, 0.48), (0.44, 0.62),
                  (0.58, 0.62), (0.86, 0.56), (0.60, 0.64), (0.88, 0.58)),
    ]

    /// Paso al frente: rodilla trasera baja, torso erguido.
    static let lunge: [StickPose] = [
        StickPose((0.48, 0.13), (0.48, 0.25), (0.48, 0.53),
                  (0.44, 0.38), (0.43, 0.52), (0.52, 0.38), (0.53, 0.52),
                  (0.46, 0.74), (0.45, 0.94), (0.50, 0.74), (0.51, 0.94)),
        StickPose((0.46, 0.19), (0.46, 0.31), (0.45, 0.59),
                  (0.42, 0.44), (0.41, 0.58), (0.50, 0.44), (0.51, 0.58),
                  (0.66, 0.72), (0.68, 0.94), (0.30, 0.80), (0.24, 0.94)),
    ]

    /// Sentadilla con balón → de pie → lanzamiento arriba (3 fases).
    static let wallBall: [StickPose] = [
        StickPose((0.44, 0.30), (0.46, 0.41), (0.40, 0.64),
                  (0.52, 0.44), (0.50, 0.32), (0.54, 0.45), (0.52, 0.33),
                  (0.56, 0.76), (0.47, 0.94), (0.59, 0.77), (0.52, 0.94)),
        StickPose((0.50, 0.16), (0.50, 0.28), (0.50, 0.55),
                  (0.44, 0.38), (0.47, 0.24), (0.56, 0.38), (0.53, 0.24),
                  (0.48, 0.75), (0.47, 0.94), (0.52, 0.75), (0.53, 0.94)),
        StickPose((0.50, 0.16), (0.50, 0.28), (0.50, 0.55),
                  (0.44, 0.20), (0.46, 0.04), (0.56, 0.20), (0.54, 0.04),
                  (0.48, 0.75), (0.47, 0.94), (0.52, 0.75), (0.53, 0.94)),
    ]

    /// Flexión profunda → vuelo → recepción sobre el cajón (3 fases).
    static let boxJump: [StickPose] = [
        StickPose((0.44, 0.34), (0.46, 0.44), (0.42, 0.66),
                  (0.36, 0.52), (0.28, 0.60), (0.52, 0.52), (0.56, 0.60),
                  (0.54, 0.76), (0.44, 0.94), (0.58, 0.77), (0.50, 0.94)),
        StickPose((0.50, 0.08), (0.50, 0.19), (0.50, 0.42),
                  (0.40, 0.14), (0.36, 0.02), (0.60, 0.14), (0.64, 0.02),
                  (0.44, 0.54), (0.40, 0.66), (0.56, 0.54), (0.60, 0.66)),
        StickPose((0.50, 0.24), (0.50, 0.35), (0.50, 0.56),
                  (0.42, 0.46), (0.38, 0.58), (0.58, 0.46), (0.62, 0.58),
                  (0.46, 0.66), (0.44, 0.76), (0.54, 0.66), (0.56, 0.76)),
    ]

    // ══════════════════ CADENA POSTERIOR ══════════════════

    /// Peso muerto: cadera atrás, piernas casi rectas, barra pegada.
    static let deadlift: [StickPose] = [
        StickPose((0.50, 0.13), (0.50, 0.25), (0.50, 0.53),
                  (0.47, 0.38), (0.46, 0.54), (0.53, 0.38), (0.54, 0.54),
                  (0.48, 0.74), (0.47, 0.94), (0.52, 0.74), (0.53, 0.94)),
        StickPose((0.68, 0.38), (0.61, 0.42), (0.38, 0.53),
                  (0.60, 0.58), (0.59, 0.76), (0.64, 0.58), (0.63, 0.76),
                  (0.42, 0.75), (0.44, 0.94), (0.46, 0.75), (0.48, 0.94)),
    ]

    /// Tumbado boca abajo: el talón se acerca al glúteo.
    static let legCurl: [StickPose] = [
        StickPose((0.14, 0.60), (0.24, 0.62), (0.50, 0.66),
                  (0.20, 0.72), (0.12, 0.78), (0.22, 0.74), (0.14, 0.80),
                  (0.70, 0.68), (0.90, 0.70), (0.70, 0.70), (0.90, 0.72)),
        StickPose((0.14, 0.60), (0.24, 0.62), (0.50, 0.66),
                  (0.20, 0.72), (0.12, 0.78), (0.22, 0.74), (0.14, 0.80),
                  (0.70, 0.68), (0.72, 0.44), (0.70, 0.70), (0.74, 0.46)),
    ]

    /// Hombros apoyados, la cadera sube hasta alinear tronco y muslos.
    static let hipThrust: [StickPose] = [
        StickPose((0.24, 0.48), (0.33, 0.52), (0.54, 0.74),
                  (0.31, 0.60), (0.26, 0.70), (0.35, 0.61), (0.30, 0.71),
                  (0.72, 0.66), (0.76, 0.90), (0.74, 0.68), (0.78, 0.92)),
        StickPose((0.24, 0.48), (0.33, 0.52), (0.57, 0.58),
                  (0.31, 0.60), (0.26, 0.70), (0.35, 0.61), (0.30, 0.71),
                  (0.75, 0.58), (0.76, 0.90), (0.77, 0.60), (0.78, 0.92)),
    ]

    /// Swing: bisagra atrás → de pie → arco a la altura del hombro.
    static let kettlebellSwing: [StickPose] = [
        StickPose((0.66, 0.38), (0.59, 0.43), (0.38, 0.52),
                  (0.52, 0.60), (0.42, 0.70), (0.55, 0.61), (0.45, 0.71),
                  (0.38, 0.72), (0.36, 0.92), (0.44, 0.72), (0.42, 0.92)),
        StickPose((0.50, 0.16), (0.50, 0.28), (0.50, 0.55),
                  (0.58, 0.42), (0.66, 0.52), (0.60, 0.43), (0.68, 0.53),
                  (0.47, 0.75), (0.46, 0.94), (0.53, 0.75), (0.54, 0.94)),
        StickPose((0.50, 0.16), (0.50, 0.28), (0.50, 0.55),
                  (0.62, 0.32), (0.78, 0.30), (0.64, 0.33), (0.80, 0.31),
                  (0.47, 0.75), (0.46, 0.94), (0.53, 0.75), (0.54, 0.94)),
    ]

    /// Tumbado → apoyo en codo → media rodilla, con el brazo siempre vertical.
    static let turkishGetUp: [StickPose] = [
        StickPose((0.28, 0.62), (0.36, 0.64), (0.58, 0.68),
                  (0.36, 0.50), (0.34, 0.34), (0.30, 0.72), (0.20, 0.78),
                  (0.72, 0.58), (0.76, 0.82), (0.74, 0.72), (0.92, 0.76)),
        StickPose((0.34, 0.44), (0.40, 0.52), (0.58, 0.68),
                  (0.44, 0.38), (0.44, 0.20), (0.44, 0.66), (0.34, 0.78),
                  (0.72, 0.58), (0.76, 0.82), (0.76, 0.72), (0.94, 0.76)),
        StickPose((0.46, 0.24), (0.48, 0.35), (0.50, 0.58),
                  (0.52, 0.24), (0.54, 0.08), (0.42, 0.46), (0.38, 0.60),
                  (0.62, 0.72), (0.68, 0.92), (0.40, 0.78), (0.28, 0.90)),
    ]

    // ══════════════════ EMPUJE ══════════════════

    /// Flexión en el suelo: cuerpo horizontal, codos hacia atrás.
    static let pushUp: [StickPose] = [
        StickPose((0.78, 0.44), (0.68, 0.48), (0.38, 0.57),
                  (0.67, 0.63), (0.68, 0.80), (0.70, 0.64), (0.71, 0.80),
                  (0.22, 0.66), (0.07, 0.77), (0.22, 0.68), (0.07, 0.79)),
        StickPose((0.78, 0.60), (0.68, 0.64), (0.38, 0.68),
                  (0.78, 0.66), (0.68, 0.80), (0.81, 0.67), (0.71, 0.80),
                  (0.22, 0.74), (0.07, 0.79), (0.22, 0.76), (0.07, 0.81)),
    ]

    /// Tumbado en banco: la carga baja al pecho y sube vertical.
    static let benchPress: [StickPose] = [
        StickPose((0.72, 0.58), (0.63, 0.60), (0.36, 0.62),
                  (0.70, 0.50), (0.62, 0.46), (0.73, 0.52), (0.65, 0.47),
                  (0.22, 0.68), (0.16, 0.86), (0.22, 0.70), (0.16, 0.88)),
        StickPose((0.72, 0.58), (0.63, 0.60), (0.36, 0.62),
                  (0.63, 0.46), (0.62, 0.28), (0.66, 0.47), (0.65, 0.29),
                  (0.22, 0.68), (0.16, 0.86), (0.22, 0.70), (0.16, 0.88)),
    ]

    /// Banco inclinado: el cuerpo va en diagonal, la carga sube hacia arriba-atrás.
    static let inclinePress: [StickPose] = [
        StickPose((0.66, 0.40), (0.60, 0.46), (0.38, 0.66),
                  (0.68, 0.44), (0.60, 0.36), (0.71, 0.45), (0.63, 0.37),
                  (0.26, 0.74), (0.20, 0.92), (0.26, 0.76), (0.20, 0.94)),
        StickPose((0.66, 0.40), (0.60, 0.46), (0.38, 0.66),
                  (0.61, 0.34), (0.61, 0.16), (0.64, 0.35), (0.64, 0.17),
                  (0.26, 0.74), (0.20, 0.92), (0.26, 0.76), (0.20, 0.94)),
    ]

    /// Agarre cerrado: mismo recorrido que el press, pero los codos van pegados.
    static let closeGripPress: [StickPose] = [
        StickPose((0.72, 0.58), (0.63, 0.60), (0.36, 0.62),
                  (0.65, 0.52), (0.63, 0.46), (0.67, 0.53), (0.65, 0.47),
                  (0.22, 0.68), (0.16, 0.86), (0.22, 0.70), (0.16, 0.88)),
        StickPose((0.72, 0.58), (0.63, 0.60), (0.36, 0.62),
                  (0.63, 0.44), (0.63, 0.28), (0.65, 0.45), (0.65, 0.29),
                  (0.22, 0.68), (0.16, 0.86), (0.22, 0.70), (0.16, 0.88)),
    ]

    /// De pie: de los hombros a por encima de la cabeza.
    static let overheadPress: [StickPose] = [
        StickPose((0.50, 0.20), (0.50, 0.32), (0.50, 0.58),
                  (0.38, 0.42), (0.40, 0.28), (0.62, 0.42), (0.60, 0.28),
                  (0.47, 0.76), (0.46, 0.95), (0.53, 0.76), (0.54, 0.95)),
        StickPose((0.50, 0.20), (0.50, 0.32), (0.50, 0.58),
                  (0.42, 0.24), (0.44, 0.06), (0.58, 0.24), (0.56, 0.06),
                  (0.47, 0.76), (0.46, 0.95), (0.53, 0.76), (0.54, 0.95)),
    ]

    /// Arnold: las manos parten juntas frente a la cara y rotan al abrirse.
    static let arnoldPress: [StickPose] = [
        StickPose((0.50, 0.20), (0.50, 0.32), (0.50, 0.58),
                  (0.42, 0.44), (0.47, 0.30), (0.58, 0.44), (0.53, 0.30),
                  (0.47, 0.76), (0.46, 0.95), (0.53, 0.76), (0.54, 0.95)),
        StickPose((0.50, 0.20), (0.50, 0.32), (0.50, 0.58),
                  (0.38, 0.22), (0.34, 0.07), (0.62, 0.22), (0.66, 0.07),
                  (0.47, 0.76), (0.46, 0.95), (0.53, 0.76), (0.54, 0.95)),
    ]

    /// Paralelas: manos fijas a los lados, el cuerpo baja entre ellas.
    static let dip: [StickPose] = [
        StickPose((0.50, 0.18), (0.50, 0.29), (0.50, 0.54),
                  (0.38, 0.36), (0.36, 0.44), (0.62, 0.36), (0.64, 0.44),
                  (0.44, 0.72), (0.40, 0.88), (0.56, 0.72), (0.60, 0.88)),
        StickPose((0.50, 0.32), (0.50, 0.43), (0.50, 0.66),
                  (0.32, 0.52), (0.36, 0.44), (0.68, 0.52), (0.64, 0.44),
                  (0.44, 0.82), (0.40, 0.95), (0.56, 0.82), (0.60, 0.95)),
    ]

    /// Apertura (vista frontal): los brazos describen un arco de fuera a dentro.
    static let chestFly: [StickPose] = [
        StickPose((0.50, 0.16), (0.50, 0.28), (0.50, 0.56),
                  (0.30, 0.34), (0.13, 0.30), (0.70, 0.34), (0.87, 0.30),
                  (0.46, 0.74), (0.45, 0.94), (0.54, 0.74), (0.55, 0.94)),
        StickPose((0.50, 0.16), (0.50, 0.28), (0.50, 0.56),
                  (0.40, 0.38), (0.47, 0.43), (0.60, 0.38), (0.53, 0.43),
                  (0.46, 0.74), (0.45, 0.94), (0.54, 0.74), (0.55, 0.94)),
    ]

    /// Apertura posterior: torso inclinado, brazos cuelgan y se abren.
    static let reverseFly: [StickPose] = [
        StickPose((0.50, 0.30), (0.50, 0.40), (0.50, 0.62),
                  (0.42, 0.54), (0.40, 0.70), (0.58, 0.54), (0.60, 0.70),
                  (0.46, 0.76), (0.45, 0.94), (0.54, 0.76), (0.55, 0.94)),
        StickPose((0.50, 0.30), (0.50, 0.40), (0.50, 0.62),
                  (0.32, 0.44), (0.15, 0.42), (0.68, 0.44), (0.85, 0.42),
                  (0.46, 0.76), (0.45, 0.94), (0.54, 0.76), (0.55, 0.94)),
    ]

    /// Tríceps: el codo queda arriba y fijo; solo se extiende el antebrazo.
    static let tricepExtension: [StickPose] = [
        StickPose((0.50, 0.18), (0.50, 0.30), (0.50, 0.56),
                  (0.43, 0.16), (0.52, 0.29), (0.57, 0.16), (0.48, 0.30),
                  (0.47, 0.75), (0.46, 0.94), (0.53, 0.75), (0.54, 0.94)),
        StickPose((0.50, 0.18), (0.50, 0.30), (0.50, 0.56),
                  (0.43, 0.16), (0.46, 0.02), (0.57, 0.16), (0.54, 0.02),
                  (0.47, 0.75), (0.46, 0.94), (0.53, 0.75), (0.54, 0.94)),
    ]

    // ══════════════════ TRACCIÓN ══════════════════

    /// Dominada: manos fijas en la barra, el cuerpo sube.
    static let pullUp: [StickPose] = [
        StickPose((0.50, 0.31), (0.50, 0.41), (0.50, 0.65),
                  (0.46, 0.26), (0.43, 0.09), (0.54, 0.26), (0.57, 0.09),
                  (0.47, 0.80), (0.45, 0.95), (0.53, 0.80), (0.55, 0.95)),
        StickPose((0.50, 0.16), (0.50, 0.27), (0.50, 0.52),
                  (0.35, 0.23), (0.43, 0.09), (0.65, 0.23), (0.57, 0.09),
                  (0.47, 0.68), (0.45, 0.84), (0.53, 0.68), (0.55, 0.84)),
    ]

    /// Jalón sentado: la barra baja al pecho, los codos van abajo y atrás.
    static let latPulldown: [StickPose] = [
        StickPose((0.50, 0.34), (0.50, 0.44), (0.50, 0.66),
                  (0.42, 0.30), (0.38, 0.12), (0.58, 0.30), (0.62, 0.12),
                  (0.62, 0.72), (0.72, 0.90), (0.64, 0.74), (0.74, 0.92)),
        StickPose((0.51, 0.32), (0.51, 0.42), (0.50, 0.66),
                  (0.29, 0.40), (0.40, 0.38), (0.73, 0.40), (0.62, 0.38),
                  (0.62, 0.72), (0.72, 0.90), (0.64, 0.74), (0.74, 0.92)),
    ]

    /// Remo inclinado: torso a 45°, la barra sube al abdomen.
    static let barbellRow: [StickPose] = [
        StickPose((0.70, 0.34), (0.62, 0.40), (0.38, 0.54),
                  (0.60, 0.56), (0.59, 0.74), (0.64, 0.57), (0.63, 0.75),
                  (0.36, 0.72), (0.34, 0.92), (0.42, 0.72), (0.40, 0.92)),
        StickPose((0.70, 0.34), (0.62, 0.40), (0.38, 0.54),
                  (0.76, 0.52), (0.60, 0.56), (0.80, 0.53), (0.64, 0.57),
                  (0.36, 0.72), (0.34, 0.92), (0.42, 0.72), (0.40, 0.92)),
    ]

    /// Remo sentado en polea: el torso acompaña ligeramente al tirón.
    static let cableRow: [StickPose] = [
        StickPose((0.36, 0.36), (0.41, 0.45), (0.32, 0.64),
                  (0.56, 0.50), (0.72, 0.52), (0.58, 0.51), (0.74, 0.53),
                  (0.62, 0.60), (0.82, 0.70), (0.64, 0.62), (0.84, 0.72)),
        StickPose((0.28, 0.33), (0.35, 0.43), (0.32, 0.64),
                  (0.28, 0.52), (0.45, 0.54), (0.30, 0.53), (0.47, 0.55),
                  (0.62, 0.60), (0.82, 0.70), (0.64, 0.62), (0.84, 0.72)),
    ]

    /// Remo a una mano: el brazo lejano queda apoyado, el cercano trabaja.
    static let oneArmRow: [StickPose] = [
        StickPose((0.70, 0.36), (0.62, 0.42), (0.38, 0.52),
                  (0.66, 0.56), (0.70, 0.72), (0.55, 0.62), (0.54, 0.80),
                  (0.34, 0.70), (0.32, 0.92), (0.42, 0.70), (0.40, 0.92)),
        StickPose((0.70, 0.36), (0.62, 0.42), (0.38, 0.52),
                  (0.66, 0.56), (0.70, 0.72), (0.73, 0.54), (0.58, 0.58),
                  (0.34, 0.70), (0.32, 0.92), (0.42, 0.70), (0.40, 0.92)),
    ]

    /// Face pull: los codos suben altos y abiertos, las manos llegan a las orejas.
    static let facePull: [StickPose] = [
        StickPose((0.50, 0.20), (0.50, 0.32), (0.50, 0.58),
                  (0.36, 0.30), (0.21, 0.26), (0.64, 0.30), (0.79, 0.26),
                  (0.47, 0.76), (0.46, 0.95), (0.53, 0.76), (0.54, 0.95)),
        StickPose((0.50, 0.20), (0.50, 0.32), (0.50, 0.58),
                  (0.21, 0.23), (0.40, 0.17), (0.79, 0.23), (0.60, 0.17),
                  (0.47, 0.76), (0.46, 0.95), (0.53, 0.76), (0.54, 0.95)),
    ]

    // ══════════════════ BRAZOS ══════════════════

    /// Curl simultáneo: los codos no se mueven.
    static let bicepCurl: [StickPose] = [
        StickPose((0.50, 0.13), (0.50, 0.25), (0.50, 0.53),
                  (0.44, 0.40), (0.43, 0.56), (0.56, 0.40), (0.57, 0.56),
                  (0.48, 0.74), (0.47, 0.94), (0.52, 0.74), (0.53, 0.94)),
        StickPose((0.50, 0.13), (0.50, 0.25), (0.50, 0.53),
                  (0.44, 0.40), (0.47, 0.27), (0.56, 0.40), (0.53, 0.27),
                  (0.48, 0.74), (0.47, 0.94), (0.52, 0.74), (0.53, 0.94)),
    ]

    /// Curl alterno: un brazo sube mientras el otro baja.
    static let hammerCurl: [StickPose] = {
        let a = StickPose((0.50, 0.13), (0.50, 0.25), (0.50, 0.53),
                          (0.44, 0.40), (0.46, 0.27), (0.56, 0.40), (0.57, 0.56),
                          (0.48, 0.74), (0.47, 0.94), (0.52, 0.74), (0.53, 0.94))
        return [a, a.mirroredSides]
    }()

    // ══════════════════ CORE ISOMÉTRICO ══════════════════

    /// Plancha sobre antebrazos, con la oscilación mínima de la respiración.
    static let plank: [StickPose] = [
        StickPose((0.79, 0.50), (0.69, 0.54), (0.40, 0.62),
                  (0.69, 0.68), (0.79, 0.76), (0.71, 0.69), (0.81, 0.77),
                  (0.22, 0.70), (0.08, 0.78), (0.22, 0.72), (0.08, 0.80)),
        StickPose((0.79, 0.48), (0.69, 0.52), (0.40, 0.59),
                  (0.69, 0.68), (0.79, 0.76), (0.71, 0.69), (0.81, 0.77),
                  (0.22, 0.68), (0.08, 0.78), (0.22, 0.70), (0.08, 0.80)),
    ]

    /// Hollow: espalda baja pegada, brazos y piernas extendidos y elevados.
    static let hollowHold: [StickPose] = [
        StickPose((0.44, 0.60), (0.52, 0.62), (0.72, 0.64),
                  (0.36, 0.54), (0.22, 0.50), (0.38, 0.56), (0.24, 0.52),
                  (0.84, 0.54), (0.94, 0.42), (0.86, 0.56), (0.96, 0.44)),
        StickPose((0.44, 0.63), (0.52, 0.64), (0.72, 0.66),
                  (0.36, 0.57), (0.22, 0.54), (0.38, 0.59), (0.24, 0.56),
                  (0.84, 0.57), (0.94, 0.46), (0.86, 0.59), (0.96, 0.48)),
    ]

    /// Dead bug: brazo y pierna OPUESTOS se extienden, luego cambian.
    static let deadBug: [StickPose] = {
        let a = StickPose((0.46, 0.66), (0.53, 0.67), (0.70, 0.68),
                          (0.42, 0.58), (0.28, 0.52), (0.52, 0.58), (0.50, 0.44),
                          (0.74, 0.52), (0.72, 0.38), (0.84, 0.62), (0.97, 0.61))
        return [a, a.mirroredSides]
    }()

    /// Bird dog: cuadrupedia, brazo y pierna opuestos se extienden.
    static let birdDog: [StickPose] = [
        StickPose((0.72, 0.44), (0.64, 0.48), (0.38, 0.52),
                  (0.66, 0.62), (0.68, 0.78), (0.74, 0.42), (0.90, 0.38),
                  (0.34, 0.66), (0.34, 0.80), (0.24, 0.48), (0.08, 0.44)),
        StickPose((0.72, 0.48), (0.64, 0.52), (0.38, 0.55),
                  (0.66, 0.64), (0.68, 0.80), (0.67, 0.65), (0.70, 0.81),
                  (0.34, 0.68), (0.34, 0.82), (0.33, 0.70), (0.33, 0.84)),
    ]

    /// Superman: en prono, brazos y piernas se despegan del suelo.
    static let superman: [StickPose] = [
        StickPose((0.18, 0.66), (0.28, 0.67), (0.56, 0.68),
                  (0.16, 0.70), (0.04, 0.70), (0.16, 0.72), (0.04, 0.72),
                  (0.74, 0.70), (0.92, 0.71), (0.74, 0.72), (0.92, 0.73)),
        StickPose((0.18, 0.58), (0.28, 0.62), (0.56, 0.68),
                  (0.16, 0.58), (0.04, 0.52), (0.16, 0.60), (0.04, 0.54),
                  (0.74, 0.66), (0.92, 0.58), (0.74, 0.68), (0.92, 0.60)),
    ]

    /// Rueda abdominal: de rodillas, rueda hacia fuera y regresa.
    static let abWheel: [StickPose] = [
        StickPose((0.58, 0.44), (0.52, 0.50), (0.42, 0.66),
                  (0.60, 0.62), (0.66, 0.78), (0.62, 0.63), (0.68, 0.79),
                  (0.40, 0.84), (0.28, 0.90), (0.42, 0.86), (0.30, 0.92)),
        StickPose((0.74, 0.54), (0.66, 0.58), (0.46, 0.68),
                  (0.80, 0.66), (0.92, 0.76), (0.82, 0.67), (0.94, 0.77),
                  (0.42, 0.84), (0.30, 0.90), (0.44, 0.86), (0.32, 0.92)),
    ]

    // ══════════════════ CORE DINÁMICO ══════════════════

    /// Abdominal completo: el torso llega a la vertical.
    static let sitUp: [StickPose] = [
        StickPose((0.18, 0.64), (0.28, 0.66), (0.56, 0.70),
                  (0.24, 0.58), (0.18, 0.56), (0.26, 0.59), (0.20, 0.57),
                  (0.72, 0.54), (0.86, 0.72), (0.74, 0.56), (0.88, 0.74)),
        StickPose((0.46, 0.34), (0.50, 0.46), (0.56, 0.70),
                  (0.48, 0.30), (0.44, 0.26), (0.50, 0.31), (0.46, 0.27),
                  (0.72, 0.54), (0.86, 0.72), (0.74, 0.56), (0.88, 0.74)),
    ]

    /// Crunch: recorrido corto, solo se despegan los omóplatos.
    static let crunch: [StickPose] = [
        StickPose((0.22, 0.63), (0.32, 0.66), (0.58, 0.70),
                  (0.27, 0.56), (0.22, 0.56), (0.29, 0.57), (0.24, 0.57),
                  (0.72, 0.52), (0.84, 0.72), (0.74, 0.53), (0.86, 0.73)),
        StickPose((0.33, 0.48), (0.40, 0.56), (0.58, 0.70),
                  (0.34, 0.44), (0.30, 0.42), (0.36, 0.45), (0.32, 0.43),
                  (0.72, 0.52), (0.84, 0.72), (0.74, 0.53), (0.86, 0.73)),
    ]

    /// V-up: manos y pies se encuentran arriba formando una V.
    static let vUp: [StickPose] = [
        StickPose((0.16, 0.62), (0.26, 0.64), (0.54, 0.68),
                  (0.14, 0.56), (0.02, 0.54), (0.16, 0.58), (0.04, 0.56),
                  (0.72, 0.68), (0.92, 0.68), (0.72, 0.70), (0.92, 0.70)),
        StickPose((0.36, 0.42), (0.44, 0.52), (0.54, 0.70),
                  (0.48, 0.36), (0.62, 0.28), (0.50, 0.37), (0.64, 0.29),
                  (0.68, 0.52), (0.78, 0.32), (0.70, 0.54), (0.80, 0.34)),
    ]

    /// Elevación de piernas: el torso queda quieto, solo suben las piernas.
    static let legRaise: [StickPose] = [
        StickPose((0.16, 0.60), (0.26, 0.62), (0.54, 0.68),
                  (0.22, 0.68), (0.10, 0.70), (0.24, 0.70), (0.12, 0.72),
                  (0.72, 0.70), (0.92, 0.72), (0.72, 0.72), (0.92, 0.74)),
        StickPose((0.16, 0.60), (0.26, 0.62), (0.54, 0.68),
                  (0.22, 0.68), (0.10, 0.70), (0.24, 0.70), (0.12, 0.72),
                  (0.62, 0.52), (0.66, 0.30), (0.64, 0.54), (0.68, 0.32)),
    ]

    /// Giro ruso: sentado, el tronco rota de lado a lado.
    static let russianTwist: [StickPose] = [
        StickPose((0.44, 0.32), (0.46, 0.43), (0.52, 0.66),
                  (0.34, 0.50), (0.26, 0.54), (0.38, 0.51), (0.30, 0.55),
                  (0.68, 0.54), (0.82, 0.68), (0.70, 0.56), (0.84, 0.70)),
        StickPose((0.52, 0.31), (0.50, 0.43), (0.52, 0.66),
                  (0.60, 0.48), (0.68, 0.44), (0.62, 0.49), (0.70, 0.45),
                  (0.68, 0.54), (0.82, 0.68), (0.70, 0.56), (0.84, 0.70)),
    ]

    /// Limpiaparabrisas: tumbado, piernas verticales que barren de lado a lado.
    static let windshieldWiper: [StickPose] = [
        StickPose((0.50, 0.80), (0.50, 0.71), (0.50, 0.55),
                  (0.32, 0.73), (0.15, 0.75), (0.68, 0.73), (0.85, 0.75),
                  (0.36, 0.38), (0.21, 0.24), (0.38, 0.40), (0.23, 0.26)),
        StickPose((0.50, 0.80), (0.50, 0.71), (0.50, 0.55),
                  (0.32, 0.73), (0.15, 0.75), (0.68, 0.73), (0.85, 0.75),
                  (0.64, 0.38), (0.79, 0.24), (0.62, 0.40), (0.77, 0.26)),
    ]

    /// Mountain climber: desde plancha, las rodillas entran alternando.
    static let mountainClimber: [StickPose] = {
        let a = StickPose((0.78, 0.46), (0.68, 0.50), (0.40, 0.58),
                          (0.68, 0.64), (0.70, 0.80), (0.71, 0.65), (0.73, 0.81),
                          (0.24, 0.66), (0.10, 0.78), (0.52, 0.70), (0.44, 0.82))
        return [a, a.mirroredSides]
    }()

    // ══════════════════ MARCHA Y CARDIO ══════════════════

    /// Trote: ciclo de zancada de cuatro tiempos.
    static let run: [StickPose] = {
        let contact = StickPose((0.50, 0.12), (0.50, 0.24), (0.50, 0.52),
                                (0.40, 0.36), (0.36, 0.48), (0.60, 0.34), (0.64, 0.44),
                                (0.62, 0.68), (0.68, 0.84), (0.40, 0.70), (0.34, 0.86))
        let passing = StickPose((0.50, 0.11), (0.50, 0.23), (0.50, 0.50),
                                (0.45, 0.36), (0.43, 0.49), (0.55, 0.35), (0.57, 0.47),
                                (0.51, 0.71), (0.52, 0.90), (0.49, 0.71), (0.48, 0.90))
        return [contact, passing, contact.mirroredSides, passing.mirroredSides]
    }()

    /// Sprint: más inclinación de tronco y rodillas mucho más altas.
    static let sprint: [StickPose] = {
        let drive = StickPose((0.58, 0.11), (0.55, 0.23), (0.48, 0.50),
                              (0.42, 0.30), (0.34, 0.40), (0.64, 0.32), (0.72, 0.44),
                              (0.66, 0.56), (0.76, 0.70), (0.36, 0.70), (0.26, 0.86))
        let recover = StickPose((0.58, 0.10), (0.55, 0.22), (0.48, 0.48),
                                (0.48, 0.30), (0.44, 0.44), (0.58, 0.34), (0.64, 0.46),
                                (0.56, 0.64), (0.62, 0.82), (0.46, 0.68), (0.40, 0.88))
        return [drive, recover, drive.mirroredSides, recover.mirroredSides]
    }()

    /// Caminata rápida: mismo ciclo que el trote, amplitud reducida y pie apoyado.
    static let walk: [StickPose] = {
        let step = StickPose((0.50, 0.13), (0.50, 0.25), (0.50, 0.53),
                             (0.44, 0.38), (0.41, 0.52), (0.56, 0.38), (0.59, 0.52),
                             (0.58, 0.73), (0.62, 0.94), (0.43, 0.74), (0.39, 0.94))
        let pass = StickPose((0.50, 0.13), (0.50, 0.25), (0.50, 0.53),
                             (0.47, 0.38), (0.45, 0.53), (0.53, 0.38), (0.55, 0.53),
                             (0.52, 0.74), (0.53, 0.94), (0.48, 0.74), (0.47, 0.94))
        return [step, pass, step.mirroredSides, pass.mirroredSides]
    }()

    /// Escaladora: manos en los apoyos, escalón alto continuo.
    static let stairClimb: [StickPose] = {
        let up = StickPose((0.52, 0.16), (0.51, 0.28), (0.49, 0.54),
                           (0.58, 0.36), (0.66, 0.30), (0.60, 0.37), (0.68, 0.31),
                           (0.62, 0.58), (0.58, 0.74), (0.44, 0.74), (0.42, 0.94))
        let mid = StickPose((0.52, 0.15), (0.51, 0.27), (0.49, 0.53),
                            (0.58, 0.36), (0.66, 0.30), (0.60, 0.37), (0.68, 0.31),
                            (0.56, 0.68), (0.54, 0.86), (0.48, 0.72), (0.46, 0.92))
        return [up, mid, up.mirroredSides, mid.mirroredSides]
    }()

    /// Step: sube al cajón, se pone de pie y baja (3 fases).
    static let stepUp: [StickPose] = [
        StickPose((0.44, 0.20), (0.45, 0.32), (0.45, 0.58),
                  (0.38, 0.44), (0.36, 0.58), (0.52, 0.44), (0.54, 0.58),
                  (0.62, 0.62), (0.68, 0.74), (0.44, 0.78), (0.43, 0.95)),
        StickPose((0.56, 0.14), (0.55, 0.26), (0.54, 0.52),
                  (0.48, 0.38), (0.46, 0.52), (0.62, 0.38), (0.64, 0.52),
                  (0.60, 0.62), (0.64, 0.74), (0.52, 0.64), (0.56, 0.74)),
        StickPose((0.50, 0.18), (0.50, 0.30), (0.50, 0.56),
                  (0.44, 0.42), (0.42, 0.56), (0.56, 0.42), (0.58, 0.56),
                  (0.58, 0.64), (0.62, 0.74), (0.44, 0.76), (0.42, 0.95)),
    ]

    /// Rodillas altas: la rodilla pasa por encima de la cadera.
    static let highKnees: [StickPose] = {
        let lift = StickPose((0.50, 0.11), (0.50, 0.23), (0.50, 0.50),
                             (0.40, 0.32), (0.36, 0.44), (0.60, 0.34), (0.66, 0.44),
                             (0.62, 0.46), (0.70, 0.58), (0.47, 0.72), (0.46, 0.92))
        let down = StickPose((0.50, 0.12), (0.50, 0.24), (0.50, 0.51),
                             (0.44, 0.34), (0.41, 0.47), (0.56, 0.34), (0.60, 0.46),
                             (0.54, 0.66), (0.58, 0.82), (0.48, 0.72), (0.47, 0.92))
        return [lift, down, lift.mirroredSides, down.mirroredSides]
    }()

    /// Pedaleo sentado: las piernas describen un círculo completo.
    static let cycle: [StickPose] = [
        StickPose((0.36, 0.22), (0.39, 0.33), (0.34, 0.58),
                  (0.52, 0.38), (0.64, 0.42), (0.54, 0.39), (0.66, 0.43),
                  (0.60, 0.58), (0.66, 0.74), (0.52, 0.68), (0.58, 0.82)),
        StickPose((0.36, 0.22), (0.39, 0.33), (0.34, 0.58),
                  (0.52, 0.38), (0.64, 0.42), (0.54, 0.39), (0.66, 0.43),
                  (0.58, 0.68), (0.54, 0.84), (0.58, 0.56), (0.68, 0.70)),
        StickPose((0.36, 0.22), (0.39, 0.33), (0.34, 0.58),
                  (0.52, 0.38), (0.64, 0.42), (0.54, 0.39), (0.66, 0.43),
                  (0.52, 0.68), (0.58, 0.82), (0.60, 0.58), (0.66, 0.74)),
        StickPose((0.36, 0.22), (0.39, 0.33), (0.34, 0.58),
                  (0.52, 0.38), (0.64, 0.42), (0.54, 0.39), (0.66, 0.43),
                  (0.58, 0.56), (0.68, 0.70), (0.58, 0.68), (0.54, 0.84)),
    ]

    /// Elíptica: de pie, brazos y piernas empujan y tiran a la vez.
    static let elliptical: [StickPose] = {
        let a = StickPose((0.50, 0.14), (0.50, 0.26), (0.50, 0.54),
                          (0.38, 0.38), (0.30, 0.46), (0.62, 0.38), (0.70, 0.46),
                          (0.62, 0.68), (0.70, 0.86), (0.40, 0.72), (0.32, 0.90))
        let b = StickPose((0.50, 0.14), (0.50, 0.26), (0.50, 0.54),
                          (0.44, 0.40), (0.38, 0.50), (0.56, 0.40), (0.62, 0.50),
                          (0.54, 0.74), (0.58, 0.90), (0.47, 0.74), (0.44, 0.90))
        return [a, b, a.mirroredSides, b.mirroredSides]
    }()

    /// Remada: piernas, cadera y brazos en secuencia.
    static let rowing: [StickPose] = [
        StickPose((0.34, 0.34), (0.40, 0.43), (0.34, 0.64),
                  (0.52, 0.46), (0.66, 0.48), (0.54, 0.47), (0.68, 0.49),
                  (0.58, 0.54), (0.76, 0.66), (0.60, 0.56), (0.78, 0.68)),
        StickPose((0.24, 0.30), (0.31, 0.40), (0.30, 0.64),
                  (0.40, 0.48), (0.54, 0.52), (0.42, 0.49), (0.56, 0.53),
                  (0.56, 0.66), (0.78, 0.68), (0.58, 0.68), (0.80, 0.70)),
    ]

    // ══════════════════ PLIOMETRÍA ══════════════════

    /// Salto de cuerda: rebote bajo, las manos apenas se mueven.
    static let jumpRope: [StickPose] = [
        StickPose((0.50, 0.16), (0.50, 0.28), (0.50, 0.55),
                  (0.40, 0.42), (0.34, 0.52), (0.60, 0.42), (0.66, 0.52),
                  (0.47, 0.76), (0.46, 0.95), (0.53, 0.76), (0.54, 0.95)),
        StickPose((0.50, 0.11), (0.50, 0.23), (0.50, 0.50),
                  (0.40, 0.37), (0.34, 0.47), (0.60, 0.37), (0.66, 0.47),
                  (0.47, 0.70), (0.48, 0.86), (0.53, 0.70), (0.52, 0.86)),
    ]

    /// Burpee completo: de pie → manos al suelo → plancha → salto (4 fases).
    static let burpee: [StickPose] = [
        StickPose((0.50, 0.14), (0.50, 0.26), (0.50, 0.54),
                  (0.42, 0.40), (0.41, 0.56), (0.58, 0.40), (0.59, 0.56),
                  (0.47, 0.75), (0.46, 0.94), (0.53, 0.75), (0.54, 0.94)),
        StickPose((0.48, 0.44), (0.50, 0.54), (0.46, 0.72),
                  (0.56, 0.66), (0.60, 0.86), (0.58, 0.67), (0.62, 0.87),
                  (0.58, 0.80), (0.48, 0.94), (0.60, 0.81), (0.52, 0.94)),
        StickPose((0.76, 0.56), (0.66, 0.60), (0.38, 0.68),
                  (0.66, 0.70), (0.68, 0.86), (0.68, 0.71), (0.70, 0.87),
                  (0.22, 0.74), (0.08, 0.84), (0.22, 0.76), (0.08, 0.86)),
        StickPose((0.50, 0.06), (0.50, 0.18), (0.50, 0.44),
                  (0.40, 0.12), (0.36, 0.01), (0.60, 0.12), (0.64, 0.01),
                  (0.46, 0.60), (0.44, 0.74), (0.54, 0.60), (0.56, 0.74)),
    ]

    /// Salto de tijera (vista frontal): brazos y piernas abren y cierran.
    static let jumpingJack: [StickPose] = [
        StickPose((0.50, 0.14), (0.50, 0.26), (0.50, 0.54),
                  (0.44, 0.40), (0.44, 0.56), (0.56, 0.40), (0.56, 0.56),
                  (0.48, 0.74), (0.48, 0.94), (0.52, 0.74), (0.52, 0.94)),
        StickPose((0.50, 0.14), (0.50, 0.26), (0.50, 0.54),
                  (0.34, 0.24), (0.24, 0.08), (0.66, 0.24), (0.76, 0.08),
                  (0.38, 0.74), (0.28, 0.92), (0.62, 0.74), (0.72, 0.92)),
    ]

    // ══════════════════ OTROS ══════════════════

    /// Crol: cuerpo horizontal, los brazos giran alternando.
    static let swim: [StickPose] = {
        let a = StickPose((0.66, 0.58), (0.58, 0.60), (0.32, 0.64),
                          (0.72, 0.50), (0.86, 0.44), (0.46, 0.72), (0.32, 0.78),
                          (0.18, 0.66), (0.04, 0.70), (0.18, 0.70), (0.04, 0.74))
        let b = StickPose((0.66, 0.58), (0.58, 0.60), (0.32, 0.64),
                          (0.66, 0.72), (0.78, 0.78), (0.54, 0.50), (0.66, 0.44),
                          (0.18, 0.68), (0.04, 0.66), (0.18, 0.72), (0.04, 0.78))
        return [a, b, a.mirroredSides, b.mirroredSides]
    }()

    /// Sombra: golpes alternos con guardia alta.
    static let shadowBox: [StickPose] = {
        let a = StickPose((0.46, 0.16), (0.47, 0.28), (0.48, 0.54),
                          (0.40, 0.34), (0.44, 0.24), (0.66, 0.32), (0.80, 0.30),
                          (0.42, 0.74), (0.38, 0.94), (0.56, 0.74), (0.60, 0.94))
        return [a, a.mirroredSides]
    }()

    /// Battle ropes: base ancha, los brazos generan ondas alternadas.
    static let battleRopes: [StickPose] = {
        let a = StickPose((0.50, 0.24), (0.50, 0.35), (0.50, 0.58),
                          (0.38, 0.40), (0.30, 0.26), (0.62, 0.44), (0.70, 0.58),
                          (0.40, 0.74), (0.32, 0.94), (0.60, 0.74), (0.68, 0.94))
        return [a, a.mirroredSides]
    }()

    /// Farmer's walk: erguido, brazos rectos por el peso, pasos cortos.
    static let farmersWalk: [StickPose] = {
        let a = StickPose((0.50, 0.12), (0.50, 0.24), (0.50, 0.52),
                          (0.42, 0.38), (0.41, 0.56), (0.58, 0.38), (0.59, 0.56),
                          (0.56, 0.72), (0.60, 0.92), (0.44, 0.72), (0.40, 0.92))
        return [a, a.mirroredSides]
    }()

    // ══════════════════ FLEXIBILIDAD ══════════════════

    /// Perro boca abajo ↔ plancha alta.
    static let yoga: [StickPose] = [
        StickPose((0.62, 0.52), (0.56, 0.47), (0.38, 0.27),
                  (0.66, 0.62), (0.74, 0.80), (0.68, 0.63), (0.76, 0.81),
                  (0.26, 0.52), (0.16, 0.82), (0.26, 0.54), (0.16, 0.84)),
        StickPose((0.72, 0.46), (0.64, 0.52), (0.38, 0.62),
                  (0.68, 0.64), (0.72, 0.80), (0.70, 0.65), (0.74, 0.81),
                  (0.24, 0.70), (0.14, 0.82), (0.24, 0.72), (0.14, 0.84)),
    ]

    /// Rodillo: el cuerpo se desplaza sobre el foam de ida y vuelta.
    static let foamRoll: [StickPose] = [
        StickPose((0.36, 0.44), (0.42, 0.52), (0.58, 0.68),
                  (0.32, 0.62), (0.22, 0.74), (0.34, 0.64), (0.24, 0.76),
                  (0.74, 0.62), (0.88, 0.78), (0.76, 0.64), (0.90, 0.80)),
        StickPose((0.24, 0.40), (0.30, 0.48), (0.46, 0.66),
                  (0.20, 0.60), (0.10, 0.74), (0.22, 0.62), (0.12, 0.76),
                  (0.62, 0.62), (0.78, 0.80), (0.64, 0.64), (0.80, 0.82)),
    ]

    /// Estiramiento de psoas: media rodilla en el suelo, cadera al frente.
    static let hipFlexorStretch: [StickPose] = [
        StickPose((0.44, 0.24), (0.46, 0.36), (0.46, 0.60),
                  (0.38, 0.48), (0.36, 0.62), (0.54, 0.48), (0.56, 0.62),
                  (0.68, 0.72), (0.74, 0.92), (0.30, 0.82), (0.16, 0.90)),
        StickPose((0.44, 0.28), (0.46, 0.40), (0.49, 0.64),
                  (0.38, 0.52), (0.36, 0.66), (0.54, 0.52), (0.56, 0.66),
                  (0.71, 0.74), (0.75, 0.92), (0.28, 0.84), (0.14, 0.92)),
    ]

    /// Postura del niño ↔ gato: la espalda se alarga y se redondea.
    static let backStretch: [StickPose] = [
        StickPose((0.72, 0.66), (0.62, 0.64), (0.36, 0.62),
                  (0.76, 0.70), (0.90, 0.74), (0.78, 0.72), (0.92, 0.76),
                  (0.30, 0.78), (0.18, 0.84), (0.30, 0.80), (0.18, 0.86)),
        StickPose((0.68, 0.58), (0.60, 0.52), (0.36, 0.52),
                  (0.62, 0.66), (0.64, 0.82), (0.64, 0.67), (0.66, 0.83),
                  (0.32, 0.70), (0.24, 0.84), (0.32, 0.72), (0.24, 0.86)),
    ]

    /// Paloma: pierna delantera cruzada, el torso se pliega al frente.
    static let pigeonPose: [StickPose] = [
        StickPose((0.46, 0.32), (0.48, 0.43), (0.50, 0.66),
                  (0.40, 0.54), (0.34, 0.70), (0.56, 0.54), (0.60, 0.70),
                  (0.30, 0.72), (0.52, 0.76), (0.70, 0.74), (0.90, 0.80)),
        StickPose((0.34, 0.52), (0.40, 0.56), (0.50, 0.66),
                  (0.26, 0.62), (0.14, 0.72), (0.28, 0.64), (0.16, 0.74),
                  (0.30, 0.72), (0.52, 0.76), (0.70, 0.74), (0.90, 0.80)),
    ]
}
