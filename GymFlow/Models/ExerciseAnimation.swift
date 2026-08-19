import Foundation
import CoreGraphics

// MARK: - Pose de figura articulada
//
// Todas las coordenadas están normalizadas (0…1) sobre un lienzo cuadrado,
// con el origen arriba-izquierda (convención de SwiftUI).
// "Far" = extremidad del lado lejano (se dibuja atenuada para dar profundidad),
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

    /// Init posicional compacto — el orden es el mismo de arriba.
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

// MARK: - Patrones de movimiento

enum MovementPattern: String, CaseIterable {
    case squat, lunge, push, pull, hinge, curl, plank
    case crunch, twist, run, cycle, rowing, jump, stretch, punch, carry

    /// Duración de un ciclo completo, en segundos.
    var cycleDuration: Double {
        switch self {
        case .run, .punch:            return 0.7
        case .jump, .cycle:           return 0.9
        case .crunch, .twist, .curl:  return 1.6
        case .squat, .push, .pull, .rowing, .lunge, .hinge, .carry: return 2.0
        case .plank:                  return 3.4
        case .stretch:                return 4.0
        }
    }

    var keyframes: [StickPose] {
        switch self {
        case .squat:   return Self.squatFrames
        case .lunge:   return Self.lungeFrames
        case .push:    return Self.pushFrames
        case .pull:    return Self.pullFrames
        case .hinge:   return Self.hingeFrames
        case .curl:    return Self.curlFrames
        case .plank:   return Self.plankFrames
        case .crunch:  return Self.crunchFrames
        case .twist:   return Self.twistFrames
        case .run:     return Self.runFrames
        case .cycle:   return Self.cycleFrames
        case .rowing:  return Self.rowingFrames
        case .jump:    return Self.jumpFrames
        case .stretch: return Self.stretchFrames
        case .punch:   return Self.punchFrames
        case .carry:   return Self.carryFrames
        }
    }

    /// Etiqueta corta del patrón, para la ficha del ejercicio.
    var displayName: String {
        let english = AppLanguage.current == .english
        switch self {
        case .squat:   return english ? "Squat pattern"    : "Patrón de sentadilla"
        case .lunge:   return english ? "Lunge pattern"    : "Patrón de zancada"
        case .push:    return english ? "Push pattern"     : "Patrón de empuje"
        case .pull:    return english ? "Pull pattern"     : "Patrón de tracción"
        case .hinge:   return english ? "Hip hinge"        : "Bisagra de cadera"
        case .curl:    return english ? "Arm curl"         : "Flexión de brazo"
        case .plank:   return english ? "Isometric hold"   : "Sostén isométrico"
        case .crunch:  return english ? "Trunk flexion"    : "Flexión de tronco"
        case .twist:   return english ? "Trunk rotation"   : "Rotación de tronco"
        case .run:     return english ? "Running gait"     : "Carrera"
        case .cycle:   return english ? "Cyclic pedaling"  : "Pedaleo cíclico"
        case .rowing:  return english ? "Rowing stroke"    : "Remada"
        case .jump:    return english ? "Jump pattern"     : "Patrón de salto"
        case .stretch: return english ? "Static stretch"   : "Estiramiento"
        case .punch:   return english ? "Punch combo"      : "Combinación de golpes"
        case .carry:   return english ? "Loaded carry"     : "Transporte con carga"
        }
    }

    /// Claves de técnica. Van por patrón (no por ejercicio) porque las
    /// indicaciones de una sentadilla valen igual para todas sus variantes.
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
                ? ["Hands slightly wider than shoulders",
                   "Elbows at ~45°, not flared out",
                   "Lower under control, don't bounce",
                   "Keep a straight line head to heels"]
                : ["Manos algo más abiertas que los hombros",
                   "Codos a ~45°, no abiertos del todo",
                   "Baja controlado, sin rebotar",
                   "Línea recta de la cabeza a los talones"]
        case .pull:
            return english
                ? ["Start from a full hang, shoulders active",
                   "Lead with the elbows, not the hands",
                   "Chest toward the bar",
                   "Lower slowly — that's half the work"]
                : ["Parte colgado, hombros activos",
                   "Tira con los codos, no con las manos",
                   "Lleva el pecho hacia la barra",
                   "Baja lento — ahí está la mitad del trabajo"]
        case .hinge:
            return english
                ? ["Hinge at the hips, not the lower back",
                   "Keep the bar close to your legs",
                   "Neutral spine throughout",
                   "Squeeze glutes to finish standing"]
                : ["Flexiona la cadera, no la espalda baja",
                   "Mantén la barra pegada a las piernas",
                   "Columna neutra en todo el recorrido",
                   "Aprieta glúteos al terminar de pie"]
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
        case .plank:
            return english
                ? ["Straight line: head, hips, heels",
                   "Brace the abs, tuck the hips slightly",
                   "Shoulders stacked over elbows",
                   "Breathe — don't hold your breath"]
                : ["Línea recta: cabeza, cadera, talones",
                   "Aprieta el abdomen, retrovierte la pelvis",
                   "Hombros alineados sobre los codos",
                   "Respira — no aguantes el aire"]
        case .crunch:
            return english
                ? ["Curl the spine, don't yank the neck",
                   "Chin off the chest, eyes up",
                   "Exhale as you lift",
                   "Lower with control"]
                : ["Enrolla la columna, no tires del cuello",
                   "Barbilla separada del pecho, mirada arriba",
                   "Exhala al subir",
                   "Baja controlado"]
        case .twist:
            return english
                ? ["Rotate from the ribcage, not the arms",
                   "Keep the chest tall",
                   "Move slow — speed hides the work",
                   "Heels light or lifted for more load"]
                : ["Gira desde las costillas, no con los brazos",
                   "Mantén el pecho alto",
                   "Ve lento — la velocidad esconde el trabajo",
                   "Talones ligeros o elevados para más carga"]
        case .run:
            return english
                ? ["Land under your hips, not ahead",
                   "Short, quick steps",
                   "Relaxed shoulders, arms at ~90°",
                   "Breathe in a steady rhythm"]
                : ["Aterriza bajo la cadera, no por delante",
                   "Pasos cortos y rápidos",
                   "Hombros sueltos, brazos a ~90°",
                   "Respira en un ritmo constante"]
        case .cycle:
            return english
                ? ["Slight bend in the knee at the bottom",
                   "Push and pull through the whole circle",
                   "Relaxed grip, back long",
                   "Keep cadence steady"]
                : ["Rodilla algo flexionada abajo",
                   "Empuja y tira en todo el círculo",
                   "Agarre suelto, espalda larga",
                   "Mantén la cadencia estable"]
        case .rowing:
            return english
                ? ["Order: legs, then hips, then arms",
                   "Return in reverse: arms, hips, legs",
                   "Keep the back flat, chest open",
                   "Drive with the legs, not the arms"]
                : ["Orden: piernas, luego cadera, luego brazos",
                   "Vuelve al revés: brazos, cadera, piernas",
                   "Espalda plana, pecho abierto",
                   "Empuja con las piernas, no con los brazos"]
        case .jump:
            return english
                ? ["Land soft, on the balls of your feet",
                   "Knees bend on impact to absorb",
                   "Stay tall, minimal ground time",
                   "Wrists do the work, not the arms"]
                : ["Cae suave, sobre la punta de los pies",
                   "Flexiona rodillas al caer para amortiguar",
                   "Mantente erguido, poco tiempo en el suelo",
                   "Trabajan las muñecas, no los brazos"]
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
        case .punch:
            return english
                ? ["Hands up, chin tucked",
                   "Rotate the hip into each punch",
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

// MARK: - Keyframes por patrón

extension MovementPattern {

    // Sentadilla: de pie → abajo (cadera atrás, torso inclinado)
    static let squatFrames: [StickPose] = [
        StickPose((0.50, 0.13), (0.50, 0.25), (0.50, 0.53),
                  (0.56, 0.36), (0.62, 0.30), (0.57, 0.37), (0.63, 0.31),
                  (0.48, 0.74), (0.47, 0.94), (0.52, 0.74), (0.53, 0.94)),
        StickPose((0.42, 0.29), (0.44, 0.40), (0.37, 0.64),
                  (0.54, 0.45), (0.63, 0.43), (0.55, 0.46), (0.64, 0.44),
                  (0.55, 0.75), (0.46, 0.94), (0.58, 0.76), (0.52, 0.94)),
    ]

    // Zancada: de pie → pierna adelante flexionada, rodilla trasera abajo
    static let lungeFrames: [StickPose] = [
        StickPose((0.48, 0.13), (0.48, 0.25), (0.48, 0.53),
                  (0.44, 0.38), (0.43, 0.52), (0.52, 0.38), (0.53, 0.52),
                  (0.46, 0.74), (0.45, 0.94), (0.50, 0.74), (0.51, 0.94)),
        StickPose((0.46, 0.19), (0.46, 0.31), (0.45, 0.59),
                  (0.42, 0.44), (0.41, 0.58), (0.50, 0.44), (0.51, 0.58),
                  (0.66, 0.72), (0.68, 0.94), (0.30, 0.80), (0.24, 0.94)),
    ]

    // Empuje (flexión / press banca): cuerpo horizontal, se baja el pecho
    static let pushFrames: [StickPose] = [
        StickPose((0.76, 0.41), (0.67, 0.45), (0.40, 0.55),
                  (0.66, 0.61), (0.67, 0.78), (0.69, 0.61), (0.70, 0.78),
                  (0.23, 0.64), (0.09, 0.75), (0.23, 0.66), (0.09, 0.78)),
        StickPose((0.76, 0.56), (0.67, 0.60), (0.40, 0.65),
                  (0.75, 0.62), (0.67, 0.78), (0.78, 0.63), (0.70, 0.78),
                  (0.23, 0.71), (0.09, 0.77), (0.23, 0.73), (0.09, 0.80)),
    ]

    // Tracción (dominada): manos fijas arriba, el cuerpo sube
    static let pullFrames: [StickPose] = [
        StickPose((0.50, 0.31), (0.50, 0.41), (0.50, 0.65),
                  (0.46, 0.26), (0.43, 0.09), (0.54, 0.26), (0.57, 0.09),
                  (0.47, 0.80), (0.45, 0.95), (0.53, 0.80), (0.55, 0.95)),
        StickPose((0.50, 0.16), (0.50, 0.27), (0.50, 0.52),
                  (0.35, 0.23), (0.43, 0.09), (0.65, 0.23), (0.57, 0.09),
                  (0.47, 0.68), (0.45, 0.84), (0.53, 0.68), (0.55, 0.84)),
    ]

    // Bisagra (peso muerto): torso baja, cadera atrás, piernas casi rectas
    static let hingeFrames: [StickPose] = [
        StickPose((0.50, 0.13), (0.50, 0.25), (0.50, 0.53),
                  (0.47, 0.38), (0.46, 0.54), (0.53, 0.38), (0.54, 0.54),
                  (0.48, 0.74), (0.47, 0.94), (0.52, 0.74), (0.53, 0.94)),
        StickPose((0.68, 0.38), (0.61, 0.42), (0.38, 0.53),
                  (0.60, 0.58), (0.59, 0.76), (0.64, 0.58), (0.63, 0.76),
                  (0.42, 0.75), (0.44, 0.94), (0.46, 0.75), (0.48, 0.94)),
    ]

    // Curl: codos fijos, el antebrazo sube
    static let curlFrames: [StickPose] = [
        StickPose((0.50, 0.13), (0.50, 0.25), (0.50, 0.53),
                  (0.44, 0.40), (0.43, 0.56), (0.56, 0.40), (0.57, 0.56),
                  (0.48, 0.74), (0.47, 0.94), (0.52, 0.74), (0.53, 0.94)),
        StickPose((0.50, 0.13), (0.50, 0.25), (0.50, 0.53),
                  (0.44, 0.40), (0.47, 0.27), (0.56, 0.40), (0.53, 0.27),
                  (0.48, 0.74), (0.47, 0.94), (0.52, 0.74), (0.53, 0.94)),
    ]

    // Plancha: sostén con micro-movimiento de respiración
    static let plankFrames: [StickPose] = [
        StickPose((0.79, 0.50), (0.69, 0.54), (0.40, 0.62),
                  (0.69, 0.68), (0.79, 0.76), (0.71, 0.69), (0.81, 0.77),
                  (0.22, 0.70), (0.08, 0.78), (0.22, 0.72), (0.08, 0.80)),
        StickPose((0.79, 0.48), (0.69, 0.52), (0.40, 0.59),
                  (0.69, 0.68), (0.79, 0.76), (0.71, 0.69), (0.81, 0.77),
                  (0.22, 0.68), (0.08, 0.78), (0.22, 0.70), (0.08, 0.80)),
    ]

    // Abdominal: tumbado, el tronco se enrolla
    static let crunchFrames: [StickPose] = [
        StickPose((0.22, 0.63), (0.32, 0.66), (0.58, 0.70),
                  (0.27, 0.56), (0.22, 0.56), (0.29, 0.57), (0.24, 0.57),
                  (0.72, 0.52), (0.84, 0.72), (0.74, 0.53), (0.86, 0.73)),
        StickPose((0.33, 0.48), (0.40, 0.56), (0.58, 0.70),
                  (0.34, 0.44), (0.30, 0.42), (0.36, 0.45), (0.32, 0.43),
                  (0.72, 0.52), (0.84, 0.72), (0.74, 0.53), (0.86, 0.73)),
    ]

    // Giro ruso: sentado, el tronco rota de lado a lado
    static let twistFrames: [StickPose] = [
        StickPose((0.44, 0.32), (0.46, 0.43), (0.52, 0.66),
                  (0.34, 0.50), (0.26, 0.54), (0.38, 0.51), (0.30, 0.55),
                  (0.68, 0.54), (0.82, 0.68), (0.70, 0.56), (0.84, 0.70)),
        StickPose((0.52, 0.31), (0.50, 0.43), (0.52, 0.66),
                  (0.60, 0.48), (0.68, 0.44), (0.62, 0.49), (0.70, 0.45),
                  (0.68, 0.54), (0.82, 0.68), (0.70, 0.56), (0.84, 0.70)),
    ]

    // Carrera: 4 fotogramas para un ciclo de zancada completo
    static let runFrames: [StickPose] = [
        StickPose((0.50, 0.12), (0.50, 0.24), (0.50, 0.52),
                  (0.40, 0.36), (0.36, 0.48), (0.60, 0.34), (0.64, 0.44),
                  (0.62, 0.68), (0.68, 0.84), (0.40, 0.70), (0.34, 0.86)),
        StickPose((0.50, 0.11), (0.50, 0.23), (0.50, 0.50),
                  (0.45, 0.36), (0.43, 0.49), (0.55, 0.35), (0.57, 0.47),
                  (0.51, 0.71), (0.52, 0.90), (0.49, 0.71), (0.48, 0.90)),
        StickPose((0.50, 0.12), (0.50, 0.24), (0.50, 0.52),
                  (0.60, 0.34), (0.64, 0.44), (0.40, 0.36), (0.36, 0.48),
                  (0.40, 0.70), (0.34, 0.86), (0.62, 0.68), (0.68, 0.84)),
        StickPose((0.50, 0.11), (0.50, 0.23), (0.50, 0.50),
                  (0.55, 0.35), (0.57, 0.47), (0.45, 0.36), (0.43, 0.49),
                  (0.49, 0.71), (0.48, 0.90), (0.51, 0.71), (0.52, 0.90)),
    ]

    // Pedaleo: sentado, las piernas describen un círculo (4 fotogramas)
    static let cycleFrames: [StickPose] = [
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

    // Remada: sentado, tira hacia atrás y vuelve
    static let rowingFrames: [StickPose] = [
        StickPose((0.34, 0.34), (0.40, 0.43), (0.34, 0.64),
                  (0.52, 0.46), (0.66, 0.48), (0.54, 0.47), (0.68, 0.49),
                  (0.58, 0.54), (0.76, 0.66), (0.60, 0.56), (0.78, 0.68)),
        StickPose((0.24, 0.30), (0.31, 0.40), (0.30, 0.64),
                  (0.40, 0.48), (0.54, 0.52), (0.42, 0.49), (0.56, 0.53),
                  (0.56, 0.66), (0.78, 0.68), (0.58, 0.68), (0.80, 0.70)),
    ]

    // Salto (cuerda / burpee): abajo → en el aire
    static let jumpFrames: [StickPose] = [
        StickPose((0.50, 0.20), (0.50, 0.32), (0.50, 0.58),
                  (0.40, 0.42), (0.34, 0.50), (0.60, 0.42), (0.66, 0.50),
                  (0.46, 0.76), (0.45, 0.94), (0.54, 0.76), (0.55, 0.94)),
        StickPose((0.50, 0.11), (0.50, 0.23), (0.50, 0.48),
                  (0.40, 0.32), (0.34, 0.40), (0.60, 0.32), (0.66, 0.40),
                  (0.46, 0.64), (0.44, 0.80), (0.54, 0.64), (0.56, 0.80)),
    ]

    // Estiramiento: alcance lento y sostenido
    static let stretchFrames: [StickPose] = [
        StickPose((0.50, 0.14), (0.50, 0.26), (0.50, 0.54),
                  (0.42, 0.40), (0.40, 0.55), (0.58, 0.40), (0.60, 0.55),
                  (0.47, 0.75), (0.46, 0.94), (0.53, 0.75), (0.54, 0.94)),
        StickPose((0.58, 0.26), (0.54, 0.36), (0.48, 0.60),
                  (0.60, 0.30), (0.66, 0.20), (0.62, 0.44), (0.70, 0.50),
                  (0.42, 0.78), (0.38, 0.94), (0.58, 0.76), (0.64, 0.92)),
    ]

    // Boxeo: alterna golpes con guardia alta
    static let punchFrames: [StickPose] = [
        StickPose((0.46, 0.16), (0.47, 0.28), (0.48, 0.54),
                  (0.40, 0.34), (0.44, 0.24), (0.66, 0.32), (0.80, 0.30),
                  (0.42, 0.74), (0.38, 0.94), (0.56, 0.74), (0.60, 0.94)),
        StickPose((0.46, 0.16), (0.47, 0.28), (0.48, 0.54),
                  (0.66, 0.31), (0.80, 0.28), (0.40, 0.34), (0.44, 0.24),
                  (0.42, 0.74), (0.38, 0.94), (0.56, 0.74), (0.60, 0.94)),
    ]

    // Transporte con carga: caminar erguido, brazos rectos abajo
    static let carryFrames: [StickPose] = [
        StickPose((0.50, 0.12), (0.50, 0.24), (0.50, 0.52),
                  (0.42, 0.38), (0.41, 0.56), (0.58, 0.38), (0.59, 0.56),
                  (0.56, 0.72), (0.60, 0.92), (0.44, 0.72), (0.40, 0.92)),
        StickPose((0.50, 0.12), (0.50, 0.24), (0.50, 0.52),
                  (0.42, 0.38), (0.41, 0.56), (0.58, 0.38), (0.59, 0.56),
                  (0.44, 0.72), (0.40, 0.92), (0.56, 0.72), (0.60, 0.92)),
    ]
}

// MARK: - Mapeo ejercicio → patrón

struct ExerciseAnimationCatalog {
    private static let byExerciseId: [String: MovementPattern] = [
        // Cardio
        "trote": .run, "cinta": .run, "sprints": .run, "caminata": .run,
        "escaladora": .run, "step": .run, "aerobicos": .jump, "hiit": .jump,
        "bici": .cycle, "elip": .cycle,
        "remar": .rowing, "remo_erg": .rowing,
        "cuerda": .jump, "nata": .stretch, "box": .punch,

        // Fuerza
        "bench": .push, "manc": .push, "flex": .push, "dips": .push,
        "shoulder": .push, "arnold": .push, "press_inclinado": .push,
        "press_cerrado": .push, "aperturas": .push, "tricep": .push,
        "pull": .pull, "jalon": .pull, "remo": .pull, "polea": .pull,
        "remo_un_brazo": .pull, "face_pull": .pull, "reverse_fly": .pull,
        "squat": .squat, "ext_quad": .squat, "hip_thrust": .hinge,
        "lunge": .lunge, "peso": .hinge, "femoral": .hinge,
        "bicep": .curl, "curl_martillo": .curl,

        // Core
        "abs": .crunch, "crunches": .crunch, "v_ups": .crunch,
        "elevacion": .crunch, "rueda": .plank,
        "plancha": .plank, "hollow": .plank, "dead_bug": .plank,
        "bird_dog": .plank, "supman": .plank,
        "russian": .twist, "windshield": .twist,
        "burpee": .jump, "mtn": .run,

        // Funcional
        "kettlebell": .hinge, "get_up": .hinge,
        "battle_ropes": .punch, "wall_ball": .squat, "box_jump": .jump,
        "farmers_walk": .carry,

        // Flexibilidad
        "yoga": .stretch, "foam_roll": .stretch, "hip_flexor": .stretch,
        "espalda_str": .stretch, "pigeon": .stretch,
    ]

    private static let byCategory: [String: MovementPattern] = [
        "Cardio": .run, "Fuerza": .push, "Core": .crunch,
        "Funcional": .squat, "Flexibilidad": .stretch,
    ]

    /// Patrón para un ejercicio. Cae a la categoría si el id no está mapeado
    /// (p. ej. ejercicios importados de la PWA con ids desconocidos).
    static func pattern(forId id: String, category: String) -> MovementPattern {
        byExerciseId[id] ?? byCategory[category] ?? .squat
    }
}
