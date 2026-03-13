import SwiftUI

struct AuroraView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for i in 0..<3 {
                    let yBase = size.height * (0.3 + CGFloat(i) * 0.2)
                    let yMove = sin(time * 0.4 + Double(i)) * 40
                    
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: yBase + yMove))
                    
                    for x in stride(from: 0, to: size.width, by: 8) {
                        let wave = sin(x / 80 + time * 0.5 + Double(i)) * 25
                        path.addLine(to: CGPoint(x: x, y: yBase + wave + yMove))
                    }
                    let finalX = size.width
                    let finalWave = sin(finalX / 80 + time * 0.5 + Double(i)) * 25
                    path.addLine(to: CGPoint(x: finalX, y: yBase + finalWave + yMove))
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.addLine(to: CGPoint(x: 0, y: size.height))
                    path.closeSubpath()
                    
                    let colors: [Color] = [
                        Color(red: 0.85, green: 0.40, blue: 0.13).opacity(0.35),
                        Color(red: 0.85, green: 0.13, blue: 0.70).opacity(0.35),
                        Color(red: 0.13, green: 0.70, blue: 0.85).opacity(0.35)
                    ]
                    context.fill(path, with: .color(colors[i]))
                }
            }
        }
    }
}

struct GlowOrbs: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let positions: [(x: Double, y: Double, r: Double, h: Double)] = [
                    (0.2, 0.35, 100, 0.10),
                    (0.75, 0.45, 70, 0.88),
                    (0.5, 0.7, 85, 0.60)
                ]
                for (i, p) in positions.enumerated() {
                    let cx = size.width * p.x + sin(t * 0.15 + Double(i)) * 25
                    let cy = size.height * p.y + cos(t * 0.12 + Double(i)) * 20
                    let center = CGPoint(x: cx, y: cy)
                    let grad = Gradient(colors: [
                        Color(hue: p.h, saturation: 0.7, brightness: 0.85).opacity(0.35),
                        Color(hue: p.h, saturation: 0.5, brightness: 0.6).opacity(0)
                    ])
                    context.fill(
                        Circle().path(in: CGRect(x: cx - p.r, y: cy - p.r, width: p.r * 2, height: p.r * 2)),
                        with: .radialGradient(grad, center: center, startRadius: 0, endRadius: p.r)
                    )
                }
            }
            .blur(radius: 35)
        }
    }
}
