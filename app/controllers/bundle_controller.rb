class BundleController < ApplicationController

  require 'zlib'

  before_filter :log_referrer
  before_filter :find_bundle, :except => [ :list ]

  after_filter :compress, :only => [:bundle]
  layout "standard", :except => [ :atom ] 

  BUNDLE_SIZE_LIMIT = 5**21-1 # 5M

  
  protected
  
  def find_bundle
    # let's not burden the SDS down by forcing it to find *all* the bundles in a portal first,
    # esp. if we already know the bundle id
    begin
      @bundle = Bundle.find(params[:id])
      raise "incorrect portal" if @bundle.workgroup.portal_id != @portal.id
    rescue
      resource_not_found('Bundle', params[:id])
    end
  end

  public
  
  def bundle
    if @bundle
      if request.put? and (request.env['CONTENT_TYPE'] == "application/xml")
        begin 
          raise "bundle too large" if request.raw_post.length > BUNDLE_SIZE_LIMIT
          if request.env['HTTP_CONTENT_ENCODING'] == 'b64gzip'
            content = Zlib::GzipReader.new(StringIO.new(B64::B64.decode(request.raw_post))).read
          else
            content = request.raw_post
          end
          @bundle.bc = content
          @bundle.save!
          response.headers['Content-md5'] = B64::B64.folding_encode(Digest::MD5.digest(@bundle.bundle_content.content))
          response.headers['Location'] =  "#{url_for(:controller => :bundle, :id => @bundle.id)}"
  #        response.headers['Cache-Control'] = 'no-cache'
          response.headers['Cache-Control'] = 'public'
          render(:xml => "", :status => 200) # updated
        rescue => e
          render(:text => e, :status => 400) # Bad Request
        end
      elsif request.get?
        response.headers["Content-Type"] = "text/xml"
        render :text => @bundle.bundle_content.content, :layout => false
      else
        render(:text => "Forbidden: request not allowed. Only PUT and GET requests are allowed.", :status => 403) # Forbidden
      end
    else
      render(:text => "Not Found", :status => 404) # Not Found
    end
  end
  
  def copy
    # find the destination workgroup
    begin
      @workgroup = Workgroup.find(params[:wid])
    rescue
      resource_not_found('Workgroup', params[:wid])
    end
    
    begin
      # we need to modify the otrunk uuid and OTUser uuid and name in any ot_learner_data before we copy the bundle
      pid = spawn do
        # get the bundle contents
        content_xml = REXML::Document.new(@bundle.bundle_content.content).root
        # for each ot_learner_data sock entry
        content_xml.elements.each("//sockParts[@rimName='ot.learner.data']/sockEntries") { |sock|
          begin
            #   unpack it
            ot_learner_data_xml = REXML::Document.new(Zlib::GzipReader.new(StringIO.new(B64::B64.decode(sock.attributes["value"]))).read).root
            #   modify it
            otrunk_id = UUID.timestamp_create().to_s
            user_id = UUID.timestamp_create().to_s
            ot_learner_data_xml.attributes["id"] = otrunk_id
            ot_learner_data_xml.elements["//otrunk/objects/OTStateRoot/userMap/entry"].attributes["key"] = user_id
            user_object = ot_learner_data_xml.elements["/otrunk/objects/OTStateRoot/userMap/entry/OTReferenceMap/user/OTUserObject"]
            user_object.attributes["id"] = user_id
            user_object.attributes["name"] = @workgroup.name
            #   repack it and save it to the bundle contents
            gzip_string_io = StringIO.new()
            gzip = Zlib::GzipWriter.new(gzip_string_io)
            gzip.write(ot_learner_data_xml.to_s)
            gzip.close
            gzip_string_io.rewind
            val = B64::B64.encode(gzip_string_io.string)
            sock.attributes["value"] = val
          rescue
            logger.warn "Couldn't modify sock entry in bundle #{@bundle.id}"
          end
        }
           
        new_bundle = Bundle.create!(:workgroup_id => @workgroup.id, :workgroup_version => @workgroup.version, :bc => content_xml.to_s)
      end
      wait(pid)
      render(:xml => "", :status => 201)
    rescue => e
      render(:xml => "<xml><error>#{e}</error><backtrace>#{e.backtrace.join("\n")}</backtrace></xml>", :status => 400)
    end
  end

end