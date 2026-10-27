import Foundation

/// Checks what someone types into the profile form. Pure functions, so the edit screen can call them on every keystroke.
nonisolated enum ProfileValidator {

    enum FieldError: Equatable, Sendable {
        case nameEmpty, nameTooLong, phoneInvalid, emailInvalid
    }

    static let maxNameLength = 40

    static func validateName(_ raw: String) -> FieldError? {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return .nameEmpty }
        if name.count > maxNameLength { return .nameTooLong }
        return nil
    }

    /// Strips spaces and dashes, then the country code, so "+65 9123-4567" and "6591234567" both become "91234567".
    static func normalisedPhone(_ raw: String) -> String {
        var phone = raw.filter { !$0.isWhitespace && $0 != "-" }
        if phone.hasPrefix("+65") {
            phone.removeFirst(3)
        } else if phone.hasPrefix("65"), phone.count == 10 {
            phone.removeFirst(2)
        }
        return phone
    }

    /// Optional, but when given it must be a Singapore number: 8 digits starting with 3, 6, 8 or 9.
    static func validatePhone(_ raw: String) -> FieldError? {
        let phone = normalisedPhone(raw)
        if phone.isEmpty { return nil }
        return phone.wholeMatch(of: /[3689]\d{7}/) == nil ? .phoneInvalid : nil
    }

    /// Optional. A light check (something@something.tld), not full RFC 5322.
    static func validateEmail(_ raw: String) -> FieldError? {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if email.isEmpty { return nil }
        return email.wholeMatch(of: /[^\s@]+@[^\s@]+\.[^\s@]{2,}/) == nil ? .emailInvalid : nil
    }

    /// "91234567" becomes "+65 9123 4567". Anything that isn't 8 digits is returned as it is.
    static func formattedPhone(_ digits: String) -> String {
        guard digits.count == 8 else { return digits }
        return "+65 \(digits.prefix(4)) \(digits.suffix(4))"
    }

    static func message(for error: FieldError) -> String {
        switch error {
        case .nameEmpty: "Enter your name"
        case .nameTooLong: "Keep it to \(maxNameLength) characters"
        case .phoneInvalid: "Enter an 8-digit Singapore number"
        case .emailInvalid: "Enter a valid email"
        }
    }
}
