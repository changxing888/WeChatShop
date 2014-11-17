module UsersHelper
  def gravatar_for(user, options = { size: 80 })
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    size = options[:size]
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    image_tag(gravatar_url, alt: user.first_name+" "+user.last_name, class: "gravatar")
  end

  # Works with UsersController and User model
  def current_user?(user)
    user == current_user
  end

  def admin_user
    redirect_to(root_url) unless admin_user?(current_user)
  end

  def admin_user?(user)
    user.admin == 1
  end

  def correct_user?(user)
    user == current_user
  end
end
