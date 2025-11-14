# Event System using Observer Pattern
# Provides event publishing and subscription mechanism

class EventSystem
  @@subscribers = {}
  
  # Subscribe to an event topic
  def self.subscribe(topic, subscriber)
    @@subscribers[topic] ||= []
    @@subscribers[topic] << subscriber
  end
  
  # Publish an event to all subscribers of a topic
  def self.publish(topic, event_data)
    return unless @@subscribers[topic]
    
    @@subscribers[topic].each do |subscriber|
      begin
        subscriber.handle_event(topic, event_data)
      rescue => e
        Rails.logger.error "Error in subscriber #{subscriber.class.name} for topic #{topic}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
  
  # Get all subscribers for a topic (for debugging)
  def self.subscribers_for(topic)
    @@subscribers[topic] || []
  end
  
  # Clear all subscribers (for testing)
  def self.clear_subscribers
    @@subscribers = {}
  end
end

# Base class for event subscribers
class EventSubscriber
  def handle_event(topic, event_data)
    raise NotImplementedError, "Subclasses must implement handle_event"
  end
end

