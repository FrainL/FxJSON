//
//  Implements.swift
//  FxJSON
//
//  Created by Frain on 7/5/16.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016~2017 Frain
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

import Foundation

//MARK: - JSON

extension JSON: JSONEncodable {
  
  public var json: JSON {
    return self
  }
  
  public init(_ object: @autoclosure () throws -> JSONEncodable) {
    do { try self = object().json } catch { self = .error(error) }
  }
  
  public init(operate: (Mapper) -> ()) {
    let mapper = Mapper(json: .object([:]))
    operate(mapper)
    self = mapper.json
  }
  
  public func transformed(operate: (Mapper) -> ()) -> JSON {
    let mapper = Mapper(json: self)
    operate(mapper)
    return(mapper.json)
  }
  
  public func decode<T: JSONDecodable>() throws -> T {
    return try T(decode: self)
  }
  
  public func map<T: JSONDecodable, U: JSONEncodable>(
    _ transform: (T) throws -> U) rethrows -> JSON {
    return try T(self).map(transform).map { $0.json } ?? self
  }
  
  public func flatMap<T: JSONDecodable>(
    _ transform: (T) throws -> JSON) rethrows -> JSON {
    return try T(self).map(transform) ?? self
  }
}

//MARK: - JSONCodable

extension String: JSONCodable, DefaultInitable {
  
  public init(decode json: JSON) throws {
    guard case let .string(str) = json else { throw String.mismatchError(json: json) }
    self = str
  }
  
  public var json: JSON {
    return .string(self)
  }
}

extension Bool: JSONCodable, DefaultInitable {
  
  public init(decode json: JSON) throws {
    guard case let .bool(boo) = json else { throw Bool.mismatchError(json: json) }
    self = boo
  }
  
  public var json: JSON {
    return .bool(self)
  }
}

extension Float: JSONCodable, DefaultInitable {
  
  public init(decode json: JSON) throws {
    guard case let .number(num) = json else { throw Float.mismatchError(json: json) }
    self = num.floatValue
  }
  
  public var json: JSON {
    return .number(NSNumber(value: self))
  }
}

extension Double: JSONCodable, DefaultInitable {
  
  public init(decode json: JSON) throws {
    guard case let .number(num) = json else { throw Double.mismatchError(json: json) }
    self = num.doubleValue
  }
  
  public var json: JSON {
    return .number(NSNumber(value: self))
  }
}

extension Int: JSONCodable, DefaultInitable {
  
  public init(decode json: JSON) throws {
    guard case let .number(num) = json else { throw Int.mismatchError(json: json) }
    self = num.intValue
  }
  
  public var json: JSON {
    return .number(NSNumber(value: self))
  }
}

extension Int8: JSONCodable, DefaultInitable {
  
  public init(decode json: JSON) throws {
    guard case let .number(num) = json else { throw Int8.mismatchError(json: json) }
    self = num.int8Value
  }
  
  public var json: JSON {
    return .number(NSNumber(value: self))
  }
}

extension Int16: JSONCodable, DefaultInitable {
  
  public init(decode json: JSON) throws {
    guard case let .number(num) = json else { throw Int16.mismatchError(json: json) }
    self = num.int16Value
  }
  
  public var json: JSON {
    return .number(NSNumber(value: self))
  }
}

extension Int32: JSONCodable, DefaultInitable {
  
  public init(decode json: JSON) throws {
    guard case let .number(num) = json else { throw Int32.mismatchError(json: json) }
    self = num.int32Value
  }
  
  public var json: JSON {
    return .number(NSNumber(value: self))
  }
}

extension Int64: JSONCodable, DefaultInitable {
  
  public init(decode json: JSON) throws {
    guard case let .number(num) = json else { throw Int64.mismatchError(json: json) }
    self = num.int64Value
  }
  
  public var json: JSON {
    return .number(NSNumber(value: self))
  }
}

extension Date: JSONCodable {
  
  public init?(_ json: JSON) {
    guard let dic = (try? Date(decode: json)) else { return nil }
    self = dic
  }
  
  public init(decode json: JSON) throws {
    switch json {
    case .string(let dateString):
      self.init()
      let formatter: DateFormatter = {
        if case .formatter(let formatter) = DateTransform.default {
          return formatter
        }
        return .default
      }()
      guard let date = formatter.date(from: dateString) else {
        throw JSON.Error.formatter(format: formatter.dateFormat, value: dateString)
      }
      self = date
    case .number(let v):
      let since: DateTransform.Since = {
        if case .timeIntervalSince(let since) = DateTransform.default {
          return since
        }
        return .default
      }()
      self.init(timeIntervalSince1970: v.doubleValue + since.timeInterval)
    default:
      throw DateTransform.default.objectType.mismatchError(json: json)
    }
  }

  public var json: JSON {
    switch DateTransform.default {
    case .formatter(let formatetr):
      return .string(formatetr.string(from: self))
    case .timeIntervalSince(let since):
      return .number(NSNumber(value: timeIntervalSince1970 - since.timeInterval))
    }
  }
}

extension URL: JSONCodable {
  
  public init(decode json: JSON) throws {
    guard let urlString = String(json)?
      .addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
      else { throw String.mismatchError(json: json) }
    if urlString.characters.isEmpty, let url = URL(string: "about://") { self = url; return }
    guard let url = URL(string: urlString) else {
      throw JSON.Error.other(description: "URL init error, urlString is \(urlString)")
    }
    self = url
  }
  
  public var json: JSON {
    return .string(self.absoluteString)
  }
}

extension NSNull: JSONEncodable {
  
  public var json: JSON {
    return JSON()
  }
}

extension Optional: JSONCodable {
  
  public init?(_ json: JSON) {
    guard let dic = (try? Optional<Wrapped>(decode: json)) else { return nil }
    self = dic
  }
  
  public init(decode json: JSON) throws {
    guard let T = Wrapped.self as? JSONDecodable.Type else {
      throw JSON.Error.notConfirmTo(protocol: JSONDecodable.self, actual: Wrapped.self)
    }
    self = T.init(json) as! Wrapped?
  }
  
  public var json: JSON {
    guard Wrapped.self is JSONEncodable.Type else {
      return .error(JSON.Error.notConfirmTo(protocol: JSONEncodable.self, actual: Wrapped.self))
    }
    if case let .some(v as JSONEncodable) = self { return v.json }
    return nil
  }
}

extension ImplicitlyUnwrappedOptional: JSONCodable, DefaultInitable {
  
  public init?(_ json: JSON) {
    guard let dic = (try? ImplicitlyUnwrappedOptional<Wrapped>(decode: json)) else { return nil }
    self = dic
  }
  
  public init(decode json: JSON) throws {
    guard let T = Wrapped.self as? JSONDecodable.Type else {
      throw JSON.Error.notConfirmTo(protocol: JSONDecodable.self, actual: Wrapped.self)
    }
    self = T.init(json) as! Wrapped?
  }
  
  public var json: JSON {
    guard Wrapped.self is JSONEncodable.Type else {
      return .error(JSON.Error.notConfirmTo(protocol: JSONEncodable.self, actual: Wrapped.self))
    }
    switch self {
    case let .some(value as JSONEncodable): return value.json
    default: return nil
    }
  }
}

extension Set: JSONCodable, DefaultInitable {
  
  public init?(_ json: JSON) {
    guard let dic = (try? Set<Element>(decode: json)) else { return nil }
    self = dic
  }
  
  public init(decode json: JSON) throws {
    self.init()
    guard let T = Element.self as? JSONDecodable.Type else {
      throw JSON.Error.notConfirmTo(protocol: JSONDecodable.self, actual: Element.self)
    }
    for value in json.asArray {
      if let value = T.init(value) as! Element? {
        self.insert(value)
      }
    }
  }
  
  public var json: JSON {
    return JSON(try JSON.array(self.map { element in
      if let element = element as? JSONEncodable {
        let json = element.json
        if let error = json.error { throw error }
        return json.object
      }
      return element as Any
    }))
  }
}

extension Array: JSONCodable, DefaultInitable {
  
  public init?(_ json: JSON) {
    guard let dic = (try? [Element](decode: json)) else { return nil }
    self = dic
  }
  
  public init(decode json: JSON) throws {
    guard let arr = json.array else { throw [Any].mismatchError(json: json) }
    if let T = Element.self as? JSONDecodable.Type {
      self = arr.flatMap { T.init(JSON(any: $0)) as! Element? }
    } else {
      throw JSON.Error.notConfirmTo(protocol: JSONDecodable.self, actual: Element.self)
    }
  }
  
  public var json: JSON {
    return JSON(try JSON.array(self.map { element in
      if let element = element as? JSONEncodable {
        let json = element.json
        if let error = json.error { throw error }
        return json.object
      }
      return element as Any
    }))
  }
}

extension Array where Element == Any {
  
  public init?(_ json: JSON) {
    guard let dic = (try? [Element](decode: json)) else { return nil }
    self = dic
  }
  
  public init(decode json: JSON) throws {
    guard let arr = json.array else { throw [Any].mismatchError(json: json) }
    self = arr
  }
}

extension Dictionary: JSONCodable, DefaultInitable {
  
  public init?(_ json: JSON) {
    guard let dic = (try? [Key: Value](decode: json)) else { return nil }
    self = dic
  }
  
  public init(decode json: JSON) throws {
    guard let dict = json.dict else { throw [String: Any].mismatchError(json: json) }
    guard Key.self is String.Type else {
      throw JSON.Error.notConfirmTo(protocol: String.self, actual: Key.self)
    }
    if let T = Value.self as? JSONDecodable.Type {
      self = dict.flatMap { ($0.0 as! Key, T.init(JSON(any: $0.1)) as! Value?) }
    } else {
      throw JSON.Error.notConfirmTo(protocol: JSONDecodable.self, actual: Value.self)
    }
  }
  
  public var json: JSON {
    guard Key.self is String.Type else {
      return .error(JSON.Error.notConfirmTo(protocol: String.self, actual: Key.self))
    }
    return JSON(try JSON.object(self.map { (key, value) in
      if let value = value as? JSONEncodable {
        let json = value.json
        if let error = json.error { throw error }
        return (key as! String, json.object)
      }
      return (key as! String, value as Any)
    }))
  }
}

extension Dictionary where Key == String, Value == Any {
  
  public init?(_ json: JSON) {
    guard let dict = json.dict else { return nil }
    self = dict
  }
  
  public init(decode json: JSON) throws {
    guard let dict = json.dict else { throw [String: Any].mismatchError(json: json) }
    self = dict
  }
}

//MARK: - Transform

public enum CustomTransform<JSONObject: JSONCodable, Object: JSONCodable>: Transform {
  
  case fromJSON((JSONObject) throws -> Object)
  case toJSON((Object) throws -> JSONObject)
  case both(fromJSON: (JSONObject) throws -> Object, toJSON: (Object) throws -> JSONObject)
  
  public var jsonObjectType: JSONCodable.Type {
    return JSONObject.self
  }
  
  public var objectType: JSONCodable.Type {
    return Object.self
  }
  
  public var fromJSONFunc: Transform.Func? {
    switch self {
    case let .fromJSON(fromJSONFunc), let .both(fromJSON: fromJSONFunc, toJSON: _):
      return { try fromJSONFunc($0 as! JSONObject) }
    default:
      return nil
    }
  }
  
  public var toJSONFunc: Transform.Func? {
    switch self {
    case let .toJSON(toJSONFunc), let .both(fromJSON: _, toJSON: toJSONFunc):
      return { try toJSONFunc($0 as! Object) }
    default:
      return nil
    }
  }
}

public extension DateFormatter {
  
  @nonobjc static var `default`: DateFormatter = {
    $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return $0
  }(DateFormatter())
}

public enum DateTransform: Transform {
  
  public enum Since {
    
    case year1970
    case now
    case referenceDate
    case date(Date)
    
    var timeInterval: TimeInterval {
      switch self {
      case .year1970: return 0
      case .now: return Date().timeIntervalSince1970
      case .referenceDate: return NSTimeIntervalSince1970
      case .date(let date): return date.timeIntervalSince1970
      }
    }
    
    static var `default`: Since = .year1970
  }
  
  case formatter(DateFormatter)
  case timeIntervalSince(Since)
  
  public static var `default`: DateTransform = .formatter(.default)
  
  public var jsonObjectType: JSONCodable.Type {
    switch self {
    case .formatter: return String.self
    case .timeIntervalSince: return TimeInterval.self
    }
  }
  
  public var objectType: JSONCodable.Type {
    switch DateTransform.default {
    case .formatter: return String.self
    case .timeIntervalSince: return TimeInterval.self
    }
  }
  
  func setTransform(from: DateTransform, to: DateTransform) -> Transform.Func {
    let deserialize = { (JSONCodable: JSONCodable) throws -> Date in
      switch from {
      case .formatter(let formatter):
        let dateString = JSONCodable as! String
        if let date = formatter.date(from: dateString) { return date }
        throw JSON.Error.formatter(format: formatter.dateFormat, value: dateString)
      case .timeIntervalSince(let since):
        let dateNum = JSONCodable as! TimeInterval
        return Date(timeIntervalSince1970: dateNum + since.timeInterval)
      }
    }
    let serialize = { (date: Date) -> JSONCodable in
      switch to {
      case .formatter(let formatter): return formatter.string(from: date)
      case .timeIntervalSince(let since): return date.timeIntervalSince1970 - since.timeInterval
      }
    }
    return { serialize(try deserialize($0)) }
  }
  
  public var fromJSONFunc: Transform.Func? {
    return setTransform(from: self, to: DateTransform.default)
  }
  
  public var toJSONFunc: Transform.Func? {
    return setTransform(from: DateTransform.default, to: self)
  }
}
