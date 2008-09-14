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

class Kunjungan < ActiveRecord::Base
  set_table_name "Kunjungan"
  #  belongs_to :dosen, :foreign_key => "IDDosen", :conditions => 'id >= 1'
  #  belongs_to :mahasiswa, :foreign_key => "IDMahasiswa"
  
  attr :id_barcode # new atribute for id_barcode
  
  def dosen
    Dosen.find(:first, :conditions => "IDDosen = '#{self['IDDosen']}'")
  end
  
  def mahasiswa
    Mahasiswa.find(:first, :conditions => "IDMahasiswa = '#{self['IDMahasiswa']}'")
  end

  def self.per_page
    11
  end
  
  def id_barcode=(input)
    if input =~ /^0/
      self["IDMahasiswa"]=input
    elsif input =~ /^1/
      self["IDDosen"]=input
    end
    
  end
    
  validates_presence_of "IDMahasiswa", :if => Proc.new { |kunjungan| kunjungan['IDDosen'].blank? }
  validates_presence_of "IDDosen", :if => Proc.new { |kunjungan| kunjungan['IDMahasiswa'].blank? }
  
  
end
