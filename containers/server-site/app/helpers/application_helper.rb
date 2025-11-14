module ApplicationHelper
  def format_bytes(bytes)
    sizes = ['B', 'KB', 'MB', 'GB', 'TB']
    return '0 B' if bytes == 0
    i = (Math.log(bytes) / Math.log(1024)).floor
    "#{(bytes / (1024 ** i)).round(2)} #{sizes[i]}"
  end
  
  def format_duration(seconds)
    return '0s' if seconds.nil? || seconds < 0
    
    days = (seconds / 86400).floor
    hours = ((seconds % 86400) / 3600).floor
    minutes = ((seconds % 3600) / 60).floor
    secs = (seconds % 60).floor
    
    parts = []
    parts << "#{days}d" if days > 0
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{secs}s" if secs > 0 || parts.empty?
    
    parts.join(' ')
  end
end
