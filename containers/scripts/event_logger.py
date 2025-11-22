#!/usr/bin/env python3
"""
Event Logger Script
Polls Minecraft server logs every second and writes events to CSV files.
Uses OOP design for easy extension with new event types.
"""

import re
import time
import csv
import os
import hashlib
import json
from datetime import datetime
from abc import ABC, abstractmethod
from typing import Optional, Dict, Any


class UuidResolver:
    """Handles UUID resolution and caching for players"""
    
    def __init__(self, usercache_file: str, usercache_file_fallback: str):
        self.usercache_file = usercache_file
        self.usercache_file_fallback = usercache_file_fallback
        self.uuid_cache: Dict[str, str] = {}
        self.cache_loaded = False
        self.namespace = b'\x6b\xa7\xb8\x10\x9d\xad\x11\xd1\x80\xb4\x00\xc0\x4f\xd4\x30\xc8'
    
    def load_cache(self):
        """Load UUID mappings from usercache.json"""
        usercache_path = self.usercache_file if os.path.exists(self.usercache_file) else self.usercache_file_fallback
        
        if not os.path.exists(usercache_path):
            return
        
        try:
            with open(usercache_path, 'r') as f:
                usercache = json.load(f)
                for entry in usercache:
                    self.uuid_cache[entry['name'].lower()] = entry['uuid']
            self.cache_loaded = True
            print(f"Loaded {len(self.uuid_cache)} UUID mappings from {usercache_path}")
        except Exception as e:
            print(f"Error loading UUID cache from {usercache_path}: {e}")
    
    def get_uuid(self, username: str) -> Optional[str]:
        """Get UUID for a username from cache"""
        if not self.cache_loaded:
            self.load_cache()
        return self.uuid_cache.get(username.lower())
    
    def set_uuid(self, username: str, uuid: str):
        """Store UUID in cache"""
        self.uuid_cache[username.lower()] = uuid
    
    def generate_fallback_uuid(self, username: str) -> str:
        """Generate a deterministic UUID v5 as fallback"""
        name_bytes = f"minecraft:{username.lower()}".encode()
        hash_bytes = hashlib.sha1(self.namespace + name_bytes).digest()
        return f"{hash_bytes[0:4].hex()}-{hash_bytes[4:6].hex()}-{hash_bytes[6:8].hex()}-{hash_bytes[8:10].hex()}-{hash_bytes[10:16].hex()}"
    
    def resolve_uuid(self, username: str, use_fallback: bool = True) -> str:
        """Resolve UUID for a username, with optional fallback generation"""
        uuid = self.get_uuid(username)
        if not uuid and use_fallback:
            uuid = self.generate_fallback_uuid(username)
            print(f"Warning: UUID not found for '{username}', using fallback UUID: {uuid}")
            self.set_uuid(username, uuid)
        return uuid or ''


class LogTimestampExtractor:
    """Extracts timestamps from log lines"""
    
    @staticmethod
    def extract(line: str) -> datetime:
        """Extract timestamp from log line"""
        timestamp_match = re.search(r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})', line)
        if timestamp_match:
            try:
                return datetime.strptime(timestamp_match.group(1), '%Y-%m-%d %H:%M:%S')
            except:
                pass
        return datetime.now()


class EventParser(ABC):
    """Base class for event parsers"""
    
    def __init__(self, uuid_resolver: UuidResolver, timestamp_extractor: LogTimestampExtractor):
        self.uuid_resolver = uuid_resolver
        self.timestamp_extractor = timestamp_extractor
    
    @abstractmethod
    def parse(self, line: str) -> Optional[Dict[str, Any]]:
        """Parse a log line and return event dict if found, None otherwise"""
        pass


class PlayerEventParser(EventParser):
    """Parses player join/leave events"""
    
    def parse(self, line: str) -> Optional[Dict[str, Any]]:
        """Parse player events from log line"""
        # Pattern 1: UUID authentication log
        uuid_auth_match = re.search(
            r'UUID of player (.+?) is ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})',
            line, re.IGNORECASE
        )
        if uuid_auth_match:
            name = uuid_auth_match.group(1).strip()
            uuid = uuid_auth_match.group(2).strip()
            self.uuid_resolver.set_uuid(name, uuid)
            # Authentication is not a join event, return None
            return None
        
        # Pattern 2: Player join with UUID
        join_match = re.search(
            r'\[.*?\] \[.*?\] \[.*?\]: (.+?)\[\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\] joined the game',
            line, re.IGNORECASE
        )
        if join_match:
            name = join_match.group(1).strip()
            uuid = join_match.group(2).strip()
            self.uuid_resolver.set_uuid(name, uuid)
            return {
                'uuid': uuid,
                'name': name,
                'timestamp': self.timestamp_extractor.extract(line),
                'state': 'logon'
            }
        
        # Pattern 3: Player join without UUID
        join_match2 = re.search(r'\[.*?\] \[.*?\] \[.*?\]: (.+?) joined the game', line)
        if join_match2:
            name = join_match2.group(1).strip()
            uuid = self.uuid_resolver.resolve_uuid(name)
            return {
                'uuid': uuid,
                'name': name,
                'timestamp': self.timestamp_extractor.extract(line),
                'state': 'logon'
            }
        
        # Pattern 4: Player leave
        leave_match = re.search(r'\[.*?\] \[.*?\] \[.*?\]: (.+?) left the game', line)
        if leave_match:
            name = leave_match.group(1).strip()
            uuid = self.uuid_resolver.resolve_uuid(name)
            return {
                'uuid': uuid,
                'name': name,
                'timestamp': self.timestamp_extractor.extract(line),
                'state': 'logoff'
            }
        
        return None


class EntityDeathParser(EventParser):
    """Parses named entity death events"""
    
    def parse(self, line: str) -> Optional[Dict[str, Any]]:
        """Parse entity death events from log line"""
        # Pattern: Named entity EntityType['Name'/ID, l='ServerLevel[world]', x=X, y=Y, z=Z] died: Name was slain by Killer
        death_match = re.search(
            r'Named entity (\w+)\[\'(.+?)\'/\d+, l=\'ServerLevel\[world\]\', x=([-\d.]+), y=([-\d.]+), z=([-\d.]+)\] died: .+? was slain by (.+)',
            line
        )
        if death_match:
            entity_type = death_match.group(1).strip()
            entity_name = death_match.group(2).strip()
            x = death_match.group(3).strip()
            y = death_match.group(4).strip()
            z = death_match.group(5).strip()
            killer = death_match.group(6).strip()
            
            # Try to get UUIDs (empty if not players)
            entity_uuid = self.uuid_resolver.get_uuid(entity_name) or ''
            killer_uuid = self.uuid_resolver.get_uuid(killer) or ''
            
            return {
                'entity_type': entity_type,
                'entity_name': entity_name,
                'entity_uuid': entity_uuid,
                'killer': killer,
                'killer_uuid': killer_uuid,
                'x': x,
                'y': y,
                'z': z,
                'timestamp': self.timestamp_extractor.extract(line)
            }
        
        return None


class CsvWriter:
    """Handles writing events to CSV files"""
    
    def __init__(self, csv_file: str, headers: list):
        self.csv_file = csv_file
        self.headers = headers
    
    def write(self, event: Dict[str, Any]):
        """Write event to CSV file"""
        file_exists = os.path.exists(self.csv_file)
        
        with open(self.csv_file, 'a', newline='') as f:
            writer = csv.writer(f)
            
            # Write header if file is new
            if not file_exists:
                writer.writerow(self.headers)
            
            # Write event data in header order
            row = [event.get(header.lower().replace(' ', '_'), '') for header in self.headers]
            writer.writerow(row)
        
        self._log_event(event)
    
    def _log_event(self, event: Dict[str, Any]):
        """Log event to console (override in subclasses for custom logging)"""
        pass


class PlayerEventWriter(CsvWriter):
    """Writes player events to CSV"""
    
    def __init__(self, csv_file: str):
        super().__init__(csv_file, ['UUID', 'Name', 'time', 'state'])
    
    def _log_event(self, event: Dict[str, Any]):
        print(f"Logged {event['state']}: {event['name']} ({event['uuid']}) at {event['timestamp']}")


class EntityDeathWriter(CsvWriter):
    """Writes entity death events to CSV"""
    
    def __init__(self, csv_file: str):
        super().__init__(csv_file, ['EntityType', 'EntityName', 'EntityUUID', 'Killer', 'KillerUUID', 'X', 'Y', 'Z', 'Timestamp'])
    
    def _log_event(self, event: Dict[str, Any]):
        print(f"Logged entity death: {event['entity_name']} ({event['entity_type']}) slain by {event['killer']} at ({event['x']}, {event['y']}, {event['z']})")


class MinecraftLogParser:
    """Main class that orchestrates log parsing and event writing"""
    
    def __init__(self, log_file: str, data_dir: str = '/minecraft/data'):
        self.log_file = log_file
        self.data_dir = data_dir
        self.last_position = 0
        
        # Initialize components
        self.uuid_resolver = UuidResolver(
            f'{data_dir}/usercache.json',
            '/minecraft/usercache.json'
        )
        self.timestamp_extractor = LogTimestampExtractor()
        
        # Initialize parsers
        self.parsers = [
            PlayerEventParser(self.uuid_resolver, self.timestamp_extractor),
            EntityDeathParser(self.uuid_resolver, self.timestamp_extractor)
        ]
        
        # Initialize writers
        self.player_writer = PlayerEventWriter(f'{data_dir}/player_events.csv')
        self.entity_death_writer = EntityDeathWriter(f'{data_dir}/entity_deaths.csv')
        
        # Map event types to writers
        self.writer_map = {
            'logon': self.player_writer,
            'logoff': self.player_writer,
            'startup': self.player_writer,
            'entity_death': self.entity_death_writer
        }
    
    def initialize(self):
        """Initialize the parser (load cache, ensure directories exist)"""
        os.makedirs(self.data_dir, exist_ok=True)
        self.uuid_resolver.load_cache()
        
        # Log server startup event
        startup_event = {
            'uuid': '00000000-0000-0000-0000-000000000000',
            'name': 'SERVER',
            'timestamp': datetime.now(),
            'state': 'startup'
        }
        self.player_writer.write(startup_event)
    
    def poll_logs(self):
        """Poll the log file for new events"""
        if not os.path.exists(self.log_file):
            return
        
        try:
            with open(self.log_file, 'r') as f:
                f.seek(self.last_position)
                
                for line in f:
                    # Try each parser
                    for parser in self.parsers:
                        event = parser.parse(line)
                        if event:
                            # Determine writer based on event type
                            if 'state' in event:
                                writer = self.writer_map.get(event['state'], self.player_writer)
                            elif 'entity_type' in event:
                                writer = self.entity_death_writer
                            else:
                                continue
                            
                            writer.write(event)
                            break  # Only process each line once
                
                self.last_position = f.tell()
        except Exception as e:
            print(f"Error reading log file: {e}")
    
    def reload_uuid_cache(self):
        """Reload UUID cache from usercache.json"""
        self.uuid_resolver.load_cache()
    
    def run(self, poll_interval: float = 1.0, cache_reload_interval: float = 300.0):
        """Run the main polling loop"""
        self.initialize()
        
        print("Event Logger started")
        print(f"Log file: {self.log_file}")
        print(f"Player events CSV: {self.data_dir}/player_events.csv")
        print(f"Entity deaths CSV: {self.data_dir}/entity_deaths.csv")
        print("Polling every 1 second...")
        
        last_cache_reload = time.time()
        
        try:
            while True:
                # Reload UUID cache periodically
                if time.time() - last_cache_reload > cache_reload_interval:
                    self.reload_uuid_cache()
                    last_cache_reload = time.time()
                
                # Poll logs
                self.poll_logs()
                
                # Wait
                time.sleep(poll_interval)
        except KeyboardInterrupt:
            print("\nEvent Logger stopped")


def main():
    """Main entry point"""
    parser = MinecraftLogParser('/minecraft/logs/latest.log', '/minecraft/data')
    parser.run()


if __name__ == '__main__':
    main()
