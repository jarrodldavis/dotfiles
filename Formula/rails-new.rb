class RailsNew < Formula
  desc "Create Rails projects with Ruby installed"
  homepage "https://github.com/rails/rails-new"
  url "https://github.com/rails/rails-new/releases/download/v0.4.1/rails-new-universal-apple-darwin.tar.gz"
  version "0.4.1"
  sha256 "b7d800ddfa851540bccffabea5149e085752aeffc7b6e9719af113e195b03237"
  license "MIT"

  def install
    bin.install "rails-new"
  end

  test do
    system bin/"rails-new" --version
  end
end
