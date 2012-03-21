maintainer        "AKQA SF Ops"
maintainer_email  "sf.ops@akqa.com"
license           "'open' like android"
description       "Installs MongoDB and builds the ReplicaSet"
version           "1.1.1"

depends "apt"
depends "python"

%w{ debian ubuntu }.each do |os|
  supports os
end
