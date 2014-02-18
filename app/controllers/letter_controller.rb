class LetterController < ApplicationController
  def list
    @items = Letter.page(params[:page])

  end

  def view
    @item = Letter.find(params[:id])
    marker_array = []
    from_coord = coords(@item.from_location)
    to_coord = coords(@item.to_location)
    marker_array << from_coord unless from_coord.nil?
    marker_array << to_coord unless to_coord.nil?

    @markers = Gmaps4rails.build_markers(marker_array) do |coord, marker|
      unless coord.nil?
        marker.lat coord[0]
        marker.lng coord[1]
      end
    end
    @fulltext = File.open(@item.plaintext_filename, 'r').read
  end

  protected
  def preload_geo
    @geo = {}
    geo = File.open('useful_geo.txt','r').read.lines
    geo.each { |g| fields = g.chomp.split(',')
      @geo[fields[0]] = [fields[1], fields[2]]
    }
  end
  def coords(loc)
    preload_geo if @geo.nil?
    return @geo[loc]
  end
end
