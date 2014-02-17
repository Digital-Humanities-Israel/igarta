class Letter < ActiveRecord::Base
  attr_accessible :author, :from_location, :from_location_norm, :recipient, :seq_no, :to_location, :to_location_norm, :url, :letter_date, :plaintext_filename
end
