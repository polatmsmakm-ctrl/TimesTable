import SwiftUI
import UIKit

struct TestView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let table: Int

    @State private var questions: [Fact] = []
    @State private var index = 0
    @State private var input = ""
    @State private var results: [Bool] = []
    @State private var wrongFacts: [Fact] = []
    @State private var flash: Bool? = nil
    @State private var finished = false
    @State private var started = Date()

    private let rows: [[String]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["⌫", "0", "✓"]]

    private var score: Int { results.filter { $0 }.count }
    private var passed: Bool { score >= Store.passMark }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if finished {
                resultView
            } else if index < questions.count {
                quizView
            }
        }
        .onAppear { restart() }
    }

    // MARK: الاختبار

    private var current: Fact { questions[index] }
    private var other: Int { current.a == table ? current.b : current.a }

    private var quizView: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.dim)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("اختبار جدول \(table)")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(Theme.text)
                    Text("سؤال \(index + 1) من \(questions.count)")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.dim)
                }
            }
            ProgressView(value: Double(index), total: Double(questions.count))
                .tint(Theme.gold)

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                Text("\(table)")
                Text("×").foregroundColor(Theme.gold)
                Text("\(other)")
                Text("=").foregroundColor(Theme.dim)
                Text(input.isEmpty ? "?" : input)
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

            Text("بدون تلميحات. اجتز \(Store.passMark) من \(questions.count) لتفتح الجدول التالي.")
                .font(.system(size: 14))
                .foregroundColor(Theme.dim)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

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
                            .disabled(flash != nil)
                        }
                    }
                }
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .padding(18)
    }

    private var answerColor: Color {
        if let f = flash { return f ? Theme.green : Theme.pink }
        return input.isEmpty ? Theme.dim : Theme.text
    }

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: passed ? "star.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(passed ? Theme.gold : Theme.pink)
                    .padding(.top, 30)
                Text("\(score) من \(questions.count)")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.text)
                Text(passed ? "نجحت! جدول \(table) صار متقنًا" : "تحتاج \(Store.passMark) من \(questions.count) للنجاح")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(passed ? Theme.green : Theme.pink)
                if passed && table < 9 {
                    Text("انفتح جدول \(table + 1)")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.teal)
                }

                if !wrongFacts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("راجع هذه الحقائق")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(Theme.gold)
                        ForEach(wrongFacts, id: \.key) { f in
                            Text(ltr("\(table) × \(f.a == table ? f.b : f.a) = \(f.product)"))
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(Theme.text)
                            Text(Tricks.hint(for: f))
                                .font(.system(size: 13))
                                .foregroundColor(Theme.dim)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                }

                Button(action: { restart() }) {
                    Text("أعد الاختبار")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: 0x1A1305))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button(action: { dismiss() }) {
                    Text("رجوع")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(18)
        }
    }

    // MARK: المنطق

    private func restart() {
        questions = (1...10).map { Fact(table, $0) }.shuffled()
        index = 0
        input = ""
        results = []
        wrongFacts = []
        flash = nil
        finished = false
        started = Date()
    }

    private func press(_ k: String) {
        guard flash == nil, !finished, index < questions.count else { return }
        if k == "⌫" {
            if !input.isEmpty { input.removeLast() }
            return
        }
        if k == "✓" {
            submit()
            return
        }
        if input.count < 3 { input += k }
        if input.count == String(current.product).count { submit() }
    }

    private func submit() {
        guard let value = Int(input), index < questions.count else { return }
        let f = current
        let ok = (value == f.product)
        let elapsed = Date().timeIntervalSince(started)
        store.record(f, correct: ok, fast: elapsed <= 6)
        results.append(ok)
        if !ok { wrongFacts.append(f) }
        flash = ok
        UINotificationFeedbackGenerator().notificationOccurred(ok ? .success : .error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            flash = nil
            input = ""
            if index + 1 >= questions.count {
                store.submitScore(table, score)
                finished = true
            } else {
                index += 1
                started = Date()
            }
        }
    }
}
