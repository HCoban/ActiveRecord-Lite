require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    ar = []
    v = []
    params.each do |key, value|
      ar << "#{key} = ?"
      v << value
    end
    ar = ar.join(" AND ")
    results = DBConnection.execute(<<-SQL, *v)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{ar}
    SQL
    return nil if results.empty?
    self.new(results.first)
  end
end

class SQLObject
  extend Searchable
end
