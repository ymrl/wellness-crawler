require 'sequel'
Sequel::Model.plugin(:schema)
Sequel.connect("sqlite://db/wellness.db")

class Lectures < Sequel::Model
  unrestrict_primary_key
  set_schema do
    primary_key :id
    timestamp :time
    integer :period
    string :subject
    string :instructor
    string :syllabus
    bool :lot
    float :odds
    integer :rest
  end
end
Lectures.create_table if !Lectures.table_exists?
