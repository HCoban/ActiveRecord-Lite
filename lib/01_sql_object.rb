require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    unless @columns
      @columns = DBConnection.execute2("SELECT * FROM #{self.table_name}")
      @columns = @columns.first.map! { |col| col.to_sym }
    end
    @columns
  end

  def self.finalize!
    columns.each do |name|
      define_method("#{name}") do
        attributes[name]
      end

      define_method("#{name}=") do |val|
        attributes[name] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        "#{self.table_name}".*
      FROM
        "#{self.table_name}"
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        "#{self.table_name}".*
      FROM
        "#{self.table_name}"
      WHERE
        "#{self.table_name}".id = ?
    SQL
    return nil if results.empty?
    self.new(results.first)
  end

  def initialize(params = {})
    params.each do |attr_name, val|
      attr_name = attr_name.to_sym
      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      end
      self.send((attr_name.to_s+'=').to_sym, val)
    end
  end

  def attributes
    @attributes ||= {}
    @attributes
    # ...
  end

  def attribute_values
    self.class.columns.map { |col| send(col) }
  end

  def insert
    q_marks = (["?"] * attribute_values.length).join(', ')
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{self.class.columns.join(", ")})
      VALUES
        (#{q_marks})
    SQL
    id = DBConnection.last_insert_row_id
    self.id = id
  end

  def update
    set_line = self.class.columns[1..-1].map { |col| "#{col} = ?"}.join(", ")
    DBConnection.execute(<<-SQL, attribute_values[1..-1])
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    if self.id.nil?
      insert
    else
      update
    end
    # ...
  end
end
