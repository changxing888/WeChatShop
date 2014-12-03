class Category
  include Mongoid::Document
  #acts_as_nested_set :dependent => :destroy
  
  mount_uploader :image, CategoryImageUploader
  
  OBJECT_TYPE = %w[Merchat Product Idea]
  LOCATIONS = ["Los Angeles","San Francisco","San Diego"]

  field :display_name,      type: String
  field :app_publish_name,  type: String
  field :description,       type: String
  field :object_type,       type: String
  field :yelp_name,         type: String
  field :yelp_category_id,  type: String
  field :active,            type: Boolean, default:false
  field :show_under_top,    type: Boolean, default:false
  field :locations,         type: String
  field :order_id,          type: Integer
  
  field :image,              type: String

  has_many :subcategories, :class_name => "Category", :foreign_key=>"parent_id", :dependent => :destroy, :order=> "order_id ASC"
  belongs_to :parent, :class_name => "Category"

  belongs_to :date_type
  belongs_to :timeframe
  belongs_to :parts_of_day

  belongs_to :level
  belongs_to :cost
  

  #has_one :logo, :as => :logoable,      dependent: :destroy
  has_many :activity_categories,        dependent: :destroy
  
  validates_presence_of :display_name, :app_publish_name, :yelp_category_id  
  #validates_numericality_of :order_id  
  #default_scope where(:active=>true)

  def activities
    return [] if active == false
    ids = []
    cat_ids = []
    cat_ids << self.id.to_s
    cat_ids = self.all_sub_categories.map{|cat| cat.id.to_s}    
    act_cats = ActivityCategory.in(category_id:cat_ids)
    act_cat_ids = act_cats.map{|ac| ac.activity_id.to_s}
    acts = Activity.in(id:act_cat_ids) #.reject{|act| act.is_active? == false }
    #activities = Activity.in(id:acts.map(&:id))
  end
  

  def my_activities(user)
    ids = []
    cat_ids = []
    cat_ids << self.id.to_s
    cat_ids = self.all_sub_categories.map{|cat| cat.id.to_s}    
    act_cats = ActivityCategory.in(category_id:cat_ids)
    act_cat_ids = act_cats.map{|ac| ac.activity_id.to_s}
    acts = user.available_activities.in(id:act_cat_ids).reject{|act| act.is_active? == false }
    activities = user.available_activities.in(id:acts.map(&:id))
  end

  def my_dates
    date_ids = []
    cat_ids = []
    cat_ids << self.id.to_s
    cat_ids = self.all_sub_categories.map(&:id)
    cat_ids.each do |cat_id|      
      date_ids = date_ids | MyDate.where({:category_ids => /.*#{cat_id.to_s}*./}).map{|dt| dt.id.to_s}
    end
    MyDate.in(id:date_ids)
  end

  def self.root_categories
    where(:parent_id=>nil, :active=> true).order_by("order_id ASC")
  end
  
  def self.all_root_categories
    where(:parent_id=>nil).order_by("order_id ASC")
  end

  def sub_categories
    self.subcategories.where(:active=>true).order_by("order_id ASC")
  end

  def sub_categories_without_active
    self.subcategories.order_by("order_id ASC")
  end

  def all_sub_categories
    sub_cat = []
    if self.has_child?
      self.sub_categories.each do |st_cat|
        sub_cat << st_cat.id.to_s
        if st_cat.has_child?
          st_cat.sub_categories.each do |nd_cat|
            sub_cat << nd_cat.id.to_s
            if nd_cat.has_child?
              nd_cat.sub_categories.each do |rd_cat|
                sub_cat << rd_cat.id.to_s
              end              
            end
          end

        end
      end
    end
    Category.in(id:sub_cat)
  end

  def self.all_categories
    categories = []
    Category.root_categories.each do |root_cat|
      categories = categories << root_cat
      categories = categories | root_cat.all_sub_categories
    end
    return categories
  end

  def name
    name = []
    cat = Category.find(self.id)    
    while cat.parent.present?
      name << cat.display_name
      cat = cat.parent
      break if cat.id == self.id
    end
    name << cat.display_name
    return name.reverse
  end

  def selected?(user)
    if user.user_activity_category.present?
      return false if user.user_activity_category.activity_category.blank?
      cat_ids = user.user_activity_category.activity_category.split(",")
      return true if cat_ids.include? self.id.to_s
      
      if self.subcategories.in(id:cat_ids).first.present?
        return true
      else
        return false
      end
    else
      return  false
    end
  end

  def selected_contact?(contact)
    if contact.category_ids.present?
      cat_ids = contact.category_ids.split(",")
      return true if cat_ids.include? self.id.to_s      
      if self.subcategories.in(id:cat_ids).first.present?
        return true
      else
        return false
      end
    else
      return  false
    end
  end

  def date_type_name    
    self.date_type.nil? ? "" : self.date_type.name
  end
  def timeframe_name
    self.timeframe.nil? ? "" : self.timeframe.name  
  end
  def parts_of_day_name
    self.parts_of_day.nil? ? "" : self.parts_of_day.name
  end

  
  def has_child?
    self.subcategories.present?
  end

  def self.find_or_create_by_display_name(name)
    Category.where(:display_name=>name).first || Category.create(:display_name=>name, :app_publish_name=>name.delete(" ").underscore, :yelp_category_id => name.delete(" ").underscore)
  end

  def create_child(name)
    child = self.subcategories.where(:display_name=>name).first || self.subcategories.build(:display_name=>name, :app_publish_name=>name.delete(" ").underscore, :yelp_category_id => name.delete(" ").underscore)
    child.save
  end

  def logo_img_url
    if image.url.nil?
      ""
    else
      if Rails.env.production?
        image.url
      else
        "http://localhost:3000" + image.url.gsub("#{Rails.root.to_s}/public/category/", "/category/")
      end
    end
  end
end
