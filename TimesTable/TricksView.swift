import SwiftUI

struct TricksView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("الحيل السريعة")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(Theme.text)
                        Text("لا تحفظ 45 حقيقة، احفظ 15 وافهم الباقي")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.dim)
                    }

                    ForEach(Tricks.cards) { c in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(c.title)
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(c.color)
                            Text(c.rule)
                                .font(.system(size: 15))
                                .foregroundColor(Theme.text)
                            Text(ltr(c.example))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.gold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card()
                    }

                    Text("الحقائق الأساسية الـ15 هي كل اثنين من 3 و4 و6 و7 و8، بما فيها المربعات.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.dim)
                }
                .padding(18)
            }
        }
    }
}
