$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'json'
require 'letters'
require 'minitest/autorun'

require 'lich'

class TestLich < MiniTest::Unit::TestCase
  DATA = JSON.load(File.open(File.expand_path('../../../lich-tests.json', __FILE__)))

  def test_valid
    DATA['valid'].each do |input|
      begin
        Lich.load(input)
      rescue Lich::Error => e
        flunk "#{e}(#{e.index}) with #{input}"
      end
    end
  end

  def test_invalid
    DATA['invalid'].each do |input,ex,index|
      ex.sub!(/\ALichError_/, '')
      ex = Lich.const_get(ex)
      e = assert_raises(ex, input) { Lich.load(input) }
      assert_equal index, e.index
    end
  end

  def test_encoding
    DATA['encoding'].each do |expected,input|
      assert_equal expected, Lich.load(input), input
    end
  end
end
