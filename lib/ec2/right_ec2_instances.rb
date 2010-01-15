#
# Copyright (c) 2009 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

module RightAws

  class Ec2

  #-----------------------------------------------------------------
  #      Instances
  #-----------------------------------------------------------------

    def get_desc_instances(instances)  # :nodoc:
      result = []
      instances.each do |reservation|
        reservation[:instances_set].each do |instance|
          # Parse and remove timestamp from the reason string. The timestamp is of
          # the request, not when EC2 took action, thus confusing & useless...
          instance[:aws_reason]         = instance[:aws_reason].sub(/\(\d[^)]*GMT\) */, '')
          instance[:aws_owner]          = reservation[:aws_owner]
          instance[:aws_reservation_id] = reservation[:aws_reservation_id]
          instance[:aws_groups]         = reservation[:aws_groups]
          result << instance
        end
      end
      result
    rescue Exception
      on_exception
    end

    # Retrieve information about EC2 instances. If +list+ is omitted then returns the
    # list of all instances.
    #
    #  ec2.describe_instances #=>
    #    [{:private_ip_address=>"10.240.7.99",
    #      :aws_image_id=>"ami-c2a3f5d4",
    #      :ip_address=>"174.129.134.109",
    #      :dns_name=>"ec2-174-129-134-109.compute-1.amazonaws.com",
    #      :aws_instance_type=>"m1.small",
    #      :aws_owner=>"826693181925",
    #      :root_device_name=>"/dev/sda1",
    #      :instance_class=>"elastic",
    #      :aws_state=>"running",
    #      :private_dns_name=>"domU-12-31-39-04-00-95.compute-1.internal",
    #      :aws_reason=>"",
    #      :aws_launch_time=>"2009-11-18T14:03:25.000Z",
    #      :aws_reservation_id=>"r-54d38542",
    #      :aws_state_code=>16,
    #      :ami_launch_index=>"0",
    #      :aws_availability_zone=>"us-east-1a",
    #      :aws_groups=>["default"],
    #      :monitoring_state=>"disabled",
    #      :aws_product_codes=>[],
    #      :ssh_key_name=>"",
    #      :block_device_mappings=>
    #       [{:ebs_status=>"attached",
    #         :ebs_delete_on_termination=>true,
    #         :ebs_attach_time=>"2009-11-18T14:03:34.000Z",
    #         :device_name=>"/dev/sda1",
    #         :ebs_volume_id=>"vol-e600f98f"},
    #        {:ebs_status=>"attached",
    #         :ebs_delete_on_termination=>true,
    #         :ebs_attach_time=>"2009-11-18T14:03:34.000Z",
    #         :device_name=>"/dev/sdk",
    #         :ebs_volume_id=>"vol-f900f990"}],
    #      :aws_instance_id=>"i-8ce84ae4"} , ... ]
    #
    def describe_instances(list=[])
      link = generate_request("DescribeInstances", amazonize_list('InstanceId',list.to_a))
      request_cache_or_info(:describe_instances, link,  QEc2DescribeInstancesParser, @@bench, list.blank?) do |parser|
        get_desc_instances(parser.result)
      end
    rescue Exception
      on_exception
    end

    # Return the product code attached to instance or +nil+ otherwise.
    #
    #  ec2.confirm_product_instance('ami-e444444d','12345678') #=> nil
    #  ec2.confirm_product_instance('ami-e444444d','00001111') #=> "000000000888"
    #
    def confirm_product_instance(instance, product_code)
      link = generate_request("ConfirmProductInstance", { 'ProductCode' => product_code,
                                'InstanceId'  => instance })
      request_info(link, QEc2ConfirmProductInstanceParser.new(:logger => @logger))
    end

    # Launch new EC2 instances. Returns a list of launched instances or an exception.
    #
    #  ec2.run_instances('ami-e444444d',1,1,['my_awesome_group'],'my_awesome_key', 'Woohoo!!!', 'public') #=>
    #   [{:aws_image_id       => "ami-e444444d",
    #     :aws_reason         => "",
    #     :aws_state_code     => "0",
    #     :aws_owner          => "000000000888",
    #     :aws_instance_id    => "i-123f1234",
    #     :aws_reservation_id => "r-aabbccdd",
    #     :aws_state          => "pending",
    #     :dns_name           => "",
    #     :ssh_key_name       => "my_awesome_key",
    #     :aws_groups         => ["my_awesome_group"],
    #     :private_dns_name   => "",
    #     :aws_instance_type  => "m1.small",
    #     :aws_launch_time    => "2008-1-1T00:00:00.000Z"
    #     :aws_ramdisk_id     => "ari-8605e0ef"
    #     :aws_kernel_id      => "aki-9905e0f0",
    #     :ami_launch_index   => "0",
    #     :aws_availability_zone => "us-east-1b"
    #     }]
    #
    def run_instances(image_id, min_count, max_count, group_ids, key_name, user_data='',
                      addressing_type = nil, instance_type = nil,
                      kernel_id = nil, ramdisk_id = nil, availability_zone = nil,
                      monitoring_enabled = nil, subnet_id = nil, disable_api_termination = nil,
                      instance_initiated_shutdown_behavior = nil, block_device_mappings = nil)
 	    launch_instances(image_id, { :min_count                            => min_count,
 	                                 :max_count                            => max_count,
 	                                 :user_data                            => user_data,
                                   :group_ids                            => group_ids,
                                   :key_name                             => key_name,
                                   :instance_type                        => instance_type,
                                   :addressing_type                      => addressing_type,
                                   :kernel_id                            => kernel_id,
                                   :ramdisk_id                           => ramdisk_id,
                                   :availability_zone                    => availability_zone,
                                   :monitoring_enabled                   => monitoring_enabled,
                                   :subnet_id                            => subnet_id,
                                   :disable_api_termination              => disable_api_termination,
                                   :instance_initiated_shutdown_behavior => instance_initiated_shutdown_behavior,
                                   :block_device_mappings                =>  block_device_mappings
                                 })
    end

    # Launch new EC2 instances.
    # Options: :image_id, :addressing_type, :min_count, max_count, :key_name, :kernel_id, :ramdisk_id,
    # :availability_zone, :monitoring_enabled, :subnet_id, :disable_api_termination, :instance_initiated_shutdown_behavior,
    # :block_device_mappings
    # 
    # Returns a list of launched instances or an exception.
    #
    #  ec2.launch_instances( 'ami-c2a3f5d4',
    #                        :min_count => 1,
    #                        :group_ids => 'default',
    #                        :user_data => 'Ohoho!',
    #                        :availability_zone => "us-east-1a",
    #                        :disable_api_termination => true,
    #                        :instance_initiated_shutdown_behavior => 'terminate',
    #                        :block_device_mappings => [ {:ebs_snapshot_id=>"snap-7360871a",
    #                                                     :ebs_delete_on_termination=>true,
    #                                                     :device_name => "/dev/sdk",
    #                                                     :virtual_name => "mystorage"} ] ) #=>
    #    [{:aws_image_id=>"ami-c2a3f5d4",
    #      :dns_name=>"",
    #      :aws_instance_type=>"m1.small",
    #      :aws_owner=>"826693181925",
    #      :root_device_name=>"/dev/sda1",
    #      :instance_class=>"elastic",
    #      :state_reason_code=>0,
    #      :aws_state=>"pending",
    #      :private_dns_name=>"",
    #      :aws_reason=>"",
    #      :aws_launch_time=>"2009-11-18T14:03:25.000Z",
    #      :aws_reservation_id=>"r-54d38542",
    #      :state_reason_message=>"pending",
    #      :aws_state_code=>0,
    #      :ami_launch_index=>"0",
    #      :aws_availability_zone=>"us-east-1a",
    #      :aws_groups=>["default"],
    #      :monitoring_state=>"disabled",
    #      :aws_product_codes=>[],
    #      :ssh_key_name=>"",
    #      :aws_instance_id=>"i-8ce84ae4"}]
    #
    def launch_instances(image_id, options={})
      @logger.info("Launching instance of image #{image_id} for #{@aws_access_key_id}, " +
                   "key: #{options[:key_name]}, groups: #{(options[:group_ids]).to_a.join(',')}")
      options[:image_id]    = image_id
      options[:min_count] ||= 1
      options[:max_count] ||= options[:min_count]
      params = prepare_instance_launch_params(options)
      link = generate_request("RunInstances", params)
      instances = request_info(link, QEc2DescribeInstancesParser.new(:logger => @logger))
      get_desc_instances(instances)
    rescue Exception
      on_exception
    end

=begin
    # TODO: API does not support this call yet
    def create_instance(options={})
      @logger.info("Creating instance #{@aws_access_key_id}, " +
                   "key: #{options[:key_name]}, groups: #{(options[:group_ids]).to_a.join(',')}")
      params = prepare_instance_launch_params(options)
      link = generate_request("CreateInstance", params)
      instances = request_info(link, QEc2DescribeInstancesParser.new(:logger => @logger))
      get_desc_instances(instances).first
    rescue Exception
      on_exception
    end
=end

    def prepare_instance_launch_params(options={}) # :nodoc:
      params = amazonize_list('SecurityGroup', options[:group_ids].to_a)
      params['InstanceType']                      = options[:instance_type] || DEFAULT_INSTANCE_TYPE
      params['ImageId']                           = options[:image_id]                             unless options[:image_id].blank?
      params['AddressingType']                    = options[:addressing_type]                      unless options[:addressing_type].blank?
      params['MinCount']                          = options[:min_count]                            unless options[:min_count].blank?
      params['MaxCount']                          = options[:max_count]                            unless options[:max_count].blank?
      params['KeyName']                           = options[:key_name]                             unless options[:key_name].blank?
      params['KernelId']                          = options[:kernel_id]                            unless options[:kernel_id].blank?
      params['RamdiskId']                         = options[:ramdisk_id]                           unless options[:ramdisk_id].blank?
      params['Placement.AvailabilityZone']        = options[:availability_zone]                    unless options[:availability_zone].blank?
      params['Monitoring.Enabled']                = options[:monitoring_enabled].to_s              if     options[:monitoring_enabled]
      params['SubnetId']                          = options[:subnet_id]                            unless options[:subnet_id].blank?
      params['AdditionalInfo']                    = options[:additional_info]                      unless options[:additional_info].blank?
      params['DisableApiTermination']             = options[:disable_api_termination].to_s         unless options[:disable_api_termination].nil?
      params['InstanceInitiatedShutdownBehavior'] = options[:instance_initiated_shutdown_behavior] unless options[:instance_initiated_shutdown_behavior].blank?
#     params['VolumeId']                          = options[:volume_id]                            unless options[:volume_id].blank?
#     params['RootDeviceName']                    = options[:root_device_name]                     unless options[:root_device_name].blank?
#     params['RootDeviceType']                    = options[:root_device_type]                     unless options[:root_device_type].blank?
      params.merge!(amazonize_block_device_mappings(options[:block_device_mappings]))
      unless options[:user_data].blank?
        options[:user_data].strip!
          # Do not use CGI::escape(encode64(...)) as it is done in Amazons EC2 library.
          # Amazon 169.254.169.254 does not like escaped symbols!
          # And it doesn't like "\n" inside of encoded string! Grrr....
          # Otherwise, some of UserData symbols will be lost...
        params['UserData'] = Base64.encode64(options[:user_data]).delete("\n") unless options[:user_data].blank?
      end
      params
    end

    # Start instances.
    #
    #  ec2.start_instances("i-36e84a5e") #=>
    #    [{:aws_prev_state_name=>"stopped",
    #      :aws_instance_id=>"i-36e84a5e",
    #      :aws_current_state_code=>16,
    #      :aws_current_state_name=>"running",
    #      :aws_prev_state_code=>80}]
    #
    def start_instances(*instance_aws_ids)
      instance_aws_ids = instance_aws_ids.flatten
      link = generate_request("StartInstances", amazonize_list('InstanceId', instance_aws_ids))
      request_info(link, QEc2TerminateInstancesParser.new(:logger => @logger))
     end

    # Stop instances.
    #
    #  ec2.stop_instances("i-36e84a5e") #=>
    #    [{:aws_prev_state_code=>16,
    #      :aws_prev_state_name=>"running",
    #      :aws_instance_id=>"i-36e84a5e",
    #      :aws_current_state_code=>64,
    #      :aws_current_state_name=>"stopping"}]
    #
    def stop_instances(*instance_aws_ids)
      instance_aws_ids = instance_aws_ids.flatten
      link = generate_request("StopInstances", amazonize_list('InstanceId', instance_aws_ids))
      request_info(link, QEc2TerminateInstancesParser.new(:logger => @logger))
    end

    # Terminates EC2 instances. Returns a list of termination params or an exception.
    #
    #  ec2.terminate_instances(['i-cceb49a4']) #=>
    #    [{:aws_instance_id=>"i-cceb49a4",
    #      :aws_current_state_code=>32,
    #      :aws_current_state_name=>"shutting-down",
    #      :aws_prev_state_code=>16,
    #      :aws_prev_state_name=>"running"}]
    #
    def terminate_instances(*instance_aws_ids)
      instance_aws_ids = instance_aws_ids.flatten
      link = generate_request("TerminateInstances", amazonize_list('InstanceId', instance_aws_ids))
      request_info(link, QEc2TerminateInstancesParser.new(:logger => @logger))
    rescue Exception
      on_exception
    end

    # Retreive EC2 instance OS logs. Returns a hash of data or an exception.
    #
    #  ec2.get_console_output('i-f222222d') =>
    #    {:aws_instance_id => 'i-f222222d',
    #     :aws_timestamp   => "2007-05-23T14:36:07.000-07:00",
    #     :timestamp       => Wed May 23 21:36:07 UTC 2007,          # Time instance
    #     :aws_output      => "Linux version 2.6.16-xenU (builder@patchbat.amazonsa) (gcc version 4.0.1 20050727 ..."
    def get_console_output(instance_id)
      link = generate_request("GetConsoleOutput", { 'InstanceId.1' => instance_id })
      request_info(link, QEc2GetConsoleOutputParser.new(:logger => @logger))
    rescue Exception
      on_exception
    end

    # Reboot an EC2 instance. Returns +true+ or an exception.
    #
    #  ec2.reboot_instances(['i-f222222d','i-f222222e']) #=> true
    #
    def reboot_instances(list)
      link = generate_request("RebootInstances", amazonize_list('InstanceId', list.to_a))
      request_info(link, RightBoolResponseParser.new(:logger => @logger))
    rescue Exception
      on_exception
    end

    INSTANCE_ATTRIBUTE_MAPPING = {
      "instance_type"                        => "instanceType",
      "kernel"                               => "kernel",
      "ramdisk"                              => "ramdisk",
      "user_data"                            => "userData",
      "disable_api_termination"              => "disableApiTermination",
      "instance_initiated_shutdown_behavior" => "instanceInitiatedShutdownBehavior",
      "root_device_name"                     => "rootDeviceName",
      "block_device_mapping"                 => "blockDeviceMapping"
    }

    # Describe instance attribute.
    # Attributes: :instance_type, :kernel, :ramdisk, :user_data, :disable_api_termination, :instance_initiated_shutdown_behavior, :root_device_name, :block_device_mapping
    #
    #  ec2.describe_instance_attribute(instance, "BlockDeviceMapping") #=>
    #     [{:ebs_delete_on_termination=>true,
    #       :ebs_volume_id=>"vol-683dc401",
    #       :device_name=>"/dev/sda1"}]
    #
    #  ec2.describe_instance_attribute(instance, "InstanceType") #=> "m1.small"
    #
    #  ec2.describe_instance_attribute(instance, "InstanceInitiatedShutdownBehavior") #=> "stop"
    #
    def describe_instance_attribute(instance_id, attribute)
      attribute = INSTANCE_ATTRIBUTE_MAPPING[attribute.to_s] || attribute.to_s
      link = generate_request('DescribeInstanceAttribute',
                              'InstanceId' => instance_id,
                              'Attribute'  => attribute)
      value = request_info(link, QEc2DescribeInstanceAttributeParser.new(:logger => @logger))
      case attribute
      when "userData"
        Base64.decode64(value)
      else
        value
      end
    rescue Exception
      on_exception
    end

    # Describe instance attribute.
    # Attributes: :kernel, :ramdisk
    #
    #  ec2.reset_instance_attribute(instance, :kernel) #=> true
    #
    def reset_instance_attribute(instance_id, attribute)
      attribute = INSTANCE_ATTRIBUTE_MAPPING[attribute.to_s] || attribute.to_s
      link = generate_request('ResetInstanceAttribute',
                              'InstanceId' => instance_id,
                              'Attribute'  => attribute )
      request_info(link, RightBoolResponseParser.new(:logger => @logger))
    rescue Exception
      on_exception
    end

    # Modify instance attribute.
    # Attributes: :instance_type, :kernel, :ramdisk, :user_data, :disable_api_termination, :instance_initiated_shutdown_behavior, :root_device_name, :block_device_mapping
    #
    #  ec2.modify_instance_attribute(instance, :instance_initiated_shutdown_behavior, "stop") #=> true
    #
    def modify_instance_attribute(instance_id, attribute, value)
      attribute = INSTANCE_ATTRIBUTE_MAPPING[attribute.to_s] || attribute.to_s
      params = { 'InstanceId' => instance_id,
                 'Attribute'  => attribute }
      case attribute
      when "blockDeviceMapping"
        params.merge!(amazonize_block_device_mappings(value))
      when "userData"
        params['Value'] = Base64.encode64(value).delete("\n")
      else
        params['Value'] = value
      end
      link = generate_request('ModifyInstanceAttribute', params)
      request_info(link, RightBoolResponseParser.new(:logger => @logger))
    rescue Exception
      on_exception
    end

    #-----------------------------------------------------------------
    #      Instances: Windows addons
    #-----------------------------------------------------------------

    # Get initial Windows Server setup password from an instance console output.
    #
    #  my_awesome_key = ec2.create_key_pair('my_awesome_key') #=>
    #    {:aws_key_name    => "my_awesome_key",
    #     :aws_fingerprint => "01:02:03:f4:25:e6:97:e8:9b:02:1a:26:32:4e:58:6b:7a:8c:9f:03",
    #     :aws_material    => "-----BEGIN RSA PRIVATE KEY-----\nMIIEpQIBAAK...Q8MDrCbuQ=\n-----END RSA PRIVATE KEY-----"}
    #
    #  my_awesome_instance = ec2.run_instances('ami-a000000a',1,1,['my_awesome_group'],'my_awesome_key', 'WindowsInstance!!!') #=>
    #   [{:aws_image_id       => "ami-a000000a",
    #     :aws_instance_id    => "i-12345678",
    #     ...
    #     :aws_availability_zone => "us-east-1b"
    #     }]
    #
    #  # wait until instance enters 'operational' state and get it's initial password
    #
    #  puts ec2.get_initial_password(my_awesome_instance[:aws_instance_id], my_awesome_key[:aws_material]) #=> "MhjWcgZuY6"
    #
    def get_initial_password(instance_id, private_key)
      console_output = get_console_output(instance_id)
      crypted_password = console_output[:aws_output][%r{<Password>(.+)</Password>}m] && $1
      unless crypted_password
        raise AwsError.new("Initial password was not found in console output for #{instance_id}")
      else
        OpenSSL::PKey::RSA.new(private_key).private_decrypt(Base64.decode64(crypted_password))
      end
    rescue Exception
      on_exception
    end

    # Bundle a Windows image.
    # Internally, it queues the bundling task and shuts down the instance.
    # It then takes a snapshot of the Windows volume bundles it, and uploads it to
    # S3. After bundling completes, Rightaws::Ec2#register_image may be used to
    # register the new Windows AMI for subsequent launches.
    #
    #   ec2.bundle_instance('i-e3e24e8a', 'my-awesome-bucket', 'my-win-image-1') #=>
    #    [{:aws_update_time => "2008-10-16T13:58:25.000Z",
    #      :s3_bucket       => "kd-win-1",
    #      :s3_prefix       => "win2pr",
    #      :aws_state       => "pending",
    #      :aws_id          => "bun-26a7424f",
    #      :aws_instance_id => "i-878a25ee",
    #      :aws_start_time  => "2008-10-16T13:58:02.000Z"}]
    #
    def bundle_instance(instance_id, s3_bucket, s3_prefix,
                        s3_owner_aws_access_key_id=nil, s3_owner_aws_secret_access_key=nil,
                        s3_expires = S3Interface::DEFAULT_EXPIRES_AFTER,
                        s3_upload_policy='ec2-bundle-read')
      # S3 access and signatures
      s3_owner_aws_access_key_id     ||= @aws_access_key_id
      s3_owner_aws_secret_access_key ||= @aws_secret_access_key
      s3_expires = Time.now.utc + s3_expires if s3_expires.is_a?(Fixnum) && (s3_expires < S3Interface::ONE_YEAR_IN_SECONDS)
      # policy
      policy = { 'expiration' => AwsUtils::utc_iso8601(s3_expires),
                 'conditions' => [ { 'bucket' => s3_bucket },
                                   { 'acl'    => s3_upload_policy },
                                   [ 'starts-with', '$key', s3_prefix ] ] }.to_json
      policy64        = Base64.encode64(policy).gsub("\n","")
      signed_policy64 = AwsUtils.sign(s3_owner_aws_secret_access_key, policy64)
      # fill request params
      params = { 'InstanceId'                       => instance_id,
                 'Storage.S3.AWSAccessKeyId'        => s3_owner_aws_access_key_id,
                 'Storage.S3.UploadPolicy'          => policy64,
                 'Storage.S3.UploadPolicySignature' => signed_policy64,
                 'Storage.S3.Bucket'                => s3_bucket,
                 'Storage.S3.Prefix'                => s3_prefix,
                 }
      link = generate_request("BundleInstance", params)
      request_info(link, QEc2BundleInstanceParser.new)
    rescue Exception
      on_exception
    end

    # Describe the status of the Windows AMI bundlings.
    # If +list+ is omitted the returns the whole list of tasks.
    #
    #  ec2.describe_bundle_tasks(['bun-4fa74226']) #=>
    #    [{:s3_bucket         => "my-awesome-bucket"
    #      :aws_id            => "bun-0fa70206",
    #      :s3_prefix         => "win1pr",
    #      :aws_start_time    => "2008-10-14T16:27:57.000Z",
    #      :aws_update_time   => "2008-10-14T16:37:10.000Z",
    #      :aws_error_code    => "Client.S3Error",
    #      :aws_error_message =>
    #       "AccessDenied(403)- Invalid according to Policy: Policy Condition failed: [\"eq\", \"$acl\", \"aws-exec-read\"]",
    #      :aws_state         => "failed",
    #      :aws_instance_id   => "i-e3e24e8a"}]
    #
    def describe_bundle_tasks(list=[])
      link = generate_request("DescribeBundleTasks", amazonize_list('BundleId', list.to_a))
      request_info(link, QEc2DescribeBundleTasksParser.new)
    rescue Exception
      on_exception
    end

    # Cancel an in‐progress or pending bundle task by id.
    #
    #  ec2.cancel_bundle_task('bun-73a7421a') #=>
    #   [{:s3_bucket         => "my-awesome-bucket"
    #     :aws_id            => "bun-0fa70206",
    #     :s3_prefix         => "win02",
    #     :aws_start_time    => "2008-10-14T13:00:29.000Z",
    #     :aws_error_message => "User has requested bundling operation cancellation",
    #     :aws_state         => "failed",
    #     :aws_update_time   => "2008-10-14T13:01:31.000Z",
    #     :aws_error_code    => "Client.Cancelled",
    #     :aws_instance_id   => "i-e3e24e8a"}
    #
    def cancel_bundle_task(bundle_id)
      link = generate_request("CancelBundleTask", { 'BundleId' => bundle_id })
      request_info(link, QEc2BundleInstanceParser.new)
    rescue Exception
      on_exception
    end

    #-----------------------------------------------------------------
    #      Spot Instances
    #-----------------------------------------------------------------

    # Describe Spot Price history.
    # Options: :start_time, :end_time, instance_types, product_description
    #
    def describe_spot_price_history(options={})
      options = options.dup
      request_hash = {}
      request_hash['StartTime']          = AwsUtils::utc_iso8601(options[:start_time])     unless options[:start_time].blank?
      request_hash['EndTime']            = AwsUtils::utc_iso8601(options[:end_time])       unless options[:end_time].blank?
      request_hash['ProductDescription'] = options[:product_description]                   unless options[:product_description].blank?
      request_hash.merge!(amazonize_list('InstanceType', Array(options[:instance_types]))) unless options[:instance_types].blank?
      link = generate_request("DescribeSpotPriceHistory", request_hash)
      request_info(link, QEc2DescribeSpotPriceHistoryParser.new)
    rescue Exception
      on_exception
    end

    # Describe Spot Instance requests.
    def describe_spot_instance_requests(*spot_instance_request_ids)
      link = generate_request("DescribeSpotInstanceRequests", amazonize_list('SpotInstanceRequestId', spot_instance_request_ids.flatten))
      request_info(link, QEc2DescribeSpotInstanceParser.new(:logger => @logger))
    end

    # Create a Spot Instance request.
    #
    # Mandatory params: :image_id, :spot_price, :instance_type
    # Optional params: :valid_from, :valid_until, :instance_count, :type, :launch_group,
    # :availability_zone_group, :key_name, :user_data, :addressing_type, :kernel_id,
    # :ramdisk_id, :subnet_id, :availability_zone, :monitoring_enabled, :groups,
    # :block_device_mappings (?)
    #
    #  # example 1
    #  ec2.request_spot_instances(:image_id => 'ami-08f41161', :spot_price => 0.01, :instance_type => 'm1.small') #=>
    #    [{:monitoring_enabled=>false,
    #      :type=>"one-time",
    #      :spot_instance_requestId=>"sir-6992ce04",
    #      :image_id=>"ami-08f41161",
    #      :state=>"open",
    #      :spot_price=>0.01,
    #      :instance_type=>"m1.small",
    #      :groups=>["default"],
    #      :create_time=>"2010-01-13T01:32:14.000Z",
    #      :product_description=>"Linux/UNIX"}]
    #
    #  # example 2
    #  ec2.request_spot_instances( :image_id => 'ami-08f41161',
    #                              :spot_price => 0.01,
    #                              :instance_type => 'm1.small',
    #                              :valid_from => 10.minutes.since,
    #                              :valid_until => 1.hour.since,
    #                              :instance_count => 1,
    #                              :key_name => 'tim',
    #                              :groups => ['33','default'],
    #                              :availability_zone => 'us-east-1a',
    #                              :monitoring_enabled => true,
    #                              :launch_group => 'lg1',
    #                              :availability_zone_group => 'azg1' ) #=>
    #    [{:monitoring_enabled=>true,
    #      :type=>"one-time",
    #      :create_time=>"2010-01-13T01:58:51.000Z",
    #      :image_id=>"ami-08f41161",
    #      :launch_group=>"lg1",
    #      :valid_until=>"2010-01-13T02:58:49.000Z",
    #      :state=>"open",
    #      :availability_zone_group=>"azg1",
    #      :spot_price=>0.01,
    #      :instance_type=>"m1.small",
    #      :groups=>["default", "33"],
    #      :product_description=>"Linux/UNIX",
    #      :key_name=>"tim",
    #      :spot_instance_requestId=>"sir-41dcc403",
    #      :valid_from=>"2010-01-13T02:08:49.000Z",
    #      :availability_zone=>"us-east-1a"}]
    #      
    # TODO: KD: should it support block device mappings?
    # Amazon docs says yes but actually it does not work.
    #
    def request_spot_instances(options)
      options = options.dup
      request_hash = { 'SpotPrice'                        => options[:spot_price],
                       'LaunchSpecification.ImageId'      => options[:image_id],
                       'LaunchSpecification.InstanceType' => options[:instance_type]}
      request_hash['ValidFrom']                      = AwsUtils::utc_iso8601(options[:valid_from])  unless options[:valid_from].blank?
      request_hash['ValidUntil']                     = AwsUtils::utc_iso8601(options[:valid_until]) unless options[:valid_until].blank?
      request_hash['InstanceCount']                      = options[:instance_count]                 unless options[:instance_count].blank?
      request_hash['Type']                               = options[:type]                           unless options[:type].blank?
      request_hash['LaunchGroup']                        = options[:launch_group]                   unless options[:launch_group].blank?
      request_hash['AvailabilityZoneGroup']              = options[:availability_zone_group]        unless options[:availability_zone_group].blank?
      request_hash['LaunchSpecification.KeyName']        = options[:key_name]                       unless options[:key_name].blank?
      request_hash['LaunchSpecification.UserData']       = options[:user_data]                      unless options[:user_data].blank?
      request_hash['LaunchSpecification.AddressingType'] = options[:addressing_type]                unless options[:addressing_type].blank?
      request_hash['LaunchSpecification.KernelId']       = options[:kernel_id]                      unless options[:kernel_id].blank?
      request_hash['LaunchSpecification.RamdiskId']      = options[:ramdisk_id]                     unless options[:ramdisk_id].blank?
      request_hash['LaunchSpecification.SubnetId']       = options[:subnet_id]                      unless options[:subnet_id].blank?
      request_hash['LaunchSpecification.Placement.AvailabilityZone'] = options[:availability_zone]  unless options[:availability_zone].blank?
      request_hash['LaunchSpecification.Monitoring.Enabled']         = options[:monitoring_enabled] unless options[:monitoring_enabled].blank?
      request_hash.merge!(amazonize_list('LaunchSpecification.SecurityGroup', options[:groups]))    unless options[:groups].blank?
      request_hash.merge!(amazonize_block_device_mappings(options[:block_device_mappings], 'LaunchSpecification.BlockDeviceMapping'))
      link = generate_request("RequestSpotInstances", request_hash)
      request_info(link, QEc2DescribeSpotInstanceParser.new(:logger => @logger))
    end

    # Cancel one or more Spot Instance requests.
    #
    #  ec2.cancel_spot_instance_requests('sir-60662c03',"sir-d3c96e04", "sir-4fa8d804","sir-6992ce04") #=>
    #    [{:state=>"cancelled", :spot_instance_request_id=>"sir-60662c03"},
    #     {:state=>"cancelled", :spot_instance_request_id=>"sir-6992ce04"},
    #     {:state=>"cancelled", :spot_instance_request_id=>"sir-4fa8d804"},
    #     {:state=>"cancelled", :spot_instance_request_id=>"sir-d3c96e04"}]
    #
    def cancel_spot_instance_requests(*spot_instance_request_ids)
      link = generate_request("CancelSpotInstanceRequests", amazonize_list('SpotInstanceRequestId', spot_instance_request_ids.flatten))
      request_info(link, QEc2CancelSpotInstanceParser.new(:logger => @logger))
    end

    # Create the data feed for Spot Instances
    # (Enables to view Spot Instance usage logs)
    #
    #  ec2.create_spot_datafeed_subscription('bucket-for-konstantin-eu', 'splogs/') #=>
    #    { :owner_id=>"826693181925",
    #      :bucket=>"bucket-for-konstantin-eu",
    #      :prefix=>"splogs/",
    #      :state=>"Active"}
    #
    def create_spot_datafeed_subscription(bucket, prefix=nil)
      request_hash = { 'Bucket' => bucket }
      request_hash['Prefix'] = prefix unless prefix.blank?
      link = generate_request("CreateSpotDatafeedSubscription", request_hash)
      request_info(link, QEc2DescribeSpotDatafeedSubscriptionParser.new(:logger => @logger))
    end

    # Describe the data feed for Spot Instances.
    #
    #  ec2.describe_spot_datafeed_subscription #=>
    #    { :owner_id=>"826693181925",
    #      :bucket=>"bucket-for-konstantin-eu",
    #      :prefix=>"splogs/",
    #      :state=>"Active"}
    #
    def describe_spot_datafeed_subscription
      link = generate_request("DescribeSpotDatafeedSubscription")
      request_info(link, QEc2DescribeSpotDatafeedSubscriptionParser.new(:logger => @logger))
    end


    # Delete the data feed for Spot Instances.
    #
    #  ec2.delete_spot_datafeed_subscription #=> true
    #
    def delete_spot_datafeed_subscription()
      link = generate_request("DeleteSpotDatafeedSubscription")
      request_info(link, RightBoolResponseParser.new(:logger => @logger))
    end

    #-----------------------------------------------------------------
    #      Helpers
    #-----------------------------------------------------------------

    BLOCK_DEVICE_KEY_MAPPING = {                               # :nodoc:
      :device_name               => 'DeviceName',
      :virtual_name              => 'VirtualName',
      :no_device                 => 'NoDevice',
      :ebs_snapshot_id           => 'Ebs.SnapshotId',
      :ebs_volume_size           => 'Ebs.VolumeSize',
      :ebs_delete_on_termination => 'Ebs.DeleteOnTermination' }

    def amazonize_block_device_mappings(block_device_mappings, key = 'BlockDeviceMapping') # :nodoc:
      result = {}
      unless block_device_mappings.blank?
        block_device_mappings = [block_device_mappings] unless block_device_mappings.is_a?(Array)
        block_device_mappings.each_with_index do |b, idx|
          BLOCK_DEVICE_KEY_MAPPING.each do |local_name, remote_name|
            value = b[local_name]
            case local_name
            when :no_device then value = value ? '' : nil   # allow to pass :no_device as boolean
            end
            result["#{key}.#{idx+1}.#{remote_name}"] = value unless value.nil?
          end
        end
      end
      result
    end

    #-----------------------------------------------------------------
    #      PARSERS: Instances
    #-----------------------------------------------------------------

    class QEc2DescribeInstancesParser < RightAWSParser #:nodoc:
      def tagstart(name, attributes)
           # DescribeInstances property
        case full_tag_name
        when 'DescribeInstancesResponse/reservationSet/item',
             'RunInstancesResponse'
          @reservation = { :aws_groups    => [],
                           :instances_set => [] }
        when %r{instancesSet/item$}
            # the optional params (sometimes are missing and we dont want them to be nil)
          @item = { :aws_reason       => '',
                    :dns_name         => '',
                    :private_dns_name => '',
                    :ami_launch_index => '',
                    :ssh_key_name     => '',
                    :aws_state        => '',
                    :aws_product_codes => [] }
        when %r{blockDeviceMapping/item$}
          @item[:block_device_mappings] ||= []
          @block_device_mapping = {}
        end
      end
      def tagend(name)
        case name
        when 'reservationId'    then @reservation[:aws_reservation_id] = @text
        when 'ownerId'          then @reservation[:aws_owner]          = @text
        when 'groupId'          then @reservation[:aws_groups]        << @text
        when 'instanceId'       then @item[:aws_instance_id]       = @text
        when 'imageId'          then @item[:aws_image_id]          = @text
        when 'privateDnsName'   then @item[:private_dns_name]      = @text
        when 'dnsName'          then @item[:dns_name]              = @text
        when 'reason'           then @item[:aws_reason]            = @text
        when 'keyName'          then @item[:ssh_key_name]          = @text
        when 'amiLaunchIndex'   then @item[:ami_launch_index]      = @text
        when 'productCode'      then @item[:aws_product_codes]    << @text
        when 'instanceType'     then @item[:aws_instance_type]     = @text
        when 'launchTime'       then @item[:aws_launch_time]       = @text
        when 'availabilityZone' then @item[:aws_availability_zone] = @text
        when 'kernelId'         then @item[:aws_kernel_id]         = @text
        when 'ramdiskId'        then @item[:aws_ramdisk_id]        = @text
        when 'platform'         then @item[:aws_platform]          = @text
        when 'subnetId'         then @item[:subnet_id]             = @text
        when 'vpcId'            then @item[:vpc_id]                = @text
        when 'privateIpAddress' then @item[:private_ip_address]    = @text
        when 'ipAddress'        then @item[:ip_address]            = @text
        when 'architecture'     then @item[:architecture]          = @text
        when 'rootDeviceType'   then @item[:root_device_type]      = @text
        when 'rootDeviceName'   then @item[:root_device_name]      = @text
        when 'instanceClass'    then @item[:instance_class]        = @text
        else
          case full_tag_name
          when %r{/stateReason/code$}    then @item[:state_reason_code]    = @text.to_i
          when %r{/stateReason/message$} then @item[:state_reason_message] = @text
          when %r{/instanceState/code$}  then @item[:aws_state_code]       = @text.to_i
          when %r{/instanceState/name$}  then @item[:aws_state]            = @text
          when %r{/monitoring/state$}    then @item[:monitoring_state]     = @text
          when %r{/blockDeviceMapping/item} # no trailing $
            case name
            when 'deviceName'          then @block_device_mapping[:device_name]                = @text
            when 'virtualName'         then @block_device_mapping[:virtual_name]               = @text
            when 'volumeId'            then @block_device_mapping[:ebs_volume_id]              = @text
            when 'status'              then @block_device_mapping[:ebs_status]                 = @text
            when 'attachTime'          then @block_device_mapping[:ebs_attach_time]            = @text
            when 'deleteOnTermination' then @block_device_mapping[:ebs_delete_on_termination]  = @text == 'true' ? true : false
            when 'item'                then @item[:block_device_mappings]                     << @block_device_mapping
            end
          when %r{/instancesSet/item$} then @reservation[:instances_set] << @item
          when 'DescribeInstancesResponse/reservationSet/item',
               'RunInstancesResponse'
            @result << @reservation
          end
        end
      end
      def reset
        @result = []
      end
    end

    class QEc2ConfirmProductInstanceParser < RightAWSParser #:nodoc:
      def tagend(name)
        @result = @text if name == 'ownerId'
      end
    end

    class QEc2TerminateInstancesParser < RightAWSParser #:nodoc:
      def tagstart(name, attributes)
        @instance = {} if name == 'item'
      end
      def tagend(name)
        case full_tag_name
        when %r{/instanceId$}         then @instance[:aws_instance_id]        = @text
        when %r{/currentState/code$}  then @instance[:aws_current_state_code] = @text.to_i
        when %r{/currentState/name$}  then @instance[:aws_current_state_name] = @text
        when %r{/previousState/code$} then @instance[:aws_prev_state_code]    = @text.to_i
        when %r{/previousState/name$} then @instance[:aws_prev_state_name]    = @text
        when %r{/item$}               then @result << @instance
        end
      end
      def reset
        @result = []
      end
    end

    class QEc2DescribeInstanceAttributeParser < RightAWSParser #:nodoc:
      def tagstart(name, attributes)
        case full_tag_name
        when %r{blockDeviceMapping$}      then @result = []
        when %r{blockDeviceMapping/item$} then @block_device_mapping = {}
        end
      end
      def tagend(name)
        case full_tag_name
        when %r{/instanceType/value$}   then @result = @text
        when %r{/kernel$}               then @result = @text
        when %r{/ramdisk$}              then @result = @text
        when %r{/userData$}             then @result = @text
        when %r{/rootDeviceName/value$} then @result = @text
        when %r{/disableApiTermination/value}              then @result = @text == 'true' ? true : false
        when %r{/instanceInitiatedShutdownBehavior/value$} then @result = @text
        when %r{/blockDeviceMapping/item} # no trailing $
          case name
          when 'deviceName'          then @block_device_mapping[:device_name]                = @text
          when 'virtualName'         then @block_device_mapping[:virtual_name]               = @text
          when 'noDevice'            then @block_device_mapping[:no_device]                  = @text
          when 'volumeId'            then @block_device_mapping[:ebs_volume_id]              = @text
          when 'status'              then @block_device_mapping[:ebs_status]                 = @text
          when 'attachTime'          then @block_device_mapping[:ebs_attach_time]            = @text
          when 'deleteOnTermination' then @block_device_mapping[:ebs_delete_on_termination]  = @text == 'true' ? true : false
          when 'item'                then @result                                           << @block_device_mapping
          end
        end
      end
      def reset
        @result = nil
      end
    end

  #-----------------------------------------------------------------
  #      PARSERS: Console
  #-----------------------------------------------------------------

    class QEc2GetConsoleOutputParser < RightAWSParser #:nodoc:
      def tagend(name)
        case name
        when 'instanceId' then @result[:aws_instance_id] = @text
        when 'timestamp'  then @result[:aws_timestamp]   = @text
                               @result[:timestamp]       = (Time.parse(@text)).utc
        when 'output'     then @result[:aws_output]      = Base64.decode64(@text)
        end
      end
      def reset
        @result = {}
      end
    end

  #-----------------------------------------------------------------
  #      Instances: Windows related part
  #-----------------------------------------------------------------

    class QEc2DescribeBundleTasksParser < RightAWSParser #:nodoc:
      def tagstart(name, attributes)
        @bundle = {} if name == 'item'
      end
      def tagend(name)
        case name
#        when 'requestId'  then @bundle[:request_id]    = @text
        when 'instanceId' then @bundle[:aws_instance_id]   = @text
        when 'bundleId'   then @bundle[:aws_id]            = @text
        when 'bucket'     then @bundle[:s3_bucket]         = @text
        when 'prefix'     then @bundle[:s3_prefix]         = @text
        when 'startTime'  then @bundle[:aws_start_time]    = @text
        when 'updateTime' then @bundle[:aws_update_time]   = @text
        when 'state'      then @bundle[:aws_state]         = @text
        when 'progress'   then @bundle[:aws_progress]      = @text
        when 'code'       then @bundle[:aws_error_code]    = @text
        when 'message'    then @bundle[:aws_error_message] = @text
        when 'item'       then @result                    << @bundle
        end
      end
      def reset
        @result = []
      end
    end

    class QEc2BundleInstanceParser < RightAWSParser #:nodoc:
      def tagend(name)
        case name
#        when 'requestId'  then @result[:request_id]    = @text
        when 'instanceId' then @result[:aws_instance_id]   = @text
        when 'bundleId'   then @result[:aws_id]            = @text
        when 'bucket'     then @result[:s3_bucket]         = @text
        when 'prefix'     then @result[:s3_prefix]         = @text
        when 'startTime'  then @result[:aws_start_time]    = @text
        when 'updateTime' then @result[:aws_update_time]   = @text
        when 'state'      then @result[:aws_state]         = @text
        when 'progress'   then @result[:aws_progress]      = @text
        when 'code'       then @result[:aws_error_code]    = @text
        when 'message'    then @result[:aws_error_message] = @text
        end
      end
      def reset
        @result = {}
      end
    end



    #-----------------------------------------------------------------
    #      PARSERS: Spot Instances
    #-----------------------------------------------------------------

    class QEc2DescribeSpotPriceHistoryParser < RightAWSParser #:nodoc:
      def tagstart(name, attributes)
        @item = {} if name == 'item'
      end
      def tagend(name)
        case name
        when 'instanceType'       then @item[:instance_type]       = @text
        when 'productDescription' then @item[:product_description] = @text
        when 'spotPrice'          then @item[:spot_price]          = @text.to_f
        when 'timestamp'          then @item[:timestamp]           = @text
        when 'item'               then @result                    << @item
        end
      end
      def reset
        @result = []
      end
    end

    class QEc2DescribeSpotInstanceParser < RightAWSParser #:nodoc:
      def tagstart(name, attributes)
        case full_tag_name
        when %r{spotInstanceRequestSet/item$}
          @item = {}
        when %r{/blockDeviceMapping/item$}
          @item[:block_device_mappings] ||= []
          @block_device_mapping = {}
        end
      end
      def tagend(name)
        case name
        when 'spotInstanceRequestId' then @item[:spot_instance_requestId] = @text
        when 'spotPrice'             then @item[:spot_price]              = @text.to_f
        when 'type'                  then @item[:type]                    = @text
        when 'state'                 then @item[:state]                   = @text
        when 'fault'                 then @item[:fault]                   = @text
        when 'code'                  then @item[:code]                    = @text
        when 'message'               then @item[:message]                 = @text
        when 'validFrom'             then @item[:valid_from]              = @text
        when 'validUntil'            then @item[:valid_until]             = @text
        when 'launchGroup'           then @item[:launch_group]            = @text
        when 'availabilityZoneGroup' then @item[:availability_zone_group] = @text
        when 'imageId'               then @item[:image_id]                = @text
        when 'keyName'               then @item[:key_name]                = @text
        when 'userData'              then @item[:userData]                = @text
        when 'data'                  then @item[:data]                    = @text
        when 'addressingType'        then @item[:addressing_type]         = @text
        when 'instanceType'          then @item[:instance_type]           = @text
        when 'availabilityZone'      then @item[:availability_zone]       = @text
        when 'kernelId'              then @item[:kernel_id]               = @text
        when 'ramdiskId'             then @item[:ramdisk_id]              = @text
        when 'subnetId'              then @item[:subnet_id]               = @text
        when 'instanceId'            then @item[:instance_id]             = @text
        when 'createTime'            then @item[:create_time]             = @text
        when 'productDescription'    then @item[:product_description]     = @text
        when 'groupId'               then (@item[:groups] ||= [])        << @text
        else
          case full_tag_name
          when %r{monitoring/enabled$}
            @item[:monitoring_enabled] = @text == 'true'
          when %r{/blockDeviceMapping/item} # no trailing $
            case name
            when 'deviceName'          then @block_device_mapping[:device_name]                = @text
            when 'virtualName'         then @block_device_mapping[:virtual_name]               = @text
            when 'volumeSize'          then @block_device_mapping[:ebs_volume_size]            = @text.to_i
            when 'snapshotId'          then @block_device_mapping[:ebs_snapshot_id]            = @text
            when 'deleteOnTermination' then @block_device_mapping[:ebs_delete_on_termination]  = @text == 'true' ? true : false
            when 'item'                then @item[:block_device_mappings]                     << @block_device_mapping
            end
          when %r{spotInstanceRequestSet/item$}
            @result << @item
          end
        end
      end
      def reset
        @result = []
      end
    end

    class QEc2CancelSpotInstanceParser < RightAWSParser #:nodoc:
      def tagstart(name, attributes)
        @item = {} if name == 'item'
      end
      def tagend(name)
        case name
        when 'spotInstanceRequestId' then @item[:spot_instance_request_id] = @text
        when 'state'                 then @item[:state]                    = @text
        when 'item'                  then @result                         << @item
        end
      end
      def reset
        @result = []
      end
    end

    class QEc2DescribeSpotDatafeedSubscriptionParser < RightAWSParser #:nodoc:
      def tagend(name)
        case name
        when 'ownerId' then @result[:owner_id] = @text
        when 'bucket'  then @result[:bucket]   = @text
        when 'prefix'  then @result[:prefix]   = @text
        when 'state'   then @result[:state]    = @text
        when 'fault'   then @result[:fault]    = @text
        when 'code'    then @result[:code]     = @text
        when 'message' then @result[:message]  = @text
        end
      end
      def reset
        @result = {}
      end
    end

  end

end