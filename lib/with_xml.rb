require 'xml'

module WithXml

  # Customize the xml serialization for ActiveRecord objects. It uses the
  # with_xml block to define options declared in the ActiveRecord that
  # allows for the customization of the to_xml and from_xml call.
  def self.included(base)
    base.extend ClassMethods
  end

  def self.create_mapping_for(xml)
    return self.mapper_attr_name
  end

  module ClassMethods

    # Specifies the options of handling incoming (from_xml) xml data and
    # serialization (to_xml)
    #
    #   class Article < ActiveRecord::Base
    #     with_xml :feed, :to => ["magazine", "blog", "newspaper"] do
    #       bind :heading, :to => ["subject", "title"]
    #       bind :body, :to => ["content", "message", "post"]
    #       serialize :except => [ :name ], :skip_instruct => true
    #     end
    #   end
    #
    def with_xml(name, options = {}, &block)
      self.send(:include, WithXml::InstanceMethods)
      write_inheritable_attribute :binder_table, {}
      class_inheritable_reader    :transition_table
      xt = read_inheritable_attribute(:binder_table)
      with_xml = SupportingClasses::WithXmlMacro.new(name, options, xt, &block)
      write_inheritable_attribute :with_xml, with_xml
    end

  end

  module InstanceMethods

    # Override the default from_xml and perform some mapping goodness
    #  +xml+ string of the xml to import
    def from_xml(xml)
      mapper = SupportingClasses::Binder.new("#{xml}", self)
      mapped_attributes = mapper.map
      self.attributes = mapped_attributes if mapped_attributes
      self
    end

    # Override the default to_xml with our custom options
    def to_xml(options = {}, &block)
      with_xml = self.class.read_inheritable_attribute(:with_xml)
      if with_xml
        options = with_xml.serialize_opts.merge(options)
      end
      super(options, &block)
    end

  end

  module SupportingClasses

    class WithXmlMacro
      attr_reader :name
      attr_reader :binders
      attr_reader :opts
      attr_reader :matchers
      attr_reader :serialize_opts

      def initialize(name, opts, binder_table, &block)
        @matchers = []
        @name = name.to_sym
        @binders = binder_table[@name] = {}
        instance_eval(&block) if block
        extract_options!(opts)
      end

      # Adds each 'bind' option to the binders array
      #  +name+ of the attribute
      def map(name, xml_attr_opts)
        @binders[name] = SupportingClasses::XmlAttr.new(name, xml_attr_opts)
      end

      # Adds the options used to export the xml (to_xml)
      def serialize(opts)
        @serialize_opts = opts
      end

      # Return true or false if we have a match
      #  +name+ of the element to match
      def has_match?(name)
        matchers = @opts[:match] || Array.new
        return true if matchers.find {|n| n == name}
      end

      private

      # Parse options decalared in the with_xml
      def extract_options!(opts)
        return nil if opts.nil?
        @opts = opts
        @matchers = opts[:alias] if opts[:alias]
        @matchers.collect!{|x| x.to_s}
      end

    end

    class XmlAttr
      attr_reader :name
      attr_reader :matchers

      def initialize(name, opts = {})
        @matchers = []
        @name, @opts = name.to_s, opts
        opts[:to] = [] unless opts[:to]
        opts[:to].insert(0, name.to_s)
        @matchers = opts[:to].flatten
      end
    end

    class Binder
      attr_reader :xml, :activerecord, :with_xml

      def initialize(xml, activerecord)
        @xml, @activerecord = xml, activerecord
        @with_xml = activerecord.class.read_inheritable_attribute(:with_xml)
        @with_xml.matchers << activerecord.class.class_name.downcase
      end

      # Creates a new hash map that matches the ActiveRecord fields from the given xml
      def map
        xml_attrs = {}
        return xml_attrs unless valid_xml?(xml)

        activerecord.attributes.each_key do |key|
          if !@with_xml.binders.has_key?(key.to_sym)
            @with_xml.binders[key.to_sym] = SupportingClasses::XmlAttr.new(key)
          end
        end

        root_xml = find_root_element(xml)
        if root_xml
          xml_attrs = find_attributes_for(root_xml)
        end
        return xml_attrs
      end

      private

      # Determine if the xml is well-formed or not
      #   +xml+ string to validate
      def valid_xml?(xml)
        begin
          XML::Document.string(xml)
        rescue Exception
          return false
          # Return nil if an exception is thrown
        end
      end

      # Based on the aliases, find the root element of the xml document
      #   +xml+ string that contains the root elements
      def find_root_element(xml)
        doc = XML::Document.string(xml)
        @with_xml.matchers.each do |root|
          if new_xml = find_element(doc, root)
            return new_xml
          end
        end
        return false
      end

      # Given, the list of :to options, find the first ActiveRecord
      # field that matches the given key
      def find_attributes_for(element)
        attrs = {}
        @with_xml.binders.each do |key, binder|
          binder.matchers.each do |matcher|
            if node = find_element(element, matcher)
              attrs[binder.name] = find_text(node)
            end
          end
        end
        return attrs
      end

      # Find the first element matching the xpath (ignores case)
      #  +doc+ to be searched
      def find_element(doc, xpath = '/')
        xml = (doc.find_first("//#{xpath}") ||
              doc.find_first("//#{xpath.downcase}") ||
              doc.find_first( "//#{xpath.upcase}"))
        return xml
      end

      # Find and format each element text
      def find_text(doc)
        return if doc.nil?
        text = ""
        doc.children.each do |child|
          text << "#{child.content.strip} " unless child.content.strip.empty?
        end
        text.strip
      end

    end
  end

end
