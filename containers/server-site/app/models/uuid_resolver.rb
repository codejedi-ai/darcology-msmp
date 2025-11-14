require 'json'

class UuidResolver
  USERCACHE_FILE = '/minecraft/usercache.json'
  USERCACHE_FILE_SHARED = '/data/usercache.json'  # Try shared data volume first
  
  # Cache of username -> UUID mappings
  @@cache = {}
  @@cache_loaded = false
  @@last_cache_load = nil
  CACHE_EXPIRATION = 5.minutes  # How often to reload usercache.json
  
  def self.get_uuid(username)
    load_cache unless @@cache_loaded
    @@cache[username.downcase] || generate_fallback_uuid(username)
  end
  
  def self.get_username(uuid)
    load_cache unless @@cache_loaded
    @@cache.key(uuid) || uuid # Return UUID if username not found
  end
  
  def self.load_cache
    # Try shared data volume first, then fallback to logs mount
    usercache_path = File.exist?(USERCACHE_FILE_SHARED) ? USERCACHE_FILE_SHARED : USERCACHE_FILE
    
    return unless File.exist?(usercache_path)
    
    begin
      data = JSON.parse(File.read(usercache_path))
      @@cache = {}
      
      data.each do |entry|
        name = entry['name']
        uuid = entry['uuid']
        @@cache[name.downcase] = uuid if name && uuid
      end
      
      @@cache_loaded = true
      @@last_cache_load = Time.now
      Rails.logger.info "Loaded UUID cache from #{usercache_path}. Entries: #{@@cache.size}"
    rescue => e
      Rails.logger.error "Failed to load usercache.json from #{usercache_path}: #{e.message}"
      @@cache_loaded = true # Mark as loaded to prevent repeated attempts
    end
  end
  
  def self.reload_cache
    @@cache_loaded = false
    @@cache = {}
    load_cache
  end
  
  def self.reload_cache_if_stale
    if @@last_cache_load.nil? || (Time.now - @@last_cache_load) > CACHE_EXPIRATION
      reload_cache
    end
  end
  
  # Generate a deterministic UUID v5 from username as fallback
  # This ensures same username always gets same UUID until usercache.json is available
  def self.generate_fallback_uuid(username)
    require 'digest'
    
    # Use UUID v5 namespace (DNS namespace: 6ba7b810-9dad-11d1-80b4-00c04fd430c8)
    namespace = "\x6b\xa7\xb8\x10\x9d\xad\x11\xd1\x80\xb4\x00\xc0\x4f\xd4\x30\xc8"
    name = "minecraft:#{username.downcase}"
    
    # Generate SHA-1 hash
    hash = Digest::SHA1.digest(namespace + name)
    
    # Convert to UUID format (version 5)
    bytes = hash.bytes
    bytes[6] = (bytes[6] & 0x0f) | 0x50  # Version 5
    bytes[8] = (bytes[8] & 0x3f) | 0x80  # Variant
    
    # Format as UUID string
    sprintf("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15])
  end
  
  def self.clear_cache
    @@cache = {}
    @@cache_loaded = false
  end
end

