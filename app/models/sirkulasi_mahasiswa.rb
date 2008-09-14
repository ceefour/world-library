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

class SirkulasiMahasiswa < ActiveRecord::Base
  set_table_name "SirkulasiMahasiswa"
  #  belongs_to :mahasiswa, :foreign_key => "IDMahasiswa"
  #  belongs_to :info_buku, :foreign_key => "InfoIDBuku" 
  
  def mahasiswa
    Mahasiswa.find(:first, :conditions => "IDMahasiswa = '#{self['IDMahasiswa']}'")
  end
  
  def info_buku
    InfoBuku.find(:first, :conditions => "InfoIDBuku = '#{self['InfoIDBuku']}'")
  end
  
  def self.per_page
    11
  end
  
  validates_presence_of "IDMahasiswa", "InfoIDBuku", "IDBuku"
  validates_uniqueness_of "IDBuku", :message => 'can not use same IDBuku'
end
