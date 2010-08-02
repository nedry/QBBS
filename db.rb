require "pg_ext"

TABLE_LIST = ["areas","bulletins","doors","other","system","groups","users","who","who_t","log","subsys","wall"]

def open_database
  # begin
  puts "-DB: Checking Tables"
  @db = PGconn.connect(DATAIP,5432,nil,nil,DATABASE,nil,nil)
  # rescue
  #  puts "-FATAL: Database Connection Failed.  Halted."
  # end
end

def result_as_array(res)
  ary=[]
  tuples = res.ntuples; tuples -=1
  for i in 0..tuples  do
    ary << []
    fields = res.nfields;fields -=1
    for j in 0..fields  do
      ary[i] << res.getvalue(i,j)
    end
  end
  return ary
end

def make_table_list
  result = []

  res = @db.exec("SELECT relname FROM pg_class \
  WHERE relname NOT LIKE 'pg_%'\
  AND relname NOT LIKE 'sql%' \
  AND relkind = 'r'")

  result = result_as_array(res)
  return result
end

def check_tables
  t_list = make_table_list.flatten

  t_list = ["none"] if t_list.nil?

  TABLE_LIST.each {|x|
    create_table(x) if t_list.index(x).nil?
  }
  puts"-DB: Tables Verified"
  puts
end

def create_table(table)
  puts "-DB: (FATAL): #{table} table not found  Run makedb.rb"
  exit
end

def set_up_database
  open_database
  make_table_list
  check_tables
  @db.close
end
