import Foundation

enum ListDisplayFormatter {
    static func dateTime(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    static func duration(seconds: Double) -> String {
        "\(Int(seconds.rounded()))s"
    }
}
