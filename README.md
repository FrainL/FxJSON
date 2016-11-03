

# Features

- [x] [快速](#它很快)


- [x] [JSON 和自定义类型互相转化](#FxJSON-能很轻易地将-JSON-和自定义结构互相转化，只需一个方法)


- [x] [Date 转换和自定义转换方式](#4.-TransformType)


- [x] [Swifty 的错误处理](#3.-错误处理)


- [x] [所有常见类型支持](#4.-类型支持)
- [x] [全面而灵活，面向协议]()


- [x] [playground 示例](#使用-playground-查看：)


- [x] [与多个主流库一同使用]()
- [x] [支持函数式编程]()


# Overview —— Why FxJSON

#### 它很快

这里用了和  [JASON](https://github.com/delba/JASON) 相同的 [Benchmarks]()（改成了 Swift 3 的语法），见 [PerformanceTests](https://github.com/FrainL/FxJSON/blob/master/FxJSONTests/PerformanceTests.swift) 。

|            |         100         |        1000        |       10000        |    Δ    |
| ---------- | :-----------------: | :----------------: | :----------------: | :-----: |
| FxJSON     | 0.002sec(21% STDEV) | 0.017sec(9% STDEV) | 0.170sec(9% STDEV) |    1    |
| SwiftyJSON | 0.007sec(16% STDEV) | 0.075sec(8% STDEV) | 0.678sec(8% STDEV) | 3.5~4.4 |
| JASON      | 0.009sec(10% STDEV) | 0.083sec(3% STDEV) | 0.852sec(6% STDEV) | 4.5~5.0 |

#### 它很优雅

[所有支持的类型]()你都可以通过下面这种方式来从 JSON 转换（包括你自定义的类型，见下文）：

```swift
let json = JSON(jsonData: jsonData) 		// Data?
let json = JSON(jsonString: jsonString)		// String?
if let numbers = [Int](json["data", "numbers"]) {
  // do some thing with numbers
}
```

或者直接从 `Data?` 或 JSON 形式的 `String?` 转换：

```swift
if let dict = try? [String: String](jsonData: someDataFromNet) {
  // do some thing with dict
}
```

或者使用带非常 Swifty 的错误处理方式的 `throws` 转换：

```swift
do {
  let user = try User(throws: json["user"])
} catch let JSON.Error.notExist(dict: dict, key: key) {
  print(dict, key)
} catch {
  print(error)
}
```

同时，这些支持的类型还能直接转化为 `JSON` 或者 `Data`、JSON 形式的 `String`

```swift
let json = ["key": 123].json
let jsondata = try [123, 456, 789].jsonData()
let jsonString = try user.jsonString()
```

自定义 JSON 也很简单：

```swift
let json = ["code": 0, "data": ["users": users]] as JSON
```

甚至还能这样：

```swift
let json = JSON {
  $0["code"] << 0
  $0["data", "users"] << users
}
```

#### 它很全面

使用 FxJSON 你不仅能将 JSON 类型转化为 FxJSON 的支持类型，你还能通过一些 [Protocol]() 来让任何数据结构支持上面的全部功能。

使用  `JSONDecodable` 来使自定义类型能从 JSON 转化：

```swift
struct User: JSONDecodable {
  let gender: Gender
  let website: URL
  let signUpTime: Date
  
  enum Gender: Int, JSONTransformable { // RawRepresentable 默认通过 rawValue 默认支持
    case boy
    case girl
  }
  
  init(decode json: JSON) throws {
    gender      = try json["gender"]<
    website     = try json["website"]<
    signUpTime  = try json["signUpTime"][DateTransform.timeIntervalSince(.year1970)]<
    // 使用 DateTransform 来指定如何转换为 Date
  }
}

let user = try User(throws: json)
```

使用 `JSONConvertable` 来使引用类型支持从 JSON 转化：

```swift
extension UIColor: JSONConvertable {
  public static func convert(from json: JSON) -> Self? {
    guard let hex = Int(json) else { return nil }
    let r = (CGFloat)((hex >> 16) & 0xFF)
    let g = (CGFloat)((hex >> 8) & 0xFF)
    let b = (CGFloat)(hex & 0xFF)
    return self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
  }
}

if let color = UIColor(json) {
  //Use color to do something
}
```

使用 `JSONEncodable` 来支持转换为 JSON：

```swift
extension User: JSONEncodable { } // 默认通过 Mirror 实现

// 或者你也可以自己定义 encode 函数(非必须)
extension User {
  func encode(mapper: JSON.Mapper) {
    mapper["gender"] << gender
    mapper["website"] << website
    mapper["signUpTime"] << signUpTime
  }
}
```

#### 它很好用

使用 `JSONMappable` ，你不用写一个 `map`  函数，不用继承自 `NSObject` ，FxJSON 默认为你支持从 JSON 到该结构（不管是 `Class` 还是 `Struct` ）的转化。

```swift
struct User: JSONMappable { //只需 JSONMappable 实现 init()，默认通过 Mirror 转换
	var userID: Int64!
	var name: String!
	var admin: Bool = false
	var whatsUp: String?
	var website: URL?
	var signUpTime: Date?			//Date 通过 DateTransform.default 转化
    var lastLoginDate = Date()
	var friends: [User]?
}

//或者你也可以用 map 函数自定义转换方式(可选)
extension User {  
  mutating func map(mapper: JSON.Mapper) {
    admin         >< mapper							// >< 表示忽略该属性
    signUpTime    << mapper["signUpTime"]			// << 表示仅从 JSON 转换到 object
    lastLoginDate >> mapper["lastLoginDate"]		// >> 表示仅从 object 转换到 JSON
    whatsUp       <> mapper[noneNull: "whatsUp"]	// <> 表示和 JSON 互相转换
    //noneNull 参数表示为空时返回，不插入 JSON
  }
}
```

## Installation

#### CocoaPods

You can use [CocoaPods](http://cocoapods.org/) to install FxJSON by adding it to your `Podfile`:

```
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
    pod 'FxJSON'
end
```

#### Carthage 

You can use [Carthage](https://github.com/Carthage/Carthage) to install FxJSON by adding it to your `Cartfile`:

```
github "FrainL/FxJSON"
```

## Usage

1. [使用 playground 查看用例]()
2. [处理 JSON 数据]()
   1. [初始化]()
   2. [获取数据]()
   3. [转换]()
   4. [JSON as MutableCollection]()
   5. [创建 JSON]()
3. [使用 Protocol]()

### 1. 使用 playground 查看

1. 打开 FxJSON.workspace
2. 使用 iPhone 5s 以上模拟器 build FxJSON 
3. 在 workspace 中打开 FxJSON.playground

### 2. 处理 JSON 数据

#### 1. 初始化

```swift
let json = JSON(typeThatSupported)
let json = JSON(any: any)					//Any
let json = JSON(jsonData: data)				//Data?
let json = JSON(jsonString: jsonString)		//String?
```

或者任何自带或使用 protocol 支持的自定义类型都可以直接使用 `some.json` 获取。详见[类型支持](#4.-类型支持)。

#### 2. 获取数据

FxJSON 支持地址式的下标。

```swift
json["code"]
json["data", "users", 0]

let path: JSON.Index = ["data", "users", 1]
json[path]
json[path, "name"]
```

使用 `SupportedType(json)` 的形式可以获取 optional 数据。

```swift
if let code = Int(json["code"]) {
	// do something here
}
let website = URL(json[path]["website"])
```

使用 `SupportedType(noneNull: json)` 的形式可以获取非 optional 数据。

```swift
let userID = Int(noneNull: json[path]["userID"])
```

使用 `SupportedType(throws: json)`  的形式的初始化带有错误处理。

```swift
let name = try String(throws: json[path, "name"])

do {
  let number = try Int(throws: json["notExist"])
} catch let JSON.Error.notExist(dict: dict, key: key) {
  print(key, dict)
}
```

`[SupportedType]` 、`[Any]`、`[String: SupportedType]`、 `[String: Any]` 同样也是支持的类型。

```swift
let friends = [[String: Any]](json[path, "friends"])
```

### 3. fot-in

`JSON` 是一个 `MutableCollection` ，它能使用所有 `MutableCollection` 的方法，比如 `isEmpty` 、`count` 等等都能使用。

在使用 for-in 的时候，无论 `JSON` 是 `.array` 还是 `.object`，`Element` 都是 `JSON`  类型。

```swift
for subJSON in json {
  //do some thing
}
```

特别的，如果有需要，可以用 `.asDic` 和 `asArray` 来使用 for-in。（因为使用了 `LazyMapCollection` ，使用这两者会比直接使用 for-in 性能更好）

```swift
// If JSON is an object
for (key, subJSON) in json.asDic { 
  // do something
}
// If JSON is an array
for subJSON in json.asArray {
  // do something
}
```

### 4. 转换

通过设置 `DateTransform.default` 来更改 `Date` 的默认的转换方式。

```swift
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
DateTransform.default = DateTransform.formatter(formatter)
```

`Date` 可以通过 `DateTransform` 进行转换。（默认格式化器为 "yyyy-MM-dd'T'HH:mm:ssZ" ）

```swift
let signUpTime = Date(json[path, "signUpTime"])
let date = Date(JSON(NSTimeIntervalSince1970)[DateTransform.timeIntervalSince(.year1970)])
```

你可以你还可以通过 `CustomTransform` 来自定义转换方式，可以选用 `.toJSON` , `.fromJSON` 或 `.both` 来定义需要的转换方式（使用  `throw` 以便进行错误处理）：

```swift
let from = CustomTransform<String, Int>.fromJSON {
  if let number = Int($0) { return number }
  throw JSON.Error.customTransfrom(source: $0)
}
let to = CustomTransform<String, Int>.toJSON { "\($0)" }
let code = Int(json["code"][from])

do {
  let code = try Int(throws: json[path, "name"][from])
} catch let JSON.Error.customTransfrom(source: any) {
  any
}
```

### 5. 创造 JSON

FxJSON 能提供目前为止最为便捷的创造 JSON 的方式，使用 Literal：

```swift
let userJSON = [
	"userID": userID,
	"name": name,
	"admin": admin
] as JSON
```

使用操作符 `<<` ：

```swift
let createJSON = JSON {
	$0["code"][to] 				<< code
	$0["data", "users", 0] 		<< user
	$0[path] << JSON {
		$0 						<< userJSON
		$0[noneNull: "whatsUp"] << whatsUp
		$0["website"]			<< website
		$0["signUpTime"] 		<< signUpTime
		$0["friends"] 			<< friends
	}
}
```

### 3. 使用协议

#### 1. JSONDecodable 

#### 2. JSONEncodable 

#### 3. JSONMappable

#### 4. JSONConvertable、JSONTransformable

## References

#### 1. Supported Types 

| Supported Type                           | Default value |
| :--------------------------------------- | ------------- |
| `String`                                 | ""            |
| `Bool`                                   | false         |
| `Float`, `Double`                        | 0.0           |
| `Int`, `Int8`, `Int16`, `Int32`, `Int64` | 0             |
| `Date`                                   | ×             |
| `URL`                                    | ×             |
| `NSNull`                                 | ×             |
| `Optional<SupportedType>`                | ×             |
| `ImplicitlyUnwrappedOptional<SupportedType>` | nil           |
| `Set<SupportedType>`                     | []            |
| `Array<SupportedType>`                   | []            |
| `Array<Any>`                             | []            |
| `Dictionary<String, SupportedType>`      | [:]           |
| `Dictionary<String, Any>`                | [:]           |

**note:**  × 表示该类型没有默认值

#### 2. Protocols

| Protocol             | 需要实现的方法                                  | 继承的 Protocol                     | 说明                                       |
| -------------------- | ---------------------------------------- | -------------------------------- | ---------------------------------------- |
| JSONSerializable     | var json: JSON { get }                   | 无                                | 该协议让类型支持转换成 JSON，当类型为 RawRepresentable 且 RawValue 为支持的类型时默认支持 |
| JSONDeserializable   | init?(_ json: JSON)                      | 无                                | 该协议让类型支持从 JSON 转换，当类型为 RawRepresentable 且 RawValue 为支持的类型时时默认支持 |
| JSONTransformable    | var json: JSON { get }; init?(_ json: JSON) | 无                                | JSONDeserializable & JSONSerializable    |
| DefaultInitializable | init()                                   | 无                                | 支持该协议并支持 JSONDeserializable 则可以使用 init(noneNull json: JSON) 方法 |
| JSONConvertable      | static func convert(from json: JSON) -> Self? | JSONDeserializable               | 该协议让引用类型支持从 JSON 转换                      |
| JSONDecodable        | init(decode json: JSON) throws           | JSONDeserializable               | 该协议让类型支持从 JSON 转换                        |
| JSONEncodable        | func encode(mapper: JSON.Mapper) // 可选   | JSONSerializable                 | 该协议让类型支持从 JSON 转换                        |
| JSONCodable          | init(decode json: JSON) throws; func encode(mapper: JSON.Mapper) // 可选 | 无                                | JSONEncodable & JSONDecodable            |
| JSONMappable         | init(); mutating func map(mapper: JSON.Mapper) // 可选 | DefaultInitializable、JSONCodable | 该协议让自定义类型支持与 JSON 互相转换                   |

#### 3. Errors

| JSON.Error       | Associated Values                  |
| ---------------- | ---------------------------------- |
| .initalize       | (error: Swift.Error)               |
| .unSupportType   | (type: Any.Type)                   |
| .encodeToData    | (wrongObject: Any)                 |
| .notExist        | (dict: [String: Any], key: String) |
| .wrongType       | (subscript: JSON, key: Index)      |
| .outOfBounds     | (arr: [Any], index: Int)           |
| .deserilize      | (from: JSON, to: Any.Type)         |
| .formatter       | (format: String, value: String)    |
| .customTransfrom | (source: Any)                      |

## Extend

### 与 Alamofire 一起使用

```swift
Alamofire.request(.GET, url).validate().responseJSON { response in
  switch response.result {
  case .Success:
    let json = JSON(jsonData: response.result.value)
    print("JSON: \(json)")
  case .Failure(let error):
    print(error)
  }
}
```

### 与 Realm 一起使用

```swift
struct Model: Object, JSONDecodable {
  dynamic var code = 0
  dynamic var name = ""

  init(decode json: JSON) throws {
    code	= try json["code"]<
    name	= try json["name"]<
  }
}
```

## Funtional Programming

`JSON` 类型是一个 Monad 和 Funtor，除了作为 `MutableCollection` 的默认的 `map` 、`flatMap` 方法以外，FxJSON 还这样的 `map` 函数：

```swift
JSON(123).map { (number: Int) -> String in "\($0)" }	//String: "123"
```

除此之外，使用 `func <<<T : JSONDeserializable>(lhs: JSON, rhs: JSON.Index)` 和 Curry 、 Applicative 配合 `JSONConvertable` ，还可以这样写（保证多少参数编译器都不会报 `Complicate` ）：

```swift
struct User: JSONConvertable {
  let name: String
  let age: Int?
  let friends: [User]
	
  static func convert(from json: JSON) -> User? {
    return curry(User.init)
      <*> json << "name"
      <*> json << ["others", "age"]
      <*> json << "friends"
  }
}
```

## To do List

