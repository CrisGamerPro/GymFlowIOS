import ActivityKit
import WidgetKit
import SwiftUI

struct GymFlowWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // ── Lock Screen / Banner UI ───────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label {
                        Text(context.attributes.routineName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    } icon: {
                        Text("🏋️")
                            .font(.system(size: 15))
                    }
                    
                    Spacer()
                    
                    if context.state.isCompleted {
                        Text("¡Completado! 🎉")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text("\(Int(context.state.progressPercent * 100))%")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
                
                if !context.state.isCompleted {
                    HStack(spacing: 6) {
                        Text(context.state.currentExerciseName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Serie \(context.state.currentSet)/\(context.state.totalSets)")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Barra de progreso
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange)
                                .frame(
                                    width: max(0, geo.size.width * CGFloat(context.state.progressPercent)),
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(.orange)

        } dynamicIsland: { context in
            DynamicIsland {
                // ── Dynamic Island expandida ─────────────────────────────
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.routineName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    } icon: {
                        Text("🏋️")
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progressPercent * 100))%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        HStack {
                            Text(context.state.currentExerciseName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("Serie \(context.state.currentSet)/\(context.state.totalSets)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        ProgressView(value: context.state.progressPercent)
                            .tint(.orange)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Text("🏋️")
            } compactTrailing: {
                Text("\(Int(context.state.progressPercent * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
            } minimal: {
                Text("🏋️")
            }
            .keylineTint(.orange)
        }
    }
}
