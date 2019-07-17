require 'rugged'
require_relative './exporter'

class UserDefaultsRepositoryExporter < UserDefaultsExporter
  def initialize repository_path
    @repository_path = File.expand_path repository_path
    super(output: File.join(@repository_path, 'user-defaults'), exclusions: nil)
  end

  def export
    super
    repo = Rugged::Repository.init_at @repository_path
    commit repo
  end

  private

  def commit repo
    unless repo.is_a? Rugged::Repository
      raise TypeError, "Expected a Rugged::Repository, got #{repo.class}"
    end

    index = repo.index
    parents = []

    unless repo.empty?
      head_commit = repo.head.target
      index.read_tree head_commit.tree
      parents.append head_commit
    end

    index.add_all

    options = {
      :tree => index.write_tree(repo),
      :message => "update user defaults",
      :parents => parents,
      :update_ref => 'HEAD'
    }

    commit = Rugged::Commit.create(repo, options)
    index.write
  end
end
