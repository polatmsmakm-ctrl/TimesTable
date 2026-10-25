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

    private var left: Int { flipped ? fact.b : fact.a }
    private var right: Int { flipped ? fact.a : fact.b }

    private let rows: [[String]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["⌫", "0", "✓"]]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 14) {
                header
                Picker("المجموعة", selection: $store.mode) {
                    ForEach(PoolMode.allCases, id: \.self) { m in
                        Text(m.title).tag(m)
                    }
                }
                .pickerStyle(.segmented)

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
    }

    // MARK: الأجزاء

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("تدريب الاسترجاع")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(Theme.text)
                Text("اكتب الناتج من ذاكرتك دون حساب")
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
        flipped = Bool.random()
        started = Date()
    }
}
