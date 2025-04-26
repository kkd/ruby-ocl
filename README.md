[![RSpec Tests](https://github.com/kkd/ruby-ocl/actions/workflows/rspec.yml/badge.svg)](https://github.com/kkd/ruby-ocl/actions/workflows/rspec.yml)
![Ruby Version](https://img.shields.io/badge/Ruby-3.2.1-blue)
![Gem Version](https://img.shields.io/badge/gem-v0.1.0-blue)

# OCL - Object Constraint Language for Ruby

Simple and extensible constraint checking for Ruby classes.  
Supports **invariants**, **preconditions**, **postconditions**, and **derived attributes**.

---

## Overview

OCL (Object Constraint Language) brings lightweight contract-based programming to Ruby.  
It enables you to define formal constraints on your classes to ensure that your objects always remain in a valid state.

The supported constraint types are:

- **Invariants**: Conditions that must always be true for objects
- **Preconditions**: Conditions that must be true before a method executes
- **Postconditions**: Conditions that must be true after a method executes
- **Derived attributes**: Attributes that are dynamically computed based on other values

---

## Features

- ✅ Fluent DSL for defining contracts
- ✅ Immediate runtime validation
- ✅ Rich and informative error messages
- ✅ Minimal and dependency-free
- ✅ Easy to integrate into any Ruby project

---
## Difference Between OCL and Testing Frameworks (RSpec, test-unit)

OCL constraints (invariants, preconditions, postconditions, derived attributes) provide **runtime validation** inside your production code.  
They ensure that objects remain valid even during real-world operation.

In contrast, testing frameworks like RSpec or test-unit are used during **development** to check if your code behaves as expected.

| Purpose          | OCL                               | RSpec / test-unit                  |
|------------------|-----------------------------------|------------------------------------|
| When             | Runtime                           | Development / Testing phase       |
| Scope            | Object internal consistency       | Behavior of methods and APIs      |
| Failure Reaction | Immediate runtime error (ValidationError) | Test failure report          |
| Usage            | Embed constraints in class definitions | Write test cases separately |

Use both together for best quality:  
- OCL guarantees your object's internal health at runtime.  
- RSpec ensures your business logic works correctly during development.

---

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ocl'
```

Or install it yourself with:

```bash
gem install ocl
```

---

## Basic Usage

```ruby
require 'ocl'

class Account
  include OCL

  attr_accessor_with_invariant :limit
  attr_accessor_with_invariant :amount
  attr_accessor :owner

  def initialize(owner)
    @owner = owner
    @limit = 0
    @amount = 0
  end

  def withdraw(amount_to_withdraw)
    @amount -= amount_to_withdraw
  end
end

# Define constraints
Account.inv('IncomeInvariant') do |c|
  expected = c.owner.income < 5_000_000 ? 200_000 : (c.owner.income * 0.1).round
  c.expect(c.limit).to_be(expected)
end

Account.pre(:withdraw, 'PositiveAndWithinLimit') do |c, amount_to_withdraw|
  c.expect(amount_to_withdraw).to_be_positive
  c.expect(amount_to_withdraw).to_be_less_than_or_equal_to(c.limit)
end

Account.post(:withdraw, 'AmountNonNegative') do |c, result, amount_to_withdraw|
  c.expect(c.amount).to_be_greater_than_or_equal_to(0)
end
```

---

## Derived Attributes Example

```ruby
class User
  include OCL

  attr_accessor_with_invariant :first_name, :last_name

  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end
end

# Define a derived attribute
User.derived(:full_name) do |c|
  "#{c.first_name} #{c.last_name}"
end

user = User.new("Taro", "Yamada")
puts user.full_name  # => "Taro Yamada"
```

---
## Important Note on Writing Validation Blocks

When defining `invariant`, `precondition`, or `postcondition` blocks in OCL, **do not combine multiple expectations using logical operators such as `&&` or `||`**.

Instead, **call each `expect` separately**.

✅ Correct:

```ruby
pre(:withdraw, 'PositiveAndWithinLimit') do |c, amount|
  c.expect(amount).to_be_positive
  c.expect(amount).to_be_less_than_or_equal_to(c.limit)
end
```

❌ Incorrect:

```ruby
pre(:withdraw, 'PositiveAndWithinLimit') do |c, amount|
  c.expect(amount).to_be_positive && c.expect(amount).to_be_less_than_or_equal_to(c.limit)
end
```

**Reason:**  
In OCL, `expect` does not return a true/false value. It only records validation results internally.  
Using `&&` or `||` will not combine validations correctly, and validation errors may not be detected.

Always write expectations separately to ensure proper validation.

---
## Development

After checking out the repo:

```bash
bundle install
```

Then, to run the tests:

```bash
rake
```
or

```bash
rspec
```

To build and install the gem locally:

```bash
gem build ocl.gemspec
gem install ./ocl-0.1.0.gem
```

---

## References

- [OMG Object Constraint Language (OCL) Specification 2.4 (PDF)](https://www.omg.org/spec/OCL/2.4/PDF)

This gem implements a minimal and Ruby-idiomatic subset of the OCL standard,  
focusing on runtime validation of invariants, preconditions, postconditions, and derived properties.

---

## License

MIT License © 2025 Takeshi Kakeda
