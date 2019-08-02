
import Foundation

public typealias Record = [String:Value]

public enum DataType {
    case String
    case Blob
    case Null
    case Int
    case Double
    case UUID
}

public enum SWSQLOp {
    case Insert
    case Update
    case Delete
}
