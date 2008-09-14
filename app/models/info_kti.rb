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

class InfoKTI < ActiveRecord::Base
  set_table_name "InfoKTI"
    
  def self.per_page
    10
  end
  
  validates_presence_of "InfoIDKTI", "Judul"
  validates_uniqueness_of "InfoIDKTI"
  validates_uniqueness_of "Judul", :message => 'can not use same title'
  
end
