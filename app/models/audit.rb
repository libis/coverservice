require 'sequel'

class Audit < Sequel::Model(:audit)

  def self.insert_entry(audit_row)
    self.insert(audit_row)
  end

  def self.render_template(institution_code, mime_type)
    case mime_type
    when 'application/json'
      self.where(institution_code: institution_code).all
    else
      yield self.where(institution_code: institution_code).first if block_given?
    end
  end
end