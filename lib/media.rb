class Media
  
  attr_reader :error
  
  def initialize(db, options = {})
    @db = db
    @files = @db.collection('fs.files')
    @options = options
    
    # Set common filename if using upload
    if @options[:file] && @options[:file][:filename]
      @options[:filename] = @options[:file][:filename]
    end
  end
  
  def store
    
    if @options[:file] && @options[:file][:tempfile] && 
        @options[:file][:filename]
      
      # Write file in DB
      write_file
      
      # Test if thumbnail generation needs to be done
      thumb_gen = true
      if (@options["metadata"] &&
        @options["metadata"]["no_thumb"] &&
        @options["metadata"]["no_thumb"] == "true") ||
        (@options[:metadata] && 
        @options[:metadata][:parent_id])
        thumb_gen = false
      end
      
      # Generate related file if there isn't already a parent_id
      if thumb_gen
        case MIME::Types.type_for(@options[:file][:filename]).to_s
        when /^image/
          # Generate thumbnails
          generate_thumbnails
        end
      end
      
    else
      @error = "missing file parameters"
    end
  end
  
  def self.remove(db, _id)
    object_id = Mongo::ObjectID.from_string(_id)
    if db.collection('fs.files').find_one(object_id)
      
      # Remove associated files
      db.collection('fs.files').find({"metadata.parent_id" => object_id}).each do |child|
        Media.remove(db, child["_id"].to_s)
      end
      
      db.collection('fs.chunks').remove({:files_id => object_id})
      db.collection('fs.files').remove({:_id => object_id})
    end
  end
  
  def self.update(db, _id, metadata)
    object_id = Mongo::ObjectID.from_string(_id)
    coder = HTMLEntities.new
    if db.collection('fs.files').find_one(object_id)
      metadata.each do |k, v|
        case k
        when "gallery_name"
          db.collection('fs.files').update({:_id => object_id},
                                           {"$set" => {"metadata.gallery_url" => Media.to_permalink(v)}})
        when "portfolio"
          db.collection('fs.files').update({:_id => object_id},
                                           {"$set" => {"metadata.portfolio_url" => Media.to_permalink(v)}})
        end
        db.collection('fs.files').update({:_id => object_id},
                                         {"$set" => {"metadata.#{k}" => coder.encode(v, :named)}})
          
      end
    end
  end
  
  def self.find(db, metadata, options = {})
    
    db_files = db.collection('fs.files')
    
    if options[:id]
      if doc = db_files.find_one(Mongo::ObjectID.from_string(options[:id]))
        return Media.jsonify(doc)
      else 
        return nil
      end
    else
    
      # Build dot_notation query: http://www.mongodb.org/display/DOCS/Dot+Notation
      dot_notation = {}
      metadata.each{|key, value| dot_notation["metadata.#{key}"] = value}
    
      dot_notation["filename"] = options[:filename] if options[:filename]
      dot_notation["_id"] = Mongo::ObjectID.from_string(options[:id]) if options[:id]
    
      # # DEBUG
      # GridStore.list(db).each do |media|
      #   p media.inspect
      #   GridStore.open(db, media, 'r') { |f| p f.inspect }
      # end
      # p "dot_notation: #{dot_notation.inspect}"
      # # DEBUG
    
      # Use query on fs.files to fetch files in DB
      grid = db_files.find(dot_notation)
    
      if options[:thumb] && doc = grid.next_document
        thumb_filename = "thumb_#{options[:thumb]}*"
        grid = db_files.find({"filename" => /#{thumb_filename}/, "metadata.parent_id" => doc["_id"]})
      end
    
      # Different returns depending on number of files returned
      if grid.count == 1
        return Media.jsonify(grid.next_document)
      elsif grid.count > 1
        files = []
        grid.each do |doc|
          files << Media.jsonify(doc)
        end
        return files
      else
        return nil
      end
    end
  end
  
  def to_json
    Media.jsonify @files.find_one(:filename => @options[:filename])
  end
  
  def self.jsonify(doc)
    data = {:id => doc["_id"].to_s, 
            :filename => doc["filename"], 
            :length => doc["length"], 
            :metadata => doc["metadata"]}
    data[:url] = "/"
    if doc["metadata"]
      data[:url] += "site/#{doc["metadata"]["site_id"]}/" if doc["metadata"]["site_id"]
      data[:url] += (doc["metadata"]["app_name"] + "/") if doc["metadata"]["app_name"]
      data[:url] += (doc["metadata"]["product_id"] + "/") if doc["metadata"]["product_id"]
    end
    data[:url] += doc["filename"]
    data
  end
  
  def saved?
    GridStore.exist? @db, @options[:file][:filename]
  end
  
  def grid_file
    
    ## Inspect database
    # GridStore.list(@db).each do |media|
    #   p media.inspect
    #   GridStore.open(@db, media, 'r') { |f| p f.metadata.inspect }
    # end
    
    # GridStore needs to be search by metadata
    if @options["metadata"]
      
      # Build dot_notation query: http://www.mongodb.org/display/DOCS/Dot+Notation
      dot_notation = {}
      @options["metadata"].each{|key, value| dot_notation["metadata.#{key}"] = value}
      
      if @options[:filename]
        dot_notation["filename"] = @options[:filename]
      end
      # p "dot_notation: #{dot_notation.inspect}"
      
      # Use query on fs.files to fetch files in DB
      grid = @files.find(dot_notation)
      
      if @options["thumb"] && grid.count > 0
        thumb_filename = "thumb_#{@options["thumb"]["size"]}x#{@options["thumb"]["size"]}_#{@options[:filename]}"
        grid = @files.find({"filename" => thumb_filename, "metadata.parent_id" => grid.next_document["_id"]})
      end
      
      # Different returns depending on number of files returned
      if grid.count == 1
        return Media.jsonify(grid.next_document)
      elsif grid.count > 1
        files = []
        grid.each do |doc|
          files << Media.jsonify(doc)
        end
        return files
      else
        return nil
      end
    end
    
    # GridStore needs to be search by filename
    if @options[:filename] || GridStore.exist?(@db, @options[:filename])
      return @files.find_one(:filename => @options[:filename])
    end
  end
  
  def id
    if @options && GridStore.exist?(@db, @options[:filename])
      GridStore.open(@db, @options[:filename], 'r') { |f|
        f.files_id
      }
    end
  end
  
  def url
    url = "/"
    if @options && GridStore.exist?(@db, @options[:filename])
      GridStore.open(@db, @options[:filename], 'r') { |f|
        if f.metadata
          url += "site/#{f.metadata["site_id"]}/" if f.metadata["site_id"]
          url += (f.metadata["app_name"] + "/") if f.metadata["app_name"]
          url += (f.metadata["product_id"] + "/") if f.metadata["product_id"]
        end
      }
    end
    url << @options[:filename]
  end
  
  protected
  
  def self.to_permalink(str)
    str = Unicode.normalize_KD(str).gsub(/[^\x00-\x7F]/n,'')
    str = str.gsub(/[^-_\s\w]/, ' ').downcase.squeeze(' ').tr(' ','-').gsub(/-+$/,'')
  end
  
  def generate_thumbnails
    [{:height => 100, :width => 100},
      {:height => 300, :width => 300},
      {:height => 1000, :width => 1000},].each do |thumb|
      
      # Create new thumbnail file  
      filename = "thumb_#{thumb[:width]}x#{thumb[:height]}_#{@options[:filename]}"
      tmp = Tempfile.new(filename)
      
      MojoMagick::resize(@options[:file][:tempfile].path, tmp.path, 
                        { :width => thumb[:width],
                          :height => thumb[:height], 
                          :scale => '>'})
      
      # Change options for new file
      options = {:file => {:filename => filename, :tempfile => tmp}}
      options[:metadata] = {:parent_id => @options["_id"]}
      options[:metadata].merge(@options[:metadata]) if @options[:metadata]
      options["overwrite"] = @options["overwrite"] if @options["overwrite"]
      
      # Store new file
      Media.new(@db, options).store
    end
  end
  
  def write_file
    
    # Set the writing mode so file can be store in multiple GridStore chunks
    writing_mode = 'w'
    
    if @options["overwrite"] && GridStore.exist?(@db, @options[:filename])
      GridStore.open(@db, @options[:filename], 'w') {}
    else
      # Verify metadata are the same before to overwrite
      while GridStore.exist?(@db, @options[:filename]) &&
          GridStore.open(@db, @options[:filename], 'r') { |f| (@options["metadata"] != f.metadata) }
        # if file exists, but not the same metadata
        # change filename to avoid overwriting
        filemane, extension = @options[:filename].split "."
        if filemane[/_(\d+)$/]
          @options[:filename] = filemane.gsub(/_(\d+)$/){|s| "_#{s.to_i + 1}"} + '.' + extension
        else
          @options[:filename] = filemane + '_0.' + extension
        end
      end
    end
    
    content_type = MIME::Types.type_for(@options[:filename]).to_s
    GridStore.open(@db, @options[:filename], 'w',
                  :content_type => content_type,
                  :metadata => @options[:metadata]) { |f|
      f.write @options[:file][:tempfile].read
    }
    
    # Store _id to retrieve it later, for parent relation for example
    file = @files.find({'filename' => @options[:filename]}).sort(:updated_at, :desc).first
    @options["_id"] = file["_id"]
  end
  
end