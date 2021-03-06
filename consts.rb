DEBUG = false
DLOG = true
LISTENPORT = 2323
QWK = true
QWK_DEBUG = false
NNTP = true
FIDO =true
SMTP = false
IRC_ON =  true
IRC_DEBUG = true
SCREENSAVER = true
FLASH_POL = false
MULTIBBS = true

#this is the port for the flash policy server, which is for allowing flash based
#telnet clients.  It actually runs on port 843, but that cannot be done on
#linux without root.  You should either use a router to translate port 8430 to
#port 843 or use iptables to do the same thing.

POLICYPORT = 8430

#how long to wait between IRC reconnect attempts.  Set to 0 to not reconnect.
BOT_RECONNECT_DELAY = 60

BBS_LIST_MSG_AREA = 21
BBS_LIST_USER = "BBSINFO"

#if the schedule thread hangs, how long to wait to try again.
SCHED_RECONNECT_DELAY = 480
BS = 8
ESC = 27
DBS =127
CR = 13
LF = 10
CTRL_U = 21
QUOTE = 230.chr
DLIM = 13.chr
DAY_SEC = 86400
CLS ="\e[2J"
HOME = "\e[H"
CRLF = "\r\n"
NOECHOCHAR = 46
LOW = 0..31
PRINTABLE = 32..126
TELNETCMD = 250..255
SPACE = " "
YESNO ="%W;(%Y;Y,%R;n%W;): "
NOYES ="%W;(%R;y,%Y;N%W;): "
RET = "%Y;<--^%W;"
IRC_PROMPT= "%G;:%W;"


ECHO = true
NOECHO = false
WRAP = true
NOWRAP = false
VER = "QUARKware (QBBS) 8b"
DONE = false

SYSOPNAME = "SYSOP"
FEEDBACK_TO = "THE DOCTOR"

SYSTEMNAME = "TARDIS BBS"
SYSTEMLOCATION = "The TARDIS"
NODES = 10
ROOT_PATH = "/home/mark/QBBS/"




#QOTD location (or nil for disabled)

QOTD = "/usr/share/games/fortunes"

#Today in History location (or nil for disabled)

TIH = "#{ROOT_PATH}/tih.dat"

# Full Screen Editor
FULLSCREENPROG = 'nano -R -r 78 -Q"> " -t -o %a'
#FULLSCREENPROG = 'ruby edit.rb -L %a'
FULLSCREENDIR = "#{ROOT_PATH}quote"

#IRC/Chat Settings

IRCSERVER = "irc.rizon.net"
IRCPORT = 6667
IRCCHANNEL = "#hecnet_chat" 
IRCBOTUSER = "HAL9000"
IRCTOPIC = "Knownspace and RetroBBS Chat"
IRCBOTCMD = "!"

IRCOPERID = "HAL9000T"
IRCOPERPSWD = "x1g9t6m3a0"


#QWK/REP Settings (to be converted to postgres for multiple networks)

QWKMAIL = 0

#Defaults... Don't change, unless you want to.

D_QWKEXT = "QWK"
D_REPEXT = "REP"
D_QWKDIR = "qwk"
D_REPDIR = "rep"
D_REPDATA = "MSG"

#How long QWK message routes live, in days...

ROUTE_SCAVENGE = 90


D_QWKTAG ="* TARDIS BBS - Home of QUARKware * telnet bbs.cortex-media.info"


QWKREPINTERVAL = 15
QWKDOWNLOADTIMEOUT = 600

#NNTP settings

NNTP_TEAR = "---"
NNTP_TAG = "#{VER} - QUARKnntp 0.9"



#FidoNET settings

FIDOUSER = "FIDONET"
NETMAIL = "NETMAIL"
BADNETMAIL = "BADNETMAIL"

FIDOINTERVAL = 10

FIDOZONE = 3
FIDONET = 712
FIDONODE = 848
FIDOPOINT = 42

H_FIDONET = 712
H_FIDONODE = 848
H_FIDOZONE = 3

H_PKT_PASSWORD = "answer42"
TOPT = 0
FMPT = FIDOPOINT

TZONE = "GMT"
CHARSET = "PC-8"
TID = "QUARKtoss .5"

TEAR = "--- #{VER}"
ORGIN = " * Origin: TARDIS BBS - bbs.retrobbs.org (#{FIDOZONE}:#{FIDONET}/#{FIDONODE}.#{FIDOPOINT})"

TEMPINDIR = "#{ROOT_PATH}fido/tempin"
TEMPOUTDIR = "#{ROOT_PATH}fido/tempout"
BUNDLEOUTDIR = "#{ROOT_PATH}fido/out"
BUNDLEINDIR = "#{ROOT_PATH}fido/in"
PKTTEMP  = "#{ROOT_PATH}fido/packet"
BACKUPIN = "#{ROOT_PATH}fido/backup_in"
BACKUPOUT = "#{ROOT_PATH}fido/backup_out"
SPOOL = "#{ROOT_PATH}fido/spool/out"

#SMTP Settings

MAILBOXDIR = "/var/mail/mark"
TEMPSMTPDIR = "#{ROOT_PATH}smtp-in/mark"
POSTMASTER = "postmaster@bbs.retrobbs.org"
SMTPDOMAIN = "bbs.retrobbs.org"
SMTPSERVER = "127.0.0.1"
#General Settings

TEXTPATH ="text/"

MAXMESSAGESIZE = 80
DEFLEVEL = 60
TELESYSOPLEVEL = 192
MAXSESSIONS = 40

MAXPASSWORDMISS = 3

IDLEWARN = 5

IDLELIMIT = 10
TDLELIMIT = 600


WEB_IDLE_MAX = 30
MAX_L_CALLERS = 10

#Door Constants
DOS     = 0
LINUX   = 1
RSTS    = 2

RBBS  = 0
RBBSDROPFILE = "DORINFO1.DEF"

RSTS_MAX = 50
RSTS_BASE = 100
RSTS_DEFAULT_PSWD = "R5J3Y9S0"

DATABASE = "qbbs"
DATAIP   = "127.0.0.1"


COLORTABLE = {
  '%R;' => "\e[0m\e[;1;31m", '%G;' => "\e[0m\e[;1;32m",
  '%Y;' => "\e[0m\e[;1;33m", '%B;' => "\e[0m\e[;1;34m",
  '%M;' => "\e[0m\e[;1;35m", '%C;' => "\e[0m\e[;1;36m",
  '%W;' => "\e[0m\e[;1;37m", '%r;' => "\e[0m\e[;31m",
  '%g;' => "\e[0m\e[;32m", '%y;' => "\e[0m\e[;33m",
  '%b;' => "\e[0m\e[;34m", '%m;' => "\e[0m\e[;35m",
  '%c;' => "\e[0m\e[;36m", '%w;' => "\e[0m\e[;37m",

  '%RR;' => "\e[;1;31;41m", '%Gr;' => "\e[;1;32;41m",
  '%YR;' => "\e[;1;33;41m", '%Br;' => "\e[;1;34;41m",
  '%MR;' => "\e[;1;35;41m", '%Cr;' => "\e[;1;36;41m",
  '%WR;' => "\e[;1;37;41m", '%rr;' => "\e[;31;41m",
  '%gr;' => "\e[;32;41m", '%yr;' => "\e[;33;41m",
  '%br;' => "\e[;34;41m", '%mr;' => "\e[;35;41m",
  '%cr;' => "\e[;36;41m", '%wr;' => "\e[;31;41m",

  '%RG;' => "\e[;1;31;42m", '%GG;' => "\e[;1;32;42m",
  '%YG;' => "\e[;1;33;42m", '%BG;' => "\e[;1;34;42m",
  '%MG;' => "\e[;1;35;42m", '%CG;' => "\e[;1;36;42m",
  '%WG;' => "\e[;1;37;42m", '%rg;' => "\e[;31;42m",
  '%gg;' => "\e[;32;42m", '%yg;' => "\e[;33;42m",
  '%bg;' => "\e[;34;42m", '%mg;' => "\e[;35;42m",
  '%cg;' => "\e[;36;42m", '%wg;' => "\e[;31;42m",

  '%RY;' => "\e[;1;31;43m", '%GY;' => "\e[;1;32;43m",
  '%YY;' => "\e[;1;33;43m", '%BY;' => "\e[;1;34;43m",
  '%MY;' => "\e[;1;35;43m", '%CY;' => "\e[;1;36;43m",
  '%WY;' => "\e[;1;37;43m", '%ry;' => "\e[;31;43m",
  '%gy;' => "\e[;32;43m", '%yy;' => "\e[;33;43m",
  '%by;' => "\e[;34;43m", '%my;' => "\e[;35;43m",
  '%cy;' => "\e[;36;43m", '%wy;' => "\e[;31;43m",

  '%RB;' => "\e[;1;31;44m", '%GB;' => "\e[;1;32;44m",
  '%YB;' => "\e[;1;33;44m", '%BB;' => "\e[;1;34;44m",
  '%MB;' => "\e[;1;35;44m", '%CB;' => "\e[;1;36;44m",
  '%WB;' => "\e[;1;37;44m", '%rb;' => "\e[;31;44m",
  '%gb;' => "\e[;32;44m", '%yb;' => "\e[;33;44m",
  '%bb;' => "\e[;34;44m", '%mb;' => "\e[;35;44m",
  '%cb;' => "\e[;36;44m", '%wb;' => "\e[;31;44m",

  '%RM;' => "\e[;1;31;45m", '%GM;' => "\e[;1;32;45m",
  '%YM;' => "\e[;1;33;45m", '%BM;' => "\e[;1;34;45m",
  '%MM;' => "\e[;1;35;45m", '%CM;' => "\e[;1;36;45m",
  '%WM;' => "\e[;1;37;45m", '%rm;' => "\e[;31;45m",
  '%gm;' => "\e[;32;45m", '%ym;' => "\e[;33;45m",
  '%bm;' => "\e[;34;45m", '%mm;' => "\e[;35;45m",
  '%cm;' => "\e[;36;45m", '%wm;' => "\e[;31;45m",

  '%RC;' => "\e[;1;31;46m", '%GC;' => "\e[;1;32;46m",
  '%YC;' => "\e[;1;33;46m", '%BC;' => "\e[;1;34;46m",
  '%MC;' => "\e[;1;35;46m", '%CC;' => "\e[;1;36;46m",
  '%WC;' => "\e[;1;37;46m", '%rc;' => "\e[;31;46m",
  '%gc;' => "\e[;32;46m", '%yc;' => "\e[;33;46m",
  '%bc;' => "\e[;34;46m", '%mc;' => "\e[;35;46m",
  '%cc;' => "\e[;36;46m", '%wc;' => "\e[;31;46m",

  '%RW;' => "\e[;1;31;47m", '%GW;' => "\e[;1;32;47m",
  '%YW;' => "\e[;1;33;47m", '%BW;' => "\e[;1;34;47m",
  '%MW;' => "\e[;1;35;47m", '%CW;' => "\e[;1;36;47m",
  '%WW;' => "\e[;1;37;47m", '%rw;' => "\e[;31;47m",
  '%gw;' => "\e[;32;47m", '%yw;' => "\e[;33;47m",
  '%bw;' => "\e[;34;47m", '%mw;' => "\e[;35;47m",
  '%cw;' => "\e[;36;47m", '%ww;' => "\e[;31;47m"
}





CELERITY_COLORTABLE = {
  '|R' => "\e[;1;31;40m", '|G' => "\e[;1;32;40m",
  '|Y' => "\e[;1;33;40m", '|B' => "\e[;1;34;40m",
  '|M' => "\e[;1;35;40m", '|C' => "\e[;1;36;40m",
  '|W' => "\e[;1;37;40m", '|r' => "\e[;31;40m",
  '|g' => "\e[;32;40m", '|y' => "\e[;33;40m",
  '|b' => "\e[;34;40m", '|m' => "\e[;35;40m",
  '|c' => "\e[;36;40m", '|w' => "\e[;31;40m"
}

IRCCOLORTABLE = {
  "\cc04" => "\e[;1;31;40m", "\cc03" => "\e[;1;32;40m",
  "\cc08" => "\e[;1;33;40m", "\cc02" => "\e[;1;34;40m",
  "\cc06" => "\e[;1;35;40m", "\cc11" => "\e[;1;36;40m",
  "\cc16" => "\e[;1;37;40m", "\cc05" => "\e[;31;40m",
  "\cc09" => "\e[;32;40m", "\cc07" => "\e[;33;40m",
  "\cc12" => "\e[;34;40m", "\cc14" => "\e[;35;40m",
  "\cc10" => "\e[;36;40m", "\cc15" => "\e[;31;40m",
  "\co" =>  "\e[;1;37;40m"
}





TIME_TABLE = {
  "40F0"  => "Atlantic", "412C"  => "Eastern",
  "4168"  => "Central", "41A4"  => "Mountain",
  "41E0"  => "Pacific", "421C"  => "Yukon",
  "4258"  => "Hawaii/Alaska", "4294"  => "Bering",
  "C0F0" => "Atlantic-D","C12C" => "Eastern-D",
  "C168" => "Central-D","C1A4" => "Mountain-D",
  "C1E0" => "Pacific","C21C" => "Yukon",
  "C258" => "Hawaii/Alaska-D","C294" => "BerinG-D",
  "2294" => "Midway","21E0" => "Vancouver",
  "21A4" => "Edmonton","2168" => "Winnipeg",
  "212C" => "Bogota","20F0" => "Caracas",
  "20B4" => "Rio de Janeiro","2078" => "Fernando de Noronha",
  "203C" => "Azores","1000" => "London",
  "103C" => "Berlin","1078" => "Athens",
  "10B4" => "Moscow","10F0" => "Dubai",
  "110E" => "Kabul","112C" => "Karachi",
  "114A" => "Bombay","1159" => "Kathmandu",
  "1168" => "Dhaka", "11A4" => "Bangkok",
  "11E0" => "Hong Kong","121C" => "Tokyo",
  "1258" => "Sydney","1294" => "Noumea",
"12D0" => "Wellington"}


#Mail Types

Q_NETMAIL = 1
F_NETMAIL = 2
SMTP_MAIL = 3
LOCAL     = 4

SMTP_MOVE_ERROR = 1
SMTP_SUCCESS    = 2
NO_SMTP_TO_COPY = 3

#Log Constants

L_SCHEDULE = 1
L_FIDO = 2
L_EXPORT = 3
L_IMPORT = 4
L_USER = 5
L_CONNECT = 6
L_SECURITY = 7
L_ERROR = 8
L_MESSAGE = 9

#Menu Locations

USER =1
BULLETIN = 2
READ = 3
OTHER = 4
DOOR = 5
THEME = 6
AREA = 7
SCREEN = 8
GROUP = 9
BBS = 10
PROFILE = 11

#Theme Defaults

MAIN_PROMPT = "%G;-=%M;:%C;@aname@%M;:%C;New - @new@%M;:%W;? for Menu%G;:=-%W;"
TEXT_PATH = "text/"
#READ_PROMPT = "%M%[Area #{@c_area}]%C% #{sdir} #{out}[%p] #'(1-#{h_msg}): "
