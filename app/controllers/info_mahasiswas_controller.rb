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

class InfoMahasiswasController < ApplicationController
  
   # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create ], :redirect_to => { :action => :index }
  verify :method => :put, :only => [ :update ], :redirect_to => { :action => :index }
  verify :method => :delete, :only => [ :destroy ], :redirect_to => { :action => :index }

  def index
    @info_mahasiswa = Mahasiswa.paginate(:page => params[:page], :order => "IDMahasiswa", 
      :conditions => "IDMahasiswa is not null")
  end

  def show
    @info_mahasiswa = Mahasiswa.find(params[:id].to_i)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @info_mahasiswa}
    end
  end
  
  def new
    @info_mahasiswa= Mahasiswa.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @info_mahasiswa }
    end
  end

  def create
    @info_mahasiswa = Mahasiswa.new(params[:info_mahasiswa])
    
    respond_to do |format|
      if @info_mahasiswa.save
        flash[:notice] = 'Mahasiswa was successfully created.'
        # format.html { redirect_to info_mahasiswa_url(@info_mahasiswa.id) }
        # format.html { redirect_to info_mahasiswa_url(@info_mahasiswa)"InfoIDMahasiswa" }
        format.html { redirect_to info_mahasiswa_url(@info_mahasiswa) } #simple action
        format.xml  { render :xml => @info_mahasiswa, :status => :created, :location => @info_mahasiswa}
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @info_mahasiswa.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @info_mahasiswa = Mahasiswa.find(params[:id].to_i)
  end

  def update
    @info_mahasiswa = Mahasiswa.find(params[:id].to_i)
    if @info_mahasiswa.update_attributes(params[:info_mahasiswa])
      flash[:notice] = 'info_mahasiswa was successfully updated.'
      redirect_to :action => 'show', :id => @info_mahasiswa
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @info_mahasiswa = Mahasiswa.find(params[:id].to_i)
    @info_mahasiswa.destroy
    redirect_to :action => 'index'
  end
  
end
