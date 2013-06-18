   # Quarkware BBS
   # Copyright (C) 2013  Mark Firestone / Fly By Night Software
    
   # This program is free software: you can redistribute it and/or modify
   # it under the terms of the GNU General Public License as published by
   # the Free Software Foundation, either version 3 of the License, or
   # (at your option) any later version.

   # This program is distributed in the hope that it will be useful,
   # but WITHOUT ANY WARRANTY; without even the implied warranty of
   # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   # GNU General Public License for more details.

   # You should have received a copy of the GNU General Public License
   # along with this program.  If not, see <http://www.gnu.org/licenses/>.

$LOAD_PATH << "."
require 'top.rb'
require 'consts.rb'

#  ------------------ MAIN ------------------

$stdout.flush

DataMapper::Logger.new('log/db', :debug)
DataMapper.setup(:default, "postgres://#{DATAIP}/#{DATABASE}")
DataMapper.finalize

who = Who_old.new
debuglog = DebugLog.new
message = []
irc_who =Irc_who.new

ssock = ServerSocket.new(irc_who, who, message,debuglog)


ssock.run
