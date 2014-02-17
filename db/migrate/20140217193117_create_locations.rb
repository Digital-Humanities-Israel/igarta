class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :name
      t.string :name_norm
      t.integer :letter_id

      t.timestamps
    end
  end
end
