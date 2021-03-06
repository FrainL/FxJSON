//
//  JSON.swift
//  FxJSON
//
//  Created by Frain on 7/2/16.
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

public enum JSON {
    
  case object([String: Any])
  case array([Any])
  case string(String)
  case number(NSNumber)
  case bool(Swift.Bool)
  case error(Swift.Error)
  case null
}

public extension JSON {

  var object: Any {
    switch self {
    case let .object(any): return any
    case let .array(any): return any
    case let .string(any): return any
    case let .number(any): return any
    case let .bool(any): return any
    case let .error(any): return any
    default: return NSNull()
    }
  }
  
  init() {
    self = .null
  }
  
  init(any: Any) {
    switch any {
    case let dic as [String: Any]:
      self = .object(dic)
    case let arr as [Any]:
      self = .array(arr)
    case let str as String:
      self = .string(str)
    case let num as NSNumber:
      if CFGetTypeID(num) == CFBooleanGetTypeID() {
        self = .bool(num.boolValue)
      } else {
        self = .number(num)
      }
    case let err as Swift.Error:
      self = .error(err)
    default:
      self = .null
    }
  }
  
  var type: String {
    switch self {
    case .object: return "object"
    case .array: return "array"
    case .string: return "string"
    case .number: return "number"
    case .bool: return "boolen"
    case .error: return "error"
    case .null: return "null"
    }
  }
  
  var isNull: Bool {
    return self == .null
  }
  
  var isError: Bool {
    if case .error = self { return true }
    return false
  }
  
  var error: Swift.Error? {
    if case let .error(error) = self { return error }
    return nil
  }
}

//MARK: - Error handling

public extension JSON {
    
  enum Error: Swift.Error, CustomStringConvertible {
    
    case initalize(error: Swift.Error)
    case typeMismatch(expected: Any.Type, actual: String)
    case notConfirmTo(protocol: Any.Type, actual: Any.Type)
    case encodeToJSON(wrongObject: Any)
    case notExist(dict: [String: Any], key: String)
    case wrongType(subscript: JSON, key: Index)
    case outOfBounds(arr: [Any], index: Int)
    case formatter(format: String, value: String)
    case customTransfrom(source: Any)
    case other(description: String)
    
    public var description: String {
      switch self {
      case .initalize(let error):
        return "Initalize error, \(error))"
      case let .typeMismatch(expected, actual):
        return "TypeMismatch, expected \(expected), got \(actual))"
      case let .notConfirmTo(`protocol`, actual):
        return "\(actual) does not confirm to \(`protocol`)"
      case .encodeToJSON(wrongObject: let any):
        return "Error when encoding to JSON: \(any)"
      case .notExist(dict: let dict, key: let key):
        return "Key: \"\(key)\" not exist, dict is: \(dict)"
      case .wrongType(subscript: let json, key: let key):
        return "Cannot subscrpit key: \(key) to \(json.debugDescription)"
      case .outOfBounds(arr: let arr, index: let index):
        return "Subscript \(index) to \(arr) is out of bounds"
      case .formatter(format: let format, value: let value):
        return "Cannot phrase \(value) with \(format)"
      case .customTransfrom(source: let source):
        return "CustomTransfrom error, source: \(source)"
      case .other(description: let description):
        return description
      }
    }
  }
}

// MARK: - ExpressibleByLiteral

extension JSON: ExpressibleByDictionaryLiteral {
  
  public init(dictionaryLiteral elements: (String, JSONEncodable)...) {
    var dict = [String: Any](minimumCapacity: elements.count)
    for element in elements { dict[element.0] = element.1.json.object }
    self = .object(dict)
  }
}

extension JSON: ExpressibleByArrayLiteral {
  
  public init(arrayLiteral elements: JSONEncodable...) {
    self = .array(elements.map { $0.json.object })
  }
}

extension JSON: ExpressibleByStringLiteral {
  
  public init(stringLiteral value: StringLiteralType) {
    self = .string(value)
  }
  
  public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
    self = .string(value)
  }
  
  public init(unicodeScalarLiteral value: StringLiteralType) {
    self = .string(value)
  }
}

extension JSON: ExpressibleByIntegerLiteral {
  
  public init(integerLiteral value: IntegerLiteralType) {
    self = .number(NSNumber(value: value))
  }
}

extension JSON: ExpressibleByFloatLiteral {
  
  public init(floatLiteral value: FloatLiteralType) {
    self = .number(NSNumber(value: value))
  }
}

extension JSON: ExpressibleByBooleanLiteral {
  
  public init(booleanLiteral value: BooleanLiteralType) {
    self = .bool(value)
  }
}

extension JSON: ExpressibleByNilLiteral {
  
  public init(nilLiteral: ()) {
    self.init()
  }
}

//MARK: - convert to and from jsonData and jsonString

public extension JSON {
    
  init(jsonData: Data?, options: JSONSerialization.ReadingOptions = []) {
    guard let data = jsonData else { self.init(); return }
    do {
      let object = try JSONSerialization.jsonObject(with: data, options: options)
      self.init(any: object)
    } catch {
      self.init(JSON.error(JSON.Error.initalize(error: error)))
    }
  }
  
  init(jsonString: String?, options: JSONSerialization.ReadingOptions = []) {
    self.init(jsonData: jsonString?.data(using: String.Encoding.utf8), options: options)
  }
  
  func jsonData(withOptions opt: JSONSerialization.WritingOptions = []) throws -> Data {
    guard JSONSerialization.isValidJSONObject(object) else {
      throw error ?? Error.encodeToJSON(wrongObject: object)
    }
    return try JSONSerialization.data(withJSONObject: object, options: opt)
  }
    
  func jsonString(withOptions opt: JSONSerialization.WritingOptions = [],
                  encoding ecd: String.Encoding = String.Encoding.utf8) throws -> String {
    switch self {
    case .object, .array:
      let data = try self.jsonData(withOptions: opt)
      if let jsonSrt = String(data: data, encoding: ecd) { return jsonSrt }
      throw Error.encodeToJSON(wrongObject: ecd)
    default:
      throw error ?? Error.encodeToJSON(wrongObject: object)
    }
  }
}

//MARK: - StringConvertible

extension JSON: CustomStringConvertible, CustomDebugStringConvertible {
    
  public var description: String {
    return (try? jsonString(withOptions: .prettyPrinted)) ?? "\(object)"
  }
  
  public var debugDescription: String {
    return "\(type): " + ((try? jsonString()) ?? "\(object)")
  }
}

//MARK: - Equatable

extension JSON: Equatable { }

public func ==(lhs: JSON, rhs: JSON) -> Bool {
  switch (lhs, rhs) {
  case let (.object(l as NSDictionary), .object(r as NSDictionary)):
    return l == r
  case let (.array(l as NSArray), .array(r as NSArray)):
    return l == r
  case let (.string(l), .string(r)):
    return l == r
  case let (.bool(l), .bool(r)):
    return l == r
  case let (.number(l), .number(r)):
    return l == r
  case (.null, .null):
    return true
  default:
    return false
  }
}

//MARK: - For - in

public extension JSON {
  
  var dict: [String: Any]? {
    guard case let .object(dic) = self else { return nil }
    return dic
  }
  
  var array: [Any]? {
    guard case let .array(arr) = self else { return nil }
    return arr
  }
  
  var asDict: LazyMapCollection<[String: Any], (key: String, value: JSON)> {
    return (dict ?? [:]).lazy.map { ($0.0, JSON(any: $0.1)) }
  }
    
  var asArray: LazyMapCollection<[Any], JSON> {
    return (array ?? []).lazy.map { JSON(any: $0) }
  }
}

//MARK: - Dictionary extension

extension Dictionary {
  
  func map<T, U>(_ f: (Key, Value) throws -> (key: U, value: T)) rethrows -> [U: T] {
    var dict = [U: T](minimumCapacity: self.count)
    for (key, value) in self {
      let (key, value) = try f(key, value)
      dict[key] = value
    }
    return dict
  }
  
  func flatMap<T, U>(_ f: (Key, Value) -> (key: U, value: T?)) -> [U: T] {
    var dict = [U: T](minimumCapacity: self.count)
    for (key, value) in self {
      if case let (key, value?) = f(key, value) {
        dict[key] = value
      }
    }
    return dict
  }
}
