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

ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"
  map.connect '', :controller => "main"
  
  map.resources "info_mahasiswas"
  map.resources "info_dosens"
  
  map.resources "info_ktis"
  map.home "", :controller => "book_shows", :action => "show"
  
  map.about "about", :controller => "about_libraries", :action => "about"
  map.category "categories/*id", :controller => "categories", :action => 'show'
 
  map.resources "info_bukus"
  
  map.resources "library_visitors"
  map.circulation "circulation", :controller => "circulations", :action => 'show'
  map.dosen_circulation "circulations/dosen", :controller => "circulations", :action => 'dosen'
  map.currentdosen_circulation "circulations/currentdosen", :controller => "circulations", :action => 'currentdosen'
  map.currentmahasiswa_circulation "circulations/currentmahasiswa", :controller => "circulations", :action => 'currentmahasiswa'
  map.mahasiswa_circulation "circulations/mahasiswa", :controller => "circulations", :action => 'mahasiswa'
  
  map.resources "borrower_dosens", :member => {:renew => :any, :return_form => :any, :return_submit => :any}
  map.resources "borrower_mahasiswas", :collection => {:halo => :any, :apa => :any},
      :member => {:yuhu => :any, :boleh => :any}
  map.dosen_borrower "borrowersdosen", :controller => "borrowers", :action => 'dosen'
  map.mahasiswa_borrower "borrowersmahasiswa", :controller => "borrowers", :action => 'mahasiswa'
  map.currentdosen_borrower "borrowerscurrentdosen", :controller => "borrowers", :action => 'currentdosen'
  map.currentmahasiswa_borrower  "borrowerscurrentmahasiswa", :controller => "borrowers", :action => 'currentmahasiswa'
  
  map.eny_staff "enysendras", :controller => "about_libraries", :action => 'enysendra'
  map.pipit_staff "pipits", :controller => "about_libraries", :action => 'pipitharyadi'
  map.deny_staff "denys", :controller => "about_libraries", :action => 'denyisharyuni'
  map.anung_staff "anungs", :controller => "about_libraries", :action => 'nurohman'
  
  map.catalogues "catalogue", :controller => "catalogues", :action => 'basic_catalogue'
  map.login 'login', :controller => 'account', :action => 'login'
  map.logout 'logout', :controller => 'account', :action => 'logout'
  
  
  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
