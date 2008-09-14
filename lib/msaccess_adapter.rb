require 'active_record/connection_adapters/abstract_adapter'

require 'bigdecimal'
require 'bigdecimal/util'

# msaccess_adapter.rb -- ActiveRecord adapter for Microsoft Access Db
#
# "Adapted" from the sqlserver_adapter.rb for Microsoft SQL Sever:
#   Author: Joey Gibson <joey@joeygibson.com>
#
#   Modifications by DeLynn Berry <delynnb@megastarfinancial.com>,
#   Mark Imbriaco <mark.imbriaco@pobox.com>,
#   Tom Ward <tom@popdog.net>,
#   Ryan Tomayko <rtomayko@gmail.com>
# Up to July 2006
#
# Converted to MSAccess (various functions ported over to ADO) by
#   Daniel Parker <daniel@behindlogic.com>
#   -- as current maintainer -- please send bugfixes!

module ActiveRecord
  class Base
    def self.msaccess_connection(config) #:nodoc:
      require_library_or_gem 'win32ole' unless self.class.const_defined?(:WIN32OLE)
      config = config.symbolize_keys

      username    = config[:username] ? config[:username].to_s : 'sa'
      password    = config[:password] ? config[:password].to_s : ''
      autocommit  = config.key?(:autocommit) ? config[:autocommit] : true
      connection_string = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=#{config[:database]}"
      driver_url = "DBI:ADO:#{connection_string}"
      conn = WIN32OLE.new('ADODB.Connection')
      conn.Open(connection_string)
      # conn["AutoCommit"] = autocommit # Works with DBI, but not ADO
      ConnectionAdapters::MsAccessAdapter.new(conn, logger, [driver_url, username, password])
    end
  end # class Base

  module ConnectionAdapters
    class MsAccessColumn < Column# :nodoc:
      attr_reader :is_special
      attr_accessor :ole_column, :ole_table

#Human-readable Types:
# Text
# Number
# AutoNumber
# Currency
# Date/Time
# Yes/No
# Memo
# OLE Object?

#Types:
# adCurrency => Currency
# adVarWChar => Text
# adSmallInt => Number
# adUnsignedTinyInt => Number
# adDate => Date/Time
#   Format: YYYY/MM/DD HH:MM:SS
#   Quote: #{value}#
# adLongVarBinary => Number
# adDouble => Number
# adBoolean => Yes/No
# adInteger => Number

#For each type:
#1) Query value of type and see what kind of value it returns.
#2) Try to insert a value and see if it errors - see if inserting needs to be a different format
#3) Create the translation/mapping method(s) for the connector
#Test the whole thing

      def initialize(name, default, ole_column, ole_table, sql_type = nil, null = true) # TODO: check ok to remove scale_value = 0
        super(name, default, sql_type, null)
        self.ole_column = ole_column
        self.ole_table = ole_table
        @is_special = sql_type =~ /text|ntext|image/i # Why does this make it 'special'?
        # TODO: check ok to remove @scale = scale_value
        # @scale = scale_value
        # # SQL Server only supports limits on *char and float types
        # @limit = nil unless @type == :float or @type == :string
      end

      def simplified_type(field_type)
        case field_type
          when /real/i                                               : :float
          when /int|bigint|smallint|tinyint/i                        : :integer
          when /float|double|decimal|money|numeric|real|smallmoney/i : @scale == 0 ? :integer : :float
          when /datetime|smalldatetime/i                             : :datetime
          when /timestamp/i                                          : :timestamp
          when /time/i                                               : :time
          when /text|ntext/i                                         : :text
          when /binary|image|varbinary/i                             : :binary
          when /char|nchar|nvarchar|string|varchar/i                 : :string
          when /bit/i                                                : :boolean
          else super
        end
      end

      def type_cast(value)
        return nil if value.nil?
        case type
        when :string    then value 
        when :integer   then value == true || value == false ? value == true ? '1' : '0' : value.to_i 
        when :float     then value.to_f 
        when :datetime  then cast_to_date_or_time(value) 
        when :timestamp then cast_to_time(value)
        when :time      then cast_to_time(value)
        when :boolean   then value == true or (value =~ /^t(rue)?$/i) == 0 or value.to_s == '1'
        else super
        end
      end
      
      def cast_to_time(value)
        return value if value.is_a?(Time)
        time_array = ParseDate.parsedate(value)
        Time.send(Base.default_timezone, *time_array) rescue nil
      end

      def cast_to_datetime(value)
        if value.is_a?(Time)
          if value.year != 0 and value.month != 0 and value.day != 0
            return value
          else
            return Time.mktime(2000, 1, 1, value.hour, value.min, value.sec) rescue nil
          end
        end
   
        if value.is_a?(DateTime)
          return Time.mktime(value.year, value.mon, value.day, value.hour, value.min, value.sec)
        end
        
        return cast_to_time(value) if value.is_a?(Date) or value.is_a?(String) rescue nil
        value
      end
      
      # TODO: Find less hack way to convert DateTime objects into Times
      
      def self.string_to_time(value)
        if value.is_a?(DateTime)
          return Time.mktime(value.year, value.mon, value.day, value.hour, value.min, value.sec)
        else
          super
        end
      end

      # These methods will only allow the adapter to insert binary data with a length of 7K or less
      # because of a SQL Server statement length policy.
      # These methods also need to be fixed for msaccess - they often cause errors because for some
      # reason the value from the db can be an array.
      def self.string_to_binary(value)
        value.gsub(/(\r|\n|\0|\x1a)/) do
          case $1
            when "\r"   then  "%00"
            when "\n"   then  "%01"
            when "\0"   then  "%02"
            when "\x1a" then  "%03"
          end
        end
      end

      def self.binary_to_string(value)
        value.gsub(/(%00|%01|%02|%03)/) do
          case $1
            when "%00"    then  "\r"
            when "%01"    then  "\n"
            when "%02\0"  then  "\0"
            when "%03"    then  "\x1a"
          end
        end
      end

      def properties
        return @properties unless @properties.blank?
        @properties = []
        self.ole_column.Properties.each do |prop|
          @properties << prop
        end
        @properties
      end
      def properties_hash
        return @properties_hash if @properties_hash
        @properties_hash = {}
        self.properties.each do |p|
          @properties_hash[p.Name] = p
        end
        @properties_hash
      end
      def property(prop)
        self.properties_hash[prop]
      end
      def property_value(prop)
        unquote_property_value(self.property(prop).Value)
      end

      def method_missing(method_name, *args)
        return self.property_value(method_name) if method_name =~ /^[A-Z]/ && self.property(method_name)
        super
      end
      private
        def unquote_property_value(value)
          if value =~ /\\?["'](.+)\\?["']/
            value = $1
          end
          value
        end
    end

    # In ADO mode, this adapter will ONLY work on Windows systems, 
    # since it relies on Win32OLE, which, to my knowledge, is only 
    # available on Windows.
    #
    # This mode also relies on the ADO support in the DBI module. If you are using the
    # one-click installer of Ruby, then you already have DBI installed, but
    # the ADO module is *NOT* installed. You will need to get the latest
    # source distribution of Ruby-DBI from http://ruby-dbi.sourceforge.net/
    # unzip it, and copy the file 
    # <tt>src/lib/dbd_ado/ADO.rb</tt> 
    # to
    # <tt>X:/Ruby/lib/ruby/site_ruby/1.8/DBD/ADO/ADO.rb</tt> 
    # (you will more than likely need to create the ADO directory).
    # Once you've installed that file, you are ready to go.
    #
    # In ODBC mode, the adapter requires the ODBC support in the DBI module which requires
    # the Ruby ODBC module.  Ruby ODBC 0.996 was used in development and testing,
    # and it is available at http://www.ch-werner.de/rubyodbc/
    #
    # Options:
    #
    # * <tt>:mode</tt>      -- ADO or ODBC. Defaults to ADO.
    # * <tt>:username</tt>  -- Defaults to sa.
    # * <tt>:password</tt>  -- Defaults to empty string.
    # * <tt>:windows_auth</tt> -- Defaults to "User ID=#{username};Password=#{password}"
    #
    # ADO specific options:
    #
    # * <tt>:host</tt>      -- Defaults to localhost.
    # * <tt>:database</tt>  -- The name of the database. No default, must be provided.
    # * <tt>:windows_auth</tt> -- Use windows authentication instead of username/password.
    #
    # ODBC specific options:                   
    #
    # * <tt>:dsn</tt>       -- Defaults to nothing.
    #
    # ADO code tested on Windows 2000 and higher systems,
    # running ruby 1.8.2 (2004-07-29) [i386-mswin32], and SQL Server 2000 SP3.
    #
    # ODBC code tested on a Fedora Core 4 system, running FreeTDS 0.63, 
    # unixODBC 2.2.11, Ruby ODBC 0.996, Ruby DBI 0.0.23 and Ruby 1.8.2.
    # [Linux strongmad 2.6.11-1.1369_FC4 #1 Thu Jun 2 22:55:56 EDT 2005 i686 i686 i386 GNU/Linux]
    class MsAccessAdapter < AbstractAdapter
    
      def initialize(connection, logger, connection_options=nil)
        super(connection, logger)
        @connection_options = connection_options
      end

# Update this for typical MsAccess types?

      def native_database_types
        {
          :primary_key => "int NOT NULL IDENTITY(1, 1) PRIMARY KEY", #Probably needs changed
          :string      => { :name => "varchar", :limit => 255  },
          :text        => { :name => "text" },
          :integer     => { :name => "int" },
          :float       => { :name => "float", :limit => 8 },
          :decimal     => { :name => "decimal" },
          :datetime    => { :name => "datetime" },
          :timestamp   => { :name => "datetime" },
          :time        => { :name => "datetime" },
          :date        => { :name => "datetime" },
          :binary      => { :name => "image"},
          :boolean     => { :name => "bit"}
        }
      end

      def adapter_name
        'MsAccess'
      end
      
      def supports_migrations? #:nodoc:
        false
      end

      def type_to_sql(type, limit = nil, precision = nil, scale = nil) #:nodoc:
        return super unless type.to_s == 'integer'

        if limit.nil? || limit == 4
          'integer'
        elsif limit < 4
          'smallint'
        else
          'bigint'
        end
      end

      # CONNECTION MANAGEMENT ====================================#

      # Returns true if the connection is active.
      def active?
# fix for MsAccess!
        # @connection.Execute("SELECT 1").finish
        true
      rescue DBI::DatabaseError, DBI::InterfaceError
        false
      end

      # Reconnects to the database, returns false if no connection could be made.
      # fix for MsAccess!
      def reconnect!
        disconnect!
        @connection = DBI.connect(*@connection_options)
      rescue DBI::DatabaseError => e
        @logger.warn "#{adapter_name} reconnection failed: #{e.message}" if @logger
        false
      end
      
      # Disconnects from the database
      # fix for MsAccess!
      def disconnect!
        @connection.disconnect rescue nil
      end

      # CATALOG FOR SCHEMA INFORMATION ====================================#

      def catalog
        return @catalog if @catalog
        @catalog = WIN32OLE.new('ADOX.Catalog')
        @catalog.ActiveConnection = @connection
        @catalog
      end

      def tables_from_catalog
        tables = []
        tables << self.catalog.Tables.each do |table|
          tables << table
        end
        tables
      end

      def table_names_from_catalog
        table_names = []
        table_names << self.catalog.Tables.each do |table|
          table_names << table.Name
        end
        table_names
      end

      def content_tables
        table_names_from_catalog.reject! {|t| t.nil? || t =~ /MSys/}
      end
      alias :tables :content_tables

      def columns_from_catalog(table_name)
        return self.catalog.Tables.Item(self.table_names_from_catalog.index(table_name)).Columns if ole_table(table_name)
      end

      def get_column_property(ole_column, property_name)
        value = nil
        ole_column.Properties.each do |property|
          if property.Name == property_name
            value = property.Value
          end
        end
        # ole_value_to_string(value)
        value
      end

      # probably unnecessary - replace with something better
      def default_value_to_string(value)
        case
        when value.nil? : 'NULL'
        when value.kind_of?(String) : value
        else value.to_s
        end
      end

      def columns(table_name, name = nil)
        return [] if table_name.blank?
        table_name = table_name.to_s if table_name.is_a?(Symbol)
        table_name = table_name.split('.')[-1] unless table_name.nil?
        table_name = table_name.gsub(/[\[\]]/, '')

# GATHER THE COLUMNS FROM MsAccess IN HERE
# column_name, default_value, data_type, is_nullable
        columns = []
        result = []
        self.columns_from_catalog(table_name).each do |ole_column|
    # With the properties and collections of a Column object, you can: 
    # 
    # Identify the column with the Name property. 
    # Specify the data type of the column with the Type property. 
    # Determine if the column is fixed-length, or if it can contain null values with the Attributes property. 
    # Specify the maximum size of the column with the DefinedSize property. 
    # For numeric data values, specify the scale with the NumericScale property. 
    # For numeric data value, specify the maximum precision with the Precision property. 
    # Specify the Catalog that owns the column with the ParentCatalog property. 
    # For key columns, specify the name of the related column in the related table with the RelatedColumn property. 
    # For index columns, specify whether the sort order is ascending or descending with the SortOrder property. 
    # Access provider-specific properties with the Properties collection. 
          column_name = ole_column.Name
    # Problematic Types in JetSQL -> Types in MySQL
    #   COUNTER -> Integer AUTOINCREMENT
    #   CURRENCY -> Decimal(8,2)
# Proof-of-concept: The .Type contains the type, but do we need to translate the type?
          type = type_constant_for(ole_column.Type) # -> Returns a number. How do we match them up?
# Proof-of-concept: The .Attributes contains a constant or something -- is this given to us as a string?
          is_nullable = ole_column.Attributes == 'adColNullable' ? true : false
# Need to gather the length / precision / scale, etc from Access too.
          # if field[:ColType] =~ /numeric|decimal/i
          #   type = "#{field[:ColType]}(#{field[:numeric_precision]},#{field[:numeric_scale]})"
          # else
          #   type = "#{field[:ColType]}(#{field[:Length]})"
          # end
# Does Access have an IsIdentity feature?
          # is_identity = field[:IsIdentity] == 1
          columns << MsAccessColumn.new(column_name, self.default_value_for_column(ole_column), ole_column, self.ole_table(table_name), type, is_nullable)
        end

        columns
      end

      def columns_hash(table_name)
        chash = {}
        self.columns.each do |column|
          chash[column.name] = column
        end
        chash
      end

      def prefetch_primary_key?(table_name=nil)
        self.columns(table_name).each do |col|
          if col.property_value('Autoincrement')
            return false
          end
        end
        return true
      end

      def table_has_numeric_primary_key?(table_name)
        has_numeric_primary_key = false
        self.columns.each do |column|
            # has_numeric_primary_key = true
        end
        has_numeric_primary_key
      end

      def default_sequence_name(table_name, primary_key) # :nodoc:
        "#{table_name} #{primary_key}"
      end
      
      def next_sequence_value(sequence_name) #sequence_name will be like #{table_name}_seq
        table_name, primary_key = sequence_name.split(' ')
        self.columns(table_name).each do |col|
          if col.property_value('Autoincrement')
            return col.property_value('Seed') #Not completely sure if this part works properly yet!
          end
        end
        #At this point, there was no autoincrement field. Sometimes the primary key field is not set to autoincrement, but the software is intended to do that. Therefore, we can do a select query to get that value.
        return self.select_value("SELECT TOP 1 #{primary_key} AS single_value FROM [#{table_name}] ORDER BY #{primary_key} DESC").to_i+1
      end

      def default_value_for_column(ole_column)
        # if self.primary
        #   get_next_autoincrement_number(table_name)
        # else
          self.column_property_value(ole_column, 'Default')
        # end
      end

      def column_property_value(ole_column, prop_name)
        ole_column.Properties.each do |prop|
          return unquote_property_value(prop.Value) if prop.Name == prop_name
        end
      end

      # fix for MsAccess!
      def insert(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        execute(sql, name)
        id_value || select_one("SELECT @@IDENTITY AS Ident")["Ident"]
      end

      def update(sql, name = nil)
        execute(sql, name) do |handle|
          handle.rows
        end || select_one("SELECT @@ROWCOUNT AS AffectedRows")["AffectedRows"]
        # fix select_one part for MsAccess!
      end
      
      alias_method :delete, :update

      def execute(sql, name = nil)
# Take out identity_insert stuff for MsAccess
        log(sql, name) do
          @connection.Execute(sql) do |handle|
            yield(handle) if block_given?
          end
        end
      end

      def begin_db_transaction
        @connection.BeginTrans
      rescue Exception
        # Transactions aren't supported
      end

      def commit_db_transaction
        @connection.CommitTrans
      rescue Exception
        # Transactions aren't supported
      end

      def rollback_db_transaction
        @connection.RollbackTrans
      rescue Exception
        # Transactions aren't supported
      end

      def quote(value, column = nil)
        return value.quoted_id if value.respond_to?(:quoted_id)

        case value
          when TrueClass             then '1'
          when FalseClass            then '0'
          else
            if value && value.respond_to?(:acts_like) && value.respond_to?(:strftime) && value.acts_like?(:time)
              "##{value.strftime("%Y/%m/%d %H:%M:%S")}#"
            elsif value && value.respond_to?(:acts_like) && value.respond_to?(:strftime) && value.acts_like?(:date)
              "##{value.strftime("%Y/%m/%d")}#"
            else
              super
            end
        end
      end

      def quote_string(string)
        string.gsub(/\'/, "''")
      end

      def quote_column_name(name)
        "[#{name}]"
      end

      # fix for MsAccess!
      def add_limit_offset!(sql, options)
        if options[:limit] and options[:offset]
          the_sql = "SELECT count(*) as TotalRows from (#{sql.gsub(/\bSELECT(\s+DISTINCT)?\b/i, "SELECT#{$1} TOP 1000000000")}) tally"
#          the_sql = "SELECT count(*) as TotalRows from (#{sql.gsub(/\bSELECT(\s+DISTINCT)?\b/i, "SELECT#{$1} ")})"

          #          #          the_sql = "SELECT 5"
#          puts the_sql
          total_rows = select_value(the_sql)
#          puts "SELECT count(*) as TotalRows from (#{sql.gsub(/\bSELECT(\s+DISTINCT)?\b/i, "SELECT#{$1} TOP 1000000000")}) tally"
#          total_rows = @connection.select_all("SELECT count(*) as TotalRows from (#{sql.gsub(/\bSELECT(\s+DISTINCT)?\b/i, "SELECT#{$1} TOP 1000000000")}) tally")[0][:TotalRows].to_i
#          total_rows = @connection.select_value("SELECT count(*) as TotalRows from (#{sql.gsub(/\bSELECT(\s+DISTINCT)?\b/i, "SELECT#{$1} TOP 1000000000")}) tally")
#          total_rows = @connection.select_value("SELECT count(*) as TotalRows from (#{sql.gsub(/\bSELECT(\s+DISTINCT)?\b/i, "SELECT#{$1} TOP 1000000000")}) tally")
          if (options[:limit] + options[:offset]) >= total_rows
            options[:limit] = (total_rows - options[:offset] >= 0) ? (total_rows - options[:offset]) : 0
          end
          sql.sub!(/^\s*SELECT(\s+DISTINCT)?/i, "SELECT * FROM (SELECT TOP #{options[:limit]} * FROM (SELECT#{$1} TOP #{options[:limit] + options[:offset]} ")
          sql << ") AS tmp1"
          if options[:order]
            options[:order] = options[:order].split(',').map do |field|
              parts = field.split(" ")
              tc = parts[0]
              if sql =~ /\.\[/ and tc =~ /\./ # if column quoting used in query
                tc.gsub!(/\./, '\\.\\[')
                tc << '\\]'
              end
              if sql =~ /#{tc} AS (t\d_r\d\d?)/
                parts[0] = $1
              elsif parts[0] =~ /\w+\.(\w+)/
                parts[0] = $1
              end
              parts.join(' ')
            end.join(', ')
            sql << " ORDER BY #{change_order_direction(options[:order])}) AS tmp2 ORDER BY #{options[:order]}"
          else
            sql << " ) AS tmp2"
          end
        elsif sql !~ /^\s*SELECT (@@|COUNT\()/i
          sql.sub!(/^\s*SELECT(\s+DISTINCT)?/i) do
            "SELECT#{$1} TOP #{options[:limit]}"
          end unless options[:limit].nil?
        end
      end

      def add_limit_without_offset!(sql, limit) 
        limit.nil? ? sql : sql.gsub!(/SELECT/i, "SELECT TOP #{limit}") 
      end

      def recreate_database(name)
        drop_database(name)
        create_database(name)
      end

      def drop_database(name)
        execute "DROP DATABASE #{name}"
      end

      def create_database(name)
        execute "CREATE DATABASE #{name}"
      end
   
      # fix for MsAccess!
      def current_database
        @connection.select_one("select DB_NAME()")[0]
      end

      def type_constant_for(type_int)
        {
          20 => 'adBigInt',
          128 => 'adBinary',
          11 => 'adBoolean',
          8 => 'adBSTR',
          136 => 'adChapter',
          129 => 'adChar',
          6 => 'adCurrency',
          7 => 'adDate',
          133 => 'adDBDate',
          134 => 'adDBTime',
          14 => 'adDecimal',
          5 => 'adDouble',
          0 => 'adEmpty',
          10 => 'adError',
          64 => 'adFileTime',
          72 => 'adGUID',
          3 => 'adInteger',
          205 => 'adLongVarBinary',
          201 => 'adLongVarChar',
          203 => 'adLongVarWChar',
          131 => 'adNumeric',
          138 => 'adPropVariant',
          4 => 'adSingle',
          2 => 'adSmallInt',
          16 => 'adTinyInt',
          21 => 'adUnsignedBigInt',
          19 => 'adUnsignedInt',
          18 => 'adUnsignedSmallInt',
          17 => 'adUnsignedTinyInt',
          132 => 'adUserDefined',
          204 => 'adVarBinary',
          200 => 'adVarChar',
          12 => 'adVariant',
          139 => 'adVarNumeric',
          202 => 'adVarWChar',
          130 => 'adWChar'
        }[type_int]
      end

      # fix for MsAccess!
      def indexes(table_name, name = nil)
        ActiveRecord::Base.connection.instance_variable_get("@connection")["AutoCommit"] = false
        indexes = []        
        execute("EXEC sp_helpindex '#{table_name}'", name) do |handle|
          if handle.column_info.any?
            handle.each do |index| 
              unique = index[1] =~ /unique/
              primary = index[1] =~ /primary key/
              if !primary
                indexes << IndexDefinition.new(table_name, index[0], unique, index[2].split(", ").map {|e| e.gsub('(-)','')})
              end
            end
          end
        end
        indexes
      ensure
        ActiveRecord::Base.connection.instance_variable_get("@connection")["AutoCommit"] = true
      end

      def ole_table(table_name)
        self.catalog.Tables.each do |t|
          return t if t.Name == table_name
        end
        return nil
      end

      def rename_table(name, new_name)
        ole_table(name.to_s).Name = new_name.to_s
      end

      # Adds a new column to the named table.
      # See TableDefinition#column for details of the options you can use.
      def add_column(table_name, column_name, type, options = {})
        add_column_sql = "ALTER TABLE #{table_name} ADD #{quote_column_name(column_name)} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
        add_column_options!(add_column_sql, options)
        # TODO: Add support to mimic date columns, using constraints to mark them as such in the database
        # add_column_sql << " CONSTRAINT ck__#{table_name}__#{column_name}__date_only CHECK ( CONVERT(CHAR(12), #{quote_column_name(column_name)}, 14)='00:00:00:000' )" if type == :date       
        execute(add_column_sql)
      end
       
      def rename_column(table, column, new_column_name)
        execute "EXEC sp_rename '#{table}.#{column}', '#{new_column_name}'"
      end
      
      def change_column(table_name, column_name, type, options = {}) #:nodoc:
        sql_commands = ["ALTER TABLE #{table_name} ALTER COLUMN #{column_name} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"]
        if options_include_default?(options)
          remove_default_constraint(table_name, column_name)
          sql_commands << "ALTER TABLE #{table_name} ADD CONSTRAINT DF_#{table_name}_#{column_name} DEFAULT #{quote(options[:default], options[:column])} FOR #{column_name}"
        end
        sql_commands.each {|c|
          execute(c)
        }
      end
      
      def change_column_default(table_name, column_name, default)
        remove_default_constraint(table_name, column_name)
        execute "ALTER TABLE #{table_name} ADD CONSTRAINT DF_#{table_name}_#{column_name} DEFAULT #{quote(default, column_name)} FOR #{column_name}"   
      end
      
      def remove_column(table_name, column_name)
        execute "ALTER TABLE [#{table_name}] DROP COLUMN [#{column_name}]"
      end
      
      def remove_default_constraint(table_name, column_name)
        constraints = select "select def.name from sysobjects def, syscolumns col, sysobjects tab where col.cdefault = def.id and col.name = '#{column_name}' and tab.name = '#{table_name}' and col.id = tab.id"
        
        constraints.each do |constraint|
          execute "ALTER TABLE #{table_name} DROP CONSTRAINT #{constraint["name"]}"
        end
      end
      
      def remove_check_constraints(table_name, column_name)
        # TODO remove all constraints in single method
        constraints = select "SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = '#{table_name}' and COLUMN_NAME = '#{column_name}'"
        constraints.each do |constraint|
          execute "ALTER TABLE #{table_name} DROP CONSTRAINT #{constraint["CONSTRAINT_NAME"]}"
        end
      end
      
      def remove_index(table_name, options = {})
        execute "DROP INDEX #{table_name}.#{quote_column_name(index_name(table_name, options))}"
      end

#       def select_value(sql, name=nil)
# puts "Executing SQL \"#{sql}\", looking for #{name}"
#         records = select(sql, name)
#         return records[0][name]
#       end

#      private 
        def select(sql, name=nil)
#          puts sql
          repair_special_columns(sql)
          recordset = WIN32OLE.new('ADODB.Recordset')
          puts sql
          recordset.Open(sql, @connection) # Fails for some databases: why?
          recordset
          rows = []
          recordset.GetRows.each do |row|
            rows << row
          end unless recordset.EOF
          records = rows.transpose
          result = []
          records.each do |row|
            row_hash = {}
            row.each_with_index do |value, i|
              row_hash[field_names_from_recordset(recordset)[i]] = value
            end
            result << row_hash
          end
          recordset.Close
          recordset = nil
          result
        end
        # def select_one(sql, name=nil)
        #   result = select(sql, name)
        #   result.first if result
        # end

        def unquote_property_value(value)
          if value =~ /\\?["'](.+)\\?["']/
            value = $1
          end
          value
        end

        def field_names_from_recordset(recordset)
          fields = []
          recordset.Fields.each do |field|
            fields << field.Name # + "("+self.type_constant_for(field.Type)+")"
          end
          return fields
        end

        # Turns IDENTITY_INSERT ON for table during execution of the block
        # N.B. This sets the state of IDENTITY_INSERT to OFF after the
        # block has been executed without regard to its previous state

        def with_identity_insert_enabled(table_name, &block)
          set_identity_insert(table_name, true)
          yield
        ensure
          set_identity_insert(table_name, false)  
        end
        
        def set_identity_insert(table_name, enable = true)
          execute "SET IDENTITY_INSERT #{table_name} #{enable ? 'ON' : 'OFF'}"
        rescue Exception => e
          raise ActiveRecordError, "IDENTITY_INSERT could not be turned #{enable ? 'ON' : 'OFF'} for table #{table_name}"  
        end

        def get_table_name(sql)
          if sql =~ /^\s*insert\s+into\s+([^\(\s]+)\s*|^\s*update\s+([^\(\s]+)\s*/i
            $1
          elsif sql =~ /from\s+([^\(\s]+)\s*/i
            $1
          else
            nil
          end
        end

        def identity_column(table_name)
          @table_columns = {} unless @table_columns
          @table_columns[table_name] = columns(table_name) if @table_columns[table_name] == nil
          @table_columns[table_name].each do |col|
            return col.name if col.identity
          end

          return nil
        end

        def query_requires_identity_insert?(sql)
          table_name = get_table_name(sql)
          id_column = identity_column(table_name)
          sql =~ /\[#{id_column}\]/ ? table_name : nil
        end

        def change_order_direction(order)
          order.split(",").collect {|fragment|
            case fragment
              when  /\bDESC\b/i     then fragment.gsub(/\bDESC\b/i, "ASC")
              when  /\bASC\b/i      then fragment.gsub(/\bASC\b/i, "DESC")
              else                  String.new(fragment).split(',').join(' DESC,') + ' DESC'
            end
          }.join(",")
        end

        def get_special_columns(table_name)
          special = []
          @table_columns ||= {}
          @table_columns[table_name] ||= columns(table_name)
          @table_columns[table_name].each do |col|
            special << col.name if col.is_special
          end
          special
        end

        def repair_special_columns(sql)
          special_cols = get_special_columns(get_table_name(sql))
          for col in special_cols.to_a
            sql.gsub!(Regexp.new(" #{col.to_s} = "), " #{col.to_s} LIKE ")
            sql.gsub!(/ORDER BY #{col.to_s}/i, '')
          end
          sql
        end

    end #class MsAccessAdapter < AbstractAdapter
  end #module ConnectionAdapters
end #module ActiveRecord
