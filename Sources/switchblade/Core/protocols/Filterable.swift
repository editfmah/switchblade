//
//  Filterable.swift
//  
//
//  Created by Adrian Herridge on 27/12/2022.
//

import Foundation

public enum Filters {
    case uuid(name: String, value: UUID?)
    case string(name: String, value: String?)
    case int(name: String, value: Int?)
    case bool(name: String, value: Bool?)
    case datetime(name: String, value: Date?)
    case time(name: String, value: Date?)
    case year(name: String, value: Date?)
    case month(name: String, value: Date?)
    case date(name: String, value: Date?)
    case double(name: String, value: Double?)
    case float(name: String, value: Float?)
    case array(name: String, value: [String]?)
    case custom(name: String, value: Any?)
}

public protocol Filterable {
    var filters: [Filters] { get }
}

public extension [Filters] {
    var dictionary: [String:String] {
        var dict: [String:String] = [:]
        for filter in self {
            switch filter {
            case .uuid(let name, let value):
                if let value = value {
                    dict[name] = value.uuidString
                }
            case .string(let name, let value):
                if let value = value {
                    dict[name] = value
                }
            case .int(let name, let value):
                if let value = value {
                    dict[name] = "\(value)"
                }
            case .bool(let name, let value):
                if let value = value {
                    dict[name] = "\(value)"
                }
            case .date(let name, let value):
                if let value = value {
                    dict[name] = "\(value.isoDate)"
                }
            case .datetime(let name, let value):
                if let value = value {
                    dict[name] = "\(value.isoFullDate)"
                }
            case .time(let name, let value):
                if let value = value {
                    dict[name] = "\(value.isoTime)"
                }
            case .year(let name, let value):
                if let value = value {
                    dict[name] = "\(value.isoYear)"
                }
            case .month(let name, let value):
                if let value = value {
                    dict[name] = "\(value.isoMonth)"
                }
            case .double(let name, let value):
                if let value = value {
                    dict[name] = "\(value)"
                }
            case .float(let name, let value):
                if let value = value {
                    dict[name] = "\(value)"
                }
            case .array(let name, let value):
                if let value = value {
                    dict[name] = value.joined(separator: ",")
                }
            case .custom(let name, let value):
                if let value = value {
                    dict[name] = "\(value)"
                }
            }
        }
        return dict
    }
}

public extension Filters {
    var kvpString: String {
        switch self {
        case .uuid(let name, let value):
            if let value = value {
                return "\(name)=\(value.uuidString)"
            }
        case .string(let name, let value):
            if let value = value {
                return "\(name)=\(value)"
            }
        case .int(let name, let value):
            if let value = value {
                return "\(name)=\(value)"
            }
        case .bool(let name, let value):
            if let value = value {
                return "\(name)=\(value)"
            }
        case .date(let name, let value):
            if let value = value {
                return "\(name)=\(value.isoDate)"
            }
        case .datetime(let name, let value):
            if let value = value {
                return "\(name)=\(value.isoFullDate)"
            }
        case .time(let name, let value):
            if let value = value {
                return "\(name)=\(value.isoTime)"
            }
        case .year(let name, let value):
            if let value = value {
                return "\(name)=\(value.isoYear)"
            }
        case .month(let name, let value):
            if let value = value {
                return "\(name)=\(value.isoMonth)"
            }
        case .double(let name, let value):
            if let value = value {
                return "\(name)=\(value)"
            }
        case .float(let name, let value):
            if let value = value {
                return "\(name)=\(value)"
            }
        case .array(let name, let value):
            if let value = value {
                return "\(name)=\(value.joined(separator: ","))"
            }
        case .custom(let name, let value):
            if let value = value {
                return "\(name)=\(value)"
            }
        }
        return ""
    }
}

fileprivate extension Date {
    
    var milliseconds : UInt64 {
        return UInt64((self.timeIntervalSince1970 * 1000))
    }
    var seconds: UInt64 {
        return UInt64(self.timeIntervalSince1970)
    }
    func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        dateformat.timeZone = TimeZone(identifier: "UTC")
        return dateformat.string(from: self)
    }
    var isoFullDate: String {
        return getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ssZ")
    }
    var isoYear: String {
        return getFormattedDate(format: "yyyy")
    }
    var year: String {
        return getFormattedDate(format: "yyyy")
    }
    var isoMonth: String {
        return getFormattedDate(format: "yyyy-MM")
    }
    var isoDate: String {
        return getFormattedDate(format: "yyyy-MM-dd")
    }
    var isoDateWithTime: String {
        return getFormattedDate(format: "yyyy-MM-dd HH:mm:ss")
    }
    var isoTime: String {
        return getFormattedDate(format: "HH:mm:ss")
    }
    var isoDateWithHour: String {
        return getFormattedDate(format: "yyyy-MM-dd HH")
    }
    var isoDateWithHoursMinutes: String {
        return getFormattedDate(format: "yyyy-MM-dd HH:mm")
    }
    
    
    // localised for the user
    func userDate() -> String {
        return self.isoDate
    }
    
    func userDateTime() -> String {
        return ""
    }
    
    static func from(string: String) -> Date? {
        
        let dateString = string
        
        // right try and cobble something together to sort out this damned mixed date issue
        let components = dateString.components(separatedBy: CharacterSet(charactersIn: "T "))
        if components.count > 0 {
            let datePart = components[0]
            
            let dateComponents = datePart.components(separatedBy: CharacterSet(charactersIn: "-/\\|:."))
            
            if dateComponents.count > 2 {
                
                if let year = Int(dateComponents[0]), let month = Int(dateComponents[1]), let day = Int(dateComponents[2]) {
                    // we have our date parts
                    
                    var hours = 0
                    var minutes = 0
                    var seconds = 0
                    
                    if components.count > 1 {
                        let timePart = components[1]
                        
                        var timeComponents = timePart.components(separatedBy: CharacterSet(charactersIn: "-/\\|:."))
                        
                        if let hrs = timeComponents.first, let h = Int(hrs) {
                            timeComponents.removeFirst()
                            hours = h
                        }
                        
                        if let mins = timeComponents.first, let m = Int(mins) {
                            timeComponents.removeFirst()
                            minutes = m
                        }
                        
                        if let secs = timeComponents.first, let s = Int(secs) {
                            timeComponents.removeFirst()
                            seconds = s
                        }
                    }
                    
                    var calendar = Calendar(identifier: .gregorian)
                    calendar.timeZone = TimeZone(abbreviation: "UTC")!
                    let components = DateComponents(year: year, month: month, day: day, hour: hours, minute: minutes, second: seconds)
                    
                    if let newDate = calendar.date(from: components) {
                        return newDate
                    }
                    
                }
            }
            
        }
        
        return nil
    }
    
    
}
