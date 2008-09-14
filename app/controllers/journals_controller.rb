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

class JournalsController < ApplicationController
  layout 'default'
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @journal_pages, @journals = paginate :journals, :per_page => 10
  end

  def show
    @journal = Journal.find(params[:id])
  end

  def new
    @journal = Journal.new
  end

  def create
    @journal = Journal.new(params[:journal])
    if @journal.save
      flash[:notice] = 'Journal was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @journal = Journal.find(params[:id])
  end

  def update
    @journal = Journal.find(params[:id])
    if @journal.update_attributes(params[:journal])
      flash[:notice] = 'Journal was successfully updated.'
      redirect_to :action => 'show', :id => @journal
    else
      render :action => 'edit'
    end
  end

  def destroy
    Journal.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
