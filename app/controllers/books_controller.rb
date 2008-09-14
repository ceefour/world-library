#
#  Copyright (C) 2008 Prodigus Technology Consulting, LLC
#
#  This file is part of World Library.
#
#  World Library is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  World Library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with World Library.  If not, see <http://www.gnu.org/licenses/>.
#

class BooksController < ApplicationController
  def live_search

#    @phrase = request.raw_post || request.query_string
    @phrase = params[:searchtext]
    a1 = "%"
    a2 = "%"
    @searchphrase = a1 + @phrase + a2
    @results = InfoBuku.find(:all, :conditions => [ "Judul LIKE ?", @searchphrase])
   
    @number_match = @results.length
   
    render(:layout => false)
  end

  def search2
    
    if params[:name].blank?
      @results= []
    else
      @phrase = params[:name]  
      a1 = "%"
      a2 = "%"
      @searchphrase = a1 + @phrase + a2
      
      case params[:selectcatalogue]
      when ' '
        @results = InfoBuku.paginate(:page => params[:page], :order => "InfoIDBuku ASC")
      when 'Judul'
        @results = InfoBuku.paginate(:page => params[:page], :order => "Judul ASC", 
          :conditions => ["Judul LIKE ?",  @searchphrase]) rescue []
      when "ISBN"
        @results = InfoBuku.paginate(:page => params[:page], :order => "Judul ASC", 
          :conditions => ["ISBN LIKE ?",  @searchphrase]) rescue []
      when "SemuaPengarang"
        @results = InfoBuku.paginate(:page => params[:page], :order => "Judul ASC", 
          :conditions => ["SemuaPengarang LIKE ?",  @searchphrase]) rescue []
      when "Kategori"
        @results = InfoBuku.paginate(:page => params[:page], :order => "Judul ASC", 
          :conditions => ["Kategori LIKE ?",  @searchphrase]) rescue []
      end  
      @number_match = @results.length
    end
  end
  
end
