module Microstatic

class S3BucketCreator
  include UsesFog

  def initialize( aws_creds )
    check_and_store_aws_creds(aws_creds)
  end

  def create( bucket_name )
    connection.put_bucket( bucket_name )
    connection.put_bucket_acl( bucket_name, 'public-read' )
    connection.put_bucket_website( bucket_name, 'index.html', :key => '404.html' )
  end
end

end
