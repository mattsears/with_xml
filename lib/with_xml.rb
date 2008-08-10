require 'xmlsimple'

module WithXml
  # Customize the xml serialization for ActiveRecord objects. It uses the  with_xml block to 
  # define options declared in the ActiveRecord that allows for the customization of the to_xml and
  # from_xml call.
  #
  def self.included(base)
    base.extend ClassMethods
  end

  def self.create_mapping_for(xml)
    return self.mapper_attr_name
  end

  module ClassMethods
    
    # Specifies the options of handling incoming (from_xml) xml data and serialization (to_xml)
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

    ##
    # Override the default from_xml and perform some mapping goodness
    def from_xml(xml)
      mapper = SupportingClasses::Binder.new("<opt>#{xml}</opt>", self)
      mapped_attributes = mapper.bind
      self.attributes = mapped_attributes if mapped_attributes
      self
    end
    
    ##
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
        @name = name.to_sym
        @binders = binder_table[@name] = []
        instance_eval(&block) if block
        extract_options!(opts)
      end

      ##
      # Adds each 'bind' option to the binders array
      def bind(name, xml_attr_opts)
        @binders << SupportingClasses::XmlAttr.new(name, xml_attr_opts)
      end

      ##
      # Adds the options used to export the xml (to_xml)
      def serialize(opts)
        @serialize_opts = opts
      end

      ##
      # Return true or false if 
      def has_match?(name)
        matchers = @opts[:match] || Array.new
        return true if matchers.find {|n| n == name}
      end

      private

      def extract_options!(opts)
        return nil if opts.nil?
        @opts = opts
        @matchers = opts[:alias] if opts[:alias]
      end

    end

    class XmlAttr
      attr_reader :name
      attr_reader :matchers
      
      def initialize(name, opts)
        @name, @opts = name, opts
        @matchers = opts[:to] if opts[:to]
      end
    end

    class Binder
      attr_reader :xml, :activerecord, :with_xml

      def initialize(xml, activerecord)
        @xml, @activerecord = xml, activerecord
        @with_xml = activerecord.class.read_inheritable_attribute(:with_xml)
        @with_xml.matchers << activerecord.class.class_name.downcase
      end

      ##
      # Creates a new hash map that matches the ActiveRecord fields from the given xml
      def bind
        xml_hash =  Hash.from_xml(xml)
        new_xml = find_hash_for(xml_hash, @with_xml.matchers) do |key, value|
          break(value)
        end
        return hash_for(new_xml)
      end

      private

      ##
      # Searches all the keys (even nested) and returns the first one
      def find_hash_for(hash, desired_keys, &block)
        return false unless Hash === hash
        hash.each_pair do |key, value|
          if desired_keys.include?(key) || find_hash_for(value, desired_keys, &block)
            yield(key, value)
            return true
          end
        end
        return false
      end
      
      ##
      # Update the xml hash with the correct keys and values
      def hash_for(xml)
        return false unless Hash === xml
        xml.each do |element_name, element_value|
          field = field_for(element_name)
          xml.delete(element_name)
          if activerecord.has_attribute?(field)
            xml[field] = element_value.strip unless element_value.nil?
          end
        end
        return xml
      end

      ##
      # Given, the list of :to options, find the first ActiveRecord field that matches the given key
      def field_for(element)
        return element unless String === element
        atrribute_name = element.downcase # ignore case by default
        @with_xml.binders.each do |binder|
          if binder.name.to_s == atrribute_name || binder.matchers.include?(atrribute_name)
            return binder.name
          end
        end
        return atrribute_name
      end

    end
  end

end
