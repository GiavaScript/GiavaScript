module Ls
  alias BuiltinMethodBody = Proc(Value, Array(Value), Value)
  alias BuiltinPropertyGetter = Proc(Value, Value)

  record BuiltinMethodDefinition, name : String, body : BuiltinMethodBody
  record TypeObject, name : String, methods : Hash(String, BuiltinMethodDefinition), properties : Hash(String, BuiltinPropertyGetter)

  class BuiltinFunction
    getter name : String

    def initialize(@name : String, @body : BuiltinMethodBody)
    end

    def call(receiver : Value, args : Array(Value)) : Value
      @body.call(receiver, args)
    end

    def to_s(io : IO)
      io << "[builtin " << @name << "]"
    end
  end

  module RuntimeTypes
    extend self

    STRING_TYPE = TypeObject.new(
      "String",
      {
        "startsWith" => BuiltinMethodDefinition.new("String.startsWith", ->(receiver : Value, args : Array(Value)) { string_starts_with(receiver, args).as(Value) }),
        "toString"   => BuiltinMethodDefinition.new("String.toString", ->(receiver : Value, args : Array(Value)) { string_to_string(receiver, args).as(Value) }),
      } of String => BuiltinMethodDefinition,
      {
        "length" => ->(receiver : Value) { string_length(receiver).as(Value) },
      } of String => BuiltinPropertyGetter
    )

    NUMBER_TYPE = TypeObject.new(
      "Number",
      {
        "toString" => BuiltinMethodDefinition.new("Number.toString", ->(receiver : Value, args : Array(Value)) { number_to_string(receiver, args).as(Value) }),
      } of String => BuiltinMethodDefinition,
      {} of String => BuiltinPropertyGetter
    )

    ARRAY_TYPE = TypeObject.new(
      "Array",
      {
        "push"     => BuiltinMethodDefinition.new("Array.push", ->(receiver : Value, args : Array(Value)) { array_push(receiver, args).as(Value) }),
        "toString" => BuiltinMethodDefinition.new("Array.toString", ->(receiver : Value, args : Array(Value)) { array_to_string(receiver, args).as(Value) }),
      } of String => BuiltinMethodDefinition,
      {
        "length" => ->(receiver : Value) { array_length(receiver).as(Value) },
      } of String => BuiltinPropertyGetter
    )

    OBJECT_TYPE = TypeObject.new(
      "Object",
      {
        "toString" => BuiltinMethodDefinition.new("Object.toString", ->(receiver : Value, args : Array(Value)) { object_to_string(receiver, args).as(Value) }),
      } of String => BuiltinMethodDefinition,
      {} of String => BuiltinPropertyGetter
    )

    BOOL_TYPE = TypeObject.new(
      "Bool",
      {
        "toString" => BuiltinMethodDefinition.new("Bool.toString", ->(receiver : Value, args : Array(Value)) { bool_to_string(receiver, args).as(Value) }),
      } of String => BuiltinMethodDefinition,
      {} of String => BuiltinPropertyGetter
    )

    def get_type(value : Value) : TypeObject?
      return nil if value.nil?
      return nil if value.is_a?(UndefinedValue)

      case value
      when String
        STRING_TYPE
      when Int32, Float64
        NUMBER_TYPE
      when Array(Value)
        ARRAY_TYPE
      when Hash(String, Value)
        OBJECT_TYPE
      when Bool
        BOOL_TYPE
      else
        nil
      end
    end

    def lookup_type_property(value : Value, property : String) : NamedTuple(found: Bool, value: Value)
      type_object = get_type(value)
      return {found: false, value: UNDEFINED} unless type_object

      if getter = type_object.properties[property]?
        return {found: true, value: getter.call(value)}
      end

      if method = type_object.methods[property]?
        return {found: true, value: BuiltinFunction.new(method.name, method.body)}
      end

      {found: false, value: UNDEFINED}
    end

    private def string_length(receiver : Value) : Value
      receiver_string(receiver, "String.length").size
    end

    private def string_starts_with(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.startsWith")
      prefix = args[0]
      unless prefix.is_a?(String)
        raise ExpressionError.new("Error: String.startsWith expects a string argument")
      end

      receiver_string(receiver, "String.startsWith").starts_with?(prefix)
    end

    private def string_to_string(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.toString")
      receiver_string(receiver, "String.toString")
    end

    private def number_to_string(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "Number.toString")
      receiver_number(receiver, "Number.toString").to_s
    end

    private def array_length(receiver : Value) : Value
      receiver_array(receiver, "Array.length").size
    end

    private def array_push(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "Array.push")
      array_receiver = receiver_array(receiver, "Array.push")
      array_receiver << args[0]
      array_receiver.size
    end

    private def array_to_string(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "Array.toString")
      array_receiver = receiver_array(receiver, "Array.toString")
      array_receiver.map { |item| runtime_to_string(item) }.join(",")
    end

    private def object_to_string(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "Object.toString")
      object_receiver = receiver_object(receiver, "Object.toString")

      properties = object_receiver.map do |key, property_value|
        "\"#{runtime_to_string(key)}\": #{runtime_to_string(property_value)}"
      end
      "{#{properties.join(", ")}}"
    end

    private def bool_to_string(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "Bool.toString")
      receiver_bool(receiver, "Bool.toString").to_s
    end

    private def runtime_to_string(value : Value) : String
      if value.nil?
        return "null"
      end

      if value.is_a?(UndefinedValue)
        return "undefined"
      end

      if value.is_a?(String)
        return value
      end

      if value.is_a?(Array(Value))
        return "[#{value.map { |entry| runtime_to_string(entry) }.join(", ")}]"
      end

      if value.is_a?(Hash(String, Value))
        properties = value.map do |key, property_value|
          "\"#{runtime_to_string(key)}\": #{runtime_to_string(property_value)}"
        end
        return "{#{properties.join(", ")}}"
      end

      value.to_s
    end

    private def receiver_string(value : Value, method_name : String) : String
      return value if value.is_a?(String)
      raise ExpressionError.new("Error: #{method_name} receiver must be a string")
    end

    private def receiver_number(value : Value, method_name : String) : Number
      return value if value.is_a?(Int32)
      return value if value.is_a?(Float64)
      raise ExpressionError.new("Error: #{method_name} receiver must be a number")
    end

    private def receiver_array(value : Value, method_name : String) : Array(Value)
      return value if value.is_a?(Array(Value))
      raise ExpressionError.new("Error: #{method_name} receiver must be an array")
    end

    private def receiver_object(value : Value, method_name : String) : Hash(String, Value)
      return value if value.is_a?(Hash(String, Value))
      raise ExpressionError.new("Error: #{method_name} receiver must be an object")
    end

    private def receiver_bool(value : Value, method_name : String) : Bool
      return value if value.is_a?(Bool)
      raise ExpressionError.new("Error: #{method_name} receiver must be a boolean")
    end

    private def assert_arity(args : Array(Value), expected : Int32, method_name : String)
      return if args.size == expected

      raise ExpressionError.new("Error: #{method_name} expects #{expected} arguments but got #{args.size}")
    end
  end
end
