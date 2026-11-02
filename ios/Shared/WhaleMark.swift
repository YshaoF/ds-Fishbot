import SwiftUI

struct WhaleSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
        p.move(to: point(538, 202))
        p.addCurve(to: point(712,170), control1: point(605,176), control2: point(674,150))
        p.addQuadCurve(to: point(711,187), control: point(730,179))
        p.addCurve(to: point(701,268), control1: point(679,202), control2: point(672,246))
        p.addCurve(to: point(917,449), control1: point(789,330), control2: point(820,413))
        p.addQuadCurve(to: point(943,436), control: point(935,458))
        p.addLine(to: point(953,401)); p.addLine(to: point(1046,416))
        p.addCurve(to: point(896,780), control1: point(1057,568), control2: point(995,689))
        p.addCurve(to: point(984,821), control1: point(916,795), control2: point(955,810))
        p.addCurve(to: point(983,864), control1: point(1006,830), control2: point(1003,853))
        p.addCurve(to: point(815,855), control1: point(939,888), control2: point(867,882))
        p.addCurve(to: point(393,910), control1: point(703,950), control2: point(538,966))
        p.addCurve(to: point(144,537), control1: point(233,848), control2: point(152,699))
        p.addCurve(to: point(315,220), control1: point(134,382), control2: point(202,269))
        p.addCurve(to: point(538,202), control1: point(384,191), control2: point(464,187)); p.closeSubpath()
        p.move(to: point(944,402))
        p.addCurve(to: point(862,219), control1: point(879,367), control2: point(851,292))
        p.addCurve(to: point(888,146), control1: point(865,190), control2: point(879,151))
        p.addCurve(to: point(922,192), control1: point(905,136), control2: point(908,169))
        p.addCurve(to: point(1010,272), control1: point(940,223), control2: point(996,232))
        p.addLine(to: point(1020,294))
        p.addCurve(to: point(1106,257), control1: point(1052,269), control2: point(1071,258))
        p.addCurve(to: point(1189,225), control1: point(1142,256), control2: point(1162,259))
        p.addCurve(to: point(1221,222), control1: point(1204,205), control2: point(1218,205))
        p.addCurve(to: point(1123,402), control1: point(1228,289), control2: point(1191,372))
        p.addCurve(to: point(1046,419), control1: point(1095,415), control2: point(1073,418))
        p.addLine(to: point(1015,465)); p.addLine(to: point(941,443)); p.closeSubpath()
        return p.applying(CGAffineTransform(translationX: -100, y: -115)
            .concatenating(CGAffineTransform(scaleX: rect.width / 1150, y: rect.height / 855))
            .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }
}

struct WhaleMark: View {
    var body: some View {
        GeometryReader { g in
            WhaleSilhouette().fill(Color(red: 0.31, green: 0.43, blue: 0.95))
            ForEach(0..<2) { index in
                Capsule().fill(.white)
                    .frame(width: g.size.width * 0.063, height: g.size.height * 0.22)
                    .rotationEffect(.degrees(-18))
                    .position(x: g.size.width * (index == 0 ? 0.348 : 0.522),
                              y: g.size.height * (index == 0 ? 0.47 : 0.447))
            }
        }
        .aspectRatio(1150.0 / 855.0, contentMode: .fit)
        .accessibilityLabel("小鲸")
    }
}
