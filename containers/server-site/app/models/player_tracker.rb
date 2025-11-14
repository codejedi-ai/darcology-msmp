require 'json'

class PlayerTracker
  LOG_FILE = '/minecraft/logs/latest.log'
  MAX_LOG_SIZE = 10_000_000 # 10MB - don't read entire log if it's huge
  STATE_FILE = '/data/player_tracker_state.json'
  DATA_DIR = '/data'
  
  # Ensure data directory structure exists
  def self.ensure_data_structure
    Dir.mkdir(DATA_DIR) unless Dir.exist?(DATA_DIR)
  end
  
  def self.get_players
    tracker = new
    tracker.parse_logs
    tracker.get_active_players
  end
  
  def initialize
    @players = {} # Keyed by UUID
    @last_parse_position = 0
    self.class.ensure_data_structure
    load_state
  end
  
  def parse_logs
    return unless File.exist?(LOG_FILE)
    
    # Reload UUID cache periodically to catch new players
    UuidResolver.reload_cache
    
    # Only read recent portion of log if it's very large
    file_size = File.size(LOG_FILE)
    start_pos = file_size > @last_parse_position ? @last_parse_position : 0
    
    File.open(LOG_FILE, 'r') do |file|
      file.seek(start_pos)
      
      file.each_line do |line|
        parse_line(line)
      end
      @last_parse_position = file.pos
    end
    
    save_state
  end
  
  def parse_line(line)
    player_name = nil
    
    # Parse player join: [timestamp] [Server thread/INFO] [net.minecraft.server.dedicated.DedicatedServer/]: PlayerName[/<UUID>] joined the game
    if line =~ /\[.*?\] \[.*?\] \[.*?\]: (.+?)\[\/(.+?)\] joined the game/
      player_name = $1.strip
      player_uuid = $2.strip
      handle_player_join(player_uuid, player_name, extract_timestamp(line))
      return
    elsif line =~ /\[.*?\] \[.*?\] \[.*?\]: (.+?) joined the game/
      player_name = $1.strip
      # Fallback to UUID resolver if UUID not in log line
      player_uuid = UuidResolver.get_uuid(player_name)
      handle_player_join(player_uuid, player_name, extract_timestamp(line))
      return
    end
    
    # Parse player leave: [timestamp] [Server thread/INFO] [net.minecraft.server.dedicated.DedicatedServer/]: PlayerName left the game
    if line =~ /\[.*?\] \[.*?\] \[.*?\]: (.+?) left the game/
      player_name = $1.strip
      player_uuid = UuidResolver.get_uuid(player_name)
      handle_player_leave(player_uuid, player_name, extract_timestamp(line))
      return
    end
    
    # Parse chat message: [timestamp] [Server thread/INFO] [net.minecraft.server.network.ServerGamePacketListenerImpl/]: <PlayerName> message
    if line =~ /\[.*?\] \[.*?\] \[.*?\]: <(.+?)>/
      player_name = $1.strip
      player_uuid = UuidResolver.get_uuid(player_name)
      handle_player_activity(player_uuid, player_name, extract_timestamp(line))
      return
    end
    
    # Parse command execution (player commands)
    if line =~ /\[.*?\] \[.*?\] \[.*?\]: (.+?) issued server command:/
      player_name = $1.strip
      player_uuid = UuidResolver.get_uuid(player_name)
      handle_player_activity(player_uuid, player_name, extract_timestamp(line))
      return
    end
  end
  
  def extract_timestamp(line)
    # Try to extract timestamp from log line
    # Format: [2025-11-13 23:49:50.897] or [13Nov2025 22:32:28.180]
    if line =~ /\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/ || line =~ /\[(\d{2}\w{3}\d{4} \d{2}:\d{2}:\d{2})/
      begin
        time_str = $1
        # Try ISO format first
        Time.parse(time_str) rescue Time.now
      rescue
        Time.now
      end
    else
      Time.now
    end
  end
  
  def handle_player_join(uuid, player_name, timestamp)
    # Initialize player if new
    @players[uuid] ||= {
      uuid: uuid,
      name: player_name,
      joined_at: timestamp,
      last_activity: timestamp,
      is_online: true
    }
    
    # Update name in case it changed
    @players[uuid][:name] = player_name
    
    # Mark as online
    @players[uuid][:is_online] = true
    @players[uuid][:joined_at] = timestamp
    @players[uuid][:last_activity] = timestamp
  end
  
  def handle_player_leave(uuid, player_name, timestamp)
    return unless @players[uuid]
    
    # Mark as offline
    @players[uuid][:is_online] = false
    @players[uuid][:left_at] = timestamp
    @players[uuid][:last_activity] = timestamp
  end
  
  def handle_player_activity(uuid, player_name, timestamp)
    return unless @players[uuid]
    
    # Update name in case it changed
    @players[uuid][:name] = player_name
    @players[uuid][:last_activity] = timestamp
  end
  
  def get_active_players
    # Return players sorted by last activity (most recent first)
    @players.values.sort_by { |p| p[:last_activity] || Time.at(0) }.reverse
  end
  
  def get_online_count
    @players.values.count { |p| p[:is_online] }
  end
  
  private
  
  def load_state
    return unless File.exist?(STATE_FILE)
    
    begin
      state = JSON.parse(File.read(STATE_FILE))
      @players = {}
      
      state.each do |key, v|
        # Support both UUID keys and legacy username keys
        uuid = key.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i) ? key : UuidResolver.get_uuid(key)
        
        @players[uuid] = v.transform_keys(&:to_sym).tap do |player|
          # Ensure UUID is set
          player[:uuid] = uuid
          
          # Convert time strings back to Time objects
          [:joined_at, :last_activity, :left_at].each do |time_key|
            if player[time_key] && player[time_key].is_a?(String)
              player[time_key] = Time.parse(player[time_key]) rescue nil
            end
          end
        end
      end
    rescue => e
      Rails.logger.error "Failed to load player tracker state: #{e.message}"
      @players = {}
    end
  end
  
  def save_state
    return if @players.empty?
    
    begin
      state = {}
      @players.each do |uuid, player|
        state[uuid] = player.dup.tap do |p|
          # Convert Time objects to strings for JSON
          [:joined_at, :last_activity, :left_at].each do |key|
            p[key] = p[key].iso8601 if p[key].is_a?(Time)
          end
        end
      end
      
      File.write(STATE_FILE, JSON.pretty_generate(state))
    rescue => e
      Rails.logger.error "Failed to save player tracker state: #{e.message}"
    end
  end
end
