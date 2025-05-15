require 'sequel'
class Institution < Sequel::Model
  many_to_one :tenant, key: :id

  def self.exists?(code)
    !self.where(code: code).empty?
  end

  def self.render_template(code, mime_type)
    case mime_type
    when 'application/json'
      self.where(code: code).to_json(except: [:id, :tenant_id, :key])
    else
      yield self.where(code: code).first if block_given?
    end
  end

end