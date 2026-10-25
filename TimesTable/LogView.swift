import SwiftUI

struct LogView: View {
    @EnvironmentObject var store: Store
    @State private var confirmReset = false

    struct Mistake: Identifiable {
        let fact: Fact
        let wrong: Int
        var id: String { fact.key }
    }

    private var mistakes: [Mistake] {
        var list: [Mistake] = []
        for f in Store.allFacts {
            let e = store.entry(f)
            if e.wrong > 0 { list.append(Mistake(fact: f, wrong: e.wrong)) }
        }
        return list.sorted { $0.wrong > $1.wrong }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("سجل الأخطاء")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(Theme.text)
                        Text("السبب يحدد العلاج، فراجع الحيلة المناسبة")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.dim)
                    }

                    HStack(spacing: 10) {
                        stat("الإجابات", "\(store.totalAnswers)", Theme.gold)
                        stat("الدقة", accuracy, Theme.teal)
                    }

                    if mistakes.isEmpty {
                        Text("لا أخطاء مسجلة بعد. ابدأ التدريب.")
                            .foregroundColor(Theme.dim)
                            .card()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(mistakes) { item in
                                HStack {
                                    Text(ltr("\(item.fact.a) × \(item.fact.b) = \(item.fact.product)"))
                                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                                        .foregroundColor(Theme.text)
                                    Spacer()
                                    Text("أخطأت \(item.wrong)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Theme.pink)
                                }
                                .padding(.vertical, 2)
                                Text(Tricks.hint(for: item.fact))
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.dim)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Divider().background(Theme.line)
                            }
                        }
                        .card()
                    }

                    Button(role: .destructive, action: { confirmReset = true }) {
                        Text("مسح كل التقدم")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.pink)
                }
                .padding(18)
            }
        }
        .alert("مسح كل التقدم؟", isPresented: $confirmReset) {
            Button("إلغاء", role: .cancel) {}
            Button("مسح", role: .destructive) { store.reset() }
        } message: {
            Text("سيبدأ التدريب من الصفر.")
        }
    }

    private var accuracy: String {
        let t = store.totalAnswers
        if t == 0 { return "-" }
        return "\(Int((Double(store.totalRight) / Double(t) * 100).rounded()))%"
    }

    private func stat(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(Theme.dim)
        }
        .frame(maxWidth: .infinity)
        .card()
    }
}
