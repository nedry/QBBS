require 'test/unit'
require 'dm-core'
require 'dm-validations'
require 'db/db_bulletins.rb'
require 'consts.rb'

DATAIP = 'localhost'
DATABASE = 'qbbs_test'

class TestDbBulletin < Test::Unit::TestCase
  def setup
    DataMapper.setup(:default, "postgres://#{DATAIP}/#{DATABASE}")
    Bulletin.all.each {|i| i.destroy!}
  end

  def teardown
  end

  def test_add_bulletin
    assert_equal 0, b_total
    add_bulletin("hello", "/test/hello")
    assert_equal 1, b_total
  end

  def test_delete_bulletin
    assert_equal 0, b_total
    add_bulletin("hello", "/test/hello")
    assert_equal 1, b_total
    delete_bulletin(1)
    assert_equal 0, b_total
  end

  def test_fetch_bullletin
    add_bulletin("hello", "/test/hello")
    add_bulletin("world", "/test/world")
    assert_equal 2, b_total
    b = fetch_bulletin(1)
    assert_equal "hello", b.name
    assert_equal "/test/hello", b.path
    b = fetch_bulletin(2)
    assert_equal "world", b.name
    assert_equal "/test/world", b.path
  end

  def test_update_bulletin
    add_bulletin("hello", "/test/hello")
    add_bulletin("world", "/test/world")
    assert_equal 2, b_total
    a = fetch_bulletin(1)
    a.name = "goodbye"
    a.path = "/test/foo"
    update_bulletin(a)
    b = fetch_bulletin(1)
    assert_equal "goodbye", b.name
    assert_equal "/test/foo", b.path
  end

  def test_renumber_bulletins
    %w(foo bar baz quux).each do |i|
      add_bulletin(i, "/path/to/#{i}")
    end
    assert_equal 4, b_total
    (1..4).each do |number|
      a = fetch_bulletin(number)
      assert_not_nil a
    end
    delete_bulletin(2)
    assert_equal 3, b_total
    a = fetch_bulletin(2)
    assert_nil a
    renumber_bulletins
    # this should not change the total number of bulletins
    assert_equal 3, b_total
    # but the numbers should be compacted
    a = fetch_bulletin(2)
    assert_not_nil a
    a = fetch_bulletin(4)
    assert_nil a
  end
end
