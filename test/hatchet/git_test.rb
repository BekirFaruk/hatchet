require 'test_helper'

class GitAppTest < Test::Unit::TestCase
  def test_can_deploy_git_app
    Hatchet::GitApp.new("rails3_mri_193").deploy do |app|
      assert true
      assert_match '1.9.3', app.run("ruby -v")

      app.run("bash") do |cmd|
        # cmd.run("cd public/assets")
        assert cmd.run("ls public/assets").include?("application.css")
      end
    end
  end
end

