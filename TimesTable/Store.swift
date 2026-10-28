import Foundation
import SwiftUI

struct Fact: Hashable {
    let a: Int
    let b: Int

    init(_ x: Int, _ y: Int) {
        a = min(x, y)
        b = max(x, y)
    }

    var key: String { "\(a)-\(b)" }
    var product: Int { a * b }

    var isCore: Bool {
        let core: Set<Int> = [3, 4, 6, 7, 8]
        return core.contains(a) && core.contains(b)
    }

    static func from(key: String) -> Fact {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        if parts.count == 2 { return Fact(parts[0], parts[1]) }
        return Fact(7, 8)
    }
}

struct Entry: Codable {
    var box: Int = 0      // 0...4
    var seen: Int = 0
    var right: Int = 0
    var wrong: Int = 0
}

enum PoolMode: String, CaseIterable {
    case core
    case all

    var title: String {
        switch self {
        case .core: return "الأساسية (15)"
        case .all: return "الكل (45)"
        }
    }
}

final class Store: ObservableObject {
    @Published var entries: [String: Entry] = [:] {
        didSet { save() }
    }
    @Published var mode: PoolMode = .core {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: "mode") }
    }

    /// 0 = مخلوط حسب المجموعة، وإلا رقم الجدول المختار (2...10)
    @Published var focus: Int = 0 {
        didSet { UserDefaults.standard.set(focus, forKey: "focus") }
    }

    private let ud = UserDefaults.standard

    init() {
        if let d = ud.data(forKey: "entries"),
           let e = try? JSONDecoder().decode([String: Entry].self, from: d) {
            entries = e
        }
        if let m = ud.string(forKey: "mode"), let pm = PoolMode(rawValue: m) {
            mode = pm
        }
        let fo = ud.integer(forKey: "focus")
        if fo >= 2 && fo <= 10 { focus = fo }
    }

    private func save() {
        if let d = try? JSONEncoder().encode(entries) {
            ud.set(d, forKey: "entries")
        }
    }

    // MARK: الحقائق

    static let allFacts: [Fact] = {
        var out: [Fact] = []
        for a in 2...10 {
            for b in a...10 {
                out.append(Fact(a, b))
            }
        }
        return out
    }()

    static let coreFacts: [Fact] = allFacts.filter { $0.isCore }

    var pool: [Fact] {
        if focus >= 2 && focus <= 10 {
            return (1...10).map { Fact(focus, $0) }
        }
        return mode == .core ? Store.coreFacts : Store.allFacts
    }

    func entry(_ f: Fact) -> Entry {
        return entries[f.key] ?? Entry()
    }

    // MARK: الاختيار والتسجيل

    func pick(excluding: String?) -> Fact {
        let candidates = pool.filter { $0.key != excluding }
        let list = candidates.isEmpty ? pool : candidates
        let table: [Double] = [8.0, 4.0, 2.0, 1.0, 0.5]
        let weights: [Double] = list.map { f in
            let b = min(max(entry(f).box, 0), 4)
            return table[b]
        }
        let total = weights.reduce(0, +)
        var r = Double.random(in: 0..<total)
        for (i, w) in weights.enumerated() {
            r -= w
            if r < 0 { return list[i] }
        }
        return list[0]
    }

    func record(_ f: Fact, correct: Bool, fast: Bool) {
        var e = entry(f)
        e.seen += 1
        if correct {
            e.right += 1
            if fast { e.box = min(4, e.box + 1) }
        } else {
            e.wrong += 1
            e.box = 0
        }
        entries[f.key] = e
    }

    // MARK: إحصاءات

    var mastery: Double {
        let list = pool
        if list.isEmpty { return 0 }
        let sum = list.reduce(0) { $0 + min(max(entry($1).box, 0), 4) }
        return Double(sum) / Double(4 * list.count)
    }

    var totalAnswers: Int { entries.values.reduce(0) { $0 + $1.seen } }
    var totalRight: Int { entries.values.reduce(0) { $0 + $1.right } }

    func reset() {
        entries = [:]
    }
}

// MARK: الحيل

enum Tricks {
    static func hint(for f: Fact) -> String {
        if f.a == 1 {
            return "الضرب في 1 يبقي العدد: " + ltr("1 × \(f.b) = \(f.b)")
        }
        let order = [10, 2, 5, 9, 4, 3, 8, 6]
        for t in order where f.a == t || f.b == t {
            let n = (f.a == t) ? f.b : f.a
            switch t {
            case 10:
                return "أضف صفرًا: " + ltr("\(n) → \(n * 10)")
            case 2:
                return "ضاعف: " + ltr("\(n) → \(2 * n)")
            case 5:
                return "نصف الضرب في 10: " + ltr("\(n) × 10 = \(10 * n) → \(5 * n)")
            case 9:
                return "العشرات = \(n - 1) والآحاد = \(10 - n)، فالناتج " + ltr("\(9 * n)")
            case 4:
                return "ضاعف مرتين: " + ltr("\(n) → \(2 * n) → \(4 * n)")
            case 3:
                return "ضاعف ثم أضف العدد: " + ltr("\(2 * n) + \(n) = \(3 * n)")
            case 8:
                return "ضاعف ثلاث مرات: " + ltr("\(n) → \(2 * n) → \(4 * n) → \(8 * n)")
            default:
                return "اضرب في 5 ثم أضف العدد: " + ltr("\(5 * n) + \(n) = \(6 * n)")
            }
        }
        return "المربع " + ltr("7 × 7 = 49") + ". وتذكّر: " + ltr("5 · 6 · 7 · 8") + " تعني " + ltr("56 = 7 × 8")
    }

    struct Card: Identifiable {
        let id = UUID()
        let title: String
        let rule: String
        let example: String
        let color: Color
    }

    static let cards: [Card] = [
        Card(title: "الحقائق المجانية",
             rule: "الضرب في 1 يبقي العدد. في 10 أضف صفرًا. في 2 ضاعف. في 5 خذ نصف الضرب في 10.",
             example: "5 × 8 = 80 ÷ 2 = 40", color: Theme.teal),
        Card(title: "الضرب في 9",
             rule: "العشرات = العدد − 1، والآحاد تكمّل إلى 9، فمجموع رقمي الناتج 9 دائمًا.",
             example: "9 × 7 → 6 و 3 = 63", color: Theme.gold),
        Card(title: "الضرب في 3",
             rule: "ضاعف العدد ثم أضف العدد مرة أخرى.",
             example: "3 × 7 = 14 + 7 = 21", color: Theme.pink),
        Card(title: "الضرب في 4",
             rule: "ضاعف العدد مرتين.",
             example: "4 × 7 : 7 → 14 → 28", color: Theme.pink),
        Card(title: "الضرب في 6",
             rule: "اضرب في 5 ثم أضف العدد مرة واحدة.",
             example: "6 × 7 = 35 + 7 = 42", color: Theme.pink),
        Card(title: "الضرب في 8",
             rule: "ضاعف العدد ثلاث مرات.",
             example: "8 × 7 : 7 → 14 → 28 → 56", color: Theme.pink),
        Card(title: "المربعات نقاط ارتكاز",
             rule: "احفظ 36 و49 و64 و81، ومنها تصل إلى الجار بإضافة العدد.",
             example: "7 × 8 = 49 + 7 = 56", color: Theme.gold),
        Card(title: "حيلة 5-6-7-8",
             rule: "الأرقام 5 و6 و7 و8 متتالية، والناتج 56 هو 7 × 8. اربط الجملة بالحقيقة.",
             example: "5 · 6 · 7 · 8 ← 56 = 7 × 8", color: Theme.gold)
    ]
}
