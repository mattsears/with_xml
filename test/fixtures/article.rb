class Article < ActiveRecord::Base

  with_xml :feeds, :alias => ["magazine", "blog", "newspaper"] do
    map :heading, :to => ["subject", "title"]
    map :body, :to => ["content[@type='copy']", "message", "post"]
    serialize :except => [ :name ], :skip_instruct => true
  end
  attr_accessor :sources
end
