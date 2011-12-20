maintainer        "AKQA SF Ops"
maintainer_email  "sf.ops@akqa.com"
license           "'open' like android"
description       "Installs MongoDB and builds the ReplicaSet"
version           "1.0.0"


depends "apt"


%w{ debian ubuntu }.each do |os|
  supports os
end
