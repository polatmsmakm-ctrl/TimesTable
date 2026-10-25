import SwiftUI

struct MapView: View {
    @EnvironmentObject var store: Store

    private let nums = Array(2...10)

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("خريطة الإتقان")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(Theme.text)
                        Text("اللون يبين مستوى كل حقيقة، والإطار الذهبي للحقائق الأساسية")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.dim)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("الإتقان في المجموعة الحالية")
                                .foregroundColor(Theme.dim)
                            Spacer()
                            Text("\(Int((store.mastery * 100).rounded()))%")
                                .foregroundColor(Theme.gold)
                                .font(.system(size: 20, weight: .heavy))
                        }
                        ProgressView(value: store.mastery)
                            .tint(Theme.teal)
                    }
                    .card()

                    grid
                    legend
                }
                .padding(18)
            }
        }
    }

    private var grid: some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            GridRow {
                Text("×").foregroundColor(Theme.gold)
                ForEach(nums, id: \.self) { c in
                    Text("\(c)").foregroundColor(Theme.gold)
                }
            }
            ForEach(nums, id: \.self) { r in
                GridRow {
                    Text("\(r)").foregroundColor(Theme.gold)
                    ForEach(nums, id: \.self) { c in
                        cell(r, c)
                    }
                }
            }
        }
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .environment(\.layoutDirection, .leftToRight)
    }

    private func cell(_ r: Int, _ c: Int) -> some View {
        let f = Fact(r, c)
        let e = store.entry(f)
        return Text("\(r * c)")
            .foregroundColor(e.seen == 0 ? Theme.dim : Theme.text)
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(color(for: e))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(f.isCore ? Theme.gold : Color.clear, lineWidth: 1.5)
            )
    }

    private func color(for e: Entry) -> Color {
        if e.seen == 0 { return Color(hex: 0x1E232C) }
        switch e.box {
        case 0: return Color(hex: 0x7A2E3A)
        case 1: return Color(hex: 0x7A5420)
        case 2: return Color(hex: 0x6B6420)
        case 3: return Color(hex: 0x1F5A55)
        default: return Color(hex: 0x1F6B3F)
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 8) {
            legendRow(Color(hex: 0x1E232C), "لم تُختبر بعد")
            legendRow(Color(hex: 0x7A2E3A), "أخطأت فيها، تحتاج مراجعة")
            legendRow(Color(hex: 0x7A5420), "بداية الحفظ")
            legendRow(Color(hex: 0x6B6420), "تتحسن")
            legendRow(Color(hex: 0x1F5A55), "قريبة من الإتقان")
            legendRow(Color(hex: 0x1F6B3F), "متقنة وسريعة")
        }
        .card()
    }

    private func legendRow(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 5).fill(c).frame(width: 22, height: 22)
            Text(t).foregroundColor(Theme.text).font(.system(size: 15))
            Spacer()
        }
    }
}
