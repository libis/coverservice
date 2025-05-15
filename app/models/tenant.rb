require 'sequel'

class Tenant < Sequel::Model
  one_to_many :institutions

  def self.exists?(code)
    
    #pp "======Tenant ===================> #{code}"
    #pp self.where(code: code).to_json

    !self.where(code: code).empty?
  end

  def self.render_template(code, mime_type)
    case mime_type
    when 'application/json'
      self.where(code: code).to_json(except: [:id, :key], include: {institutions: {except: [:id, :tenant_id]}})
    else
      yield self.where(code: code).first if block_given?
    end
  end
end