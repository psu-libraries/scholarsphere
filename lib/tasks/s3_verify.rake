# frozen_string_literal: true

namespace :s3 do
  desc 'Verify Access to all Files'
  task verify_all: :environment do
    errors = {}
    FileResource.all.each do |f|
      resp = Faraday.get(f.file_url) do |req|
        # file.file_url only gives us a presigned URL for a GET request.
        # Signatures vary between GET and HEAD requests
        # here, we simulate a HEAD request by doing a GET request with a Range of 0
        # https://stackoverflow.com/a/39663152
        req.headers['Range'] = 'bytes=0-0'
      end

      if resp.status != 206
        errors[f.file_data['id']] = resp.status
        # Print Red dot for failure
        printf("\e[31m.\e[0m")
      else
        # Print Green dot for failure
        printf("\e\e[32m.\e[0m")
      end
    end
    printf("\n")
    print_report(errors)
  end
end

def print_report(errors)
  if errors.empty?
    puts "Validated #{FileResource.all.length} Files."
  else
    puts "There were #{errors.length} errors out of #{FileResource.all.length} Files."
    puts 'File                                  Status'
    puts '--------------------------------------------'
    errors.each do |file, status|
      puts "#{file}    #{status}"
    end
  end
end
