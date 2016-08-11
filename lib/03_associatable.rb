require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      primary_key: :id,
      foreign_key: "#{name}_id".to_sym,
      class_name: name.to_s.camelcase
    }

    options = defaults.merge(options)

    options.each do |variable, value|
      instance_variable_set("@#{variable}", value)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      primary_key: :id,
      class_name: name.to_s.singularize.camelcase,
      foreign_key: "#{self_class_name.downcase}_id".to_sym
    }

    options = defaults.merge(options)

    options.each do |variable, value|
      instance_variable_set("@#{variable}", value)
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method("#{name}") do
      options.model_class
        .where(options.primary_key => send(options.foreign_key))
        .first
    end

    self.assoc_options[name] = options
    # debugger
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method("#{name}") do
      options.model_class
        .where(options.foreign_key => self.send(options.primary_key))
    end
  end

  def assoc_options
    @assoc_options ||= Hash.new
  end
end

class SQLObject
  extend Associatable
end
