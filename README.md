# ActiveRecord Me

ActiveRecord Me is a lite version of ActiveRecord. It translates the ActiveRecord syntax to SQL.

For example

```ruby
humans = Human.where(fname: 'Matt', house_id: 1)
```

will fire the following SQL query.

```sql
SELECT
  *
FROM
  humans
WHERE
  fname = "Matt" AND house_id = 1
```

## Development

ActiveRecord Me is built on Ruby. A `DBConnection` class is implemented for connecting to a SQLite3 database.

`SQLObject` class is responsible for the interaction with the database. Models should inherit from this class similar to `ActiveRecord::Base`.

Most of the useful methods of `ActiverRecord::Base` is implemented to `SQLObject`. For example `::find(id)` fires a SQL query and returns a new instance of `SQLObject` as follows.

```ruby
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
```

`Associatable` module includes `belongs_to`, `has_many`, and `has_one_through` methods which is extended into `SQLObject`. This allows us to define associations like

```ruby
class Cat < SQLObject
  belongs_to :human, foreign_key: :owner_id

  ...
end
```

which provides access to associated model instance as follows

```ruby
breakfast = Cat.find(1)
breakfast.human #will return it's owner
```

## Future Directions

I am working on a side-project called [Rails Me][rails_link] which will have some of the useful features of Rails. After combining Rails Me with ActiveRecord Me, it will be possible to develop complete web apps using Rails Me.

[rails_link]: https://github.com/HCoban/RailsMe
