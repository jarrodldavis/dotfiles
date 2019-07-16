# frozen_string_literal: true

require 'nokogiri'

module Nokogiri
  module XML
    class Document
      def delete_property_list_keys!(keys_to_delete)
        unless keys_to_delete.is_a? Set
          raise TypeError, "Expected to receive a Set, got a #{keys_to_delete.class}"
        end

        self.
          # get root <plist> element
          root.
          # get the root's single child, a <dict> element
          child.
          # get the children of the <dict> element
          children.
          # iterate through those children
          each {|element|
            # property list dictionaries are represented as a flat array of key/value elements
            # that list alternate between <key> elements and value elements, such as <true/> or <array>
            next unless element.name == "key"

            # filter based on key name, which is the text child of <key> elements
            next unless keys_to_delete.include? element.child.text

            # remove this element (<key>) and the next (some value like <true/> or <array>)
            element.next.remove # remove sibling first since sibling traversal stops working after `remove`
            element.remove
          }

        return self
      end
    end
  end
end
