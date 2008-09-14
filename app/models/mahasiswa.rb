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

class Mahasiswa < ActiveRecord::Base
  set_table_name "Mahasiswa"
    
  def self.per_page
    11
  end
  
  validates_presence_of "IDMahasiswa", "Nama"
  validates_uniqueness_of "IDMahasiswa"
  validates_uniqueness_of "Nama", :message => 'can not use same name'
  
end
