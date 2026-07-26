import Foundation
import SwiftData

@Model
final class Exercise {
    var id: String
    var name: String
    var icon: String
    var category: String
    var unit: String
    var sets: Int
    var defaultValue: Int
    var order: Int
    var routine: Routine?
    
    init(id: String, name: String, icon: String, category: String, unit: String, sets: Int, defaultValue: Int, order: Int) {
        self.id = id
        self.name = name
        self.icon = icon
        self.category = category
        self.unit = unit
        self.sets = sets
        self.defaultValue = defaultValue
        self.order = order
    }
}
