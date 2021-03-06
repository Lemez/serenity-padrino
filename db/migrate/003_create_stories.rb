class CreateStories < ActiveRecord::Migration
  def self.up
    create_table :stories do |t|
      t.string :title
      t.float :score
      t.datetime :date
      t.string :source
      t.timestamps
    end
  end

  def self.down
    drop_table :stories
  end
end
