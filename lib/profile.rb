class Profile
  
  attr_reader :error
  
  def initialize(db, options = {})
    @db = db
    unless options &&
      (@name = options[:username]) &&
      (@password = options[:password])
      @error = "Unable to authenticate" 
    end
  end
  
  def is_admin?
    if profile = @db.collection('profiles').find_one({:username => @name, :password => @password})
      return profile["admin"] == true
    else
      return false
    end
  end
  
  def authorized?(site_id)
    if profile = @db.collection('profiles').find_one({:username => @name, :password => @password})
      return profile["site_id"].to_i == site_id.to_i
    else
      return false
    end
  end
  
  def self.create(db, params)
    db.collection('profiles').insert(params)
  end
  
end
