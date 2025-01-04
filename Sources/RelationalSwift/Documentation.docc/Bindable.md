# ``Bindable``

The `Bindable` protocol provides support for moving values in/out of SQLite statements.

### Overview

The `Bindable` protocol supports multiple types out of the box, including:

```swift
try Int.bind(to: stmt, value: 0, at: &index)
try Int32.bind(to: stmt, value: 0, at: &index)
try Int64.bind(to: stmt, value: 0, at: &index)
try Bool.bind(to: stmt, value: false, at: &index)
try Float.bind(to: stmt, value: 0, at: &index)
try Double.bind(to: stmt, value: 0, at: &index)
try String.bind(to: stmt, value: "", at: &index)
try UUID.bind(to: stmt, value: UUID(), at: &index)
try Data.bind(to: stmt, value: Data(), at: &index)
try Date.bind(to: stmt, value: Date(), at: &index)
```

Support for codable types can be added by conforming to `Bindable`:

```swift
struct MyCodable: Codable, Bindable {
    var name: String
    var id: UUID
}

let value = MyCodable(name: "Foo", id: UUID())

// Usage
try MyCodable.bind(to: stmt, value: value, at: &index)
```

Similarly, support for RawRepresentable types, where the raw type conforms to `Bindable`, can be added by conforming
to `Bindable`:

```swift
enum MyEnum: String, Bindable {
    case foo
    case bar
}

// Usage
try MyEnum.bind(to: stmt, value: .foo, at: &index)
```

All `Bindable` types support optional values:

```swift
try MyEnum?.bind(to: stmt, value: nil, at: &index)
```

Arrays of `Bindable` types are also supported:

```swift
try [String].bind(to: stmt, value: ["Foo", "Bar"], at: &index)
```

And also dictionaries of `Bindable` types are supported:

```swift
try [Int: String].bind(to: stmt, value: [0: "Foo", 1: "Bar"], at: &index)
```

Support for custom types can be added by conforming to `Bindable`.

## Topics

### Binding Values to Statements

- ``Bindable/bind(to:value:at:)-4olsr``
- ``Bindable/bind(to:value:at:)-7n3tg``
- ``Bindable/bind(to:at:)-6pfir``
- ``Bindable/bind(to:at:)-5vnri``
- ``Bindable/managedBinder``

### Extracting Values from Statements

- ``Bindable/column(of:at:)``
- ``Bindable/column(of:at:)-848gx``
- ``Bindable/column(of:at:)-498sz``
- ``Bindable/column(of:at:)-81zwe``

### Value Representation

- ``Bindable/asSQLLiteral()``

### Underlying SQL Type

- ``Bindable/detaultSQLStorageType``
