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
  fname = Matt AND house_id = 1
```
