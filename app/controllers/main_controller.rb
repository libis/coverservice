require_relative 'generic_controller'
include FileUtils::Verbose

class MainController < GenericController

  get '/?' do
    tenant_code = DataCollector::ConfigFile[:tenant]
    case @media_type
    when 'application/json'
    else
      erb :index, locals: { version: (ENV['OH_VERSION'] || 'unknown'), tenants:  Tenant.exclude(name: "ADMIN").all }, layout: true
    end
  rescue StandardError => e
    #raise e if e.class.name =~ /^CoverService/
    raise e
    raise e, make_message(e.message)
  end


  get '/:tenant/?' do

    tenant_code = params[:tenant] || DataCollector::ConfigFile[:tenant]
    raise CoverService::Error::NotFound unless Tenant.exists?(tenant_code)

    Tenant.render_template(tenant_code, @media_type) do |entity|
      erb :tenant, locals: { tenant: entity }, layout: true, :layout_options => { :views => "#{settings.views}/layouts/#{tenant_code}/" }
    end
  rescue StandardError => e
    raise e if e.class.name =~ /^CoverService/
    raise e, make_message(e.message)
  end
  
  get '/:tenant/:institution/alma:id?' do

    tenant_code = params[:tenant] || DataCollector::ConfigFile[:tenant]
    institution_code = params[:institution] || nil
    cover_location = nil

    raise CoverService::Error::NotAllowed, make_message('No authorization token') unless request.env.key?('HTTP_AUTHORIZATION') || params.key?('token')
    token_params = validate_token(institution_code)
    
    if token_params[:inst_code] != institution_code && token_params[:inst_code] != 'DEFAULT'
      raise CoverService::Error::NotAllowed, make_message('Authorization error institution code: '+ institution_code)
    end
    #pp "=========================================================================="
    #pp token_params[:user]
    #pp token_params[:inst_code]
    #pp "=========================================================================="

    raise CoverService::Error::NotFound, make_message('Invalid institution: '+ institution_code) unless Institution.exists?(institution_code)

    if params[:id].nil? || params[:id]&.empty?
      raise CoverService::Error::BadRequest, "code is required!"
    end

    storage_uri = DataCollector::ConfigFile[:cover_storage]

    tenant_cover_path = storage_uri
                      .gsub(/{{tenant}}/, params[:tenant].upcase )
                      .gsub(/{{provider}}/, params[:institution].upcase )
                      .gsub(/{{type}}/, "MMSID" ) 

    uri = URI ( tenant_cover_path )

    cover_dir = File.absolute_path("#{URI.decode_www_form_component("#{uri.host}#{uri.path}") }")


    if Dir["#{cover_dir}/#{params[:id]}*"].size > 0
      Dir["#{cover_dir}/#{params[:id]}*"].each do |cover_filename|
        #cover_location = "file://#{cover_filename}"
        cover_location = cover_filename
        break;
      end 
    end

    #only return NetworkZone covers !!
    # institution_cover_path = storage_uri
    #                  .gsub(/{{tenant}}/, params[:tenant].upcase )
    #                  .gsub(/{{provider}}/, params[:institution].upcase )
    #                  .gsub(/{{type}}/,  "MMSIS"  ) 
   
    if cover_location.nil?
      halt 404 , "No cover available for #{  params[:id] }"
    end

    cover_url = DataCollector::ConfigFile[:cover_providers][:CVR_][:url].gsub(/{{mmsid}}/,  params[:id]  ) 
    cover = {
      "CVR": {
        "MMSID":{
          "#{params[:id]}": {
            "available": true,    
            "url": cover_url
          } 
        }
      }
    }

    return cover.to_json

  rescue StandardError => e
    raise e if e.class.name =~ /^CoverService/
    raise e, make_message(e.message)    
  end

 get '/:tenant/:institution/audit?' do

    tenant_code = params[:tenant] || DataCollector::ConfigFile[:tenant]
    institution_code = params[:institution] || nil
    
    raise CoverService::Error::NotAllowed, make_message('No authorization token') unless request.env.key?('HTTP_AUTHORIZATION') || params.key?('token')

    token_params = check_authentication(institution_code)

    if token_params[:user] != "tenant_user" || token_params[:tenant_code] != "#{params[:tenant]}_ADMIN"
      raise CoverService::Error::NotAllowed, make_message('Invalid token to use this audit')
    end
    
    
    # pp "=========================================================================="
    # pp token_params
    # pp token_params[:user]
    # pp token_params[:inst_code]
    # pp "#{token_params[:tenant_code]} == #{params[:tenant]}_ADMIN"
    # pp "=========================================================================="

    raise CoverService::Error::NotFound, make_message('Invalid institution: '+ institution_code) unless Institution.exists?(institution_code)

    audit_rows = Audit.where(institution_code: params[:institution])

    erb :audit, locals: { audit_rows: audit_rows, institution_code: token_params[:inst_code] }, layout: true, :layout_options => { :views => "#{settings.views}/layouts/#{tenant_code}/" }
    
  rescue StandardError => e
    raise e if e.class.name =~ /^CoverService/
    raise e, make_message(e.message)    
  end


=begin
  # Will be handled in the CLoudApp
  get '/:tenant/:institution/alma:id?' do
    tenant_code = params[:tenant] || DataCollector::ConfigFile[:tenant]
    institution_code = params[:institution] || nil
    
    raise CoverService::Error::NotAllowed, make_message('No authorization token') unless request.env.key?('HTTP_AUTHORIZATION') || params.key?('token')
    token_params = validate_token(institution_code)
    
    if token_params[:inst_code] != institution_code && token_params[:inst_code] != 'DEFAULT'
      raise CoverService::Error::NotAllowed, make_message('Authorization error institution code: '+ institution_code)
    end
    
    # Not nessecary to check. Will be handled in the cloudApp
    if request.env.key?('HTTP_X_COVER_KEY')
      cover_api_key = request.env['HTTP_X_COVER_KEY']&.split(' ')&.last|| ''
    else
    #  raise CoverService::Error::NotAllowed, 'x-cover-key missing'
      pp "x-cover-key missing"
      pp "Using default cover_api_key"
      pp "because it this is a testing/beta version"
      cover_api_key = "25339242acc712b697828743887740d04c66ba9858edc"
    end
    
    pp "Get available cover for #{params[:id]}"
    # Get metadata from Primo
    begin
      ids = {
        mms: [params[:id]],
        isbn: nil,
        issn: nil
      }
    
      result = {}
      metadata = JSON.parse(URI.open("https://lib.is/alma#{params[:id]}/metadata").read)
    
      ids[:isbn] = [metadata["isbn"]].flatten || nil
      
      cover_providers = DataCollector::ConfigFile[:cover_providers]
      # pp "cover_providers #{cover_providers}"
    
    rescue StandardError => e
      raise e if e.class.name =~ /^CoverService/
      raise e, make_message(e.message)
    end
    
    # response 
    # {
    #  <resource_id> : {
    #    <identifier_type>: [
    #      {
    #        <identifier>: {
    #          "available": true
    #          "url": …
    #        }
    #      }
    #    ]
    #  }
    #}
 
    # Not nessecary to check all providers. Only covers uploaded in the tenant dir will be returned

     cover_providers.each do |cover_provider, cover_provider_v|
      supported_id_types = [ cover_provider_v[:supported_id_types] ].flatten
      result[cover_provider] = {}
      supported_id_types.each do |supported_id_type|
        result[cover_provider][supported_id_type] = []
        ids[supported_id_type.to_sym].each do |id|
          uri = Mustache.render(cover_provider_v[:url], {id: id, inst: institution_code, type: supported_id_type.upcase, cover_api_key: cover_api_key })
          response = HTTP.get(uri)
          case response.code 
          when 200
            result[cover_provider][supported_id_type] << { 
              id => {
                  available: true,
                  url: uri.gsub( cover_api_key, "***"  )
                }
              } 
          else
            # Only 200 is ok, all other codes will not be part of the result
            #result[cover_provider][supported_id_type] << { 
            #  id => {
            #      available: false,
            #      url: nil
            #    }
            #  } 
          end
        end
        # Dont keep empty supported_id_type in response
        result[cover_provider].delete(supported_id_type) if result[cover_provider][supported_id_type].empty?
      end
      # Dont keep empty cover_prviders in response
      result.delete(cover_provider) if result[cover_provider].empty?
    end
    result.to_json

  rescue StandardError => e
    raise e if e.class.name =~ /^CoverService/
    raise e, make_message(e.message)    
  end
=end


  post '/:tenant/:institution/?' do

    tenant_code = params[:tenant] || DataCollector::ConfigFile[:tenant]
    institution_code = params[:institution] || nil
    
    raise CoverService::Error::NotAllowed, make_message('No authorization token') unless request.env.key?('HTTP_AUTHORIZATION') || params.key?('token')

    token_params = check_authentication(institution_code)
   
    # pp token_params[:user]
    # pp token_params[:inst_code]
    # Todo : check fileextension and file size

    raise CoverService::Error::NotFound, make_message('Invalid institution: '+ institution_code) unless Institution.exists?(institution_code)
    raise CoverService::Error::UnprocessableContent, make_message('cover file is missing')  unless params[:cover]

    unless params[:cover] &&
      (tmpfile = params[:cover][:tempfile]) &&
      (cover_name = params[:cover][:filename])
      @error = "No file selected"
    end

    unless ["mmsid", "isbn", "issn"].include? params[:type]
      raise CoverService::Error::BadRequest, "Unsuperported type #{params[:type]}"
    end

    if params[:code].nil? || params[:code]&.empty?
      raise CoverService::Error::BadRequest, "code is required!"
    end

    cover_name = "#{params[:code]}#{File.extname(cover_name)}"

    storage_uri = DataCollector::ConfigFile[:cover_storage]

    # pp "===================> #{storage_uri}"
    # pp "===================> #{params[:tenant].upcase}"

    tenant_cover_path, institution_cover_path = substitute_paths(storage_uri, params, cover_name) 

    save_org_cover(institution_cover_path, tmpfile)

    cover_name = save_cover(tenant_cover_path, tmpfile)
    cover_name = save_cover(institution_cover_path, tmpfile)


    # TODO: 
    # create cover with other dimensions
    # create cover with other formats
    # create cover with other quality

    # pp "-------------------->>>> token_params[:user] #{token_params} "

    audit_row = {
      tenant_code: tenant_code,
      institution_code: institution_code,
      cover: "#{params[:type]}:#{params[:code]}",
      user_id: token_params[:user],
      execution_time: Time.now,
      method: "UPLOAD"
    }
    Audit.insert_entry(audit_row)

    {
      status: 'success',
      message: "cover uploaded successfully",
      data: {
        tenant_code: tenant_code,
        institution_code: institution_code,
        cover: "#{params[:type]}:#{params[:code]}",
        cover_name: cover_name
      }
    }.to_json
    

  rescue StandardError => e
    raise e if e.class.name =~ /^CoverService/
    raise e, make_message(e.message)
  end


  delete '/:tenant/:institution/?' do

    tenant_code = params[:tenant] || DataCollector::ConfigFile[:tenant]
    institution_code = params[:institution] || nil
    
    raise CoverService::Error::NotAllowed, make_message('No authorization token') unless request.env.key?('HTTP_AUTHORIZATION') || params.key?('token')

    token_params = check_authentication(institution_code)

    # pp token_params[:user]
    # pp token_params[:inst_code]
    # Todo : check fileextension and file size

    raise CoverService::Error::NotFound, make_message('Invalid institution: '+ institution_code) unless Institution.exists?(institution_code)
    raise CoverService::Error::UnprocessableContent, make_message('cover file is missing')  unless params[:cover]

    unless ["mmsid", "isbn", "issn"].include? params[:type]
      raise CoverService::Error::BadRequest, "Unsuperported type #{params[:type]}"
    end

    if params[:code].nil? || params[:code]&.empty?
      raise CoverService::Error::BadRequest, "code is required!"
    end

    cover_ext = "jpg"
    cover_name = "#{params[:code]}.#{ cover_ext }"

    storage_uri = DataCollector::ConfigFile[:cover_storage]

    # pp "===================> #{storage_uri}"
    # pp "===================> #{params[:tenant].upcase}"

    tenant_cover_path, institution_cover_path = substitute_paths(storage_uri, params, cover_name) 

    # pp "===================> tenant_cover_path :#{tenant_cover_path}"
    # pp "===================> institution_cover_path :#{institution_cover_path}"

    delete_cover(tenant_cover_path)
    delete_cover(institution_cover_path)
    
    audit_row = {
      tenant_code: tenant_code,
      institution_code: institution_code,
      cover: "#{params[:type]}:#{params[:code]}",
      user_id: token_params[:user],
      execution_time: Time.now,
      method: "DELETE"
    }

    Audit.insert_entry(audit_row)

    {
      status: 'success',
      message: "cover deleted successfully"
    }.to_json

  rescue StandardError => e
    raise e if e.class.name =~ /^CoverService/
    raise e, make_message(e.message)
  end

  get '*' do
    tenant_code = params[:tenant] || DataCollector::ConfigFile[:tenant]
    institution_code = params[:institution] || nil
    library_code = params[:library] || nil

    raise make_message("Hmm, do not know how to do that. Please take a look at the <a href='/#{DataCollector::ConfigFile[:endpoint]}'>help page</a>")
  rescue StandardError => e
    raise e if e.class.name =~ /^CoverService/
    raise e, make_message(e.message)
  end
end