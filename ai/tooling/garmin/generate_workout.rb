#!/usr/bin/env ruby
require 'builder'
require 'date'
require 'optparse'

# Default options
options = {
  name: "Interval Run",
  warmup_min: 10,
  interval_count: 5,
  interval_dist_km: 1.0,
  interval_pace_min: 4, # min/km
  interval_pace_sec: 30,
  recovery_min: 2,
  cooldown_min: 10,
  output: "workout.tcx"
}

OptionParser.new do |opts|
  opts.banner = "Usage: generate_workout.rb [options]"

  opts.on("-n", "--name NAME", "Workout Name") { |v| options[:name] = v }
  opts.on("-w", "--warmup MINUTES", Integer, "Warmup duration (min)") { |v| options[:warmup_min] = v }
  opts.on("-c", "--count COUNT", Integer, "Number of intervals") { |v| options[:interval_count] = v }
  opts.on("-d", "--distance KM", Float, "Interval distance (km)") { |v| options[:interval_dist_km] = v }
  opts.on("-p", "--pace MIN:SEC", "Target pace (min:sec/km)") do |v|
    m, s = v.split(':').map(&:to_i)
    options[:interval_pace_min] = m
    options[:interval_pace_sec] = s
  end
  opts.on("-r", "--recovery MINUTES", Float, "Recovery duration (min)") { |v| options[:recovery_min] = v }
  opts.on("-l", "--cooldown MINUTES", Integer, "Cooldown duration (min)") { |v| options[:cooldown_min] = v }
  opts.on("-o", "--output FILE", "Output filename") { |v| options[:output] = v }
end.parse!

def min_to_sec(min)
  (min * 60).to_i
end

def km_to_m(km)
  (km * 1000).to_i
end

# Pace (min/km) to Speed (m/s)
# 4:30 min/km = 270 sec/km
# Speed = 1000m / 270s = 3.7 m/s
def pace_to_speed(min, sec)
  total_seconds = (min * 60) + sec
  return 0 if total_seconds == 0
  1000.0 / total_seconds
end

# Create TCX
xml = Builder::XmlMarkup.new(indent: 2)
xml.instruct! :xml, encoding: "UTF-8"

xml.TrainingCenterDatabase("xsi:schemaLocation" => "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd",
                           "xmlns:ns5" => "http://www.garmin.com/xmlschemas/ActivityGoals/v1",
                           "xmlns:ns3" => "http://www.garmin.com/xmlschemas/ActivityExtension/v2",
                           "xmlns:ns2" => "http://www.garmin.com/xmlschemas/UserProfile/v2",
                           "xmlns" => "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2",
                           "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                           "xmlns:ns4" => "http://www.garmin.com/xmlschemas/ProfileExtension/v1") do
  xml.Workouts do
    xml.Workout(Sport: "Running") do
      xml.Name options[:name]
      
      xml.Step("xsi:type" => "Step_t") do
        xml.StepId 1
        xml.Name "Warmup"
        xml.Duration("xsi:type" => "Time_t") do
          xml.Seconds min_to_sec(options[:warmup_min])
        end
        xml.Intensity "Active"
        xml.Target("xsi:type" => "None_t")
      end

      # Intervals
      (1..options[:interval_count]).each do |i|
        # Active Interval
        xml.Step("xsi:type" => "Step_t") do
          xml.StepId (i * 2)
          xml.Name "Run #{i}"
          xml.Duration("xsi:type" => "Distance_t") do
            xml.Meters km_to_m(options[:interval_dist_km])
          end
          xml.Intensity "Active"
          xml.Target("xsi:type" => "Speed_t") do
            target_speed = pace_to_speed(options[:interval_pace_min], options[:interval_pace_sec])
            # Speed zone: +/- 5% roughly
            xml.SpeedZone("xsi:type" => "CustomSpeedZone_t") do
              xml.ViewAs "Pace"
              xml.LowInMetersPerSecond target_speed * 0.95 
              xml.HighInMetersPerSecond target_speed * 1.05
            end
          end
        end

        # Recovery
        xml.Step("xsi:type" => "Step_t") do
          xml.StepId (i * 2) + 1
          xml.Name "Recover #{i}"
          xml.Duration("xsi:type" => "Time_t") do
            xml.Seconds min_to_sec(options[:recovery_min])
          end
          xml.Intensity "Resting"
          xml.Target("xsi:type" => "None_t")
        end
      end

      xml.Step("xsi:type" => "Step_t") do
        xml.StepId 99
        xml.Name "Cooldown"
        xml.Duration("xsi:type" => "Time_t") do
          xml.Seconds min_to_sec(options[:cooldown_min])
        end
        xml.Intensity "Active"
        xml.Target("xsi:type" => "None_t")
      end
      
      xml.ScheduledOn(Date.today.to_s)
    end
  end
end

File.write(options[:output], xml.target!)
puts "Generated #{options[:output]}"
puts "  - #{options[:name]}"
puts "  - Warmup: #{options[:warmup_min]} min"
puts "  - Intervals: #{options[:interval_count]} x #{options[:interval_dist_km]}km @ #{options[:interval_pace_min]}:#{options[:interval_pace_sec]}/km"
puts "  - Recovery: #{options[:recovery_min]} min"
puts "  - Cooldown: #{options[:cooldown_min]} min"
