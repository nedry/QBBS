DEBUG = true
LISTENPORT = 2323
QWK = true
QWK_DEBUG = false
FIDO = true
SMTP = false
IRC_ON =  true

BS = 8
ESC = 27
DBS =127
CR = 13
LF = 10
CTRL_U = 21
QUOTE = 230.chr
DLIM = 13.chr
#DLIM = 227.chr
CLS ="\e[2J"
HOME = "\e[H"
CRLF = "\r\n"
NOECHOCHAR = 46
LOW = 0..31
PRINTABLE = 32..126
TELNETCMD = 250..255
SPACE = " "
YESNO ="%W(%YY,%Rn%W): "
NOYES ="%W(%Ry,%YN%W): "


ECHO = true
NOECHO = false
WRAP = true
NOWRAP = false
VER = "QUARKseven (QBBS) beta"
DONE = false

SYSOPNAME = "SYSOP"

SYSTEMNAME = "Retro Computing BBS"

NODES = 10
ROOT_PATH = "/home/mark/qbbs/"



#QOTD location (or nil for disabled)

QOTD = "fortune > /home/mark/qbbs/text/quote.txt"

# Full Screen Editor
#FULLSCREENPROG = 'nano -Q"> " -t -o %a'
FULLSCREENPROG = 'ruby /home/mark/qbbs/edit.rb -L '
FULLSCREENDIR = "/home/mark/qbbs/quote"

#IRC/Chat Settings

IRCSERVER = "irc.larryniven.net"
IRCPORT = 6667
IRCCHANNEL = "#knownspace"
IRCBOTUSER = "HAL9000"
IRCTOPIC = "Knownspace and RetroBBS Chat"

IRCOPERID = "HAL9000"
IRCOPERPSWD = "x1g9t6m3a0"


#QWK/REP Settings (to be converted to postgres for multiple networks)

QWKUSER = "QWKREP"
BBSID = "VERT"
REPDATA = "rep/VERT.MSG"
REPPACKET = "rep/VERT.REP"
REPPACKETUP = "VERT.REP"

QWKPACKET ="qwk/VERT.QWK"
QWKPACKETDOWN = "VERT.QWK"
QWKDIR = "qwk"

QWKMAIL = 0

QWKTAG ="#{254.chr} retroCOMPUTING BBS - Home of QUARKware #{254.chr} telnet 81.96.235.250 2323"


QWKREPINTERVAL = 15

FTPADDRESS ="vert.synchro.net"
FTPACCOUNT ="QBBS"
FTPPASSWORD ="flatmo"


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
ORGIN = " * Origin: retroCOMPUTING BBS - bbs.retrobbs.org 2323 (#{FIDOZONE}:#{FIDONET}/#{FIDONODE}.#{FIDOPOINT})"

TEMPINDIR = "/home/mark/qbbs/fido/tempin"
TEMPOUTDIR = "/home/mark/qbbs/fido/tempout"
BUNDLEOUTDIR = "/home/mark/qbbs/fido/out"
BUNDLEINDIR = "/home/mark/qbbs/fido/in"
PKTTEMP	= "/home/mark/qbbs/fido/packet"
BACKUPIN = "/home/mark/qbbs/fido/backup_in"
BACKUPOUT = "/home/mark/qbbs/fido/backup_out"
SPOOL = "/home/mark/qbbs/fido/spool/out"

#SMTP Settings

MAILBOXDIR = "/var/mail/mark"
TEMPSMTPDIR = "/home/mark/qbbs/smtp-in/mark"
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

LIDLEWARN = 2
LIDLELIMIT = 3

RIDLEWARN = 10
RIDLELIMIT = 15

WEB_IDLE_MAX = 30
MAX_L_CALLERS = 10

#Door Constants
DOS	= 0
LINUX	= 1
RSTS    = 2

RBBS	= 0
RBBSDROPFILE = "DORINFO1.DEF"

RSTS_MAX = 50
RSTS_BASE = 100
RSTS_DEFAULT_PSWD = "R5J3Y9S0"

DATABASE = "qbbs"
DATAIP   = "127.0.0.1"

COLORTABLE = {
  '%R' => "\e[;1;31;40m", '%G' => "\e[;1;32;40m",
  '%Y' => "\e[;1;33;40m", '%B' => "\e[;1;34;40m",
  '%M' => "\e[;1;35;40m", '%C' => "\e[;1;36;40m",
  '%W' => "\e[;1;37;40m", '%r' => "\e[;31;40m",
  '%g' => "\e[;32;40m", '%y' => "\e[;33;40m",
  '%b' => "\e[;34;40m", '%m' => "\e[;35;40m",
  '%c' => "\e[;36;40m", '%w' => "\e[;31;40m"
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


