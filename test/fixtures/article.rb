class Article < ActiveRecord::Base
  with_xml :feeds, :alias => ["magazine", "blog", "newspaper"] do
    bind :heading, :to => ["subject", "title"]
    bind :body, :to => ["content", "message", "post"]
    serialize :except => [ :name ], :skip_instruct => true
  end
end