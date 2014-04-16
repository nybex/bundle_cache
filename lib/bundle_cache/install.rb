require "digest"
require "aws-sdk"

module BundleCache
  def self.install
    architecture = `uname -m`.strip
    file_name = "#{ENV['BUNDLE_ARCHIVE']}-#{architecture}.tgz"
    digest_filename = "#{file_name}.sha2"
    bucket_name = ENV["AWS_S3_BUCKET"]
    bundle_dir = ENV["BUNDLE_DIR"] || "~/.bundle"
    processing_dir = ENV['PROCESS_DIR'] || ENV['HOME']

    s3 = AWS::S3.new
    bucket = s3.buckets[bucket_name]

    gem_archive = bucket.objects[file_name]
    hash_object = bucket.objects[digest_filename]

    puts "=> Downloading the bundle"
    File.open("#{processing_dir}/remote_#{file_name}", 'wb') do |file|
      gem_archive.read do |chunk|
        file.write(chunk)
      end
    end
    puts "  => Completed bundle download"

    puts "=> Extract the bundle"
    `cd #{File.dirname(bundle_dir)} && tar -xf "#{processing_dir}/remote_#{file_name}"`

    puts "=> Downloading the digest file"
    File.open("#{processing_dir}/remote_#{file_name}.sha2", 'wb') do |file|
      hash_object.read do |chunk|
        file.write(chunk)
      end
    end
    puts "  => Completed digest download"

    puts "=> All done!"
  rescue AWS::S3::Errors::NoSuchKey
    puts "There's no such archive!"
  end

end
