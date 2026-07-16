module GiavaScript
  class FunctionRuntime
    IDENTIFIER_REGEX = /^[A-Za-z_][A-Za-z0-9_]*$/

    record FunctionDefinition, parameters : Array(String), statements : Array(String), rest_parameter : String?, parameter_defaults : Hash(String, String)

    class ReturnSignal < Exception
      getter value : Value

      def initialize(@value : Value)
        super("return")
      end
    end

    def initialize
      @functions = Hash(String, FunctionDefinition).new
    end

    def define_function(stmt : String)
      name_match = stmt.match(/\Afunction\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/)
      raise ExpressionError.new("Error: invalid function definition") unless name_match

      function_name = name_match[1]
      raise ExpressionError.new("Error: invalid function name '#{function_name}'") unless function_name.matches?(IDENTIFIER_REGEX)

      param_start = name_match.end(0)
      param_end = find_matching_paren(stmt, param_start)
      raise ExpressionError.new("Error: invalid function definition") unless param_end

      param_list = stmt[param_start...param_end].strip

      rest = stmt[(param_end + 1)..].strip
      raise ExpressionError.new("Error: invalid function definition") unless rest.starts_with?('{')

      body_start = param_end + 1 + (stmt[(param_end + 1)..].index('{') || 0)
      body_end = find_matching_brace(stmt, body_start + 1)
      raise ExpressionError.new("Error: invalid function definition") unless body_end

      body = stmt[(body_start + 1)...body_end].strip

      result = parse_function_parameters(param_list)
      parameters = result[:parameters]
      rest_parameter = result[:rest_parameter]
      defaults = result[:defaults]
      statements = StatementSplitter.new(body).split
      @functions[function_name] = FunctionDefinition.new(parameters, statements, rest_parameter, defaults)
    end

    private def find_matching_paren(source : String, start : Int32) : Int32?
      depth = 0
      i = start
      string_delimiter = nil.as(Char?)
      escaping = false
      while i < source.size
        char = source[i]
        if delimiter = string_delimiter
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == delimiter
            string_delimiter = nil
          end
          i += 1
          next
        end
        case char
        when '"', '\'', '`'
          string_delimiter = char
        when '('
          depth += 1
        when ')'
          if depth == 0
            return i
          end
          depth -= 1
        end
        i += 1
      end
      nil
    end

    private def find_matching_brace(source : String, start : Int32) : Int32?
      depth = 0
      i = start
      string_delimiter = nil.as(Char?)
      escaping = false
      while i < source.size
        char = source[i]
        if delimiter = string_delimiter
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == delimiter
            string_delimiter = nil
          end
          i += 1
          next
        end
        case char
        when '"', '\'', '`'
          string_delimiter = char
        when '{'
          depth += 1
        when '}'
          if depth == 0
            return i
          end
          depth -= 1
        end
        i += 1
      end
      nil
    end

    def function_defined?(name : String) : Bool
      @functions.has_key?(name)
    end

    def function_parameter_count(name : String) : Int32?
      @functions[name]?.try(&.parameters.size)
    end

    def invoke_function(name : String, args : Array(Value), outer_env : Environment, evaluate_expression : Proc(String, Environment, Value)? = nil, &evaluate_statement : String, Environment, Bool, Bool -> String?) : Value
      function = @functions[name]?
      raise ExpressionError.new("Error: function '#{name}' does not exist") unless function

      min_args = function.parameters.size
      if function.rest_parameter.nil? && function.parameter_defaults.empty?
        if args.size < min_args
          raise ExpressionError.new("Error: function '#{name}' expects at least #{min_args} arguments but got #{args.size}")
        end
        if args.size != min_args
          raise ExpressionError.new("Error: function '#{name}' expects #{min_args} arguments but got #{args.size}")
        end
      else
        if args.size < min_args - function.parameter_defaults.size
          raise ExpressionError.new("Error: function '#{name}' expects at least #{min_args - function.parameter_defaults.size} arguments but got #{args.size}")
        end
        if function.rest_parameter.nil? && args.size > min_args
          raise ExpressionError.new("Error: function '#{name}' expects #{min_args} arguments but got #{args.size}")
        end
      end

      local_env = Environment.new(outer_env)

      function.parameters.each_with_index do |param, index|
        if index < args.size
          arg = args[index]
          if arg.is_a?(UndefinedValue) && function.parameter_defaults.has_key?(param) && evaluate_expression
            default_source = function.parameter_defaults[param]
            local_env[param] = evaluate_expression.call(default_source, local_env)
          else
            local_env[param] = arg
          end
        elsif function.parameter_defaults.has_key?(param) && evaluate_expression
          default_source = function.parameter_defaults[param]
          local_env[param] = evaluate_expression.call(default_source, local_env)
        else
          raise "BUG: missing argument for parameter '#{param}'"
        end
      end

      if rest_param = function.rest_parameter
        extra_count = args.size - min_args
        rest_values = extra_count > 0 ? args[min_args, extra_count] : Array(Value).new
        local_env[rest_param] = rest_values
      end

      begin
        function.statements.each do |stmt|
          evaluate_statement.call(stmt, local_env, true, false)
        end
      rescue ex : ReturnSignal
        return ex.value
      end

      UNDEFINED
    end

    private def parse_function_parameters(param_list : String) : NamedTuple(parameters: Array(String), rest_parameter: String?, defaults: Hash(String, String))
      params = param_list.empty? ? [] of String : split_param_list(param_list)
      parsed = [] of String
      rest_parameter = nil.as(String?)
      defaults = {} of String => String

      params.each do |param_raw|
        param = param_raw.lstrip
        if param.starts_with?("...")
          rest_param = param[3..].strip
          raise ExpressionError.new("Error: invalid parameter '#{param}'") unless rest_param.matches?(IDENTIFIER_REGEX)
          raise ExpressionError.new("Error: rest parameter must be last") if rest_parameter
          rest_parameter = rest_param
        else
          raise ExpressionError.new("Error: rest parameter must be last") if rest_parameter

          if param.includes?('=')
            eq_pos = find_default_eq_position(param)
            param_name = param[0...eq_pos].strip
            default_source = param[(eq_pos + 1)..].strip
            raise ExpressionError.new("Error: invalid parameter '#{param_name}'") unless param_name.matches?(IDENTIFIER_REGEX)
            raise ExpressionError.new("Error: invalid parameter '#{param}'") if default_source.empty?
            parsed << param_name
            defaults[param_name] = default_source
          else
            raise ExpressionError.new("Error: invalid parameter '#{param}'") unless param.matches?(IDENTIFIER_REGEX)
            parsed << param
          end
        end
      end

      all_params = parsed + (rest_parameter ? [rest_parameter] : [] of String)
      if all_params.uniq.size != all_params.size
        raise ExpressionError.new("Error: duplicate function parameters are not allowed")
      end

      {parameters: parsed, rest_parameter: rest_parameter, defaults: defaults}
    end

    private def split_param_list(param_list : String) : Array(String)
      result = [] of String
      current_start = 0
      i = 0
      paren_depth = 0
      bracket_depth = 0
      string_delimiter = nil.as(Char?)
      escaping = false

      while i < param_list.size
        char = param_list[i]

        if delimiter = string_delimiter
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == delimiter
            string_delimiter = nil
          end
          i += 1
          next
        end

        case char
        when '"', '\'', '`'
          string_delimiter = char
        when '('
          paren_depth += 1
        when ')'
          paren_depth -= 1
        when '['
          bracket_depth += 1
        when ']'
          bracket_depth -= 1
        when ','
          if paren_depth == 0 && bracket_depth == 0 && string_delimiter.nil?
            result << param_list[current_start...i]
            current_start = i + 1
          end
        end

        i += 1
      end

      result << param_list[current_start...i] if current_start < param_list.size
      result
    end

    private def find_default_eq_position(param : String) : Int32
      i = 0
      paren_depth = 0
      bracket_depth = 0
      string_delimiter = nil.as(Char?)
      escaping = false

      while i < param.size
        char = param[i]

        if delimiter = string_delimiter
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == delimiter
            string_delimiter = nil
          end
          i += 1
          next
        end

        case char
        when '"', '\'', '`'
          string_delimiter = char
        when '('
          paren_depth += 1
        when ')'
          paren_depth -= 1
        when '['
          bracket_depth += 1
        when ']'
          bracket_depth -= 1
        when '='
          if paren_depth == 0 && bracket_depth == 0 && string_delimiter.nil?
            return i
          end
        end

        i += 1
      end

      raise ExpressionError.new("Error: invalid parameter '#{param}'")
    end
  end
end
