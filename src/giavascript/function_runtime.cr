module GiavaScript
  class FunctionRuntime
    IDENTIFIER_REGEX = /^[A-Za-z_][A-Za-z0-9_]*$/

    record FunctionDefinition, parameters : Array(String), statements : Array(String), rest_parameter : String?

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
      match = stmt.match(/\Afunction\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)\s*\{(.*)\}\s*\z/m)
      raise ExpressionError.new("Error: invalid function definition") unless match

      function_name = match[1]
      param_list = match[2].strip
      body = match[3].strip

      raise ExpressionError.new("Error: invalid function name '#{function_name}'") unless function_name.matches?(IDENTIFIER_REGEX)

      result = parse_function_parameters(param_list)
      parameters = result[:parameters]
      rest_parameter = result[:rest_parameter]
      statements = StatementSplitter.new(body).split
      @functions[function_name] = FunctionDefinition.new(parameters, statements, rest_parameter)
    end

    def function_defined?(name : String) : Bool
      @functions.has_key?(name)
    end

    def function_parameter_count(name : String) : Int32?
      @functions[name]?.try(&.parameters.size)
    end

    def invoke_function(name : String, args : Array(Value), outer_env : Environment, &evaluate_statement : String, Environment, Bool, Bool -> String?) : Value
      function = @functions[name]?
      raise ExpressionError.new("Error: function '#{name}' does not exist") unless function

      min_args = function.parameters.size
      if args.size < min_args
        raise ExpressionError.new("Error: function '#{name}' expects at least #{min_args} arguments but got #{args.size}")
      end

      if function.rest_parameter.nil? && args.size != min_args
        raise ExpressionError.new("Error: function '#{name}' expects #{min_args} arguments but got #{args.size}")
      end

      local_env = Environment.new(outer_env)

      function.parameters.each_with_index do |param, index|
        local_env[param] = args[index]
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

    private def parse_function_parameters(param_list : String) : NamedTuple(parameters: Array(String), rest_parameter: String?)
      params = param_list.empty? ? [] of String : param_list.split(',').map(&.strip)
      parsed = [] of String
      rest_parameter = nil.as(String?)

      params.each do |param|
        if param.starts_with?("...")
          rest_param = param[3..].strip
          raise ExpressionError.new("Error: invalid parameter '#{param}'") unless rest_param.matches?(IDENTIFIER_REGEX)
          raise ExpressionError.new("Error: rest parameter must be last") if rest_parameter
          rest_parameter = rest_param
        else
          raise ExpressionError.new("Error: rest parameter must be last") if rest_parameter
          unless param.matches?(IDENTIFIER_REGEX)
            raise ExpressionError.new("Error: invalid parameter '#{param}'")
          end
          parsed << param
        end
      end

      all_params = parsed + (rest_parameter ? [rest_parameter] : [] of String)
      if all_params.uniq.size != all_params.size
        raise ExpressionError.new("Error: duplicate function parameters are not allowed")
      end

      {parameters: parsed, rest_parameter: rest_parameter}
    end
  end
end
