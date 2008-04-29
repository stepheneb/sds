# runs background job daemon
# gem install bj
# see: http://codeforpeople.com/lib/ruby/bj/bj-1.0.1/README
require 'bj'

# see: http://github.com/mislav/will_paginate/wikis/installation
require 'will_paginate'

# Time Zone things for consistent timestamps in the db
ActiveRecord::Base.default_timezone = :utc

require 'sds_init'
require 'uuidtools'
require 'b64'

require "math/statistics"
class Array
  include Math::Statistics
end

# require 'dike'
# Dike.on :rails
