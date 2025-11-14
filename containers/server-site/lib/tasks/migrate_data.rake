namespace :data do
  desc "Migrate old data format to new UUID-based folder structure"
  task migrate: :environment do
    require 'json'
    require 'fileutils'
    
    data_dir = '/data'
    online_dir = File.join(data_dir, 'online')
    playtime_dir = File.join(data_dir, 'player_playtime')
    old_playtime_file = File.join(data_dir, 'player_playtime.json')
    
    # Create new directories
    FileUtils.mkdir_p(online_dir) unless Dir.exist?(online_dir)
    FileUtils.mkdir_p(playtime_dir) unless Dir.exist?(playtime_dir)
    
    puts "Created directories: #{online_dir}, #{playtime_dir}"
    
    # Migrate old player_playtime.json to new format
    if File.exist?(old_playtime_file)
      puts "=========================================="
      puts "MIGRATING OLD DATA FORMAT TO NEW SCHEMA"
      puts "=========================================="
      puts "Found old player_playtime.json, migrating..."
      
      begin
        old_data = JSON.parse(File.read(old_playtime_file))
        
        migrated_count = 0
        old_data.each do |name, data|
          # Skip duplicate keys (handle malformed JSON)
          next if migrated_count > 0 && old_data.keys.count(name) > 1
          
          # Get UUID for this player name
          uuid = UuidResolver.get_uuid(name.to_s)
          
          # Create new format file
          new_file = File.join(playtime_dir, "#{uuid}.json")
          
          # Check if file already exists (merge data if it does)
          existing_data = {}
          if File.exist?(new_file)
            begin
              existing_data = JSON.parse(File.read(new_file), symbolize_names: true)
            rescue
              existing_data = {}
            end
          end
          
          # Merge playtime (take maximum to preserve highest value)
          total_playtime = [existing_data[:total_playtime] || 0, data['total_playtime'] || 0].max
          
          new_data = {
            uuid: uuid,
            name: data['name'] || name.to_s,
            total_playtime: total_playtime,
            session_count: (existing_data[:session_count] || 0) + (data['session_count'] || 0),
            first_seen: existing_data[:first_seen] || data['first_seen'],
            last_seen: existing_data[:last_seen] || data['last_seen'],
            last_session_duration: existing_data[:last_session_duration],
            last_session_end: existing_data[:last_session_end]
          }
          
          File.write(new_file, JSON.pretty_generate(new_data))
          migrated_count += 1
          puts "  ✓ Migrated #{name} -> #{uuid} (playtime: #{total_playtime.round(2)}s)"
        end
        
        # Delete old file (DEPRECATED - migration to new schema)
        # No backup - old schema is deprecated and should not be used
        File.delete(old_playtime_file)
        puts "✗ Deleted deprecated player_playtime.json (old schema)"
        puts "=========================================="
        puts "Migration complete: #{migrated_count} players migrated"
        puts "New structure: /data/player_playtime/{uuid}.json"
        puts "=========================================="
        
      rescue => e
        puts "ERROR migrating data: #{e.message}"
        puts e.backtrace.join("\n")
        raise
      end
    else
      puts "No old player_playtime.json found - using new schema"
    end
    
    # Ensure player_tracker_state.json exists (will be created on first run)
    state_file = File.join(data_dir, 'player_tracker_state.json')
    unless File.exist?(state_file)
      File.write(state_file, JSON.pretty_generate({}))
      puts "Created empty player_tracker_state.json"
    end
    
    # Verify new structure exists
    unless Dir.exist?(online_dir) && Dir.exist?(playtime_dir)
      raise "Failed to create required directories: #{online_dir}, #{playtime_dir}"
    end
    
    # Verify old files are gone (cleanup check)
    if File.exist?(old_playtime_file)
      puts "WARNING: Old player_playtime.json still exists after migration!"
      puts "This should not happen - the old schema is deprecated."
    end
    
    puts ""
    puts "Data structure verified:"
    puts "  ✓ #{online_dir}/ (online players - UUID files)"
    puts "  ✓ #{playtime_dir}/ (playtime data - UUID files)"
    puts "  ✓ #{File.join(data_dir, 'player_tracker_state.json')} (tracker state)"
    puts ""
    puts "Migration complete! Old schema files have been deleted."
    puts "Only the new UUID-based folder structure is used."
  end
end
