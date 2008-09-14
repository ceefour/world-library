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

class BorrowerMahasiswasController < ApplicationController
  
  def new
    @borrower_mahasiswa = SirkulasiMahasiswa.new
    @borrowers = SirkulasiMahasiswa.paginate(:page => params[:page], :order => "TglPinjam DESC",
      :conditions => "(IDMahasiswa is not null) and (IDMahasiswa <> '') and DATE_FORMAT(TglPinjam, '%Y%m%d') = DATE_FORMAT(CURDATE(), '%Y%m%d')")
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @borrower_mahasiswas }
    end
  end

  def create
    @borrower_mahasiswa  = SirkulasiMahasiswa.new(params[:sirkulasi_mahasiswa])
    @borrower_mahasiswa["TglPinjam"] = Time.now
    @borrower_mahasiswa["TglHrsKembali"] = Time.now + 6.days
    @borrower_mahasiswa["Belum"] = false
    @borrower_mahasiswa["Kembali"] = false
    respond_to do |format|
      if @borrower_mahasiswa .save
        flash[:notice] = 'SirkulasiMahasiswa was successfully created.'
        format.html { redirect_to new_borrower_mahasiswa_url} #simple action
      else
        @borrowers = SirkulasiMahasiswa.paginate(:page => params[:page], :order => "TglPinjam DESC",
          :conditions => "(IDMahasiswa is not null) and (IDMahasiswa <> '') and DATE_FORMAT(TglPinjam, '%Y%m%d') = DATE_FORMAT(CURDATE(), '%Y%m%d')")
        format.html { render :action => "new" }
        format.xml  { render :xml => @borrower_mahasiswa .errors, :status => :unprocessable_entity }
      end
    end
  end

  def index
    if params['IDMahasiswa'].blank?
      @borrower_mahasiswa = SirkulasiMahasiswa.paginate(:page => params[:page], :order => "TglPinjam DESC", 
        :conditions => "IDMahasiswa is not null")
    else
      @borrower_mahasiswa = SirkulasiMahasiswa.paginate(:page => params[:page], :order => "TglPinjam DESC", 
        :conditions => ["IDMahasiswa = ?", params['IDMahasiswa']])
    end
  end
 
  def destroy
    @borrower_mahasiswa = SirkulasiMahasiswa.find(params[:id].to_i)
    @borrower_mahasiswa.destroy
    redirect_to :action => 'index'
  end  
  
  def renew
    @borrower_mahasiswa = SirkulasiMahasiswa.find(params[:id])
    @borrower_mahasiswa["TglPinjam"] = Time.now
    @borrower_mahasiswa["TglHrsKembali"] = Time.now + 6.days
    respond_to do |format|
      if @borrower_mahasiswa .save
        flash[:notice] = 'SirkulasiMahasiswa was successfully created.'
        format.html { redirect_to new_borrower_mahasiswa_url} #simple action
      else
        @borrowers = SirkulasiMahasiswa.paginate(:page => params[:page], :order => "TglPinjam DESC",
          :conditions => "(IDMahasiswa is not null) and (IDMahasiswa <> '') and DATE_FORMAT(TglPinjam, '%Y%m%d') = DATE_FORMAT(CURDATE(), '%Y%m%d')")
        format.html { render :action => "new" }
        format.xml  { render :xml => @borrower_mahasiswa .errors, :status => :unprocessable_entity }
      end
    end
  end

end 
