maintainer        "AKQA SF Ops"
maintainer_email  "sf.ops@akqa.com"
license          "Apache 2.0"
description       "Installs MongoDB and builds the ReplicaSet"
version           "1.4.0"

depends "apt"
depends "python"

%w{ debian ubuntu }.each do |os|
  supports os
end
