#! /usr/bin/env ruby
#
#   aws_ami_autobackup.rb
#
# DESCRIPTION:
#
#   This tool gets: 
#   1. intances tag and values to backup. example: tag=daily_backup, value=true (daily_backup -> true)
#   2. retention time to delete old ami and snapshos that older then this retention time
#
#   The tool will do the following:
#   1. create ami from the instances that contain the tag name and value
#   2. create the ami with tags of:
#     1. aws_ami_autobackup -> tag name (example: aws_ami_autobackup -> daily_backup)
#   3. delete ami's that contain aws_ami_autobackup -> tag name and older then retention time
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   AWS
#
# DEPENDENCIES:
#   gem: rubygemps
#   gem: optparse
#   gem: aws-sdk-resources
#   credential file: ~/.aws/credentials containing aws access key and aws secret access key
#     example:
#     [default]
#     aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
#     aws_secret_access_key = YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
#
# USAGE:
#   aws_ami_autobackup.rb -t tag_name -v tag_value -r retention_time
#
# NOTES:
#
#  LICENSE:
#    Yossi Nachum   <nachum234@gmail.com>
#
require 'rubygems'
require 'optparse'
require 'date'
require 'aws-sdk-resources'

$toolname = 'aws_ami_autobackup'

#######################################
def create_ami(ec2,tag_key,tag_value)
  instances_to_backup = ec2.instances({
    filters: [{
      name: "tag:#{tag_key}",
      values: [tag_value],
      },
    ],
  })

  instances_to_backup.each do |instance_to_backup|
    instance_name = 'empty'
    instance_to_backup.tags.each do |tag|
      if tag.key == 'Name'
        instance_name = tag.value
      end
    end
    puts "create image for instance #{instance_name} (#{instance_to_backup.id})"
    image = instance_to_backup.create_image({
      name: "#{$toolname}-#{instance_to_backup.id}-#{tag_key}-#{tag_value}-#{Time.now.to_i}",
      description: "#{$toolname}-#{tag_key}-#{tag_value}-#{instance_name}",
      no_reboot: true,
    })
    puts "image name is #{image.name}"
    image.create_tags({
      tags: [
        {
          key: tag_key,
          value: tag_value,
        },
      ],
    })
  end
end
#######################################
def remove_old_ami(ec2,retention_time,tag_key,tag_value)
  retention_time_in_sec = retention_time.to_i * 24 * 60 * 60
  
  images_to_remove = ec2.images({
    owners: ['self'],
    filters: [
      {
        name: "tag:#{tag_key}",
        values: [tag_value],
      },
    ],
  })

  images_to_remove.each do |image|
    creation_unixtime = DateTime.parse(image.creation_date).to_time.to_i
    current_unixtime = Time.now.to_i
    puts "checking image #{image.name}"
    if current_unixtime - creation_unixtime > retention_time_in_sec
      puts "deleting image #{image.name} and it's snapshots"
      block_device_mappings = image.block_device_mappings
      image.deregister({})
      block_device_mappings.each do |block_device|
        unless block_device.ebs.nil?
          puts "deleting #{block_device.ebs.snapshot_id}"
          snapshot = ec2.snapshot(block_device.ebs.snapshot_id)
          snapshot.delete({})
        end
      end
    else
      puts "keeping image #{image.name}"
    end
  end
end
#######################################
#
# Main
#
#######################################
options = { :tag_name => nil,
            :tag_value => nil,
            :aws_creds_profile => 'default'
          }
OptionParser.new do |opts|
  opts.banner = "Usage: #{self.to_s} [options]"
  opts.on('-t', '--tag_name TAG_NAME', 'Tag name of the instances to backup') { |v| options[:tag_name] = v }
  opts.on('-v', '--tag_value TAG_VALUE', 'Tag value of instances to backup') { |v| options[:tag_value] = v }
  opts.on('-x', '--retention_time RETENTION_TIME', 'Retention time in days for AMIs') { |v| options[:retention_time] = v }
  opts.on('-r', '--region_name [REGION_NAME]', 'AWS Region Name') { |v| options[:region_name] = v }
  opts.on('-p', '--aws_creds_profile [AWS_CREDS_PROFILE]', 'AWS credentials profile') { |v| options[:aws_creds_profile] = v }
  opts.on_tail('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

options.each_value do |opt|
  if opt == nil
    puts "\nUsage: main [options]\n
    -t, --tag_name TAG_NAME,                      Tag name of the instances to backup (key)
    -v, --tag_value TAG_VALUE,                    Tag value of the instances to backup
    -x, --retention_time,                         Retention time in days for the AMIs
    -r, --region_name [REGION_NAME],              AWS Region Name
    -p, --aws_creds_profile [AWS_CREDS_PROFILE],  AWS credentials profile
    -h, --help                                    Prints this help
    "
    exit
  end
end

begin
  if options.has_key?(:region_name)
    credentials = Aws::SharedCredentials.new(profile_name: options[:aws_creds_profile])
    ec2 = Aws::EC2::Resource.new(credentials: credentials, region: options[:region_name])
  else
    ec2 = Aws::EC2::Resource.new(credentials: credentials)
  end
rescue Aws::Errors::MissingRegionError => error
  puts "You need to configure AWS region."
  puts "You can use the following command:"
  puts "export AWS_REGION=region_name"
  exit
end

create_ami(ec2,options[:tag_name],options[:tag_value])
remove_old_ami(ec2,options[:retention_time],options[:tag_name],options[:tag_value])