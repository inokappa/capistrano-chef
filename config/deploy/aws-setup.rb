require 'aws-sdk'
require 'yaml'
# Please set AWS access_key and secret_access_key and region.
config = YAML.load(File.read("config/deploy/config.yml"))
AWS.config(config)
#
set :local_home, ENV['HOME']
set :remote_home, "/tmp"
set :chef_local_dir, "#{local_home}/chef-repo"
set :chef_remote_dir, "#{remote_home}/chef"
set :user, "#### please set ssh user (ex ec2-user"
set :key, "#### please set ssh-key path (ex path/to/key"
set :ami, "#### plase set ami"
set :instance_type, "#### please set instance type (ex t1.micro"
set :vpc_subnet, "#### please set vpc's subnet"
set :security_group, "#### please set security group id"
set :key_name, "#### please set key name"
set :tag_name, "#### please set tag's value name"
#
servers = AWS.ec2.instances.select {|i| i.tags[:Name] == "#{tag_name}" && i.status == :running}.map(&:dns_name)
role :servers, *servers
#
namespace :ec2 do
  desc "Launch EC2 instances."
  task :launch do
    inst = AWS.ec2.instances.create({
      :image_id => "#{ami}",
      :instance_type => "#{instance_type}",
      :subnet => "#{vpc_subnet}",
      :security_group_ids => "#{security_group}",
      :key_name => "#{key_name}",
    })
    AWS.ec2.tags.create(inst, 'Name',:value => "#{tag_name}")
  end
  task :status do
    puts "#{servers}"
  end
end
#
namespace :chef do
  task :init, :roles => :servers do
    run "#{try_sudo} apt-get update"
    run "#{try_sudo} apt-get -y install sudo curl rsync"
    run "#{try_sudo} curl -L https://www.opscode.com/chef/install.sh | sudo bash"
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
      run "#{try_sudo} chef-solo -j #{chef_remote_dir}/chef-repo/nodes/localhost.json -c #{chef_remote_dir}/chef-repo/solo.rb"
    end
  end
end
