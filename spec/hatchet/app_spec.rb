require("spec_helper")

describe "AppTest" do
  it "app with default" do
    app = Hatchet::App.new("default_ruby", buildpacks: [:default])
    expect(app.buildpacks.first).to match("https://github.com/heroku/heroku-buildpack-ruby")
  end

  it "create app with stack" do
    stack = "heroku-16"
    app = Hatchet::App.new("default_ruby", stack: stack)
    app.create_app
    expect(app.platform_api.app.info(app.name)["build_stack"]["name"]).to eq(stack)
  end

  it "before deploy" do
    @called = false
    @dir = false
    app = Hatchet::App.new("default_ruby")
    def app.push_with_retry!
      # do nothing
    end
    app.before_deploy do
      @called = true
      @dir = Dir.pwd
    end
    app.deploy do
      expect(@called).to eq(true)
      expect(@dir).to eq(Dir.pwd)
    end
    expect(@dir).to_not eq(Dir.pwd)
  end

  it "auto commits code" do
    string = "foo#{SecureRandom.hex}"
    app = Hatchet::App.new("default_ruby")
    def app.push_with_retry!
      # do nothing
    end
    app.before_deploy do |app|
      expect(app.send(:needs_commit?)).to eq(false)
      `echo "#{string}" > Gemfile`
      expect(app.send(:needs_commit?)).to eq(true)
    end
    app.deploy do
      expect(File.read("Gemfile").chomp).to eq(string)
      expect(app.send(:needs_commit?)).to eq(false)
    end
  end

  it "nested in directory" do
    string = "foo#{SecureRandom.hex}"
    app = Hatchet::App.new("default_ruby")
    def app.push_with_retry!
      # do nothing
    end
    app.in_directory do
      `echo "#{string}" > Gemfile`
      dir = Dir.pwd
      app.deploy do
        expect(File.read("Gemfile").chomp).to eq(string)
        expect(dir).to eq(Dir.pwd)
      end
    end
  end

  it "run" do
    app = Hatchet::GitApp.new("default_ruby")
    app.deploy do
      expect(app.run("ls -a Gemfile 'foo bar #baz'")).to match(/ls: cannot access 'foo bar #baz': No such file or directory\s+Gemfile/)
      expect((0 != $?.exitstatus)).to be_truthy
      sleep(4)
      app.run("ls erpderp", heroku: ({ "exit-code" => (Hatchet::App::SkipDefaultOption) }))
      expect((0 == $?.exitstatus)).to be_truthy
      sleep(4)
      app.run("ls erpderp", heroku: ({ "no-tty" => nil }))
      expect((0 != $?.exitstatus)).to be_truthy
      sleep(4)
      expect(app.run("echo \\$HELLO \\$NAME", raw: true, heroku: ({ "env" => "HELLO=ohai;NAME=world" }))).to match(/ohai world/)
      sleep(4)
      expect(app.run("echo \\$HELLO \\$NAME", raw: true, heroku: ({ "env" => "" }))).to_not match(/ohai world/)
      sleep(4)
      random_name = SecureRandom.hex
      expect(app.run("mkdir foo; touch foo/#{random_name}; ls foo/")).to match(/#{random_name}/)
    end
  end
end