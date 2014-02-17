class AddPlaintextFilenameToLetter < ActiveRecord::Migration
  def change
    add_column :letters, :plaintext_filename, :string
  end
end
