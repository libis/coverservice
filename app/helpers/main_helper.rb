require 'http'
require 'lib/cover_service/error'
require 'jwt'
require 'open-uri'
require 'iso8601'
require 'rmagick'

module Sinatra
  module MainHelper
    def config
      DataCollector::ConfigFile
    end

    def check_authentication(institution_code)
      token_params = validate_token(institution_code)
      token_params = token_params.transform_keys(&:to_sym)
      if token_params[:user].nil?
        token_params[:user] = token_params[:sub]
      end
      if token_params[:inst_code] != institution_code && token_params[:inst_code] != 'DEFAULT'
        raise CoverService::Error::NotAllowed, make_message('Authorization error institution code: '+ institution_code)
      end
      return token_params
    end

    def validate_token(institution_code)
      if request.env.key?('HTTP_AUTHORIZATION')
        tokens = validate_jwt(institution_code)
        if tokens.is_a?(Array)
          tokens.first
        else
          tokens
        end
      else
        inst = Institution.where(key: params[:token])
        if inst.select().count == 0
          tenant = Tenant.where(key: params[:token])
          if tenant.select().count == 0
            raise CoverService::Error::NotAllowed, make_message('Invalid token')
          else
            token_tenant_code = tenant.select(:code).first.code
            return {'user': 'tenant_user', 'tenant_code': token_tenant_code, 'inst_code': "DEFAULT"}
          end
        end

        token_inst_code = inst.select(:code).first.code
        tenant_id = inst.select(:tenant_id).first.tenant_id
        tenant = Tenant.where(id: tenant_id)
        token_tenant_code = tenant.select(:code).first.code

        if institution_code == token_inst_code
          {'user': 'default_user', 'inst_code': institution_code}
        else
         
          raise CoverService::Error::NotAllowed, make_message('Invalid token')
        end
      end
    end

    def validate_jwt(institution_code)

      # https://developers.exlibrisgroup.com/blog/working-with-jwt-authentication-tokens/
      # mentions that the public key is available at the following URL: https://apps01.ext.exlibrisgroup.com/auth. ...
  
      jwks = JWT::JWK::Set.new(JSON.parse(URI.open("https://api-#{config[:region]}.hosted.exlibrisgroup.com/auth/#{institution_code}/jwks.json").read))
      #jwks.filter! {|key| key[:use] == 'sig' } # Signing keys only!
      JWT.decode(jwt, nil, true, algorithms: 'RS256', jwks: jwks) # algorithms : Primo => ES256 , Alma => RS256 ???

    rescue JWT::DecodeError => e
      raise CoverService::Error::NotAllowed, "Error decoding JWT: #{e.message}"
    rescue StandardError => e
      raise CoverService::Error::NotAllowed, 'Invalid token'
    end

    def jwt
      request.env['HTTP_AUTHORIZATION']&.split(' ')&.last|| ''
    end

    def accept
      headers['Accept']
    end

    def get_post_body(req)
      req.body.rewind
      JSON.parse(req.body.read)
    end

    def make_message(message)
      {message: message, tenant: params[:tenant]}.to_json
    end

    private
    
    def save_org_cover (cover_uri, tmpfile)
      begin
        unless cover_uri.is_a?(URI)
          begin
            cover_uri = URI( cover_uri )
          rescue URI::InvalidURIError
            raise CoverService::Error::BadRequest, make_message("Invalid URI #{cover_uri}")
          end
        end
        
        case cover_uri.scheme
        when 'http'
          # Not jet implemented
        when 'https'
          # Not jet implemented
        when 'file'
          file_name = "#{cover_uri.host}#{cover_uri.path}" 

          file_name_absolute_path = File.absolute_path(file_name)
          file_directory = File.dirname(file_name_absolute_path)
          org_directory = File.join(file_directory, "org")

          org_file = File.basename(file_name, File.extname(file_name))
          org_file = "#{org_file}_#{Time.now.strftime("%Y%m%d%H%M%S")}#{File.extname(file_name)}"
          org_file = File.join(org_directory, org_file)

          unless File.directory?(org_directory)
            FileUtils.mkdir_p(org_directory)
          end

          cp(tmpfile.path, org_file)

        when /amqp/
          if cover_uri.scheme =~ /^rpc/
            # Not jet implemented
          else
            # Not jet implemented
          end
        else
          raise "Do not know how to process #{source}"
        end


      rescue StandardError => e
        raise CoverService::Error::InternalServerError, make_message(e.message)
      end
    end

    def save_cover (cover_uri, tmpfile)
      begin
        unless cover_uri.is_a?(URI)
          begin
            cover_uri = URI( cover_uri )
          rescue URI::InvalidURIError
            raise CoverService::Error::BadRequest, make_message("Invalid URI #{cover_uri}")
          end
        end

        case cover_uri.scheme
        when 'http'
          # Not jet implemented
        when 'https'
          # Not jet implemented
        when 'file'
          file_name = "#{cover_uri.host}#{cover_uri.path}" 

          file_name_absolute_path = File.absolute_path(file_name)
          file_directory = File.dirname(file_name_absolute_path)
  
          unless File.directory?(file_directory)
            FileUtils.mkdir_p(file_directory)
          end

          cp(tmpfile.path, file_name)

          new_file = File.basename(file_name, File.extname(file_name))
          # TEST new_file = "#{new_file}_#{DataCollector::ConfigFile[:cover_dimentions]}.#{DataCollector::ConfigFile[:cover_extention_format]}"
          new_file = "#{new_file}.#{DataCollector::ConfigFile[:cover_extention_format]}"
          new_file = File.join(file_directory, new_file)

          image = Magick::Image.read(file_name).first
          image.change_geometry!(DataCollector::ConfigFile[:cover_dimentions]) { |cols, rows, img|
            newimg = img.resize(cols, rows)
            newimg.write(new_file)
          }

          File.delete(file_name)
          
        when /amqp/
          if cover_uri.scheme =~ /^rpc/
            # Not jet implemented
          else
            # Not jet implemented
          end
        else
          raise "Do not know how to process #{source}"
        end
        
        return File.basename(new_file)

      rescue StandardError => e
        raise CoverService::Error::InternalServerError, make_message(e.message)
      end
      
    end

    
    def delete_cover (cover_uri)
      begin
        unless cover_uri.is_a?(URI)
          begin
            cover_uri = URI( cover_uri )
          rescue URI::InvalidURIError
            raise CoverService::Error::BadRequest, make_message("Invalid URI #{cover_uri}")
          end
        end

        case cover_uri.scheme
        when 'http'
          # Not jet implemented
        when 'https'
          # Not jet implemented
        when 'file'
          file_name = "#{cover_uri.host}#{cover_uri.path}" 

          file_name_absolute_path = File.absolute_path(file_name)
          file_directory = File.dirname(file_name_absolute_path)
  
          unless File.directory?(file_directory)
            FileUtils.mkdir_p(file_directory)
          end
          
          delete_directory = File.join(file_directory, "delete")
          unless File.directory?(delete_directory)
            pp "create delete_directory #{delete_directory}"
            FileUtils.mkdir_p(delete_directory)
          end

          delete_file = File.basename(file_name, File.extname(file_name))
          delete_file = "#{delete_file}_#{Time.now.strftime("%Y%m%d%H%M%S")}#{File.extname(file_name)}"
          delete_file = File.join(delete_directory, delete_file)
          if File.file?(file_name_absolute_path)
            pp "move to delete folder with timestamp !!"
            FileUtils.mv(file_name, delete_file)
          else
            raise "cover #{file_name_absolute_path} does not exists on disk"
          end

        when /amqp/
          if cover_uri.scheme =~ /^rpc/
            # Not jet implemented
          else
            # Not jet implemented
          end
        else
          raise "Do not know how to process #{source}"
        end
      rescue StandardError => e
        raise CoverService::Error::InternalServerError, make_message(e.message)
      end
      
    end

    def  substitute_paths(storage_uri, params, cover_name) 
      tenant_cover_path =  storage_uri
                        .gsub(/{{tenant}}/, params[:tenant].upcase )
                        .gsub(/{{provider}}/, params[:tenant].upcase )
                        .gsub(/{{type}}/, params[:type].upcase ) 
      tenant_cover_path = [ tenant_cover_path.split("/"), cover_name].join("/")
      
      institution_cover_path = storage_uri
                        .gsub(/{{tenant}}/, params[:tenant].upcase )
                        .gsub(/{{provider}}/, params[:institution].upcase )
                        .gsub(/{{type}}/, params[:type].upcase ) 
      institution_cover_path =  [ institution_cover_path.split("/"), cover_name].join("/")  
      return tenant_cover_path, institution_cover_path
    end
  end

  helpers MainHelper
end
