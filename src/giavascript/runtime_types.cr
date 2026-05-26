module GiavaScript
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

    @@callback_invoker : Proc(Value, Array(Value), Value)? = nil

    STRING_TYPE = TypeObject.new(
      "String",
      {
        "at"                => BuiltinMethodDefinition.new("String.at", ->(receiver : Value, args : Array(Value)) { string_at(receiver, args).as(Value) }),
        "charAt"            => BuiltinMethodDefinition.new("String.charAt", ->(receiver : Value, args : Array(Value)) { string_char_at(receiver, args).as(Value) }),
        "charCodeAt"        => BuiltinMethodDefinition.new("String.charCodeAt", ->(receiver : Value, args : Array(Value)) { string_char_code_at(receiver, args).as(Value) }),
        "codePointAt"       => BuiltinMethodDefinition.new("String.codePointAt", ->(receiver : Value, args : Array(Value)) { string_code_point_at(receiver, args).as(Value) }),
        "concat"            => BuiltinMethodDefinition.new("String.concat", ->(receiver : Value, args : Array(Value)) { string_concat(receiver, args).as(Value) }),
        "endsWith"          => BuiltinMethodDefinition.new("String.endsWith", ->(receiver : Value, args : Array(Value)) { string_ends_with(receiver, args).as(Value) }),
        "includes"          => BuiltinMethodDefinition.new("String.includes", ->(receiver : Value, args : Array(Value)) { string_includes(receiver, args).as(Value) }),
        "indexOf"           => BuiltinMethodDefinition.new("String.indexOf", ->(receiver : Value, args : Array(Value)) { string_index_of(receiver, args).as(Value) }),
        "isWellFormed"      => BuiltinMethodDefinition.new("String.isWellFormed", ->(receiver : Value, args : Array(Value)) { string_is_well_formed(receiver, args).as(Value) }),
        "lastIndexOf"       => BuiltinMethodDefinition.new("String.lastIndexOf", ->(receiver : Value, args : Array(Value)) { string_last_index_of(receiver, args).as(Value) }),
        "localeCompare"     => BuiltinMethodDefinition.new("String.localeCompare", ->(receiver : Value, args : Array(Value)) { string_locale_compare(receiver, args).as(Value) }),
        "match"             => BuiltinMethodDefinition.new("String.match", ->(receiver : Value, args : Array(Value)) { string_match(receiver, args).as(Value) }),
        "matchAll"          => BuiltinMethodDefinition.new("String.matchAll", ->(receiver : Value, args : Array(Value)) { string_match_all(receiver, args).as(Value) }),
        "padEnd"            => BuiltinMethodDefinition.new("String.padEnd", ->(receiver : Value, args : Array(Value)) { string_pad_end(receiver, args).as(Value) }),
        "padStart"          => BuiltinMethodDefinition.new("String.padStart", ->(receiver : Value, args : Array(Value)) { string_pad_start(receiver, args).as(Value) }),
        "replace"           => BuiltinMethodDefinition.new("String.replace", ->(receiver : Value, args : Array(Value)) { string_replace(receiver, args).as(Value) }),
        "replaceAll"        => BuiltinMethodDefinition.new("String.replaceAll", ->(receiver : Value, args : Array(Value)) { string_replace_all(receiver, args).as(Value) }),
        "repeat"            => BuiltinMethodDefinition.new("String.repeat", ->(receiver : Value, args : Array(Value)) { string_repeat(receiver, args).as(Value) }),
        "search"            => BuiltinMethodDefinition.new("String.search", ->(receiver : Value, args : Array(Value)) { string_search(receiver, args).as(Value) }),
        "slice"             => BuiltinMethodDefinition.new("String.slice", ->(receiver : Value, args : Array(Value)) { string_slice(receiver, args).as(Value) }),
        "split"             => BuiltinMethodDefinition.new("String.split", ->(receiver : Value, args : Array(Value)) { string_split(receiver, args).as(Value) }),
        "startsWith"        => BuiltinMethodDefinition.new("String.startsWith", ->(receiver : Value, args : Array(Value)) { string_starts_with(receiver, args).as(Value) }),
        "substring"         => BuiltinMethodDefinition.new("String.substring", ->(receiver : Value, args : Array(Value)) { string_substring(receiver, args).as(Value) }),
        "toLocaleLowerCase" => BuiltinMethodDefinition.new("String.toLocaleLowerCase", ->(receiver : Value, args : Array(Value)) { string_to_locale_lower_case(receiver, args).as(Value) }),
        "toLocaleUpperCase" => BuiltinMethodDefinition.new("String.toLocaleUpperCase", ->(receiver : Value, args : Array(Value)) { string_to_locale_upper_case(receiver, args).as(Value) }),
        "trim"              => BuiltinMethodDefinition.new("String.trim", ->(receiver : Value, args : Array(Value)) { string_trim(receiver, args).as(Value) }),
        "trimEnd"           => BuiltinMethodDefinition.new("String.trimEnd", ->(receiver : Value, args : Array(Value)) { string_trim_end(receiver, args).as(Value) }),
        "trimStart"         => BuiltinMethodDefinition.new("String.trimStart", ->(receiver : Value, args : Array(Value)) { string_trim_start(receiver, args).as(Value) }),
        "toLowerCase"       => BuiltinMethodDefinition.new("String.toLowerCase", ->(receiver : Value, args : Array(Value)) { string_to_lower_case(receiver, args).as(Value) }),
        "toString"          => BuiltinMethodDefinition.new("String.toString", ->(receiver : Value, args : Array(Value)) { string_to_string(receiver, args).as(Value) }),
        "toUpperCase"       => BuiltinMethodDefinition.new("String.toUpperCase", ->(receiver : Value, args : Array(Value)) { string_to_upper_case(receiver, args).as(Value) }),
        "toWellFormed"      => BuiltinMethodDefinition.new("String.toWellFormed", ->(receiver : Value, args : Array(Value)) { string_to_well_formed(receiver, args).as(Value) }),
        "valueOf"           => BuiltinMethodDefinition.new("String.valueOf", ->(receiver : Value, args : Array(Value)) { string_value_of(receiver, args).as(Value) }),
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
        "at"          => BuiltinMethodDefinition.new("Array.at", ->(receiver : Value, args : Array(Value)) { array_at(receiver, args).as(Value) }),
        "concat"      => BuiltinMethodDefinition.new("Array.concat", ->(receiver : Value, args : Array(Value)) { array_concat(receiver, args).as(Value) }),
        "every"       => BuiltinMethodDefinition.new("Array.every", ->(receiver : Value, args : Array(Value)) { array_every(receiver, args).as(Value) }),
        "filter"      => BuiltinMethodDefinition.new("Array.filter", ->(receiver : Value, args : Array(Value)) { array_filter(receiver, args).as(Value) }),
        "find"        => BuiltinMethodDefinition.new("Array.find", ->(receiver : Value, args : Array(Value)) { array_find(receiver, args).as(Value) }),
        "findIndex"   => BuiltinMethodDefinition.new("Array.findIndex", ->(receiver : Value, args : Array(Value)) { array_find_index(receiver, args).as(Value) }),
        "forEach"     => BuiltinMethodDefinition.new("Array.forEach", ->(receiver : Value, args : Array(Value)) { array_for_each(receiver, args).as(Value) }),
        "includes"    => BuiltinMethodDefinition.new("Array.includes", ->(receiver : Value, args : Array(Value)) { array_includes(receiver, args).as(Value) }),
        "indexOf"     => BuiltinMethodDefinition.new("Array.indexOf", ->(receiver : Value, args : Array(Value)) { array_index_of(receiver, args).as(Value) }),
        "join"        => BuiltinMethodDefinition.new("Array.join", ->(receiver : Value, args : Array(Value)) { array_join(receiver, args).as(Value) }),
        "lastIndexOf" => BuiltinMethodDefinition.new("Array.lastIndexOf", ->(receiver : Value, args : Array(Value)) { array_last_index_of(receiver, args).as(Value) }),
        "map"         => BuiltinMethodDefinition.new("Array.map", ->(receiver : Value, args : Array(Value)) { array_map(receiver, args).as(Value) }),
        "pop"         => BuiltinMethodDefinition.new("Array.pop", ->(receiver : Value, args : Array(Value)) { array_pop(receiver, args).as(Value) }),
        "push"        => BuiltinMethodDefinition.new("Array.push", ->(receiver : Value, args : Array(Value)) { array_push(receiver, args).as(Value) }),
        "reduce"      => BuiltinMethodDefinition.new("Array.reduce", ->(receiver : Value, args : Array(Value)) { array_reduce(receiver, args).as(Value) }),
        "reverse"     => BuiltinMethodDefinition.new("Array.reverse", ->(receiver : Value, args : Array(Value)) { array_reverse(receiver, args).as(Value) }),
        "shift"       => BuiltinMethodDefinition.new("Array.shift", ->(receiver : Value, args : Array(Value)) { array_shift(receiver, args).as(Value) }),
        "slice"       => BuiltinMethodDefinition.new("Array.slice", ->(receiver : Value, args : Array(Value)) { array_slice(receiver, args).as(Value) }),
        "some"        => BuiltinMethodDefinition.new("Array.some", ->(receiver : Value, args : Array(Value)) { array_some(receiver, args).as(Value) }),
        "sort"        => BuiltinMethodDefinition.new("Array.sort", ->(receiver : Value, args : Array(Value)) { array_sort(receiver, args).as(Value) }),
        "toString"    => BuiltinMethodDefinition.new("Array.toString", ->(receiver : Value, args : Array(Value)) { array_to_string(receiver, args).as(Value) }),
        "unshift"     => BuiltinMethodDefinition.new("Array.unshift", ->(receiver : Value, args : Array(Value)) { array_unshift(receiver, args).as(Value) }),
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

    def with_callback_invoker(invoker : Proc(Value, Array(Value), Value)?, &block : -> T) : T forall T
      previous = @@callback_invoker
      @@callback_invoker = invoker
      result = block.call
      result
    ensure
      @@callback_invoker = previous
    end

    private def string_length(receiver : Value) : Value
      receiver_string(receiver, "String.length").size
    end

    private def string_starts_with(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.startsWith")
      prefix = string_argument(args[0], "String.startsWith")

      receiver_string(receiver, "String.startsWith").starts_with?(prefix)
    end

    private def string_ends_with(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.endsWith")
      suffix = string_argument(args[0], "String.endsWith")

      receiver_string(receiver, "String.endsWith").ends_with?(suffix)
    end

    private def string_includes(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.includes")
      needle = string_argument(args[0], "String.includes")

      receiver_string(receiver, "String.includes").includes?(needle)
    end

    private def string_concat(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.concat")
      suffix = string_argument(args[0], "String.concat")

      "#{receiver_string(receiver, "String.concat")}#{suffix}"
    end

    private def string_char_at(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.charAt")
      index = integer_argument(args[0], "String.charAt")

      string = receiver_string(receiver, "String.charAt")
      return "" if index < 0

      char = string[index]?
      return "" unless char

      char.to_s
    end

    private def string_at(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.at")
      index = integer_argument(args[0], "String.at")

      string = receiver_string(receiver, "String.at")
      char = string[index]?
      return UNDEFINED unless char

      char.to_s
    end

    private def string_char_code_at(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.charCodeAt")
      index = integer_argument(args[0], "String.charCodeAt")

      string = receiver_string(receiver, "String.charCodeAt")
      char = string[index]?
      return Float64::NAN unless char

      char.ord
    end

    private def string_code_point_at(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.codePointAt")
      index = integer_argument(args[0], "String.codePointAt")

      string = receiver_string(receiver, "String.codePointAt")
      char = string[index]?
      return UNDEFINED unless char

      char.ord
    end

    private def string_index_of(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.indexOf")
      needle = string_argument(args[0], "String.indexOf")
      haystack = receiver_string(receiver, "String.indexOf")
      index = haystack.index(needle)
      index ? index : -1
    end

    private def string_last_index_of(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.lastIndexOf")
      needle = string_argument(args[0], "String.lastIndexOf")
      haystack = receiver_string(receiver, "String.lastIndexOf")
      index = haystack.rindex(needle)
      index ? index : -1
    end

    private def string_is_well_formed(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.isWellFormed")
      receiver_string(receiver, "String.isWellFormed")
      true
    end

    private def string_locale_compare(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.localeCompare")
      left = receiver_string(receiver, "String.localeCompare")
      right = string_argument(args[0], "String.localeCompare")

      compare_result = left <=> right
      if compare_result == 0
        0
      elsif compare_result < 0
        -1
      else
        1
      end
    end

    private def string_match(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.match")
      pattern = string_argument(args[0], "String.match")
      string = receiver_string(receiver, "String.match")

      if pattern.empty?
        return [""] of Value
      end

      return nil unless string.includes?(pattern)

      [pattern] of Value
    end

    private def string_match_all(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.matchAll")
      pattern = string_argument(args[0], "String.matchAll")
      string = receiver_string(receiver, "String.matchAll")

      if pattern.empty?
        result = Array(Value).new(string.size + 1)
        (string.size + 1).times { result << "" }
        return result
      end

      result = [] of Value
      start_index = 0

      while start_index <= string.size
        match_index = string.index(pattern, start_index)
        break unless match_index

        result << pattern
        start_index = match_index + pattern.size
      end

      result
    end

    private def string_pad_end(receiver : Value, args : Array(Value)) : Value
      assert_arity_between(args, 1, 2, "String.padEnd")
      string = receiver_string(receiver, "String.padEnd")
      target_length = integer_argument(args[0], "String.padEnd")
      pad_string = args.size == 2 ? string_argument(args[1], "String.padEnd") : " "

      return string if target_length <= string.size
      return string if pad_string.empty?

      string + build_padding(pad_string, target_length - string.size)
    end

    private def string_pad_start(receiver : Value, args : Array(Value)) : Value
      assert_arity_between(args, 1, 2, "String.padStart")
      string = receiver_string(receiver, "String.padStart")
      target_length = integer_argument(args[0], "String.padStart")
      pad_string = args.size == 2 ? string_argument(args[1], "String.padStart") : " "

      return string if target_length <= string.size
      return string if pad_string.empty?

      build_padding(pad_string, target_length - string.size) + string
    end

    private def string_trim(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.trim")
      receiver_string(receiver, "String.trim").strip
    end

    private def string_trim_start(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.trimStart")
      receiver_string(receiver, "String.trimStart").lstrip
    end

    private def string_trim_end(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.trimEnd")
      receiver_string(receiver, "String.trimEnd").rstrip
    end

    private def string_repeat(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.repeat")
      count = integer_argument(args[0], "String.repeat")
      if count < 0
        raise ExpressionError.new("Error: String.repeat expects a non-negative integer argument")
      end

      receiver_string(receiver, "String.repeat") * count
    end

    private def string_split(receiver : Value, args : Array(Value)) : Value
      assert_arity_between(args, 1, 2, "String.split")
      separator = string_argument(args[0], "String.split")
      string = receiver_string(receiver, "String.split")

      limit = Int32::MAX
      if args.size == 2
        limit = integer_argument(args[1], "String.split")
        if limit < 0
          raise ExpressionError.new("Error: String.split expects a non-negative integer argument")
        end
      end

      return [] of Value if limit == 0

      if separator.empty?
        result = [] of Value
        string.each_char do |char|
          break if result.size >= limit
          result << char.to_s
        end
        return result
      end

      result = [] of Value
      start_index = 0

      while result.size < limit
        match_index = string.index(separator, start_index)
        break unless match_index

        result << string[start_index...match_index]
        start_index = match_index + separator.size
      end

      if result.size < limit
        result << string[start_index...string.size]
      end

      result
    end

    private def string_replace(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 2, "String.replace")
      search = string_argument(args[0], "String.replace")
      replacement = string_argument(args[1], "String.replace")
      string = receiver_string(receiver, "String.replace")

      return "#{replacement}#{string}" if search.empty?

      match_index = string.index(search)
      return string unless match_index

      prefix = string[0...match_index]
      suffix_start = match_index + search.size
      suffix = string[suffix_start...string.size]
      "#{prefix}#{replacement}#{suffix}"
    end

    private def string_replace_all(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 2, "String.replaceAll")
      search = string_argument(args[0], "String.replaceAll")
      replacement = string_argument(args[1], "String.replaceAll")
      string = receiver_string(receiver, "String.replaceAll")

      if search.empty?
        result = String.build do |builder|
          builder << replacement
          string.each_char do |char|
            builder << char
            builder << replacement
          end
        end
        return result
      end

      string.gsub(search, replacement)
    end

    private def string_search(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "String.search")
      pattern = string_argument(args[0], "String.search")
      string = receiver_string(receiver, "String.search")
      index = string.index(pattern)
      index ? index : -1
    end

    private def string_slice(receiver : Value, args : Array(Value)) : Value
      assert_arity_between(args, 1, 2, "String.slice")
      string = receiver_string(receiver, "String.slice")
      size = string.size
      start_index = normalize_slice_index(integer_argument(args[0], "String.slice"), size)
      end_index = args.size == 2 ? normalize_slice_index(integer_argument(args[1], "String.slice"), size) : size
      return "" if end_index <= start_index

      string_range_by_char_index(string, start_index, end_index)
    end

    private def string_substring(receiver : Value, args : Array(Value)) : Value
      assert_arity_between(args, 1, 2, "String.substring")
      string = receiver_string(receiver, "String.substring")
      size = string.size
      start_index = clamp_substring_index(integer_argument(args[0], "String.substring"), size)
      end_index = args.size == 2 ? clamp_substring_index(integer_argument(args[1], "String.substring"), size) : size

      if start_index > end_index
        start_index, end_index = end_index, start_index
      end

      string_range_by_char_index(string, start_index, end_index)
    end

    private def string_to_string(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.toString")
      receiver_string(receiver, "String.toString")
    end

    private def string_to_lower_case(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.toLowerCase")
      receiver_string(receiver, "String.toLowerCase").downcase
    end

    private def string_to_locale_lower_case(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.toLocaleLowerCase")
      receiver_string(receiver, "String.toLocaleLowerCase").downcase
    end

    private def string_to_upper_case(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.toUpperCase")
      receiver_string(receiver, "String.toUpperCase").upcase
    end

    private def string_to_locale_upper_case(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.toLocaleUpperCase")
      receiver_string(receiver, "String.toLocaleUpperCase").upcase
    end

    private def string_to_well_formed(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.toWellFormed")
      receiver_string(receiver, "String.toWellFormed")
    end

    private def string_value_of(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "String.valueOf")
      receiver_string(receiver, "String.valueOf")
    end

    private def number_to_string(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "Number.toString")
      receiver_number(receiver, "Number.toString").to_s
    end

    private def array_length(receiver : Value) : Value
      receiver_array(receiver, "Array.length").size
    end

    private def array_at(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "Array.at")
      index = integer_argument(args[0], "Array.at")

      array_receiver = receiver_array(receiver, "Array.at")
      normalized_index = index < 0 ? array_receiver.size + index : index
      return UNDEFINED if normalized_index < 0 || normalized_index >= array_receiver.size

      array_receiver[normalized_index]
    end

    private def array_concat(receiver : Value, args : Array(Value)) : Value
      array_receiver = receiver_array(receiver, "Array.concat")
      result = array_receiver.dup

      args.each do |arg|
        if arg.is_a?(Array(Value))
          arg.each { |value| result << value }
        else
          result << arg
        end
      end

      result
    end

    private def array_for_each(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "Array.forEach")
      callback = callback_argument(args[0], "Array.forEach")
      array_receiver = receiver_array(receiver, "Array.forEach")
      length = array_receiver.size

      index = 0
      while index < length
        break if index >= array_receiver.size

        invoke_callback(
          callback,
          [array_receiver[index], index, array_receiver] of Value,
          "Array.forEach"
        )
        index += 1
      end

      UNDEFINED
    end

    private def array_map(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "Array.map")
      callback = callback_argument(args[0], "Array.map")
      array_receiver = receiver_array(receiver, "Array.map")
      length = array_receiver.size
      result = Array(Value).new(length)

      index = 0
      while index < length
        break if index >= array_receiver.size

        mapped = invoke_callback(
          callback,
          [array_receiver[index], index, array_receiver] of Value,
          "Array.map"
        )
        result << mapped
        index += 1
      end

      result
    end

    private def array_filter(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "Array.filter")
      callback = callback_argument(args[0], "Array.filter")
      array_receiver = receiver_array(receiver, "Array.filter")
      length = array_receiver.size
      result = [] of Value

      index = 0
      while index < length
        break if index >= array_receiver.size

        value = array_receiver[index]
        predicate_result = invoke_callback(
          callback,
          [value, index, array_receiver] of Value,
          "Array.filter"
        )
        result << value if runtime_truthy?(predicate_result)
        index += 1
      end

      result
    end

    private def array_reduce(receiver : Value, args : Array(Value)) : Value
      assert_arity_between(args, 1, 2, "Array.reduce")
      callback = callback_argument(args[0], "Array.reduce")
      array_receiver = receiver_array(receiver, "Array.reduce")
      length = array_receiver.size

      accumulator = if args.size == 2
                      args[1]
                    else
                      if array_receiver.empty?
                        raise ExpressionError.new("Error: Array.reduce cannot reduce an empty array without an initial value")
                      end

                      array_receiver[0]
                    end

      index = args.size == 2 ? 0 : 1
      while index < length
        break if index >= array_receiver.size

        accumulator = invoke_callback(
          callback,
          [accumulator, array_receiver[index], index, array_receiver] of Value,
          "Array.reduce"
        )
        index += 1
      end

      accumulator
    end

    private def array_some(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "Array.some")
      callback = callback_argument(args[0], "Array.some")
      array_receiver = receiver_array(receiver, "Array.some")
      length = array_receiver.size

      index = 0
      while index < length
        break if index >= array_receiver.size

        predicate_result = invoke_callback(
          callback,
          [array_receiver[index], index, array_receiver] of Value,
          "Array.some"
        )
        return true if runtime_truthy?(predicate_result)
        index += 1
      end

      false
    end

    private def array_every(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "Array.every")
      callback = callback_argument(args[0], "Array.every")
      array_receiver = receiver_array(receiver, "Array.every")
      length = array_receiver.size

      index = 0
      while index < length
        break if index >= array_receiver.size

        predicate_result = invoke_callback(
          callback,
          [array_receiver[index], index, array_receiver] of Value,
          "Array.every"
        )
        return false unless runtime_truthy?(predicate_result)
        index += 1
      end

      true
    end

    private def array_find(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "Array.find")
      callback = callback_argument(args[0], "Array.find")
      array_receiver = receiver_array(receiver, "Array.find")
      length = array_receiver.size

      index = 0
      while index < length
        break if index >= array_receiver.size

        value = array_receiver[index]
        predicate_result = invoke_callback(
          callback,
          [value, index, array_receiver] of Value,
          "Array.find"
        )
        return value if runtime_truthy?(predicate_result)
        index += 1
      end

      UNDEFINED
    end

    private def array_find_index(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "Array.findIndex")
      callback = callback_argument(args[0], "Array.findIndex")
      array_receiver = receiver_array(receiver, "Array.findIndex")
      length = array_receiver.size

      index = 0
      while index < length
        break if index >= array_receiver.size

        predicate_result = invoke_callback(
          callback,
          [array_receiver[index], index, array_receiver] of Value,
          "Array.findIndex"
        )
        return index if runtime_truthy?(predicate_result)
        index += 1
      end

      -1
    end

    private def array_includes(receiver : Value, args : Array(Value)) : Value
      assert_arity_between(args, 1, 2, "Array.includes")
      needle = args[0]
      array_receiver = receiver_array(receiver, "Array.includes")
      start_index = args.size == 2 ? normalize_index_argument(args[1], "Array.includes", array_receiver.size) : 0

      index = start_index
      while index < array_receiver.size
        return true if array_value_equals?(array_receiver[index], needle)
        index += 1
      end

      false
    end

    private def array_index_of(receiver : Value, args : Array(Value)) : Value
      assert_arity_between(args, 1, 2, "Array.indexOf")
      needle = args[0]
      array_receiver = receiver_array(receiver, "Array.indexOf")
      start_index = args.size == 2 ? normalize_index_argument(args[1], "Array.indexOf", array_receiver.size) : 0

      index = start_index
      while index < array_receiver.size
        return index if array_value_equals?(array_receiver[index], needle)
        index += 1
      end

      -1
    end

    private def array_join(receiver : Value, args : Array(Value)) : Value
      assert_arity_between(args, 0, 1, "Array.join")
      separator = args.empty? ? "," : runtime_to_string(args[0])
      array_receiver = receiver_array(receiver, "Array.join")
      array_receiver.map { |item| runtime_to_string(item) }.join(separator)
    end

    private def array_last_index_of(receiver : Value, args : Array(Value)) : Value
      assert_arity_between(args, 1, 2, "Array.lastIndexOf")
      needle = args[0]
      array_receiver = receiver_array(receiver, "Array.lastIndexOf")
      index = if args.size == 2
                normalize_last_index_argument(args[1], "Array.lastIndexOf", array_receiver.size)
              else
                array_receiver.size - 1
              end

      while index >= 0
        return index if array_value_equals?(array_receiver[index], needle)
        index -= 1
      end

      -1
    end

    private def array_pop(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "Array.pop")
      array_receiver = receiver_array(receiver, "Array.pop")
      return UNDEFINED if array_receiver.empty?

      array_receiver.pop
    end

    private def array_push(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 1, "Array.push")
      array_receiver = receiver_array(receiver, "Array.push")
      array_receiver << args[0]
      array_receiver.size
    end

    private def array_reverse(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "Array.reverse")
      array_receiver = receiver_array(receiver, "Array.reverse")
      left = 0
      right = array_receiver.size - 1

      while left < right
        tmp = array_receiver[left]
        array_receiver[left] = array_receiver[right]
        array_receiver[right] = tmp
        left += 1
        right -= 1
      end

      array_receiver
    end

    private def array_shift(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "Array.shift")
      array_receiver = receiver_array(receiver, "Array.shift")
      return UNDEFINED if array_receiver.empty?

      array_receiver.shift
    end

    private def array_slice(receiver : Value, args : Array(Value)) : Value
      assert_arity_between(args, 0, 2, "Array.slice")
      array_receiver = receiver_array(receiver, "Array.slice")
      size = array_receiver.size
      start_index = args.size >= 1 ? normalize_slice_index(integer_argument(args[0], "Array.slice"), size) : 0
      end_index = args.size == 2 ? normalize_slice_index(integer_argument(args[1], "Array.slice"), size) : size
      return [] of Value if end_index <= start_index

      result = Array(Value).new(end_index - start_index)
      index = start_index
      while index < end_index
        result << array_receiver[index]
        index += 1
      end

      result
    end

    private def array_sort(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "Array.sort")
      array_receiver = receiver_array(receiver, "Array.sort")
      array_receiver.sort! { |left, right| runtime_to_string(left) <=> runtime_to_string(right) }
      array_receiver
    end

    private def array_to_string(receiver : Value, args : Array(Value)) : Value
      assert_arity(args, 0, "Array.toString")
      array_receiver = receiver_array(receiver, "Array.toString")
      array_receiver.map { |item| runtime_to_string(item) }.join(",")
    end

    private def array_unshift(receiver : Value, args : Array(Value)) : Value
      array_receiver = receiver_array(receiver, "Array.unshift")
      return array_receiver.size if args.empty?

      result = Array(Value).new(array_receiver.size + args.size)
      args.each { |arg| result << arg }
      array_receiver.each { |value| result << value }

      array_receiver.clear
      result.each { |value| array_receiver << value }

      array_receiver.size
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

    private def callback_argument(value : Value, method_name : String) : Value
      return value if value.is_a?(BuiltinFunction)
      return value if value.is_a?(UserFunction)
      raise ExpressionError.new("Error: #{method_name} expects a function argument")
    end

    private def invoke_callback(callback : Value, args : Array(Value), method_name : String) : Value
      invoker = @@callback_invoker
      unless invoker
        raise ExpressionError.new("Error: #{method_name} callback invoker is not configured")
      end

      invoker.call(callback, args)
    end

    private def string_argument(value : Value, method_name : String) : String
      return value if value.is_a?(String)
      raise ExpressionError.new("Error: #{method_name} expects a string argument")
    end

    private def integer_argument(value : Value, method_name : String) : Int32
      return value if value.is_a?(Int32)
      raise ExpressionError.new("Error: #{method_name} expects an integer argument")
    end

    private def normalize_slice_index(index : Int32, size : Int32) : Int32
      if index < 0
        normalized = size + index
        return 0 if normalized < 0
        return normalized
      end

      return size if index > size
      index
    end

    private def normalize_index_argument(value : Value, method_name : String, size : Int32) : Int32
      index = integer_argument(value, method_name)
      normalize_slice_index(index, size)
    end

    private def normalize_last_index_argument(value : Value, method_name : String, size : Int32) : Int32
      index = integer_argument(value, method_name)

      if index < 0
        normalized = size + index
        return -1 if normalized < 0
        return normalized
      end

      return size - 1 if index >= size
      index
    end

    private def array_value_equals?(left : Value, right : Value) : Bool
      if left.is_a?(Int32) || left.is_a?(Float64)
        return false unless right.is_a?(Int32) || right.is_a?(Float64)

        left_number = left.to_f64
        right_number = right.to_f64
        return true if left_number.nan? && right_number.nan?
        return left_number == right_number
      end

      if left.is_a?(String)
        return right.is_a?(String) && left == right
      end

      if left.is_a?(Bool)
        return right.is_a?(Bool) && left == right
      end

      if left.nil?
        return right.nil?
      end

      if left.is_a?(UndefinedValue)
        return right.is_a?(UndefinedValue)
      end

      if left.is_a?(Array(Value))
        return right.is_a?(Array(Value)) && left.object_id == right.object_id
      end

      if left.is_a?(Hash(String, Value))
        return right.is_a?(Hash(String, Value)) && left.object_id == right.object_id
      end

      if left.is_a?(BuiltinFunction)
        return right.is_a?(BuiltinFunction) && left.object_id == right.object_id
      end

      if left.is_a?(UserFunction)
        return right.is_a?(UserFunction) && left.object_id == right.object_id
      end

      false
    end

    private def runtime_truthy?(value : Value) : Bool
      return false if value.nil?
      return false if value.is_a?(UndefinedValue)

      if value.is_a?(Bool)
        return value
      end

      if value.is_a?(String)
        return !value.empty?
      end

      if value.is_a?(Int32)
        return value != 0
      end

      if value.is_a?(Float64)
        return value != 0.0
      end

      true
    end

    private def clamp_substring_index(index : Int32, size : Int32) : Int32
      return 0 if index < 0
      return size if index > size
      index
    end

    private def build_padding(pad_string : String, desired_length : Int32) : String
      return "" if desired_length <= 0

      String.build do |builder|
        chars_written = 0
        while chars_written < desired_length
          pad_string.each_char do |char|
            break if chars_written >= desired_length

            builder << char
            chars_written += 1
          end
        end
      end
    end

    private def string_range_by_char_index(string : String, start_index : Int32, end_index : Int32) : String
      return "" if end_index <= start_index

      String.build do |builder|
        char_index = 0
        string.each_char do |char|
          break if char_index >= end_index

          if char_index >= start_index
            builder << char
          end

          char_index += 1
        end
      end
    end

    private def assert_arity(args : Array(Value), expected : Int32, method_name : String)
      return if args.size == expected

      raise ExpressionError.new("Error: #{method_name} expects #{expected} arguments but got #{args.size}")
    end

    private def assert_arity_between(args : Array(Value), min : Int32, max : Int32, method_name : String)
      return if args.size >= min && args.size <= max

      raise ExpressionError.new("Error: #{method_name} expects between #{min} and #{max} arguments but got #{args.size}")
    end
  end
end
