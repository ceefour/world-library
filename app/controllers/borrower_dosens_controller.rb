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

class BorrowerDosensController < ApplicationController
  
  def new
    @borrower_dosen = SirkulasiDosen.new
    @borrowers = SirkulasiDosen.paginate(:page => params[:page], :order => "TglPinjam DESC",
      :conditions => "(IDDosen is not null) and (IDDosen <> '') AND (Kembali = false)and DATE_FORMAT(TglPinjam, '%Y%m%d') = DATE_FORMAT(CURDATE(), '%Y%m%d')") 
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @borrower_dosens }
    end
  end

  def create
    if params[:sirkulasi_dosen].blank?
      @borrower_dosen= []
    else
      @borrower_dosen  = SirkulasiDosen.new(params[:sirkulasi_dosen])
      @borrower_dosen["TglPinjam"] = Time.now
      @borrower_dosen["TglHrsKembali"] = Time.now + 6.days
      @borrower_dosen["Belum"] = false
      @borrower_dosen["Kembali"] = false
      respond_to do |format|
        if @borrower_dosen .save
          flash[:notice] = 'SirkuasiDosen was successfully created.'
          format.html { redirect_to new_borrower_dosen_url} #simple action
        else
          @borrowers = SirkulasiDosen.paginate(:page => params[:page], :order => "TglPinjam DESC",
            :conditions => "(IDDosen is not null) and (IDDosen <> '') and DATE_FORMAT(TglPinjam, '%Y%m%d') = DATE_FORMAT(CURDATE(), '%Y%m%d')") 

          format.html { render :action => "new" }
          format.xml  { render :xml => @borrower_dosen .errors, :status => :unprocessable_entity }
        end
      end
    end
  end
  
  def index
    if params['IDDosen'].blank?
      @borrower_dosen = SirkulasiDosen.paginate(:page => params[:page], :order => "TglPinjam DESC", 
        :conditions => "(IDDosen is not null) AND (Kembali = false)")
    else
      @borrower_dosen = SirkulasiDosen.paginate(:page => params[:page], :order => "TglPinjam DESC", 
        :conditions => ["(IDDosen = ?) AND (Kembali = false)", params['IDDosen']])
    end
  end
  
  def destroy
    @borrower_dosen = SirkulasiDosen.find(params[:id].to_i)
    @borrower_dosen.destroy
    redirect_to :action => 'index'
  end 

  def renew
    @borrower_dosen = SirkulasiDosen.find(params[:id])
    @borrower_dosen["TglPinjam"] = Time.now
    @borrower_dosen["TglHrsKembali"] = Time.now + 6.days
    respond_to do |format|
      if @borrower_dosen .save
        flash[:notice] = 'SirkulasiDosen was successfully renewed.'
        format.html { redirect_to borrower_dosens_url} #simple action
      else
        @borrowers = SirkulasiDosen.paginate(:page => params[:page], :order => "TglPinjam DESC",
          :conditions => "(IDDosen is not null) and (IDDosen <> '') and DATE_FORMAT(TglPinjam, '%Y%m%d') = DATE_FORMAT(CURDATE(), '%Y%m%d')")
        format.html { render :action => "new" }
        format.xml  { render :xml => @borrower_dosen .errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def return_form
    unless @borrower_dosen
      @borrower_dosen = SirkulasiDosen.find(params[:id])
    end
    @date_returned = Time.today
    @difference_days = ((@date_returned - @borrower_dosen['TglHrsKembali']) / 1.days).to_i
    if @difference_days < 0
      @holiday_days = 0
      @late_days = 0
    else
      @holiday_days = (@difference_days  / 7).to_i * 2
      @late_days = @difference_days - @holiday_days
    end
    @total = @late_days * 500
  end
    
  def return_submit
    @borrower_dosen = SirkulasiDosen.find(params[:id])
    @borrower_dosen["Kembali"] = 1
    respond_to do |format|
      if @borrower_dosen .save
        flash[:notice] = 'SirkulasiDosen was successfully returned.'
        format.html { redirect_to borrower_dosens_url} #If success progress will bring it to....?
      else
        return_form
        format.html { render :action => 'return_form' } #If not success will move....?
      end
    end
  end
end
  
