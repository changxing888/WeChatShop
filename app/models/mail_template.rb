class MailTemplate
  include Mongoid::Document

  MAIL_TEMPLATES = %w[welcome change_password forgot_password confirmation contact_us create_contact welcome_to_admin contact_us_to_admin photo_state date_state]

  field :name,   type: String
  field :subject,     type: String
  field :content,     type: String

  validates :content, presence: true
  validates :name, uniqueness: true, presence: true
  
  #def to_html(context)
  #  template = ERB.new(content, 0, "%<>")
  #  template_result = template.result(context)
  #  Sanitize.clean(RDiscount.new(template_result).to_html.encode("UTF-8", undef: :replace), Sanitize::Config::RELAXED)
  #end

  def content_html
    self.content.html_safe.gsub(/\r\n/, '').gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;','"').gsub("&#39;","'")
  end
end