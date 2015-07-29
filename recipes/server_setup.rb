#
# Cookbook Name:: gluster
# Recipe:: server_setup
#
# Copyright 2015, Biola University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Loop through each configured partition
if node['gluster']['server'].attribute?('disks')
  node['gluster']['server']['disks'].each do |d|
	# If a partition doesn't exist, create it
	if `fdisk -l 2> /dev/null | grep '/dev/#{d}1'`.empty?
	  # Pass commands to fdisk to create a new partition
	  bash 'create partition' do
		code "(echo n; echo p; echo 1; echo; echo; echo w) | fdisk /dev/#{d}"
		action :run
	  end

	  # Format the new partition
	  execute 'format partition' do
		command "mkfs.xfs -i size=512 /dev/#{d}1"
		action :run
	  end
	end

	# Create a mount point
	directory "#{node['gluster']['server']['brick_mount_path']}/#{d}1" do
	  recursive true
	  action :create
	end

	# Mount the partition and add to /etc/fstab
	mount "#{node['gluster']['server']['brick_mount_path']}/#{d}1" do
	  device "/dev/#{d}1"
	  fstype 'xfs'
	  action [:mount, :enable]
	end
  end
end

bricks = []
node['gluster']['server']['volumes'].each do |volume_name, volume_values|
  # If the node is configured as a peer for the volume, create directories to use as bricks
  if volume_values['peers'].include? node.name
	# If using LVM
	if volume_values.attribute?('lvm_volumes') || node['gluster']['server'].attribute?('lvm_volumes')
	  # Use either configured LVM volumes or default LVM volumes
	  lvm_volumes = volume_values.attribute?('lvm_volumes') ? volume_values['lvm_volumes'] : node['gluster']['server']['lvm_volumes'].take(volume_values['replica_count'])
	  lvm_volumes.each do |v|
		directory "#{node['gluster']['server']['brick_mount_path']}/#{v}/#{volume_name}" do
		  recursive true
		  action :create
		end
		bricks << "#{node['gluster']['server']['brick_mount_path']}/#{v}/#{volume_name}"
	  end
	else
	  # Use either configured disks or default disks
	  disks = volume_values.attribute?('disks') ? volume_values['disks'] : node['gluster']['server']['disks'].take(volume_values['replica_count'])
	  disks.each do |d|
		directory "#{node['gluster']['server']['brick_mount_path']}/#{d}1/#{volume_name}" do
		  action :create
		end
		bricks << "#{node['gluster']['server']['brick_mount_path']}/#{d}1/#{volume_name}"
	  end
	end
	# Save the array of bricks to the node's attributes
	node.set['gluster']['server']['bricks'] = bricks
    log "bricks = #{bricks}"
  end
end
