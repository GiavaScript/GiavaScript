module GiavaScript
  class Environment
    @values : Hash(String, Value)
    @constants : Set(String)
    @parent : Environment?

    def initialize(@parent : Environment? = nil)
      @values = Hash(String, Value).new
      @constants = Set(String).new
    end

    def has_key?(name : String) : Bool
      lookup(name)[:found]
    end

    def lookup(name : String) : NamedTuple(found: Bool, value: Value)
      current = self
      loop do
        values = current.values
        if values.has_key?(name)
          return {found: true, value: values[name]}
        end

        parent = current.parent
        return {found: false, value: UNDEFINED} unless parent

        current = parent
      end
    end

    def [](name : String) : Value
      lookup_result = lookup(name)
      return lookup_result[:value] if lookup_result[:found]

      raise KeyError.new(name)
    end

    def []=(name : String, value : Value) : Value
      @values[name] = value
    end

    def local_lookup(name : String) : NamedTuple(found: Bool, value: Value)
      if @values.has_key?(name)
        {found: true, value: @values[name]}
      else
        {found: false, value: UNDEFINED}
      end
    end

    def set_local(name : String, value : Value) : Value
      @values[name] = value
    end

    def delete_local(name : String)
      @values.delete(name)
    end

    def declare_const(name : String, value : Value) : Value
      @constants << name
      @values[name] = value
    end

    def constant?(name : String) : Bool
      current = self
      loop do
        return true if current.constants.includes?(name)

        parent = current.parent
        return false unless parent

        current = parent
      end
    end

    protected getter values : Hash(String, Value)
    protected getter constants : Set(String)
    protected getter parent : Environment?
  end
end
