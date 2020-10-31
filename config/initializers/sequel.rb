require "sequel/core"

# initialize Sequel and have it reuse Active Record's database connection
DB = Sequel.postgres(extension: :activerecord_connection)
