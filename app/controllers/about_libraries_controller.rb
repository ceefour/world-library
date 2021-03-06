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
class AboutLibrariesController < ApplicationController
  
  def about
    unless logged_in?
      flash[:notice] = 'Anda harus login untuk melihat halaman !'
      redirect_to home_url
      return                                                                                                               
    end
    @time = Time.now
  end
  
  def time
    render :text => Time.now.to_s
  end
  
  def counter
    if session[:counter]
      session[:counter] = session[:counter] - 1
      if session[:counter] <= 0
        session[:counter] = 6
      end
    else
      session[:counter] = 6
    end
    render :text => session[:counter].to_s
  end
  
end
