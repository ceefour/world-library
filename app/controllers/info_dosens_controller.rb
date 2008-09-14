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

class InfoDosensController < ApplicationController

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create ], :redirect_to => { :action => :index }
  verify :method => :put, :only => [ :update ], :redirect_to => { :action => :index }
  verify :method => :delete, :only => [ :destroy ], :redirect_to => { :action => :index }

  def index
    @info_dosen = Dosen.paginate(:page => params[:page], :order => "IDDosen", 
      :conditions => "IDDosen is not null")
  end

  def show
    @info_dosen = Dosen.find(params[:id].to_i)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @info_dosen }
    end
  end
  
  def new
    @info_dosen= Dosen.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @info_dosen }
    end
  end

  def create
    @info_dosen = Dosen.new(params[:info_dosen])
    
    respond_to do |format|
      if @info_dosen.save
        flash[:notice] = 'Dosen was successfully created.'
        # format.html { redirect_to info_dosen_url(@info_kti.id) }
        # format.html { redirect_to info_dosen_url(@info_kti)"InfoIDKTI" }
        format.html { redirect_to info_dosen_url(@info_dosen) } #simple action
        format.xml  { render :xml => @info_dosen, :status => :created, :location => @info_dosen}
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @info_dosen.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @info_dosen = Dosen.find(params[:id].to_i)
  end

  def update
    @info_dosen = Dosen.find(params[:id])
    if @info_dosen.update_attributes(params[:info_dosen])
      flash[:notice] = 'info_dosen was successfully updated.'
      redirect_to :action => 'show', :id => @info_dosen
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @info_dosen = Dosen.find(params[:id].to_i)
    @info_dosen.destroy
    redirect_to :action => 'index'
  end
end