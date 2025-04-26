# frozen_string_literal: true

# lib/ocl/core.rb

# Main OCL module providing invariant, precondition, postcondition, and derived attribute support.
module OCL
  def self.included(base)
    base.extend(ClassMethods)
    base.prepend InitializerHook
  end

  # Class-level methods to define OCL constraints.
  module ClassMethods
    def invariants
      @invariants ||= []
    end

    def preconditions
      @preconditions ||= Hash.new { |h, k| h[k] = [] }
    end

    def postconditions
      @postconditions ||= Hash.new { |h, k| h[k] = [] }
    end

    def derived_properties
      @derived_properties ||= {}
    end

    # Define an invariant constraint.
    def inv(name, &block)
      invariants << { name: name, block: block }
    end

    # Define a precondition constraint for a method.
    def pre(method_name, name, &block)
      wrap_method(method_name)
      preconditions[method_name] << { name: name, block: block }
    end

    # Define a postcondition constraint for a method.
    def post(method_name, name, &block)
      wrap_method(method_name)
      postconditions[method_name] << { name: name, block: block }
    end

    # Define a derived (calculated) attribute.
    def derived(name, &block)
      derived_properties[name.to_sym] = block

      define_method(name) do
        context = Context.new(self)
        self.class.derived_properties[name.to_sym].call(context)
      end
    end

    # Define an attribute with automatic invariant validation on assignment.
    def attr_accessor_with_invariant(*names)
      names.each do |name|
        attr_reader name

        define_method("#{name}=") do |value|
          instance_variable_set("@#{name}", value)
          validate_invariants!
        end
      end
    end

    private

    # Wrap an instance method to validate preconditions and postconditions.
    def wrap_method(method_name)
      @wrapped_methods ||= Set.new
      return if @wrapped_methods.include?(method_name)

      original = instance_method(method_name)
      @wrapped_methods.add(method_name)

      define_method(method_name) do |*args, &block|
        validate_preconditions!(method_name, *args)
        result = original.bind(self).call(*args, &block)
        validate_postconditions!(method_name, result, *args)
        result
      end
    end
  end

  # Internal hook to ensure superclass initialize is called properly.
  module InitializerHook
    def initialize(*args, &block)
      super(*args, &block)
    end
  end

  # Raised when any constraint validation fails.
  class ConstraintViolationError < StandardError
    def initialize(errors)
      super(errors.is_a?(Array) ? errors.join(', ') : errors)
    end
  end

  # Context passed to validation blocks, providing access to the target object and helpers.
  class Context
    attr_reader :object

    def initialize(object)
      @object = object
      @errors = []
    end

    def method_missing(name, *args, &block)
      if args.empty?
        object.public_send(name)
      else
        super
      end
    end

    def respond_to_missing?(_name, _include_private = false)
      true
    end

    # Create an expectation object for fluent assertions.
    def expect(actual)
      Expectation.new(actual, self)
    end

    # Record an error message in the context.
    def add_error(detail)
      @errors << detail
    end

    # Check if all assertions passed.
    def valid?
      @errors.empty?
    end

    # Return accumulated error messages.
    def error_messages
      @errors
    end

    # Fluent assertions used within validation blocks.
    class Expectation
      def initialize(actual, context)
        @actual = actual
        @context = context
      end

      def to_be(expected)
        return if @actual == expected

        @context.add_error("Expected #{@actual.inspect} to equal #{expected.inspect}")
      end

      def to_not_be(expected)
        return unless @actual == expected

        @context.add_error("Expected #{@actual.inspect} to not equal #{expected.inspect}")
      end

      def to_be_positive
        return if @actual.positive?

        @context.add_error("Expected #{@actual.inspect} to be positive")
      end

      def to_be_greater_than(value)
        return if @actual > value

        @context.add_error("Expected #{@actual.inspect} to be greater than #{value.inspect}")
      end

      def to_be_greater_than_or_equal_to(value)
        return if @actual >= value

        @context.add_error("Expected #{@actual.inspect} to be greater than or equal to #{value.inspect}")
      end

      def to_be_less_than(value)
        return if @actual < value

        @context.add_error("Expected #{@actual.inspect} to be less than #{value.inspect}")
      end

      def to_be_less_than_or_equal_to(value)
        return if @actual <= value

        @context.add_error("Expected #{@actual.inspect} to be less than or equal to #{value.inspect}")
      end
    end
  end

  # Validate all defined invariants.
  def validate_invariants!
    errors = []

    self.class.invariants.each do |inv|
      context = Context.new(self)
      inv[:block].call(context)
      errors << "Invariant '#{inv[:name]}' violated: " + context.error_messages.join(', ') unless context.valid?
    end

    raise ConstraintViolationError, errors unless errors.empty?
  end

  # Validate preconditions before method execution.
  def validate_preconditions!(method_name, *args)
    errors = []

    self.class.preconditions[method_name].each do |pre|
      context = Context.new(self)
      pre[:block].call(context, *args)
      unless context.valid?
        errors << "Precondition '#{pre[:name]}' for #{method_name} violated: " + context.error_messages.join(', ')
      end
    end

    raise ConstraintViolationError, errors unless errors.empty?
  end

  # Validate postconditions after method execution.
  def validate_postconditions!(method_name, result, *args)
    errors = []

    self.class.postconditions[method_name].each do |post|
      context = Context.new(self)
      post[:block].call(context, result, *args)
      unless context.valid?
        errors << "Postcondition '#{post[:name]}' for #{method_name} violated: " + context.error_messages.join(', ')
      end
    end

    raise ConstraintViolationError, errors unless errors.empty?
  end
end
