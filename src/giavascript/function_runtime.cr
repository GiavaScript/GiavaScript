module GiavaScript
  class FunctionRuntime
    IDENTIFIER_REGEX = /^[A-Za-z_][A-Za-z0-9_]*$/
    FUNCTION_NAME_REGEX = /^[A-Za-z_][A-Za-z0-9_]*$/

    record FunctionDefinition, parameters : Array(String), body : String

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

      raise ExpressionError.new("Error: invalid function name '#{function_name}'") unless function_name.matches?(FUNCTION_NAME_REGEX)

      parameters = parse_function_parameters(param_list)
      @functions[function_name] = FunctionDefinition.new(parameters, body)
    end

    def function_defined?(name : String) : Bool
      @functions.has_key?(name)
    end

    def invoke_function(name : String, args : Array(Value), outer_env : Hash(String, Value), &evaluate_statement : String, Hash(String, Value), Bool, Bool -> String?) : Value
      function = @functions[name]?
      raise ExpressionError.new("Error: function '#{name}' does not exist") unless function

      if args.size != function.parameters.size
        raise ExpressionError.new("Error: function '#{name}' expects #{function.parameters.size} arguments but got #{args.size}")
      end

      local_env = Hash(String, Value).new
      outer_env.each do |key, value|
        local_env[key] = value
      end

      function.parameters.each_with_index do |param, index|
        local_env[param] = args[index]
      end

      statements = StatementSplitter.new(function.body).split

      begin
        statements.each do |stmt|
          evaluate_statement.call(stmt, local_env, true, false)
        end
      rescue ex : ReturnSignal
        return ex.value
      end

      UNDEFINED
    end

    private def parse_function_parameters(param_list : String) : Array(String)
      return [] of String if param_list.empty?

      params = param_list.split(',').map(&.strip)
      parsed = [] of String

      params.each do |param|
        unless param.matches?(IDENTIFIER_REGEX)
          raise ExpressionError.new("Error: invalid parameter '#{param}'")
        end

        parsed << param
      end

      if parsed.uniq.size != parsed.size
        raise ExpressionError.new("Error: duplicate function parameters are not allowed")
      end

      parsed
    end
  end
end
