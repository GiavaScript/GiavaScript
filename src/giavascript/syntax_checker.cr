module GiavaScript
  class SyntaxChecker
    include StatementParserShared

    def initialize
      @source = ""
    end

    def errors(source : String) : Array(String)
      collected = [] of String
      check_source(source, collected)
      collected
    end

    private def check_source(source : String, errors : Array(String))
      tokenizer = StatementTokenizer.new(source)

      loop do
        statement_source = begin
          tokenizer.next_statement
        rescue ex : ExpressionError
          errors << (ex.message || "Error: invalid statement")
          break
        end

        break unless statement_source

        statement_source = statement_source.strip
        next if statement_source.empty?

        statement = begin
          parse_statement_source(statement_source)
        rescue ex : ExpressionError
          errors << (ex.message || "Error: invalid statement")
          next
        end

        check_node(statement, errors)
      end
    end

    private def check_node(statement : Statement, errors : Array(String))
      case statement
      when RawStatement
        check_raw(statement.source, errors)
      when BlockStatement
        statement.statements.each { |inner| check_node(inner, errors) }
      when IfStatement
        check_node(statement.then_branch, errors)
        statement.else_branch.try { |branch| check_node(branch, errors) }
      when ForStatement
        statement.init.try { |init| check_raw(init.source, errors) }
        statement.update.try { |update| check_raw(update.source, errors) }
        check_node(statement.body, errors)
      when ForOfStatement, ForInStatement, WhileStatement, DoWhileStatement
        check_node(statement.body, errors)
      when SwitchStatement
        statement.clauses.each do |clause|
          clause.statements.each { |inner| check_node(inner, errors) }
        end
      when TryStatement
        check_node(statement.try_branch, errors)
        statement.catch_branch.try { |branch| check_node(branch, errors) }
        statement.finally_branch.try { |branch| check_node(branch, errors) }
      end
    end

    private def check_raw(source : String, errors : Array(String))
      source = source.strip
      return if source.empty?
      return if source == "break" || source == "continue"

      if starts_with_keyword_in_source?(source, "function")
        check_function(source, errors)
        return
      end

      if match = source.match(/^(var|let|const)\s+([\[{][\s\S]*)$/)
        declaration = AssignmentSplitter.split(match[2].strip)
        unless declaration
          errors << "Error: destructuring declaration requires an initializer"
          return
        end

        check_pattern(declaration[:lhs], errors)
        check_expression(declaration[:rhs], errors)
        return
      end

      if match = source.match(/^(var|let|const)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)\s*([\s\S]+)$/)
        check_expression(match[3].strip, errors)
        return
      end

      if source.matches?(/^(var|let|const)\s+[A-Za-z_][A-Za-z0-9_]*$/)
        return
      end

      if match = source.match(/^throw(?:\s+([\s\S]+))?$/)
        match[1]?.try { |expression| check_expression(expression.strip, errors) }
        return
      end

      if match = source.match(/^return(?:\s+(.+))?$/m)
        match[1]?.try { |expression| check_expression(expression.strip, errors) }
        return
      end

      if match = source.match(/^(.+?)\s*(\+\+|--)$/)
        check_expression(match[1].strip, errors)
        return
      end

      if assignment = AssignmentSplitter.split(source)
        if assignment[:operator] == "=" && (assignment[:lhs].starts_with?('[') || assignment[:lhs].starts_with?('{'))
          check_pattern(assignment[:lhs], errors)
        end

        check_expression(assignment[:rhs], errors)
        return
      end

      check_expression(source, errors)
    end

    private def check_function(source : String, errors : Array(String))
      expression = begin
        ExpressionParser.new(source).parse
      rescue ex : ExpressionError
        errors << (ex.message || "Error: invalid function definition")
        return
      end

      if expression.is_a?(FunctionExpr)
        check_source(expression.body_source, errors)
      else
        errors << "Error: invalid function definition"
      end
    end

    private def check_pattern(source : String, errors : Array(String))
      BindingPatternParser.new(source).parse
    rescue ex : ExpressionError
      errors << (ex.message || "Error: invalid destructuring pattern")
    end

    private def check_expression(source : String, errors : Array(String))
      ExpressionParser.new(source).parse
    rescue ex : ExpressionError
      errors << (ex.message || "Error: invalid right-hand side '#{source}'")
    end
  end
end
