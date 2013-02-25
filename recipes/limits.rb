# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#  http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.


# Recipe to put in the necessary changes for limits.conf - allowing for more open files and processes.
# The deploy user is hard coded, but may want to be put in as a variable at some point.

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


