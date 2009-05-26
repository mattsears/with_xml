$:.unshift(File.dirname(__FILE__) + '/../lib')
RAILS_ROOT = File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/fixtures'
require 'action_controller'
require 'action_controller/test_process'
require 'stringio'
require 'hpricot'
require "with_xml"
require File.join(File.dirname(__FILE__), "/../init")
require File.join(File.dirname(__FILE__), '/fixtures', 'article')

# gem install redgreen for colored test output
begin require 'redgreen'; rescue LoadError; end

ActiveRecord::Base.configurations['test'] = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'][ENV['DB'] || 'sqlite3'])

load(File.dirname(__FILE__) + "/schema.rb") if File.exist?(File.dirname(__FILE__) + "/schema.rb")

FIXTURE_LOAD_PATH = File.join(File.dirname(__FILE__), '/fixtures/')

class Test::Unit::TestCase #:nodoc:

  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end

  def assert_respond_to_all object, methods
    methods.each do |method|
      [method.to_s, method.to_sym].each { |m| assert_respond_to object, m }
    end
  end

end

def load_xml_article(filename)
  dir = FIXTURE_LOAD_PATH  + "articles/"
  article = File.readlines(dir + filename).to_s
  article.chomp
end

module TagMatchers

  class TagMatcher

    def initialize(expected)
      @expected = expected
      @text     = nil
    end

    def with_text(text)
      @text = text
      self
    end

    def matches?(target)
      @target = target
      doc = Hpricot(target)
      @elem = doc.at(@expected)
      @elem && (@text.nil? || @elem.inner_html == @text) || false
    end

  end

  def has_tag(target, expression, text = nil)
    tag = TagMatcher.new(expression)
    tag.with_text(text) if text
    tag.matches?(target)
  end

end

