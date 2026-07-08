import Foundation
@testable import OrchardKit

extension UserDefaults.Key where Value == String {
    static var userDefaultTestValue: UserDefaults.Key<String> {
        .init(name: "userDefaultTestValue")
    }
}

extension UserDefaults.Key where Value == Bool {
    static var boolTestValue: UserDefaults.Key<Bool> {
        .init(name: "boolTestValue")
    }
}

extension UserDefaults.Key where Value == Int {
    static var intTestValue: UserDefaults.Key<Int> {
        .init(name: "intTestValue")
    }
}

extension UserDefaults.Key where Value == Float {
    static var floatTestValue: UserDefaults.Key<Float> {
        .init(name: "floatTestValue")
    }
}

extension UserDefaults.Key where Value == Double {
    static var doubleTestValue: UserDefaults.Key<Double> {
        .init(name: "doubleTestValue")
    }
}

extension UserDefaults.Key where Value == Date {
    static var dateTestValue: UserDefaults.Key<Date> {
        .init(name: "dateTestValue")
    }
}

extension UserDefaults.Key where Value == Data {
    static var dataTestValue: UserDefaults.Key<Data> {
        .init(name: "dataTestValue")
    }
}
