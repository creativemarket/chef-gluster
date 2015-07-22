gluster Cookbook
================
This cookbook is used to install and configure Gluster on both servers and clients. This cookbook makes several assumptions when configuring Gluster servers:

1. If using the cookbook to format disks, each disk will contain a single partition dedicated for Gluster
2. Non-replicated volume types are not supported
3. All peers for a volume will be configured with the same number of bricks

Platforms
---------
This cookbook has been tested on Ubuntu 12.04/14.04 and CentOS 6.5.

Attributes
----------

### gluster::default
- `node['gluster']['version']` - version to install, defaults to 3.6

### gluster::server
Node attributes to specify server volumes to create

- `node['gluster']['server']['node_count'] - number of servers in the pool required for volume creation to begin`
- `node['gluster']['server']['brick_mount_path']` - default path to use for mounting bricks
- `node['gluster']['server']['disks']` - an array of disks to create partitions on and format for use with Gluster, (for example, ['sdb', 'sdc'])
- `node['gluster']['server']['peer_retries']` - attempt to connect to peers up to N times
- `node['gluster']['server']['peer_retry_delays']` - number of seconds to wait between attempts to initially attempt to connect to peers
- `node['gluster']['server']['volumes'][VOLUME_NAME]['allowed_hosts']` - an optional array of IP addresses to allow access to the volume
- `node['gluster']['server']['volumes'][VOLUME_NAME]['disks']` - an optional array of disks to put bricks on (for example, ['sdb', 'sdc']); by default the cookbook will use the first x number of disks, equal to the replica count
- `node['gluster']['server']['volumes'][VOLUME_NAME]['lvm_volumes']` - an optional array of logical volumes to put bricks on (for example, ['LogVolGlusterBrick1', 'LogVolGlusterBrick2']); by default the cookbook will use the first x number of volumes, equal to the replica count
- `node['gluster']['server']['volumes'][VOLUME_NAME]['peer_names']` - an optional array of Chef node names for peers used in the volume
- `node['gluster']['server']['volumes'][VOLUME_NAME]['peers']` - an array of FQDNs for peers used in the volume
- `node['gluster']['server']['volumes'][VOLUME_NAME]['quota']` - an optional disk quota to set for the volume, such as '10GB'
- `node['gluster']['server']['volumes'][VOLUME_NAME]['replica_count']` - the number of replicas to create

LWRPs
-----
Use the gluster_mount LWRP to mount volumes on clients:

```ruby
gluster_mount 'volume_name' do
  server 'gluster1.example.com'
  backup_server 'gluster2.example.com'
  mount_point '/mnt/gluster/volume_name'
  action [:mount, :enable]
end
```

```ruby
gluster_mount 'volume_name' do
  server 'gluster1.example.com'
  backup_server ['gluster2.example.com', 'gluster3.example.com']
  mount_point '/mnt/gluster/volume_name'
  action [:mount, :enable]
end
```

Usage
-----

On two or more identical systems, attach the desired number of dedicated disks to use for Gluster storage. Add the `gluster::server` recipe to the node's run list and add any appropriate attributes, such as volumes to the `['gluster']['server']['volumes']` attribute. If the cookbook will be used to manage disks, add the disks to the `['gluster']['server']['disks']` attribute; otherwise format the disks appropriately and add them to the `['gluster']['server']['volumes'][VOLUME_NAME]['disks']` attribute. Once all peers for a volume have configured their bricks, the 'master' peer (the last in the array) will create and start the volume.

For clients, add the gluster::default or gluster::client recipe to the node's run list, and mount volumes using the `gluster_mount` LWRP. The Gluster volume will be mounted on the next chef-client run (provided the volume exists and is available) and added to /etc/fstab.
