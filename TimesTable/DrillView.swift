import SwiftUI
import UIKit

struct DrillView: View {
    @EnvironmentObject var store: Store

    enum Phase { case asking, right, wrong }

    @State private var fact = Fact(7, 8)
    @State private var flipped = false
    @State private var input = ""
    @State private var phase: Phase = .asking
    @State private var started = Date()
    @State private var lastKey: String? = nil
    @State private var retryKey: String? = nil
    @State private var retryIn = 0
    @State private var asked = 0
    @State private var correctCount = 0
    @State private var streak = 0
    @State private var hint = ""
    @State private var showTest = false
    @State private var lockedTable = 0

    private var left: Int { flipped ? fact.b : fact.a }
    private var right: Int { flipped ? fact.a : fact.b }

    private let rows: [[String]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["⌫", "0", "✓"]]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 14) {
                header
                chips
                if store.focus >= 2 {
                    testButton
                }
                if store.focus == 0 {
                    Picker("المجموعة", selection: $store.mode) {
                        ForEach(PoolMode.allCases, id: \.self) { m in
                            Text(m.title).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Spacer(minLength: 0)
                equation
                feedback
                Spacer(minLength: 0)
                pad
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .onAppear {
            if lastKey == nil { next() }
        }
        .onChange(of: store.mode) { _ in
            retryKey = nil
            next()
        }
        .onChange(of: store.focus) { _ in
            retryKey = nil
            next()
        }
        .fullScreenCover(isPresented: $showTest) {
            TestView(table: store.focus)
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(.dark)
        }
        .alert("الجدول مقفل", isPresented: Binding(get: { lockedTable > 0 }, set: { if !$0 { lockedTable = 0 } })) {
            Button("حسنًا", role: .cancel) {}
        } message: {
            Text("اجتز اختبار جدول \(lockedTable - 1) أولًا بنتيجة \(Store.passMark) من 10.")
        }
    }

    // MARK: الأجزاء

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("تدريب الاسترجاع")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(Theme.text)
                Text(store.focus == 0 ? "اكتب الناتج من ذاكرتك دون حساب" : "جدول \(store.focus): الإتقان \(Int((store.mastery * 100).rounded()))%")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.dim)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("صحيح \(correctCount) من \(asked)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.teal)
                Text("سلسلة \(streak)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.gold)
            }
        }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("مخلوط", 0)
                ForEach(2...9, id: \.self) { n in
                    chip("جدول \(n)", n)
                }
            }
        }
    }

    private func chip(_ title: String, _ n: Int) -> some View {
        let on = store.focus == n
        let locked = n >= 2 && !store.isUnlocked(n)
        let star = n >= 2 && store.isPassed(n)
        return Button(action: {
            if locked { lockedTable = n } else { store.focus = n }
        }) {
            HStack(spacing: 4) {
                Text(title)
                if locked { Image(systemName: "lock.fill") }
                if star { Image(systemName: "star.fill") }
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(on ? Color(hex: 0x1A1305) : (locked ? Theme.dim : Theme.text))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(on ? Theme.gold : Theme.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
        }
    }

    private var testButton: some View {
        Button(action: { showTest = true }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                Text("اختبار جدول \(store.focus)")
                if store.best(store.focus) > 0 {
                    Text("(أفضل نتيجة \(store.best(store.focus)) من 10)")
                        .font(.system(size: 13))
                }
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Theme.teal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.teal.opacity(0.6), lineWidth: 1))
        }
    }

    private var equation: some View {
        HStack(spacing: 14) {
            Text("\(left)")
            Text("×").foregroundColor(Theme.gold)
            Text("\(right)")
            Text("=").foregroundColor(Theme.dim)
            Text(answerText)
                .foregroundColor(answerColor)
                .frame(minWidth: 96)
                .padding(.vertical, 4)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .font(.system(size: 52, weight: .heavy, design: .rounded))
        .foregroundColor(Theme.text)
        .environment(\.layoutDirection, .leftToRight)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
    }

    private var answerText: String {
        if phase == .wrong { return "\(fact.product)" }
        return input.isEmpty ? "?" : input
    }

    private var answerColor: Color {
        switch phase {
        case .asking: return input.isEmpty ? Theme.dim : Theme.text
        case .right: return Theme.green
        case .wrong: return Theme.pink
        }
    }

    private var feedback: some View {
        VStack(spacing: 8) {
            switch phase {
            case .asking:
                Text(" ").font(.system(size: 16))
            case .right:
                Text("ممتاز!")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Theme.green)
            case .wrong:
                Text("الصحيح: " + ltr("\(left) × \(right) = \(fact.product)"))
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(Theme.pink)
                Text(hint)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.dim)
                    .multilineTextAlignment(.center)
                Button(action: { next() }) {
                    Text("فهمت، التالي")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: 0x1A1305))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(Theme.gold)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(minHeight: 120)
    }

    private var pad: some View {
        VStack(spacing: 10) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { k in
                        Button(action: { press(k) }) {
                            Text(k)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(k == "✓" ? Color(hex: 0x1A1305) : Theme.text)
                                .frame(maxWidth: .infinity, minHeight: 58)
                                .background(k == "✓" ? Theme.teal : Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
                        }
                        .disabled(phase != .asking)
                    }
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: المنطق

    private func press(_ k: String) {
        guard phase == .asking else { return }
        if k == "⌫" {
            if !input.isEmpty { input.removeLast() }
            return
        }
        if k == "✓" {
            submit()
            return
        }
        if input.count < 3 { input += k }
        if input.count == String(fact.product).count { submit() }
    }

    private func submit() {
        guard let value = Int(input) else { return }
        let ok = (value == fact.product)
        let elapsed = Date().timeIntervalSince(started)
        store.record(fact, correct: ok, fast: elapsed <= 6)
        asked += 1
        if ok {
            correctCount += 1
            streak += 1
            phase = .right
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            let snapshot = asked
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                if phase == .right && asked == snapshot { next() }
            }
        } else {
            streak = 0
            phase = .wrong
            hint = Tricks.hint(for: fact)
            retryKey = fact.key
            retryIn = 3
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func next() {
        input = ""
        phase = .asking
        var chosen: Fact? = nil
        if let rk = retryKey {
            retryIn -= 1
            if retryIn <= 0 {
                chosen = Fact.from(key: rk)
                retryKey = nil
            }
        }
        let f = chosen ?? store.pick(excluding: lastKey)
        fact = f
        lastKey = f.key
        if store.focus >= 2 {
            flipped = (f.a != store.focus)
        } else {
            flipped = Bool.random()
        }
        started = Date()
    }
}
