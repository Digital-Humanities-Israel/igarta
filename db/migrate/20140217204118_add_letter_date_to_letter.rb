class AddLetterDateToLetter < ActiveRecord::Migration
  def change
    add_column :letters, :letter_date, :string
  end
end
