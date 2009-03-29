ActiveRecord::Schema.define(:version => 1) do
  create_table :articles do |t|
    t.string :name, :heading, :body, :author, :sources
  end
end