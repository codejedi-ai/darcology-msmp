require 'json'
require 'csv'

class DataLogger
  DATA_DIR = '/data'
  ONLINE_DIR = File.join(DATA_DIR, 'online')
  PLAYTIME_DIR = File.join(DATA_DIR, 'player_playtime')
  
  # Ensure data directories exist
  def self.ensure_data_dir
    Dir.mkdir(DATA_DIR) unless Dir.exist?(DATA_DIR)
    Dir.mkdir(ONLINE_DIR) unless Dir.exist?(ONLINE_DIR)
    Dir.mkdir(PLAYTIME_DIR) unless Dir.exist?(PLAYTIME_DIR)
  end
  
  # Create online player file when player joins
  # File: /data/online/{uuid}.json
  # NOTE: This is called by OnlineFileService via Observer pattern
  def self.create_online_player(uuid, player_name, timestamp)
    ensure_data_dir
    
    online_file = File.join(ONLINE_DIR, "#{uuid}.json")
    
    data = {
      uuid: uuid,
      name: player_name,
      joined_at: timestamp.iso8601,
      session_start: timestamp.iso8601
    }
    
    File.write(online_file, JSON.pretty_generate(data))
  end
  
  # Remove online player file when player leaves
  # NOTE: This is called by OnlineFileService via Observer pattern
  def self.remove_online_player(uuid)
    ensure_data_dir
    
    online_file = File.join(ONLINE_DIR, "#{uuid}.json")
    File.delete(online_file) if File.exist?(online_file)
  end
  
  # Get a single online player by UUID
  def self.get_online_player(uuid)
    ensure_data_dir
    return nil unless Dir.exist?(ONLINE_DIR)
    
    online_file = File.join(ONLINE_DIR, "#{uuid}.json")
    return nil unless File.exist?(online_file)
    
    begin
      JSON.parse(File.read(online_file), symbolize_names: true)
    rescue => e
      Rails.logger.error "Failed to read online player file #{online_file}: #{e.message}"
      nil
    end
  end
  
  # Get all online players
  def self.get_online_players
    ensure_data_dir
    return [] unless Dir.exist?(ONLINE_DIR)
    
    players = []
    Dir.glob(File.join(ONLINE_DIR, '*.json')).each do |file|
      begin
        data = JSON.parse(File.read(file), symbolize_names: true)
        players << data
      rescue => e
        Rails.logger.error "Failed to read online player file #{file}: #{e.message}"
      end
    end
    
    players
  end
  
  # Update player playtime when player leaves
  # File: /data/player_playtime/{uuid}.json
  # NOTE: This is called by PlaytimeService via Observer pattern
  def self.update_player_playtime(uuid, player_name, session_duration, total_playtime, timestamp)
    ensure_data_dir
    
    playtime_file = File.join(PLAYTIME_DIR, "#{uuid}.json")
    
    # Read existing data or create new
    existing_data = {}
    if File.exist?(playtime_file)
      begin
        existing_data = JSON.parse(File.read(playtime_file), symbolize_names: true)
      rescue
        existing_data = {}
      end
    end
    
    # Update or create player data
    existing_data[:uuid] = uuid
    existing_data[:name] = player_name
    existing_data[:total_playtime] = total_playtime
    existing_data[:session_count] = (existing_data[:session_count] || 0) + 1
    existing_data[:last_seen] = timestamp.iso8601
    existing_data[:first_seen] ||= timestamp.iso8601
    existing_data[:last_session_duration] = session_duration
    existing_data[:last_session_end] = timestamp.iso8601
    
    # Write updated data
    File.write(playtime_file, JSON.pretty_generate(existing_data))
  end
  
  # Get player playtime data by UUID
  def self.get_player_playtime(uuid)
    ensure_data_dir
    playtime_file = File.join(PLAYTIME_DIR, "#{uuid}.json")
    return nil unless File.exist?(playtime_file)
    
    begin
      JSON.parse(File.read(playtime_file), symbolize_names: true)
    rescue
      nil
    end
  end
  
  # Get all player playtime data
  def self.get_all_playtime_data
    ensure_data_dir
    return {} unless Dir.exist?(PLAYTIME_DIR)
    
    playtime_data = {}
    Dir.glob(File.join(PLAYTIME_DIR, '*.json')).each do |file|
      begin
        data = JSON.parse(File.read(file), symbolize_names: true)
        uuid = data[:uuid] || File.basename(file, '.json')
        playtime_data[uuid] = data
      rescue => e
        Rails.logger.error "Failed to read playtime file #{file}: #{e.message}"
      end
    end
    
    playtime_data
  end
  
  # Log player join/leave events to CSV with UUID
  def self.log_player_event(event_type, player_uuid, player_name, timestamp)
    ensure_data_dir
    
    csv_file = File.join(DATA_DIR, 'player_sessions.csv')
    file_exists = File.exist?(csv_file)
    
    CSV.open(csv_file, 'a') do |csv|
      # Write header if file is new (includes UUID as primary key)
      csv << ['timestamp', 'event_type', 'player_uuid', 'player_name'] unless file_exists
      csv << [timestamp.iso8601, event_type, player_uuid, player_name]
    end
  end
  
  # Get all player session logs
  def self.get_player_sessions(limit = nil)
    ensure_data_dir
    csv_file = File.join(DATA_DIR, 'player_sessions.csv')
    return [] unless File.exist?(csv_file)
    
    sessions = []
    CSV.foreach(csv_file, headers: true) do |row|
      sessions << {
        timestamp: Time.parse(row['timestamp']),
        event_type: row['event_type'],
        player_uuid: row['player_uuid'] || row['player_name'], # Backward compatibility
        player_name: row['player_name']
      }
    end
    
    sessions = sessions.sort_by { |s| s[:timestamp] }.reverse
    limit ? sessions.first(limit) : sessions
  end
  
  # Log CPU stats to CSV
  def self.log_cpu_stats(usage_percent, cores, timestamp = Time.now)
    ensure_data_dir
    
    csv_file = File.join(DATA_DIR, 'cpu_stats.csv')
    file_exists = File.exist?(csv_file)
    
    CSV.open(csv_file, 'a') do |csv|
      csv << ['timestamp', 'usage_percent', 'cores'] unless file_exists
      csv << [timestamp.iso8601, usage_percent, cores]
    end
    
    # Keep only last 10000 entries to prevent file from growing too large
    trim_csv_file(csv_file, 10000)
  end
  
  # Log memory stats to CSV
  def self.log_memory_stats(stats, timestamp = Time.now)
    ensure_data_dir
    
    csv_file = File.join(DATA_DIR, 'memory_stats.csv')
    file_exists = File.exist?(csv_file)
    
    CSV.open(csv_file, 'a') do |csv|
      csv << ['timestamp', 'total', 'used', 'free', 'available', 'usage_percent'] unless file_exists
      csv << [
        timestamp.iso8601,
        stats[:total],
        stats[:used],
        stats[:free],
        stats[:available],
        stats[:usage_percent]
      ]
    end
    
    # Keep only last 10000 entries
    trim_csv_file(csv_file, 10000)
  end
  
  # Get CPU stats history
  def self.get_cpu_stats_history(limit = 1000)
    ensure_data_dir
    csv_file = File.join(DATA_DIR, 'cpu_stats.csv')
    return [] unless File.exist?(csv_file)
    
    stats = []
    CSV.foreach(csv_file, headers: true) do |row|
      stats << {
        timestamp: Time.parse(row['timestamp']),
        usage_percent: row['usage_percent'].to_f,
        cores: row['cores'].to_i
      }
    end
    
    stats.sort_by { |s| s[:timestamp] }.reverse.first(limit)
  end
  
  # Get memory stats history
  def self.get_memory_stats_history(limit = 1000)
    ensure_data_dir
    csv_file = File.join(DATA_DIR, 'memory_stats.csv')
    return [] unless File.exist?(csv_file)
    
    stats = []
    CSV.foreach(csv_file, headers: true) do |row|
      stats << {
        timestamp: Time.parse(row['timestamp']),
        total: row['total'].to_i,
        used: row['used'].to_i,
        free: row['free'].to_i,
        available: row['available'].to_i,
        usage_percent: row['usage_percent'].to_f
      }
    end
    
    stats.sort_by { |s| s[:timestamp] }.reverse.first(limit)
  end
  
  private
  
  def self.trim_csv_file(file_path, max_lines)
    return unless File.exist?(file_path)
    
    lines = File.readlines(file_path)
    return if lines.length <= max_lines
    
    # Keep header + last max_lines entries
    header = lines.first
    data_lines = lines[1..-1].last(max_lines)
    
    File.write(file_path, (header + data_lines).join)
  end
end
