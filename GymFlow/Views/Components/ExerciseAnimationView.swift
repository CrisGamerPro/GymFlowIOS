import SwiftUI

/// Figura articulada animada que representa el patrón de movimiento de un
/// ejercicio. Se dibuja con Canvas (una sola vista, sin árbol de vistas por
/// segmento) y se anima con TimelineView, así que no necesita estado propio
/// ni assets — funciona igual en una miniatura de 44 pt que a pantalla completa.
struct ExerciseAnimationView: View {
    let pattern: MovementPattern
    var tint: Color = Theme.amber
    var isPlaying: Bool = true
    /// Grosor del trazo relativo al lado del lienzo.
    var strokeRatio: CGFloat = 0.055

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying)) { timeline in
            Canvas { context, size in
                let pose = Self.pose(for: pattern, at: timeline.date, playing: isPlaying)
                Self.draw(pose: pose, in: &context, size: size,
                          tint: tint, strokeRatio: strokeRatio)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Interpolación

    static func pose(for pattern: MovementPattern, at date: Date, playing: Bool) -> StickPose {
        let frames = pattern.keyframes
        guard let first = frames.first else { return Poses.squat[0] }
        guard frames.count > 1, playing else { return first }

        let elapsed = date.timeIntervalSinceReferenceDate
        let progress = (elapsed.truncatingRemainder(dividingBy: pattern.cycleDuration)) / pattern.cycleDuration

        // Con 2 fotogramas el ciclo es ida y vuelta (ping-pong): así una
        // sentadilla baja y sube en un mismo ciclo sin saltos.
        if frames.count == 2 {
            let t = progress < 0.5 ? progress * 2 : (1 - progress) * 2
            return StickPose.lerp(frames[0], frames[1], easeInOut(t))
        }

        // Con 3+ fotogramas el ciclo es continuo y vuelve al primero.
        let scaled = progress * Double(frames.count)
        let index = min(frames.count - 1, Int(scaled))
        let next = (index + 1) % frames.count
        return StickPose.lerp(frames[index], frames[next], easeInOut(scaled - Double(index)))
    }

    private static func easeInOut(_ t: Double) -> Double {
        let clamped = max(0, min(1, t))
        return clamped * clamped * (3 - 2 * clamped)
    }

    // MARK: - Dibujo

    private static func draw(pose: StickPose, in context: inout GraphicsContext,
                             size: CGSize, tint: Color, strokeRatio: CGFloat) {
        let side = min(size.width, size.height)
        let originX = (size.width - side) / 2
        let originY = (size.height - side) / 2

        func point(_ p: CGPoint) -> CGPoint {
            CGPoint(x: originX + p.x * side, y: originY + p.y * side)
        }

        func limb(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Path {
            var path = Path()
            path.move(to: point(a))
            path.addLine(to: point(b))
            path.addLine(to: point(c))
            return path
        }

        let lineWidth = side * strokeRatio
        let style = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        let far = GraphicsContext.Shading.color(tint.opacity(0.38))
        let near = GraphicsContext.Shading.color(tint)

        // Extremidades lejanas primero — quedan "detrás" y dan profundidad.
        context.stroke(limb(pose.neck, pose.elbowFar, pose.handFar), with: far, style: style)
        context.stroke(limb(pose.hip, pose.kneeFar, pose.footFar), with: far, style: style)

        // Torso
        var torso = Path()
        torso.move(to: point(pose.neck))
        torso.addLine(to: point(pose.hip))
        context.stroke(torso, with: near, style: style)

        // Cuello
        var neckLine = Path()
        neckLine.move(to: point(pose.head))
        neckLine.addLine(to: point(pose.neck))
        context.stroke(neckLine, with: near, style: style)

        // Extremidades cercanas
        context.stroke(limb(pose.neck, pose.elbowNear, pose.handNear), with: near, style: style)
        context.stroke(limb(pose.hip, pose.kneeNear, pose.footNear), with: near, style: style)

        // Cabeza
        let headRadius = side * 0.075
        let headCenter = point(pose.head)
        let headRect = CGRect(
            x: headCenter.x - headRadius, y: headCenter.y - headRadius,
            width: headRadius * 2, height: headRadius * 2
        )
        context.fill(Path(ellipseIn: headRect), with: near)
    }
}

/// Miniatura con fondo, para usar donde antes iba el emoji.
struct ExerciseAnimationTile: View {
    let pattern: MovementPattern
    var size: CGFloat = 44
    var tint: Color = Theme.amber
    var isPlaying: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(tint.opacity(0.12))
            ExerciseAnimationView(
                pattern: pattern,
                tint: tint,
                isPlaying: isPlaying,
                strokeRatio: 0.07
            )
            .padding(size * 0.13)
        }
        .frame(width: size, height: size)
    }
}
