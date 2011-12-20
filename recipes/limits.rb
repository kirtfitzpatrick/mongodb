#Recipe to put in the necessary changes for limits.conf - allowing for more open files and processes.
#The deploy user is hard coded, but may want to be put in as a variable at some point.

include_recipe "mongodb"

file2append = '/etc/security/limits.conf'

if File.exists?(file2append)
    file file2append do
      additional_content = %Q{
# Automatically added to #{file2append}-mongodb
deploy soft nofile 65572
deploy hard nofile 65572
deploy soft noproc 16384
deploy hard noproc 16384

mongodb soft nofile 65572
mongodb hard nofile 65572
mongodb soft noproc 16384
mongodb hard noproc 16384

root soft nofile 65572
root hard nofile 65572
root soft noproc 16384
root hard noproc 16384
# End appending of #{file2append}-mongodb
}
        only_if do
          current_content = File.read(file2append)
          current_content.index(additional_content).nil?
        end

        current_content = File.read(file2append)
        orig_content    = current_content.gsub(/\n# Automatically added to #{file2append}-mongodb(.|\n)*# End appending of #{file2append}-mongodb\n/, '')
        
        owner "root"
        group "root"
        mode "0644"
        content orig_content + additional_content
        notifies :restart, "service[mongodb]", :immediately
    end
end


