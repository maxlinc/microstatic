require 'digest/md5'
require 'pathname'

module Microstatic

# The following is based on code generously 
# shared by Giles Alexander (@gga)
class S3Deployer
  include UsesFog
  def initialize( local_dir, bucket, aws_creds )
    check_and_store_aws_creds(aws_creds)

    @local_dir = Pathname.new(local_dir)
    @bucket = bucket
  end

  def upload
    Pathname.glob(@local_dir+"**/*") do |child|
      upload_file(child) unless child.directory?
    end
  end

  def upload_file( file )
    s3_key = file.relative_path_from(@local_dir).to_s

    begin
      s3_object = connection.head_object(@bucket,s3_key)
    rescue Excon::Errors::NotFound
      s3_object = false
    end

    if !s3_object
      log_action('CREATE', s3_key)
      connection.put_object( @bucket, s3_key, file.open, 'x-amz-acl' => 'public-read' )
    else
      s3_md5 = s3_object.headers['ETag'].sub(/"(.*)"/,'\1')
      local_md5 = Digest::MD5.hexdigest( file.read )

      if( s3_md5 == local_md5 )
        log_action('NO CHANGE', s3_key)
      else
        log_action('UPDATE', s3_key)
        connection.put_object( @bucket, s3_key, file.open )
      end
    end
  end

  def log_action(action,file)
    message = action.to_s.rjust(10) + "  " + file
    puts message
  end
end

end
