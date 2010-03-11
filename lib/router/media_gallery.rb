# -------------
# Media Gallery
# -------------

get '/:site_name/files/:filename' do
  fetch_media({:filename => params[:filename], "metadata" => {"site_name" => params[:site_name]}})
end

get '/:site_name/thumb/:filename' do
  if grid_file = Media.find(options.db, 
                            {"site_name" => params[:site_name]}, 
                            {:filename => params[:filename], :thumb => 300})
    grid_file = grid_file.first if grid_file.kind_of?(Array)
    content_type MIME::Types.type_for(grid_file[:filename]).to_s
    GridStore.read(options.db, grid_file[:filename])
  end
end

# Return list of portolios
get '/:site_name/portfolios' do
  content_type :json
  portfolios = {}
  portfolios_parameters = {"site_name" => params[:site_name]}
  
  if medias = Media.find(options.db, portfolios_parameters)
  
    # If Media class forced into json format
    unless medias.kind_of?(Array)
      medias = [medias]
    end
  
    # Filter medias to sort galleries
    medias.each do |media|
      portfolio_id = media[:metadata]["portfolio"]
      unless portfolios.has_key? portfolio_id
        portfolios[portfolio_id] = {:id => portfolio_id,
                                    :name => portfolio_id,
                                    :thumb => media[:filename],
                                    :url => media[:metadata]["portfolio_url"]}
      end
    end
    
  end
  
  # Send back json
  if callback = request.env["rack.request.query_hash"]["callback"]
    "#{callback}(#{portfolios.to_json})"
  else
    portfolios.to_json
  end
end

# Return param portolio details
get '/:site_name/portfolio/:portfolio' do
  content_type :json
  
  portfolio = {:id => params[:portfolio], :name => params[:portfolio], :galleries => []}
  portfolio_parameters = {"site_name" => params[:site_name], 
                          "portfolio_url" => params[:portfolio]}
  
  if medias = Media.find(options.db, portfolio_parameters)
    
    galleries = {}
    
    # If Media class forced into json format
    unless medias.kind_of?(Array)
      medias = [medias]
    end
    
    # Filter medias to sort galleries
    medias.each do |media|
      gallery_name = media[:metadata]["gallery_name"]
      unless galleries.has_key? gallery_name
        galleries[gallery_name] = true
        portfolio[:galleries] << {:name => gallery_name,
                                  :thumb => media[:filename],
                                  :url => media[:metadata]["gallery_url"]}
      end
    end
    
    # Send back json
    if callback = request.env["rack.request.query_hash"]["callback"]
      "#{callback}(#{portfolio.to_json})"
    else
      portfolio.to_json
    end
  else
    error 404
  end
  
end

# Return param gallery details
get '/:site_name/gallery/:gallery' do
  content_type :json
  
  gallery = {:id => params[:gallery], :medias  => []}
  gallery_parameters = {"site_name" => params[:site_name],
                        "gallery_url" => params[:gallery]}
  
  if medias = Media.find(options.db, gallery_parameters)
    
    # If Media class forced into json format
    unless medias.kind_of?(Array)
      medias = [medias]
    end
    
    medias.each do |media|
      gallery[:name] = media[:metadata]["gallery_name"]
      gallery[:portfolio] = media[:metadata]["portfolio"]
      gallery[:portfolio_url] = media[:metadata]["portfolio_url"]
      gallery[:gallery_url] = media[:metadata]["gallery_url"]
      gallery[:medias] << media
    end
    
    # Send back json
    if callback = request.env["rack.request.query_hash"]["callback"]
      "#{callback}(#{gallery.to_json})"
    else
      gallery.to_json
    end
    
  else
    error 404
  end
end

# Return param media details
get '/:site_name/media/:media' do
  content_type :json
  
  media_parameters = {"site_name" => params[:site_name]}
  
  if media = Media.find(options.db, media_parameters, :id => params[:media])
    # Send back json
    if callback = request.env["rack.request.query_hash"]["callback"]
      "#{callback}(#{media.to_json})"
    else
      media.to_json
    end
    
  else
    error 404
  end
end