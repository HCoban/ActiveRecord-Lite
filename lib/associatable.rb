require_relative 'searchable'
require 'active_support/inflector'

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
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method("#{name}") do
      options.model_class
        .where(options.primary_key => send(options.foreign_key))
        .first
    end

    self.assoc_options[name] = options
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method("#{name}") do
      options.model_class
        .where(options.foreign_key => self.send(options.primary_key))
    end
  end

  def has_one_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]

    define_method(name) do
      source_options = through_options.model_class.assoc_options[source_name]
      results = DBConnection.execute(<<-SQL, self.send(through_options.foreign_key))

        SELECT
          #{source_options.table_name}.*
        FROM
          #{through_options.table_name}
        JOIN
          #{source_options.table_name}
            ON #{through_options.table_name}.#{source_options.foreign_key}
            = #{source_options.table_name}.#{source_options.primary_key}
        WHERE
          #{through_options.table_name}.#{through_options.primary_key} = ?
      SQL
      return [] if results.empty?
      source_options.model_class.new(results.first)
    end
  end

  def assoc_options
    @assoc_options ||= Hash.new
  end
end

class SQLObject
  extend Associatable
end
