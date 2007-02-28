# Turn off something automatic in ActionController ...??
ActionController::Base.param_parsers[Mime::XML] = nil

# Monkey patch Net::HTTP so it always provides a User-Agent
# if the request doesn't already specify one.
# This compensates for a bug in the tels-develop webstart server which
# throws a 500 error for requests w/o a User-Agent header.
class Net::HTTPGenericRequest
  include Net::HTTPHeader
  def initialize(m, reqbody, resbody, path, initheader = nil)
    @method = m
    @request_has_body = reqbody
    @response_has_body = resbody
    raise ArgumentError, "HTTP request path is empty" if path.empty?
    @path = path
    initialize_http_header initheader
    self['Accept'] ||= '*/*'
    self['User-Agent'] ||= 'Ruby' # this is the new line
    @body = nil
    @body_stream = nil
  end
end

# The Java SAIL EMF code returns invalid iso8601 date strings
# But the format is just a bit off. Here's one of the strings:
#
#  "2006-10-27T21:25:44.982-0400"
#
# This looks like the standard Internet Time based on ISO 8601 documented in RFC3339:
#
#  http://www.ietf.org/rfc/rfc3339.txt
#
# But the local time offset should have a ":" like this:
#
#  "2006-10-27T21:25:44.982-04:00"
# Here are some additional methods for Time that deal with this
class SdsTime < Time
  def self.java8601(java_date)
    Time.xmlschema("#{java_date[0..-3]}:#{java_date[-2..-1]}")
  end

  def to_java8601
    ts = self.getlocal.xmlschema(3)
    ts[0..-4]+ts[-2..-1]
  end
end
