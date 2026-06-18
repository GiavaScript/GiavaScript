module GiavaScript
  module InterpreterBuiltins
    private def build_global_env : Environment
      env = Environment.new
      env["console"] = build_console_object
      env["JSON"] = build_json_object
      env["Math"] = build_math_object
      env["Array"] = build_array_object
      env["Object"] = build_object_object
      env["Date"] = build_date_object
      env["String"] = build_string_object
      env["RegExp"] = build_regexp_object
      env["parseInt"] = build_parse_int_function
      env["parseFloat"] = build_parse_float_function
      env["isNaN"] = build_is_nan_function
      env
    end

    private def build_object_object : Hash(String, Value)
      object = Hash(String, Value).new

      object["assign"] = BuiltinFunction.new("Object.assign", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Object.assign")
        assert_builtin_arity_at_least(args, 1, "Object.assign")

        target = object_argument(args[0], "Object.assign", 0)

        if args.size >= 2
          index = 1
          while index < args.size
            source = object_argument(args[index], "Object.assign", index)
            source.each do |key, value|
              target[key] = value
            end
            index += 1
          end
        end

        target.as(Value)
      end)

      object["hasOwn"] = BuiltinFunction.new("Object.hasOwn", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Object.hasOwn")
        assert_builtin_arity(args, 2, "Object.hasOwn")

        target = object_argument(args[0], "Object.hasOwn", 0)
        property_key = property_key_argument(args[1], "Object.hasOwn", 1)
        target.has_key?(property_key).as(Value)
      end)

      object["keys"] = BuiltinFunction.new("Object.keys", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Object.keys")
        assert_builtin_arity(args, 1, "Object.keys")

        target = object_argument(args[0], "Object.keys", 0)
        keys = Array(Value).new(target.size)
        target.each_key { |key| keys << key }
        keys.as(Value)
      end)

      object["values"] = BuiltinFunction.new("Object.values", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Object.values")
        assert_builtin_arity(args, 1, "Object.values")

        target = object_argument(args[0], "Object.values", 0)
        values = Array(Value).new(target.size)
        target.each_value { |value| values << value }
        values.as(Value)
      end)

      object["entries"] = BuiltinFunction.new("Object.entries", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Object.entries")
        assert_builtin_arity(args, 1, "Object.entries")

        target = object_argument(args[0], "Object.entries", 0)
        entries = Array(Value).new(target.size)
        target.each do |key, value|
          entries << [key.as(Value), value] of Value
        end
        entries.as(Value)
      end)

      object
    end

    private def build_array_object : Hash(String, Value)
      array = Hash(String, Value).new

      array["isArray"] = BuiltinFunction.new("Array.isArray", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Array.isArray")
        assert_builtin_arity(args, 1, "Array.isArray")
        args[0].is_a?(Array(Value)).as(Value)
      end)

      array["of"] = BuiltinFunction.new("Array.of", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Array.of")
        values = Array(Value).new(args.size)
        args.each { |arg| values << arg }
        values.as(Value)
      end)

      array
    end

    private def build_date_object : Hash(String, Value)
      date = Hash(String, Value).new

      date["now"] = BuiltinFunction.new("Date.now", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Date.now")
        assert_builtin_arity(args, 0, "Date.now")
        Time.utc.to_unix_ms.to_f64.as(Value)
      end)

      date["__construct"] = BuiltinFunction.new("Date", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Date")
        assert_builtin_arity(args, 0, "Date")
        DateValue.new(Time.utc.to_unix_ms.to_f64).as(Value)
      end)

      date
    end

    private def build_string_object : Hash(String, Value)
      string_object = Hash(String, Value).new

      string_object["fromCharCode"] = BuiltinFunction.new("String.fromCharCode", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "String.fromCharCode")

        String.build do |builder|
          args.each_with_index do |arg, index|
            code = number_argument(arg, "String.fromCharCode", index)
            code_unit = code.to_i32 & 0xFFFF
            builder << utf16_code_unit_to_string(code_unit)
          end
        end.as(Value)
      end)

      string_object
    end

    private def build_regexp_object : Hash(String, Value)
      regexp = Hash(String, Value).new

      regexp["__construct"] = BuiltinFunction.new("RegExp", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "RegExp")
        assert_builtin_arity_between(args, 1, 2, "RegExp")

        pattern : String
        flags : String = ""

        if args[0].is_a?(RegExpValue)
          source_regexp = args[0].as(RegExpValue)
          pattern = source_regexp.pattern
          flags = args.size >= 2 ? to_primitive_string_for_globals(args[1]) : source_regexp.flags
        elsif args[0].is_a?(String)
          pattern = args[0].as(String)
          flags = args.size >= 2 ? to_primitive_string_for_globals(args[1]) : ""
        else
          raise ExpressionError.new("Error: RegExp argument 1 must be a string or RegExp")
        end

        begin
          RegExpValue.new(pattern, flags).as(Value)
        rescue ex
          raise ExpressionError.new("Error: invalid RegExp pattern '#{pattern}'")
        end
      end)

      regexp
    end

    private def build_parse_int_function : Value
      BuiltinFunction.new("parseInt", ->(_receiver : Value, args : Array(Value)) do
        assert_builtin_arity_between(args, 1, 2, "parseInt")

        source = to_primitive_string_for_globals(args[0]).lstrip
        nan = Float64::NAN.as(Value)

        result = if source.empty?
                   nan
                 else
                   sign = 1
                   if source.starts_with?('+')
                     source = source[1...source.size]
                   elsif source.starts_with?('-')
                     sign = -1
                     source = source[1...source.size]
                   end

                   if source.empty?
                     nan
                   else
                     radix = 0
                     if args.size == 2
                       radix_number = number_argument(args[1], "parseInt", 1)
                       radix = radix_number.to_i32
                     end

                     if radix != 0 && (radix < 2 || radix > 36)
                       nan
                     else
                       if radix == 0
                         if source.starts_with?("0x") || source.starts_with?("0X")
                           radix = 16
                           source = source[2...source.size]
                         else
                           radix = 10
                         end
                       elsif radix == 16 && (source.starts_with?("0x") || source.starts_with?("0X"))
                         source = source[2...source.size]
                       end

                       value = 0.0
                       parsed_any_digit = false

                       source.each_char do |char|
                         digit = parse_int_digit_value(char)
                         break unless digit
                         break if digit >= radix

                         parsed_any_digit = true
                         value = value * radix + digit
                       end

                       if parsed_any_digit
                         value *= sign

                         if value.finite? && value >= Int32::MIN && value <= Int32::MAX
                           value.to_i32.as(Value)
                         else
                           value.as(Value)
                         end
                       else
                         nan
                       end
                     end
                   end
                 end

        result.as(Value)
      end)
    end

    private def build_parse_float_function : Value
      BuiltinFunction.new("parseFloat", ->(_receiver : Value, args : Array(Value)) do
        assert_builtin_arity(args, 1, "parseFloat")
        source = to_primitive_string_for_globals(args[0]).lstrip
        nan = Float64::NAN.as(Value)

        result = if match = source.match(/\A[+-]?(?:Infinity|(?:(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?))/)
                   token = match[0]

                   if token == "Infinity" || token == "+Infinity"
                     Float64::INFINITY.as(Value)
                   elsif token == "-Infinity"
                     (-Float64::INFINITY).as(Value)
                   else
                     parsed = token.to_f64?
                     parsed ? parsed.as(Value) : nan
                   end
                 else
                   nan
                 end

        result.as(Value)
      end)
    end

    private def build_is_nan_function : Value
      BuiltinFunction.new("isNaN", ->(_receiver : Value, args : Array(Value)) do
        assert_builtin_arity(args, 1, "isNaN")
        number = coerce_to_number_for_globals(args[0])
        (number.is_a?(Float64) && number.nan?).as(Value)
      end)
    end

    private def build_console_object : Hash(String, Value)
      console = Hash(String, Value).new

      console["log"] = BuiltinFunction.new("console.log", ->(receiver : Value, args : Array(Value)) do
        unless receiver.is_a?(Hash(String, Value))
          raise ExpressionError.new("Error: console.log receiver must be an object")
        end

        @console_output.puts(args.map { |arg| console_value_to_s(arg) }.join(" "))
        UNDEFINED.as(Value)
      end)

      console
    end

    private def console_value_to_s(value : Value) : String
      return "null" if value.nil?
      return "undefined" if value.is_a?(UndefinedValue)
      return format_number_for_output(value) if value.is_a?(Int32) || value.is_a?(Float64)
      return value if value.is_a?(String)

      if value.is_a?(Array(Value))
        return "[#{value.map { |item| console_value_to_s(item) }.join(", ")}]"
      end

      if value.is_a?(Hash(String, Value))
        properties = value.map do |key, property_value|
          "\"#{console_value_to_s(key)}\": #{console_value_to_s(property_value)}"
        end
        return "{#{properties.join(", ")}}"
      end

      if value.is_a?(RegExpValue)
        return value.to_s
      end

      value.to_s
    end

    private def format_number_for_output(value : Number) : String
      return value.to_s if value.is_a?(Int32)

      float_value = value.to_f64
      return float_value.to_s unless float_value.finite?

      if float_value == float_value.round && float_value.abs >= 1_000_000_000.0
        return float_value.round.to_i64.to_s
      end

      float_value.to_s
    end

    private def build_json_object : Hash(String, Value)
      json = Hash(String, Value).new

      json["parse"] = BuiltinFunction.new("JSON.parse", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "JSON.parse")
        assert_builtin_arity(args, 1, "JSON.parse")

        source = args[0]
        unless source.is_a?(String)
          raise ExpressionError.new("Error: JSON.parse argument 1 must be a string")
        end

        begin
          json_any_to_value(::JSON.parse(source)).as(Value)
        rescue ::JSON::ParseException
          raise ExpressionError.new("Error: JSON.parse argument 1 must be valid JSON")
        end
      end)

      json["stringify"] = BuiltinFunction.new("JSON.stringify", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "JSON.stringify")
        assert_builtin_arity(args, 1, "JSON.stringify")

        value = args[0]
        if value.is_a?(UndefinedValue) || value.is_a?(BuiltinFunction) || value.is_a?(UserFunction)
          UNDEFINED.as(Value)
        else
          io = IO::Memory.new
          json_stringify_into(io, value, Set(UInt64).new, 0)
          io.to_s.as(Value)
        end
      end)

      json
    end

    private def build_math_object : Hash(String, Value)
      math = Hash(String, Value).new

      math["E"] = 2.718281828459045
      math["LN10"] = 2.302585092994046
      math["LN2"] = 0.6931471805599453
      math["LOG10E"] = 0.4342944819032518
      math["LOG2E"] = 1.4426950408889634
      math["PI"] = 3.141592653589793
      math["SQRT1_2"] = 0.7071067811865476
      math["SQRT2"] = 1.4142135623730951

      math["sqrt"] = BuiltinFunction.new("Math.sqrt", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.sqrt")
        Math.sqrt(unary_number_arg_f64(args, "Math.sqrt")).as(Value)
      end)

      math["abs"] = BuiltinFunction.new("Math.abs", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.abs")
        assert_builtin_arity(args, 1, "Math.abs")
        value = number_argument(args[0], "Math.abs", 0)
        if value.is_a?(Int32)
          value.abs.as(Value)
        else
          value.abs.to_f64.as(Value)
        end
      end)

      math["acos"] = BuiltinFunction.new("Math.acos", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.acos")
        Math.acos(unary_number_arg_f64(args, "Math.acos")).as(Value)
      end)

      math["acosh"] = BuiltinFunction.new("Math.acosh", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.acosh")
        Math.acosh(unary_number_arg_f64(args, "Math.acosh")).as(Value)
      end)

      math["asin"] = BuiltinFunction.new("Math.asin", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.asin")
        Math.asin(unary_number_arg_f64(args, "Math.asin")).as(Value)
      end)

      math["asinh"] = BuiltinFunction.new("Math.asinh", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.asinh")
        Math.asinh(unary_number_arg_f64(args, "Math.asinh")).as(Value)
      end)

      math["atan"] = BuiltinFunction.new("Math.atan", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.atan")
        Math.atan(unary_number_arg_f64(args, "Math.atan")).as(Value)
      end)

      math["atan2"] = BuiltinFunction.new("Math.atan2", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.atan2")
        y, x = binary_number_args_f64(args, "Math.atan2")
        Math.atan2(y, x).as(Value)
      end)

      math["atanh"] = BuiltinFunction.new("Math.atanh", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.atanh")
        Math.atanh(unary_number_arg_f64(args, "Math.atanh")).as(Value)
      end)

      math["cbrt"] = BuiltinFunction.new("Math.cbrt", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.cbrt")
        Math.cbrt(unary_number_arg_f64(args, "Math.cbrt")).as(Value)
      end)

      math["ceil"] = BuiltinFunction.new("Math.ceil", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.ceil")
        unary_number_arg_f64(args, "Math.ceil").ceil.to_i32.as(Value)
      end)

      math["clz32"] = BuiltinFunction.new("Math.clz32", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.clz32")
        assert_builtin_arity(args, 1, "Math.clz32")
        value = number_argument(args[0], "Math.clz32", 0)
        number_to_uint32(value).leading_zeros_count.to_i32.as(Value)
      end)

      math["cos"] = BuiltinFunction.new("Math.cos", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.cos")
        Math.cos(unary_number_arg_f64(args, "Math.cos")).as(Value)
      end)

      math["cosh"] = BuiltinFunction.new("Math.cosh", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.cosh")
        Math.cosh(unary_number_arg_f64(args, "Math.cosh")).as(Value)
      end)

      math["exp"] = BuiltinFunction.new("Math.exp", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.exp")
        Math.exp(unary_number_arg_f64(args, "Math.exp")).as(Value)
      end)

      math["expm1"] = BuiltinFunction.new("Math.expm1", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.expm1")
        Math.expm1(unary_number_arg_f64(args, "Math.expm1")).as(Value)
      end)

      math["f16round"] = BuiltinFunction.new("Math.f16round", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.f16round")
        math_f16round(unary_number_arg_f64(args, "Math.f16round")).as(Value)
      end)

      math["floor"] = BuiltinFunction.new("Math.floor", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.floor")
        unary_number_arg_f64(args, "Math.floor").floor.to_i32.as(Value)
      end)

      math["fround"] = BuiltinFunction.new("Math.fround", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.fround")
        unary_number_arg_f64(args, "Math.fround").to_f32.to_f64.as(Value)
      end)

      math["hypot"] = BuiltinFunction.new("Math.hypot", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.hypot")

        case args.size
        when 0
          0.0.as(Value)
        when 1
          number_argument(args[0], "Math.hypot", 0).to_f64.abs.as(Value)
        when 2
          x = number_argument(args[0], "Math.hypot", 0).to_f64
          y = number_argument(args[1], "Math.hypot", 1).to_f64
          Math.hypot(x, y).as(Value)
        else
          max_value = 0.0
          sum = 0.0
          encountered_nan = false
          encountered_infinity = false

          index = 0
          while index < args.size
            value = number_argument(args[index], "Math.hypot", index).to_f64
            if value.nan?
              encountered_nan = true
            else
              absolute = value.abs
              if absolute.infinite?
                encountered_infinity = true
              elsif absolute > max_value
                ratio = max_value == 0.0 ? 0.0 : max_value / absolute
                sum = sum * ratio * ratio + 1.0
                max_value = absolute
              elsif absolute != 0.0
                ratio = absolute / max_value
                sum += ratio * ratio
              end
            end

            index += 1
          end

          if encountered_infinity
            Float64::INFINITY.as(Value)
          elsif encountered_nan
            Float64::NAN.as(Value)
          elsif max_value == 0.0
            0.0.as(Value)
          else
            (max_value * Math.sqrt(sum)).as(Value)
          end
        end
      end)

      math["imul"] = BuiltinFunction.new("Math.imul", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.imul")
        assert_builtin_arity(args, 2, "Math.imul")
        left = number_to_uint32(number_argument(args[0], "Math.imul", 0))
        right = number_to_uint32(number_argument(args[1], "Math.imul", 1))
        (left &* right).unsafe_as(Int32).as(Value)
      end)

      math["log"] = BuiltinFunction.new("Math.log", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.log")
        Math.log(unary_number_arg_f64(args, "Math.log")).as(Value)
      end)

      math["log10"] = BuiltinFunction.new("Math.log10", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.log10")
        Math.log10(unary_number_arg_f64(args, "Math.log10")).as(Value)
      end)

      math["log1p"] = BuiltinFunction.new("Math.log1p", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.log1p")
        Math.log1p(unary_number_arg_f64(args, "Math.log1p")).as(Value)
      end)

      math["log2"] = BuiltinFunction.new("Math.log2", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.log2")
        Math.log2(unary_number_arg_f64(args, "Math.log2")).as(Value)
      end)

      math["max"] = BuiltinFunction.new("Math.max", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.max")
        if args.empty?
          (-Float64::INFINITY).as(Value)
        else
          max_value = number_argument(args[0], "Math.max", 0).to_f64
          index = 1
          while index < args.size
            value = number_argument(args[index], "Math.max", index).to_f64
            max_value = value if value > max_value
            index += 1
          end
          max_value.as(Value)
        end
      end)

      math["min"] = BuiltinFunction.new("Math.min", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.min")
        if args.empty?
          Float64::INFINITY.as(Value)
        else
          min_value = number_argument(args[0], "Math.min", 0).to_f64
          index = 1
          while index < args.size
            value = number_argument(args[index], "Math.min", index).to_f64
            min_value = value if value < min_value
            index += 1
          end
          min_value.as(Value)
        end
      end)

      math["pow"] = BuiltinFunction.new("Math.pow", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.pow")
        base, exponent = binary_number_args_f64(args, "Math.pow")
        (base ** exponent).as(Value)
      end)

      math["random"] = BuiltinFunction.new("Math.random", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.random")
        assert_builtin_arity(args, 0, "Math.random")
        rand.as(Value)
      end)

      math["round"] = BuiltinFunction.new("Math.round", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.round")
        unary_number_arg_f64(args, "Math.round").round.to_i32.as(Value)
      end)

      math["sign"] = BuiltinFunction.new("Math.sign", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.sign")
        assert_builtin_arity(args, 1, "Math.sign")

        value = unary_number_arg_f64(args, "Math.sign")
        if value < 0
          -1.as(Value)
        elsif value > 0
          1.as(Value)
        else
          0.as(Value)
        end
      end)

      math["sin"] = BuiltinFunction.new("Math.sin", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.sin")
        Math.sin(unary_number_arg_f64(args, "Math.sin")).as(Value)
      end)

      math["sinh"] = BuiltinFunction.new("Math.sinh", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.sinh")
        Math.sinh(unary_number_arg_f64(args, "Math.sinh")).as(Value)
      end)

      math["sumPrecise"] = BuiltinFunction.new("Math.sumPrecise", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.sumPrecise")

        if args.empty?
          0.0.as(Value)
        elsif args.size == 1
          number_argument(args[0], "Math.sumPrecise", 0).to_f64.as(Value)
        else
          sum = 0.0
          compensation = 0.0

          index = 0
          while index < args.size
            value = number_argument(args[index], "Math.sumPrecise", index).to_f64
            y = value - compensation
            t = sum + y
            compensation = (t - sum) - y
            sum = t
            index += 1
          end

          sum.as(Value)
        end
      end)

      math["tan"] = BuiltinFunction.new("Math.tan", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.tan")
        Math.tan(unary_number_arg_f64(args, "Math.tan")).as(Value)
      end)

      math["tanh"] = BuiltinFunction.new("Math.tanh", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.tanh")
        Math.tanh(unary_number_arg_f64(args, "Math.tanh")).as(Value)
      end)

      math["trunc"] = BuiltinFunction.new("Math.trunc", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.trunc")
        unary_number_arg_f64(args, "Math.trunc").trunc.to_i32.as(Value)
      end)

      math
    end

    private def assert_builtin_receiver_object(receiver : Value, method_name : String)
      return if receiver.is_a?(Hash(String, Value))

      raise ExpressionError.new("Error: #{method_name} receiver must be an object")
    end

    private def assert_builtin_arity(args : Array(Value), expected : Int32, method_name : String)
      return if args.size == expected

      raise ExpressionError.new("Error: #{method_name} expects #{expected} arguments but got #{args.size}")
    end

    private def assert_builtin_arity_between(args : Array(Value), min : Int32, max : Int32, method_name : String)
      return if args.size >= min && args.size <= max

      raise ExpressionError.new("Error: #{method_name} expects between #{min} and #{max} arguments but got #{args.size}")
    end

    private def assert_builtin_arity_at_least(args : Array(Value), minimum : Int32, method_name : String)
      return if args.size >= minimum

      raise ExpressionError.new("Error: #{method_name} expects at least #{minimum} arguments but got #{args.size}")
    end

    private def number_argument(value : Value, method_name : String, index : Int32) : Number
      return value if value.is_a?(Int32)
      return value if value.is_a?(Float64)

      raise ExpressionError.new("Error: #{method_name} argument #{index + 1} must be a number")
    end

    private def object_argument(value : Value, method_name : String, index : Int32) : Hash(String, Value)
      return value if value.is_a?(Hash(String, Value))

      raise ExpressionError.new("Error: #{method_name} argument #{index + 1} must be an object")
    end

    private def property_key_argument(value : Value, method_name : String, index : Int32) : String
      case value
      when String
        value
      when Int32, Float64, Bool, Nil, UndefinedValue
        value.to_s
      else
        raise ExpressionError.new("Error: #{method_name} argument #{index + 1} must be a string, number, boolean, null, or undefined")
      end
    end

    private def unary_number_arg_f64(args : Array(Value), method_name : String) : Float64
      assert_builtin_arity(args, 1, method_name)
      number_argument(args[0], method_name, 0).to_f64
    end

    private def binary_number_args_f64(args : Array(Value), method_name : String) : Tuple(Float64, Float64)
      assert_builtin_arity(args, 2, method_name)
      {
        number_argument(args[0], method_name, 0).to_f64,
        number_argument(args[1], method_name, 1).to_f64,
      }
    end

    private def number_to_uint32(value : Number) : UInt32
      if value.is_a?(Int32)
        value.unsafe_as(UInt32)
      else
        number_to_uint32(value.to_f64)
      end
    end

    private def number_to_uint32(value : Float64) : UInt32
      return 0_u32 if value.nan? || value.infinite? || value == 0.0

      two32 = 4_294_967_296.0
      reduced = value.trunc % two32
      reduced += two32 if reduced < 0
      reduced.to_u64.to_u32
    end

    private def math_f16round(value : Float64) : Float64
      return value if value.nan? || value.infinite? || value == 0.0

      bits = value.to_f32.unsafe_as(UInt32)
      sign = (bits >> 16) & 0x8000_u32
      exponent = ((bits >> 23) & 0xFF_u32).to_i32
      mantissa = bits & 0x007F_FFFF_u32

      half = if exponent == 0xFF
               sign | 0x7C00_u32 | (mantissa >> 13)
             else
               adjusted_exponent = exponent - 127 + 15

               if adjusted_exponent >= 0x1F
                 sign | 0x7C00_u32
               elsif adjusted_exponent <= 0
                 if adjusted_exponent < -10
                   sign
                 else
                   mantissa_with_hidden_bit = mantissa | 0x0080_0000_u32
                   shift = 14 - adjusted_exponent
                   rounded_mantissa = mantissa_with_hidden_bit >> shift
                   remainder = mantissa_with_hidden_bit & ((1_u32 << shift) - 1)
                   midpoint = 1_u32 << (shift - 1)

                   if remainder > midpoint || (remainder == midpoint && (rounded_mantissa & 1_u32) == 1_u32)
                     rounded_mantissa += 1
                   end

                   sign | rounded_mantissa
                 end
               else
                 half_exponent = (adjusted_exponent << 10).to_u32
                 rounded_mantissa = mantissa >> 13
                 remainder = mantissa & 0x1FFF_u32

                 if remainder > 0x1000_u32 || (remainder == 0x1000_u32 && (rounded_mantissa & 1_u32) == 1_u32)
                   rounded_mantissa += 1
                   if rounded_mantissa == 0x400_u32
                     rounded_mantissa = 0_u32
                     half_exponent += 0x0400_u32
                     half_exponent = 0x7C00_u32 if half_exponent >= 0x7C00_u32
                   end
                 end

                 sign | half_exponent | rounded_mantissa
               end
             end

      half_to_f64(half)
    end

    private def half_to_f64(half : UInt32) : Float64
      sign32 = (half & 0x8000_u32) << 16
      exponent = (half >> 10) & 0x1F_u32
      mantissa = half & 0x03FF_u32

      bits32 = if exponent == 0
                 if mantissa == 0
                   sign32
                 else
                   normalized = mantissa
                   exponent_value = -14
                   while (normalized & 0x0400_u32) == 0
                     normalized <<= 1
                     exponent_value -= 1
                   end
                   normalized &= 0x03FF_u32
                   exponent32 = (exponent_value + 127).to_u32 << 23
                   sign32 | exponent32 | (normalized << 13)
                 end
               elsif exponent == 0x1F
                 sign32 | 0x7F80_0000_u32 | (mantissa << 13)
               else
                 exponent32 = ((exponent.to_i32 - 15 + 127).to_u32) << 23
                 sign32 | exponent32 | (mantissa << 13)
               end

      bits32.unsafe_as(Float32).to_f64
    end

    private def parse_int_digit_value(char : Char) : Int32?
      if char.ascii_number?
        return char.ord - '0'.ord
      end

      lower = char.downcase
      return nil unless lower >= 'a' && lower <= 'z'

      lower.ord - 'a'.ord + 10
    end

    private def utf16_code_unit_to_string(code_unit : Int32) : String
      return code_unit.chr.to_s unless code_unit >= 0xD800 && code_unit <= 0xDFFF

      "\\u#{code_unit.to_s(16).rjust(4, '0')}"
    end

    private def coerce_to_number_for_globals(value : Value) : Number
      return value if value.is_a?(Int32)
      return value if value.is_a?(Float64)
      return value ? 1 : 0 if value.is_a?(Bool)
      return 0 if value.nil?
      return Float64::NAN if value.is_a?(UndefinedValue)

      if value.is_a?(String)
        trimmed = value.strip
        return 0 if trimmed.empty?

        parsed = trimmed.to_f64?
        return parsed if parsed

        return Float64::NAN
      end

      if value.is_a?(Array(Value))
        return coerce_to_number_for_globals(array_to_global_number_string(value))
      end

      Float64::NAN
    end

    private def to_primitive_string_for_globals(value : Value) : String
      return "null" if value.nil?
      return "undefined" if value.is_a?(UndefinedValue)

      if value.is_a?(Bool)
        return value ? "true" : "false"
      end

      if value.is_a?(Array(Value))
        return array_to_global_number_string(value)
      end

      if value.is_a?(Hash(String, Value))
        return "[object Object]"
      end

      if value.is_a?(BuiltinFunction)
        return "function"
      end

      if value.is_a?(UserFunction)
        return "function"
      end

      if value.is_a?(RegExpValue)
        return value.to_s
      end

      value.to_s
    end

    private def array_to_global_number_string(values : Array(Value)) : String
      values.map { |item| global_array_element_to_string(item) }.join(",")
    end

    private def global_array_element_to_string(value : Value) : String
      return "" if value.nil? || value.is_a?(UndefinedValue)

      if value.is_a?(Array(Value))
        return array_to_global_number_string(value)
      end

      if value.is_a?(Hash(String, Value))
        return "[object Object]"
      end

      if value.is_a?(BuiltinFunction)
        return "function"
      end

      if value.is_a?(UserFunction)
        return "function"
      end

      if value.is_a?(RegExpValue)
        return value.to_s
      end

      if value.is_a?(Bool)
        return value ? "true" : "false"
      end

      value.to_s
    end
  end
end
