import Foundation

/// Język aplikacji: "system", "pl" albo "en". Zapisany w UserDefaults pod kluczem `appLanguage`.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, pl, en
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return L("settings.language.system")
        case .pl: return "Polski"
        case .en: return "English"
        }
    }
}

enum Localizer {
    static var preference: String { UserDefaults.standard.string(forKey: "appLanguage") ?? "system" }

    /// Kod faktycznie używanego języka ("pl" lub "en").
    static var code: String {
        let pref = preference
        if pref == "pl" || pref == "en" { return pref }
        let sys = Bundle.main.preferredLocalizations.first ?? "en"
        return sys.hasPrefix("pl") ? "pl" : "en"
    }

    static var isPolish: Bool { code == "pl" }
    static var locale: Locale { Locale(identifier: code) }

    static var bundle: Bundle {
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"), let b = Bundle(path: path) { return b }
        return .main
    }
}

/// Tłumaczenie klucza z katalogu Localizable.xcstrings, zgodnie z wybranym językiem aplikacji.
func L(_ key: String) -> String {
    Localizer.bundle.localizedString(forKey: key, value: key, table: nil)
}

/// Formatowanie liczb zgodnie z językiem aplikacji.
enum Fmt {
    static func number(_ v: Double, maxFraction: Int = 2, grouping: Bool = true) -> String {
        var style = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...maxFraction)).locale(Localizer.locale)
        if !grouping { style = style.grouping(.never) }
        return v.formatted(style)
    }

    static func weight(_ kg: Double, unit: UnitSystem, grouping: Bool = false) -> String {
        number(unit.fromKg(kg), maxFraction: 1, grouping: grouping)
    }

    /// Objętość: ciężar w aktualnej jednostce, np. "12 450".
    static func volume(_ kg: Double, unit: UnitSystem) -> String {
        number(unit.fromKg(kg).rounded(), maxFraction: 0, grouping: true)
    }

    /// 3725 s -> "1:02:05", 540 s -> "9:00"
    static func clock(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
    }

    /// 3725 s -> "1 h 2 min"
    static func shortDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds / 60))
        let h = total / 60, m = total % 60
        return h > 0 ? "\(h) \(L("unit.h")) \(m) \(L("unit.min"))" : "\(m) \(L("unit.min"))"
    }
}
