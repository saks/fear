module Functional
  module Try
    # Returns `true` if the `Try` is a `Failure`, `false` otherwise.
    #
    def failure?
      fail NotImplementedError, "#{self.class.name}#failure?"
    end

    # Returns `true` if the `Try` is a `Success`, `false` otherwise.
    #
    def success?
      fail NotImplementedError, "#{self.class.name}#success?"
    end

    # Returns the value from this `Success` or throws the exception if
    # this is a `Failure`.
    #
    def get
      fail NotImplementedError, "#{self.class.name}#get?"
    end

    # Returns the value from this `Success` or the given `default`
    # argument if this is a `Failure`.
    #
    # Note: This will throw an exception if it is not a success and
    # default throws an exception
    #
    def get_or_else(default)
      if success?
        get
      else
        default
      end
    end

    # Returns this `Try` if it's a `Success` or the given `default`
    # argument if this is a `Failure`.
    #
    def or_else(default)
      fail ArgumentError, 'default should be Try' unless default.is_a?(Try)
      if success?
        self
      else
        default
      end
    end
  end
end