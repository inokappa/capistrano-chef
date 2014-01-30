require 'aws-sdk'
require 'yaml'

config = YAML.load(File.read("config/deploy/config.yml"))
AWS.config(config)
#
servers = AWS.ec2.instances.select {|i| i.tags[:Name] == 'hogehuga-kawahara' && i.status == :running}.map(&:dns_name)
role :servers, *servers
set :local_home, ENV['HOME']
set :remote_home, "/tmp"
set :chef_local_dir, "#{local_home}/git/myrepo/chef-repo"
set :chef_remote_dir, "#{remote_home}/chef"
set :user, "ec2-user"
set :key, "####path/to/key"
set :ami, "####plase set ami"
#
namespace :ec2 do
  desc "Launch EC2 instances."
  task :launch do
    inst = AWS.ec2.instances.create({
      :image_id => "#{ami}",
      :instance_type => "t1.micro",
      :subnet => "",
      :security_group_ids => "",
      :key_name => "",
    })
    AWS.ec2.tags.create(inst, 'Name',:value => 'hogehuga-kawahara')
  end
  task :status do
    puts "#{servers}"
  end
end
#
namespace :chef do
  task :init, :roles => :servers do
    #run "apt-get update && apt-get -y install sudo curl rsync"
    run "curl -L https://www.opscode.com/chef/install.sh | sudo bash"
  end
  task :sync, :roles => :servers do
    run "mkdir -p #{chef_remote_dir}/chef-repo/"
    find_servers_for_task(current_task).each do |server|
      if ( "#{server.port}" == nil )
        `rsync -avz #{chef_local_dir}/ -e "ssh -i #{key} -p #{server.port}" #{user}@#{server.host}:#{chef_remote_dir}/chef-repo/`
      else
        `rsync -avz #{chef_local_dir}/ -e "ssh -i #{key}" #{user}@#{server.host}:#{chef_remote_dir}/chef-repo/`
      end
    end
  end
  task :deploy, :roles => :servers do
    find_servers_for_task(current_task).each do |server|
      run "#{sudo} chef-solo -j #{chef_remote_dir}/chef-repo/nodes/localhost.json -c #{chef_remote_dir}/chef-repo/solo.rb"
    end
  end
end
