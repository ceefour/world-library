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

class BorrowersController < ApplicationController
  #  def show
  #    @borrowers = SirkulasiDosen.find(:first, :conditions => {"IDDosen" => params[:id]})
  #  end
   
  def dosen
    @borrowers = SirkulasiDosen.paginate(:page => params[:page], :order => "TglPinjam ASC", 
      :conditions => "(SirkulasiDosen.Kembali)=false")
  end
      
  def mahasiswa
    @borrowers = SirkulasiMahasiswa.paginate(:page => params[:page], :order => "TglPinjam ASC", 
      :conditions => "(SirkulasiMahasiswa.Kembali)=false")
  end
  
  def currentdosen
    @borrowers = SirkulasiDosen.paginate(:page => params[:page], :order => "TglPinjam DESC", 
      :conditions => "(IDDosen is not null) and (IDDosen <> '') AND (Kembali = false) and DATE_FORMAT(TglPinjam, '%Y%m%d') = DATE_FORMAT(CURDATE(), '%Y%m%d')")   
  end
  
  def currentmahasiswa
    @borrowers = SirkulasiMahasiswa.paginate(:page => params[:page], :order => "TglPinjam DESC", 
      :conditions => "(IDMahasiswa is not null) and (IDMahasiswa <> '') AND (Kembali = false) and DATE_FORMAT(TglPinjam, '%Y%m%d') = DATE_FORMAT(CURDATE(), '%Y%m%d')")   
  end
end
 