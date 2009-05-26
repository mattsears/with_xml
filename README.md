with_xml
====

A simple plugin for customizing behaviour and importing xml documents into ActiveRecord objects.

## Installation ##########################################################

    script/plugin install git://github.com/mattsears/with_xml.git

## Usage #################################################################

In general, you can define the xml options in the model's class definition.  In this example,
we'll set the xml options in the Article class:

    ActiveRecord::Schema.define(:version => 1) do
      create_table :articles do |t|
      t.string :name, :heading, :body, :author
    end

In the Article's class, we define the xml serialization options in the **with_xml** block like so:

    class Article < ActiveRecord::Base
      with_xml :feeds, {:alias  => ["magazine", "blog", "newspaper"]} do
        map :heading,   :to     => ["subject", "title"]
        map :body,      :to     => ["content", "message", "posts[@content='body']"]
        serialize       :except => [:name], :skip_instruct => true
      end
    end

With the **serialize option**, the script sets the global options for the **to_xml** calls.  In the code above,
we've specified not to include the :name attribute or the xml instructions in the xml return from the **to_xml** call.

    article.to_xml

...becomes...

    #<article>
    #	 <author>...</author>
    #	 <body>...</body>
    #	 <heading>...</heading>
    #</article>

The **map** options allows us to set the Article attributes with an xml string that has a different schema.  For example, data for our Article class may come from external sources such as blogs, magazines or newspapers with different xml schemas. We can use XPath to map the xml attributes or elements to the class attributes.  With the **map** options in the code above, we can import any of the following xml documents into the Article:

    article.from_xml(xml)

    #<article>
    #	 <heading>Page Six</heading>
    #	 <body>Content for article</body>
    #</article>

    #<magazine>
    #	<title>The Washington Post</title>
    #	<content>This is the content</content>
    #</magazine>

    #<blog>
    #	<title>TechCrunch</title>
    #	<post>The Post</post>
    #</blog>

    #<newspaper>
    #	<title>The Wall Street Journal</title>
    #	<content>This is the content</content>
    #	<unknown>There is no field for this element.  It will be ignored.</unknown>
    #	<AUTHOR>Caps will be  by default</AUTHOR>
    #</newspaper>

## Contact #################################################################

    Author:      Matt Sears
    Email:       matt@mattsears.com
    Home Page:   http://mattsears.com
    License:     MIT Licence (http://www.opensource.org/licenses/mit-license.html)
