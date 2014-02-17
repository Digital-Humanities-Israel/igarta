class CreateLetters < ActiveRecord::Migration
  def change
    create_table :letters do |t|
      t.string :url
      t.integer :seq_no
      t.string :author
      t.string :recipient
      t.string :from_location
      t.string :to_location
      t.string :from_location_norm
      t.string :to_location_norm

      t.timestamps
    end
  end
end
