require "with_xml"

ActiveRecord::Base.class_eval do
  include WithXml
end