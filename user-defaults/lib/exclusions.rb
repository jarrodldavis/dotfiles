# frozen_string_literal: true

require 'yaml'

class UserDefaultsExclusions
  attr_accessor :global_keys, :local_domains, :local_keys

  def initialize path
    if path.nil?
      @global_keys = Set.new
      @local_domains = Set.new
      @local_keys = {}
    else
      parsed_exclusions = YAML.load_file path
      initialize_global_keys parsed_exclusions
      initialize_local_domains parsed_exclusions
      initialize_local_keys parsed_exclusions
    end
  end

  private

  def initialize_global_keys parsed_exclusions
    parsed_global_keys = parsed_exclusions.dig(:global, :keys)

    unless parsed_global_keys.is_a? Array
      raise TypeError, "Expected global key exclusions (path :global, :keys) to be an array but got #{parsed_global_keys.class}"
    end

    @global_keys = parsed_global_keys.to_set
    return
  end

  def initialize_local_domains parsed_exclusions
    parsed_local_domains = parsed_exclusions.dig(:local, :domains)

    unless parsed_local_domains.is_a? Array
      raise TypeError, "Expected local domain exclusions (path :local, :domains) to be an array but got #{parsed_local_domains.class}"
    end

    @local_domains = parsed_local_domains.to_set
    return
  end

  def initialize_local_keys parsed_exclusions
    parsed_local_keys = parsed_exclusions.dig(:local, :keys)

    unless parsed_local_keys.is_a? Hash
      raise TypeError, "Expected local key exclusions (path :local, :keys) to be a hash but got #{parsed_local_keys.class}"
    end

    @local_keys = {}
    parsed_local_keys.each {|domain, keys|
      unless keys.is_a? Array
        raise TypeError, "Expected local key exclusions for domain #{domain} (path :local, :keys, #{domain}) to be an array, but got #{keys.class}"
      end
      @local_keys[domain] = keys.to_set
    }
    return
  end
end
