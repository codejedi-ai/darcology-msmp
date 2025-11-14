class ServerStatusChecker
  LOG_FILE = '/minecraft/logs/latest.log'
  MAX_LOG_SIZE = 10_000_000 # 10MB - don't read entire log if it's huge
  
  # Status constants
  STATUS_READY = 'ready'
  STATUS_INITIALIZING = 'initializing'
  STATUS_UNKNOWN = 'unknown'
  
  def self.get_status
    checker = new
    checker.check_status
  end
  
  def initialize
    @status = STATUS_UNKNOWN
    @last_ready_time = nil
  end
  
  def check_status
    return { status: STATUS_UNKNOWN, message: 'Log file not found' } unless File.exist?(LOG_FILE)
    
    # Check if Java process is running (server process)
    # Use `pgrep` to check for running processes
    java_running = false
    begin
      java_running = system('pgrep -f "forge.*server.jar" > /dev/null 2>&1') || 
                     system('pgrep -f "run.sh" > /dev/null 2>&1') ||
                     system('pgrep -f "java.*forge" > /dev/null 2>&1')
    rescue
      # If pgrep fails, assume process is running if log file exists and has recent activity
      java_running = File.exist?(LOG_FILE) && (Time.now - File.mtime(LOG_FILE)) < 60
    end
    
    unless java_running
      return { status: STATUS_UNKNOWN, message: 'Server process not running' }
    end
    
    # Read recent log entries to determine status
    file_size = File.size(LOG_FILE)
    start_pos = file_size > MAX_LOG_SIZE ? file_size - MAX_LOG_SIZE : 0
    
    ready_indicators = []
    initializing_indicators = []
    
    File.open(LOG_FILE, 'r') do |file|
      file.seek(start_pos) if start_pos > 0
      
      file.each_line do |line|
        # Check for "Done" message - server is ready
        if line.match(/\[.*?\] \[.*?\] \[.*?\]: Done \(.*?\)! For help, type "help"/) ||
           line.match(/\[.*?\] \[.*?\] \[.*?\]: Done \(.*?\)! For help, type 'help'/) ||
           line.match(/\[.*?\] \[.*?\] \[.*?\]: Done \(.*?\)!/)
          ready_indicators << extract_timestamp(line)
        end
        
        # Check for initialization messages
        if line.match(/\[.*?\] \[.*?\] \[.*?\]: Preparing start region/) ||
           line.match(/\[.*?\] \[.*?\] \[.*?\]: Preparing spawn area/) ||
           line.match(/\[.*?\] \[.*?\] \[.*?\]: Loading spawn chunks/) ||
           line.match(/\[.*?\] \[.*?\] \[.*?\]: Preparing level/) ||
           line.match(/\[.*?\] \[.*?\] \[.*?\]: Starting minecraft server version/) ||
           line.match(/\[.*?\] \[.*?\] \[.*?\]: Time elapsed/)
          initializing_indicators << extract_timestamp(line)
        end
      end
    end
    
    # Determine status based on most recent indicators
    latest_ready = ready_indicators.max
    latest_initializing = initializing_indicators.max
    
    if latest_ready && (!latest_initializing || latest_ready > latest_initializing)
      @status = STATUS_READY
      @last_ready_time = latest_ready
      { status: STATUS_READY, message: 'Server is ready - players can join!' }
    elsif latest_initializing
      @status = STATUS_INITIALIZING
      { status: STATUS_INITIALIZING, message: 'Server is initializing...' }
    else
      # If we can't determine from logs but process is running, assume initializing
      @status = STATUS_INITIALIZING
      { status: STATUS_INITIALIZING, message: 'Server is starting up...' }
    end
  end
  
  private
  
  def extract_timestamp(line)
    # Try to extract timestamp from log line
    # Format: [01Jan2024 12:34:56.789]
    timestamp_match = line.match(/^\[(\d{2}\w{3}\d{4} \d{2}:\d{2}:\d{2}\.\d{3})\]/)
    if timestamp_match
      begin
        Time.strptime(timestamp_match[1], '%d%b%Y %H:%M:%S.%L')
      rescue
        Time.now
      end
    else
      # Fallback to current time if we can't parse
      Time.now
    end
  end
end

