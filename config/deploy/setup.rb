role :servers, "xxx.xxxx.xxx.xxx:49153","xxx.xxx.xxx.xxx:49154"
#
set :user, "your_user"
set :path_to, "your_path"
#
set :chef_local_dir, "#{path_to}/chef-repo"
set :chef_remote_dir, "/root/chef"
#
namespace :chef do
  task :init, :roles => :servers do
    run "apt-get update && apt-get -y install sudo curl rsync"
    run "curl -L https://www.opscode.com/chef/install.sh | sudo bash"
  end
  task :sync, :roles => :servers do
    run "mkdir -p #{chef_remote_dir}/chef-repo/"
    find_servers_for_task(current_task).each do |server|
      `rsync -avz #{chef_local_dir}/ -e "ssh -p #{server.port}" root@#{server.host}:#{chef_remote_dir}/chef-repo/`
    end
  end
  task :deploy, :roles => :servers do
    find_servers_for_task(current_task).each do |server|
      run "chef-solo -j #{chef_remote_dir}/chef-repo/nodes/#{server}.json -c #{chef_remote_dir}/chef-repo/solo.rb"
    end
  end
end
