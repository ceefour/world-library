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

class LibraryVisitorsController < ApplicationController
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create ], :redirect_to => { :action => :index }
  verify :method => :put, :only => [ :update ], :redirect_to => { :action => :index }
  verify :method => :delete, :only => [ :destroy ], :redirect_to => { :action => :index }

  def index
    @library_visitor = Kunjungan.paginate(:page => params[:page], :order => "TglKunjungan DESC", 
      :conditions => "ID is not null")
  end

  def show
    @library_visitor  = Kunjungan.find(params[:id].to_i)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @library_visitor }
    end
  end
  
  def new
    @library_visitor = Kunjungan.new
    @kunjungans = Kunjungan.paginate(:page => params[:page], :order => "TglKunjungan DESC",
      :conditions => "DATE_FORMAT(TglKunjungan, '%Y%m%d') = DATE_FORMAT(CURDATE(), '%Y%m%d')") 
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @library_visitor }
    end
  end

  def create
    @library_visitor  = Kunjungan.new(params[:kunjungan])
    @library_visitor["TglKunjungan"] = Time.now
    
    respond_to do |format|
      if @library_visitor .save
        flash[:notice] = 'Kunjungan was successfully created.'

        format.html { redirect_to new_library_visitor_url} #simple action
#       format.xml  { render :xml => @library_visitor , :status => :created, :location => @library_visitor  }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @library_visitor .errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @library_visitor  = Kunjungan.find(params[:id].to_i)
  end

  def update
    @library_visitor  = Kunjungan.find(params[:id].to_i)
    if @library_visitor .update_attributes(params[:kunjungan])
      flash[:notice] = 'Kunjungan was successfully updated.'
      redirect_to :action => 'show', :id => @library_visitor 
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @library_visitor  = Kunjungan.find(params[:id].to_i)
    @library_visitor .destroy
    redirect_to :action => 'index'
  end
end
