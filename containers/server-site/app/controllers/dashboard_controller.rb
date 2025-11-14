class DashboardController < ApplicationController
  layout 'dashboard'
  @@prev_cpu_stats = {}
  @@last_cpu_update = Time.now

  def index
    @memory_stats = get_memory_stats
    @cpu_stats = get_cpu_stats
    @players = PlayerTracker.get_players
    @online_count = @players.count { |p| p[:is_online] }
    @server_status = ServerStatusChecker.get_status
  end

  def stats
    players = PlayerTracker.get_players
    memory_stats = get_memory_stats
    cpu_stats = get_cpu_stats
    
    # Log stats to data files
    DataLogger.log_memory_stats(memory_stats)
    DataLogger.log_cpu_stats(cpu_stats[:usage_percent], cpu_stats[:cores])
    
    render json: {
      memory: memory_stats,
      cpu: cpu_stats,
      players: {
        online_count: players.count { |p| p[:is_online] },
        total_count: players.count,
        list: players.map { |p| format_player(p) }
      },
      server_status: ServerStatusChecker.get_status
    }
  end
  
  def cpu
    @cpu_stats = get_cpu_stats
    @cpu_history = DataLogger.get_cpu_stats_history(100)
  end
  
  def memory
    @memory_stats = get_memory_stats
    @memory_history = DataLogger.get_memory_stats_history(100)
  end
  
  def player_sessions
    @players = PlayerTracker.get_players
    @online_count = @players.count { |p| p[:is_online] }
  end

  def download_mods
    # Check if pre-zipped mods.zip exists in shared data directory
    mods_zip_path = '/data/mods.zip'
    
    if File.exist?(mods_zip_path)
      send_file mods_zip_path,
                type: 'application/zip',
                disposition: 'attachment',
                filename: 'mods.zip'
    else
      render plain: "Sorry, mods.zip is not available", status: :not_found
    end
  end

  private

  def get_memory_stats
    meminfo = File.read('/proc/meminfo')
    
    total = meminfo.match(/MemTotal:\s+(\d+)\s+kB/)[1].to_i
    available = meminfo.match(/MemAvailable:\s+(\d+)\s+kB/)[1].to_i rescue nil
    free = meminfo.match(/MemFree:\s+(\d+)\s+kB/)[1].to_i
    buffers = meminfo.match(/Buffers:\s+(\d+)\s+kB/)[1].to_i rescue 0
    cached = meminfo.match(/Cached:\s+(\d+)\s+kB/)[1].to_i rescue 0
    
    # If MemAvailable is not available, calculate it
    available ||= free + buffers + cached
    
    used = total - available
    
    {
      total: total * 1024, # Convert to bytes
      used: used * 1024,
      free: free * 1024,
      available: available * 1024,
      usage_percent: ((used.to_f / total) * 100).round(2)
    }
  end

  def get_cpu_stats
    # Read CPU stats from /proc/stat
    stat_line = File.readlines('/proc/stat').first
    cpu_data = stat_line.split
    
    # CPU time values: user, nice, system, idle, iowait, irq, softirq, steal
    user = cpu_data[1].to_i
    nice = cpu_data[2].to_i
    system = cpu_data[3].to_i
    idle = cpu_data[4].to_i
    iowait = cpu_data[5].to_i rescue 0
    irq = cpu_data[6].to_i rescue 0
    softirq = cpu_data[7].to_i rescue 0
    steal = cpu_data[8].to_i rescue 0
    
    # Calculate usage percentage based on difference from previous reading
    prev_stats = @@prev_cpu_stats
    time_since_update = Time.now - @@last_cpu_update
    
    if prev_stats.any? && time_since_update < 5.0 && time_since_update > 0.1 # Only use previous stats if between 0.1s and 5s old
      prev_idle = (prev_stats[:idle] || 0) + (prev_stats[:iowait] || 0)
      prev_non_idle = (prev_stats[:user] || 0) + (prev_stats[:nice] || 0) + 
                      (prev_stats[:system] || 0) + (prev_stats[:irq] || 0) + 
                      (prev_stats[:softirq] || 0) + (prev_stats[:steal] || 0)
      prev_total = prev_idle + prev_non_idle
      
      curr_idle = idle + iowait
      curr_non_idle = user + nice + system + irq + softirq + steal
      curr_total = curr_idle + curr_non_idle
      
      total_diff = curr_total - prev_total
      idle_diff = curr_idle - prev_idle
      
      usage_percent = total_diff > 0 ? (100.0 * (total_diff - idle_diff) / total_diff).round(2) : 0
      usage_percent = [usage_percent, 100].min # Cap at 100%
    else
      # First reading or stale data - use load average as approximation
      load_avg = File.read('/proc/loadavg').split[0].to_f
      cores = get_cpu_cores
      usage_percent = [(load_avg / cores * 100), 100].min.round(2)
    end
    
    # Store current stats for next calculation
    @@prev_cpu_stats = {
      user: user,
      nice: nice,
      system: system,
      idle: idle,
      iowait: iowait,
      irq: irq,
      softirq: softirq,
      steal: steal
    }
    @@last_cpu_update = Time.now
    
    {
      usage_percent: usage_percent,
      cores: get_cpu_cores
    }
  end

  def get_cpu_cores
    # Count CPU cores
    File.readlines('/proc/cpuinfo').grep(/^processor/).count
  end
  
  def format_player(player)
    {
      name: player[:name],
      uuid: player[:uuid],
      is_online: player[:is_online] || false,
      last_activity_time: player[:last_activity]
    }
  end
end

