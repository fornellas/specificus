require 'json'
require 'open-uri'
require 'fileutils'

class App < Sinatra::Application
  enable :static
  helpers do
    def run command
      puts "> #{command}"
      system command
      raise "#{command} failed" unless $?.exitstatus == 0
    end
    def rdoc_generated? name, version
      system "ls specificus/public/rdoc/#{name}/#{version}"
      File.exists? "specificus/public/#{name}/#{version}"
    end
    def gen_rdoc name, version
      puts "Generating rdoc for #{name}-#{version}"
      Dir.mktmpdir do |dir|
        gem = "#{dir}/#{name}-#{version}.gem"
        File.open(gem, 'w') do |io|
          io.write(open("http://rubygems.org/gems/#{name}-#{version}.gem").read)
        end
        run "tar xf #{gem}"
        Dir.mktmpdir do |gem_data|
          run "tar -zxf data.tar.gz -C #{gem_data}/"
          run "ls #{gem_data}"
          run "rdoc --op specificus/public/rdoc/#{name}/#{version}/ #{gem_data}/"
        end
      end
    end
  end
  get '/gem/:name' do |name|
    gem = JSON.parse(open("https://rubygems.org/api/v1/gems/#{name}.json").read)
    redirect "/rdoc/#{name}/#{gem['version']}/generate"
  end
  get '/rdoc/:name/:version/generate' do |name, version|
    gen_rdoc(name, version) unless rdoc_generated?(name, version)
    redirect "/rdoc/#{name}/#{version}/index.html"
  end
end
