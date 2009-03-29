require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class WithXmlTest < Test::Unit::TestCase
  fixtures :articles
  include TagMatchers

  def test_field_override
    article = articles(:magazine) # bind :heading, :to => ["subject", "title"]
    assert_equal "New Yorker", article.heading
    magazine = load_xml_article("magazine.xml")  #title = "The Washington Post"
    article.from_xml(magazine)
    assert_equal "The Washington Post", article.heading
  end

  # test options settings

  def test_name_setter
    fixture = Article.with_xml(:test, {:alias => ["DAILYNEWS"]} ) do
      map :heading, :to => ["subject", "title"]
    end
    assert_equal :test, fixture.name
  end

  def test_options_setter
    fixture = Article.with_xml(:test, {:alias => ["DAILYNEWS"]} ) do
      map :heading, :to => ["subject", "title"]
    end
    assert_not_nil fixture.opts[:alias]
  end

  def test_matchers
    fixture = Article.with_xml(:test, {:alias => ["BEGIN_ARTICLE", "ARTICLE"]} ) do
      map :heading, :to => ["subject", "title"]
      map :body, :to => ["message", "content"]
    end
    assert_equal 2, fixture.matchers.size
  end

  # calling from_xml

  def test_field_override
    article = articles(:magazine) # bind :heading, :to => ["subject", "title"]
    assert_equal "New Yorker", article.heading
    magazine = load_xml_article("magazine.xml")  #title = "The Washington Post"
    article.from_xml(magazine)
    assert_equal "The Washington Post", article.heading
  end

  def test_from_xml_with_new_instance
    article = Article.new  # bind :body, :to => ["content", "message", "post"]
    blog = load_xml_article("blog.xml")
    article.from_xml(blog)
    assert_equal "The Post", article.body
    assert_equal "TechCrunch", article.heading
  end

  def test_from_xml_with_unknown_field
    article = Article.new
    newspaper = load_xml_article("newspaper.xml") # contains unkown field
    article.from_xml(newspaper)
    assert_equal "The Wall Street Journal", article.heading
  end

  def test_mapper_with_no_matchers
    article = Article.new
    article_xml = load_xml_article("article.xml")
    article.from_xml(article_xml)
    assert_equal "Page Six", article.heading
    assert_equal "Content for article", article.body
  end

  def test_mapper_with_nested_root
    article = Article.new
    article_xml = load_xml_article("nested_article.xml")
    article.from_xml(article_xml.to_s)
    assert_equal "Page Six", article.heading
    assert_equal "Content for article", article.body
  end

  def test_mapper_multiple_values
    article = Article.new
    article_xml = load_xml_article("article.xml")
    article.from_xml(article_xml.to_s)
    assert_equal "Source 1 Source 2", article.sources
  end

  def test_import_with_capitalized_fields
    article = Article.new
    newspaper = load_xml_article("newspaper.xml") # contains AUTHOR in all CAPS
    article.from_xml(newspaper)
    assert_equal "Caps should be ignored by default", article.author
  end

  def test_from_xml_save
    article = Article.new  # bind :body, :to => ["content", "message", "post"]
    blog = load_xml_article("article.xml")
    assert article.save!
  end

  def test_from_xml_with_multiple_nodes
    article = articles(:magazine)
    magazine = load_xml_article("magazine.xml")  #body = "This is the content"
    article.from_xml(magazine)
    assert_equal "This is the content", article.body
  end

  def test_from_xml_with_no_root
    article = Article.new
    noroot = load_xml_article("noroot.xml")
    article.from_xml(noroot) # should not cause errors
    assert_equal nil, article.body
  end

  # calling to_xml

  def test_default_to_xml_behaviour
    article = Article.new
    xml = load_xml_article("article.xml")
    article.from_xml(xml)
    export = article.to_xml
    assert has_tag(export, '//article/heading', "Page Six")
  end

  def test_export_with_options
    article = Article.new
    xml = load_xml_article("article.xml")
    article.from_xml(xml)
    export = article.to_xml
    assert has_tag(export, '//name') == false
  end

  def test_export_with_instruct_skipped
    article = Article.new
    xml = load_xml_article("article.xml")
    article.from_xml(xml)
    export = article.to_xml
    assert_no_match(%r(<?xml.+version="1.0"[^>]*>), export)
  end

  def test_export_with_local_options
    article = Article.new
    xml = load_xml_article("article.xml")
    article.from_xml(xml)
    export = article.to_xml(:except => [:author])
    assert has_tag(export, '//name')
    assert has_tag(export, '//author') == false
  end

end
