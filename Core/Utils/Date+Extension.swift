import Foundation

extension Date {
    static var todayString: String {
        Date.now.formatted(date: .long, time: .omitted)
    }
}
