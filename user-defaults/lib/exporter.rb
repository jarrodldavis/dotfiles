# frozen_string_literal: true

require_relative './exclusions'
require_relative './nokogiri_property_list'

class UserDefaultsExporter
  LOCAL_DIRECTORY_NAME = "local"
  GLOBAL_FILE_NAME = "global"
  PROPERTY_LIST_EXTENSION = "plist"

  def initialize(output:, exclusions:)
    @output_path = output
    @exclusions = UserDefaultsExclusions.new exclusions
  end

  def export
    create_output_directories

    write GLOBAL_FILE_NAME, get_global_domain_defaults

    get_local_domain_names.each {|domain|
      unless @exclusions.local_domains.include? domain
        write LOCAL_DIRECTORY_NAME, domain, get_local_domain_defaults(domain)
      end
    }
  end

  private

  def create_output_directories
    FileUtils.remove_dir @output_path, force: true
    Dir.mkdir @output_path
    Dir.mkdir File.join(@output_path, LOCAL_DIRECTORY_NAME)
  end

  def get_global_domain_defaults
    Nokogiri::XML(`defaults export -g -`) {|config| config.noblanks }.delete_property_list_keys! @exclusions.global_keys
  end

  def get_local_domain_names
    `defaults domains`.strip.split(', ')
  end

  def get_local_domain_defaults(domain)
    xml_doc = Nokogiri::XML(`defaults export #{domain} -`) {|config| config.noblanks }

    keys_to_delete = @exclusions.local_keys[domain]
    unless keys_to_delete.nil?
      xml_doc.delete_property_list_keys! keys_to_delete
    end

    xml_doc
  end

  def write(*paths, xml_doc)
    path = "#{File.join(@output_path, paths)}.#{PROPERTY_LIST_EXTENSION}"
    File.write path, xml_doc
  end
end
