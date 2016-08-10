require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = []
    params.each do |key, _|
      where_line << "#{key} = ?"
    end
    where_line = where_line.join(" AND ")

    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL
    return [] if results.empty?
    found = []
    results.map { |hash| self.new(hash) }
  end
end

class SQLObject
  extend Searchable
end
