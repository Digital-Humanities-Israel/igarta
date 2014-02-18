class AddTopicsToLetter < ActiveRecord::Migration
  def change
    add_column :letters, :topics, :string
  end
end
