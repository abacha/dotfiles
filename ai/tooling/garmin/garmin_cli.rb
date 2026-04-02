#!/usr/bin/env ruby

require 'optparse'
require 'json'
require 'fileutils'
require 'builder'
require 'date'
require 'csv'
require 'dotenv/load'

begin
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/ruby_garmin_connect-0.2.1/lib"
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/faraday-2.14.1/lib"
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/faraday-cookie_jar-0.0.8/lib"
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/faraday-follow_redirects-0.5.0/lib"
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/faraday-retry-2.4.0/lib"
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/faraday-net_http-3.4.2/lib"
  require 'garmin_connect'
  HAS_GARMIN_GEM = true
rescue LoadError => e
  HAS_GARMIN_GEM = false
  @load_error = e.message
end

class GarminCLI
  def initialize(args)
    @args = args
    @options = {}
  end

  def run
    command = @args.shift
    
    case command
    when "export"
      parse_export_options!
      export_data
when "daily"
  parse_daily_options!
  export_daily
    when "sleep"
      parse_sleep_options!
      export_sleep
    when "workout"
      parse_workout_options!
      create_workout
    when "weight"
      parse_weight_options!
      fetch_weight
    when "resync-weight"
      parse_resync_options!
      resync_weight
    else
      print_usage
    end
  end
  
  private

  def check_gem_dependency!
    unless HAS_GARMIN_GEM
      puts "ERRO: A biblioteca `ruby_garmin_connect` não está disponível (#{@load_error})."
      puts "Por favor, rode: gem install ruby_garmin_connect builder"
      exit 1
    end
  end

  def get_client
    check_gem_dependency!
    
    email = ENV['GARMIN_EMAIL'] || ENV['GARMIN_USER']
    password = ENV['GARMIN_PASSWORD']
    
    unless email && password
      # Fallback to 1Password
      op_out = `op item get Garmin --format=json 2>/dev/null`
      if $?.success?
        begin
          data = JSON.parse(op_out)
          email_field = data["fields"]&.find { |f| f["id"] == "username" }
          pass_field = data["fields"]&.find { |f| f["id"] == "password" }
          
          email = email_field["value"] if email_field
          password = pass_field["value"] if pass_field
        rescue
          # Ignore parse errors
        end
      end
    end
    
    unless email && password
      puts "ERRO: Variáveis GARMIN_EMAIL e GARMIN_PASSWORD não definidas no ambiente nem no .env, e falhou ao buscar no 1Password."
      puts "Dica: Defina no .env ou garanta que o 'op' (1Password CLI) está logado."
      exit 1
    end
    
    client = GarminConnect::Client.new(email: email, password: password)
    begin
      client.login
    rescue => e
      puts "Erro no login: #{e.message}"
      exit 1
    end
    client
  end

  # ==========================================
  # EXPORT COMMAND
  # ==========================================
  
  def parse_export_options!
    @options = { start: "2023-01-01", end: Date.today.to_s, outdir: "." }
    OptionParser.new do |opts|
      opts.banner = "Usage: garmin_cli.rb export [options]"
      opts.on("--start DATE", "Start date (YYYY-MM-DD)") { |v| @options[:start] = v }
      opts.on("--end DATE", "End date (YYYY-MM-DD)") { |v| @options[:end] = v }
      opts.on("--outdir DIR", "Output directory") { |v| @options[:outdir] = v }
    end.parse!(@args)
  end

  def map_activity_type(raw_type, activity_name)
    return "Judo" if activity_name.to_s.downcase.include?("judo")
    
    type_map = {
      "running" => "Run",
      "strength_training" => "Strength",
      "walking" => "Walk",
      "cycling" => "Cycling",
      "indoor_cycling" => "Cycling"
    }
    
    type_map[raw_type] || raw_type.gsub("_", " ").split.map(&:capitalize).join(" ")
  end

  def export_data
    client = get_client
    outdir = File.expand_path(@options[:outdir])
    FileUtils.mkdir_p(outdir)
    
    # --- WEIGHT ---
    puts "Buscando composição corporal de #{@options[:start]} a #{@options[:end]}..."
    begin
      weights_data = client.body_composition(@options[:start], @options[:end])
      weight_list = weights_data["dateWeightList"] || []
      
      csv_path = File.join(outdir, "weight.csv")
      CSV.open(csv_path, "wb") do |csv|
        csv << ["date", "weight_kg", "body_fat_percent", "muscle_mass_kg", "bone_mass_kg", "body_water_percent", "bmr"]
        
        weight_list.sort_by { |w| w["date"] || 0 }.each do |w|
          next unless w["date"]
          dt = Time.at(w["date"] / 1000.0)
          date_str = dt.strftime("%Y-%m-%d")
          
          weight = w["weight"] ? (w["weight"] / 1000.0).round(1) : nil
          fat = w["bodyFat"]
          muscle = w["muscleMass"] ? (w["muscleMass"] / 1000.0).round(1) : nil
          bone = w["boneMass"] ? (w["boneMass"] / 1000.0).round(1) : nil
          water = w["bodyWater"]
          bmr = w["bmr"]
          
          csv << [date_str, weight, fat, muscle, bone, water, bmr]
        end
      end
      puts "✅ Salvo #{weight_list.size} registros de peso em #{csv_path}"
    rescue => e
      puts "Erro ao buscar dados de peso: #{e}"
    end

    # --- ACTIVITIES ---
    puts "Buscando histórico de atividades (isso pode demorar dependendo do volume)..."
    activities = []
    start_idx = 0
    limit = 100
    
    loop do
      chunk = client.activities(start: start_idx, limit: limit)
      break if chunk.nil? || chunk.empty?
      
      reached_end = false
      chunk.each do |act|
        act_date_str = (act["startTimeLocal"] || "").split(" ").first
        if act_date_str && act_date_str < @options[:start]
          reached_end = true
          break
        end
        activities << act
      end
      
      break if reached_end || chunk.size < limit
      start_idx += limit
    end

    activities.reverse!
    
    csv_path = File.join(outdir, "activities.csv")
    CSV.open(csv_path, "wb") do |csv|
      csv << [
        "date", "activity_type", "duration_minutes", "calories", 
        "distance_km", "avg_heart_rate", "max_heart_rate", 
        "aerobic_training_effect", "anaerobic_training_effect", "training_load"
      ]
      
      activities.each do |act|
        date_str = (act["startTimeLocal"] || "").split(" ").first
        raw_type = act.dig("activityType", "typeKey") || "other"
        act_name = act["activityName"] || ""
        
        final_type = map_activity_type(raw_type, act_name)
            
        dur = act["duration"]
        duration_minutes = dur ? (dur / 60.0).round : nil
        
        cal = act["calories"]
        calories = cal ? cal.round : nil
        
        dist = act["distance"]
        distance_km = dist ? (dist / 1000.0).round(2) : nil
        
        avg_hr = act["averageHR"]
        max_hr = act["maxHR"]
        ae_te = act["aerobicTrainingEffect"] ? act["aerobicTrainingEffect"].round(1) : nil
        an_te = act["anaerobicTrainingEffect"] ? act["anaerobicTrainingEffect"].round(1) : nil
        training_load = act["activityTrainingLoad"] ? act["activityTrainingLoad"].round : nil
        
        csv << [
          date_str, final_type, duration_minutes, calories, 
          distance_km, avg_hr, max_hr, ae_te, an_te, training_load
        ]
      end
    end
    puts "✅ Salvo #{activities.size} atividades em #{csv_path}"
  end
  
  # ==========================================
  # SLEEP COMMAND
  # ==========================================

  def parse_sleep_options!
    @options = { start: (Date.today - 30).to_s, end: Date.today.to_s, outdir: "." }
    OptionParser.new do |opts|
      opts.banner = "Usage: garmin_cli.rb sleep [options]"
      opts.on("--start DATE", "Start date (YYYY-MM-DD)") { |v| @options[:start] = v }
      opts.on("--end DATE", "End date (YYYY-MM-DD)") { |v| @options[:end] = v }
      opts.on("--outdir DIR", "Output directory") { |v| @options[:outdir] = v }
    end.parse!(@args)
  end

  def export_sleep
    client = get_client
    outdir = File.expand_path(@options[:outdir])
    FileUtils.mkdir_p(outdir)
    
    start_date = Date.parse(@options[:start])
    end_date = Date.parse(@options[:end])
    
    puts "Buscando histórico de sono de #{start_date} a #{end_date}..."
    
    csv_path = File.join(outdir, "sleep.csv")
    CSV.open(csv_path, "wb") do |csv|
      csv << [
        "date", "score", "score_qualifier", "total_sleep_hours", 
        "deep_sleep_hours", "light_sleep_hours", "rem_sleep_hours", 
        "awake_hours", "avg_hr", "avg_hrv", "avg_respiration", "avg_stress"
      ]
      
      current_date = start_date
      while current_date <= end_date
        date_str = current_date.to_s
        begin
          data = client.sleep_data(date_str)
          sleep_dto = data["dailySleepDTO"]
          
          if sleep_dto
            score = sleep_dto.dig("sleepScores", "overall", "value")
            qualifier = sleep_dto.dig("sleepScores", "overall", "qualifierKey")
            
            total_sec = sleep_dto["sleepTimeSeconds"] || 0
            deep_sec = sleep_dto["deepSleepSeconds"] || 0
            light_sec = sleep_dto["lightSleepSeconds"] || 0
            rem_sec = sleep_dto["remSleepSeconds"] || 0
            awake_sec = sleep_dto["awakeSleepSeconds"] || 0
            
            avg_hr = sleep_dto["avgHeartRate"]
            avg_resp = sleep_dto["averageRespirationValue"]
            avg_stress = sleep_dto["avgSleepStress"]
            avg_hrv = data["avgOvernightHrv"]
            
            csv << [
              date_str, 
              score, 
              qualifier,
              (total_sec / 3600.0).round(2),
              (deep_sec / 3600.0).round(2),
              (light_sec / 3600.0).round(2),
              (rem_sec / 3600.0).round(2),
              (awake_sec / 3600.0).round(2),
              avg_hr,
              avg_hrv,
              avg_resp,
              avg_stress
            ]
          end
        rescue => e
          puts "Erro ao buscar dados de #{date_str}: #{e.message}"
        end
        current_date += 1
      end
    end
    
    puts "✅ CSV de Sono exportado para: #{csv_path}"
  end

  # ==========================================
# ==========================================
# DAILY COMMAND
# ==========================================

def parse_daily_options!
  @options = { start: (Date.today - 30).to_s, end: Date.today.to_s, outdir: "." }
  OptionParser.new do |opts|
    opts.banner = "Usage: garmin_cli.rb daily [options]"
    opts.on("--start DATE", "Start date (YYYY-MM-DD)") { |v| @options[:start] = v }
    opts.on("--end DATE", "End date (YYYY-MM-DD)") { |v| @options[:end] = v }
    opts.on("--outdir DIR", "Output directory") { |v| @options[:outdir] = v }
  end.parse!(@args)
end

def export_daily
  client = get_client
  outdir = File.expand_path(@options[:outdir])
  FileUtils.mkdir_p(outdir)
  
  start_date = Date.parse(@options[:start])
  end_date = Date.parse(@options[:end])
  
  puts "Buscando histórico diário (daily summary) de #{start_date} a #{end_date}..."
  
  csv_path = File.join(outdir, "daily.csv")
  CSV.open(csv_path, "wb") do |csv|
    csv << [
      "date", "total_steps", "total_calories", "active_calories", "bmr_calories",
      "resting_hr", "min_hr", "max_hr", "intensity_minutes_moderate", "intensity_minutes_vigorous",
      "avg_stress", "max_stress", "stress_percentage", 
      "body_battery_min", "body_battery_max", "body_battery_change",
      "floors_ascended"
    ]
    
    current_date = start_date
    while current_date <= end_date
      date_str = current_date.to_s
      begin
        data = client.daily_summary(date_str)
        if data && data["calendarDate"] == date_str
          csv << [
            date_str,
            data["totalSteps"],
            data["totalKilocalories"],
            data["activeKilocalories"],
            data["bmrKilocalories"],
            data["restingHeartRate"],
            data["minHeartRate"],
            data["maxHeartRate"],
            data["moderateIntensityMinutes"],
            data["vigorousIntensityMinutes"],
            data["averageStressLevel"],
            data["maxStressLevel"],
            data["stressPercentage"],
            data["bodyBatteryLowestValue"],
            data["bodyBatteryHighestValue"],
            (data["bodyBatteryChargedValue"] || 0) - (data["bodyBatteryDrainedValue"] || 0),
            data["floorsAscended"]
          ]
        end
      rescue => e
        puts "Erro ao buscar dados de #{date_str}: #{e.message}"
      end
      current_date += 1
    end
  end
  
  puts "✅ CSV Diário (Daily Summary) exportado para: #{csv_path}"
end

  # WEIGHT COMMAND
  # ==========================================
  
  def parse_weight_options!
    @options = { months: 6 }
    OptionParser.new do |opts|
      opts.banner = "Usage: garmin_cli.rb weight [options]"
      opts.on("--months N", Integer, "Months to fetch") { |v| @options[:months] = v }
    end.parse!(@args)
  end

  def fetch_weight
    client = get_client
    
    end_date = Date.today
    start_date = end_date - (30 * @options[:months])

    puts "Buscando histórico do Garmin de #{start_date} a #{end_date}..."
    begin
      weights_data = client.body_composition(start_date.to_s, end_date.to_s)
    rescue => e
      puts "Erro ao buscar dados de composição corporal: #{e}"
      exit 1
    end

    weight_list = weights_data["dateWeightList"] || []
    if weight_list.empty?
      puts "Nenhum dado de peso encontrado no período."
      return
    end

    monthly = Hash.new { |h, k| h[k] = [] }
    
    weight_list.sort_by { |x| x["date"] || 0 }.each do |w|
      next unless w["date"]
      dt = Time.at(w["date"] / 1000.0)
      
      weight = w["weight"] ? (w["weight"] / 1000.0) : 0
      fat = w["bodyFat"]
      muscle = w["muscleMass"] ? (w["muscleMass"] / 1000.0) : 0
      
      monthly[dt.strftime("%Y-%m")] << {
        date: dt.strftime("%d/%m"),
        weight: weight,
        fat: fat,
        muscle: muscle
      }
    end

    puts "\n📊 **Histórico de Peso (Últimos #{@options[:months]} meses)**\n\n"
    monthly.sort.each do |month, entries|
      puts "**#{month}**"
      entries.each do |e|
        fat_str = e[:fat] ? ", Gordura: #{e[:fat]}%" : ""
        muscle_str = e[:muscle] && e[:muscle] > 0 ? ", Músculo: #{e[:muscle].round(1)}kg" : ""
        puts " - #{e[:date]}: #{e[:weight].round(1)}kg#{fat_str}#{muscle_str}"
      end
      puts ""
    end
  end

  # ==========================================
  # RESYNC COMMAND
  # ==========================================

  def parse_resync_options!
    @options = { start: "2020-01-01", end: Date.today.to_s, dry_run: false, yes: false }
    OptionParser.new do |opts|
      opts.banner = "Usage: garmin_cli.rb resync-weight [options]"
      opts.on("--start DATE", "Start date (YYYY-MM-DD)") { |v| @options[:start] = v }
      opts.on("--end DATE", "End date (YYYY-MM-DD)") { |v| @options[:end] = v }
      opts.on("--dry-run", "Show what would happen") { @options[:dry_run] = true }
      opts.on("--yes", "Confirm resync without prompt") { @options[:yes] = true }
    end.parse!(@args)
  end

  def chunk_ranges(start_d, end_d, chunk_days)
    ranges = []
    current = start_d
    while current <= end_d
      chunk_end = [end_d, current + chunk_days - 1].min
      ranges << [current, chunk_end]
      current = chunk_end + 1
    end
    ranges
  end

  def extract_weight_records(payload)
    return [] unless payload.is_a?(Hash)
    ["weighIns", "weightList", "dateWeightList", "weightMeasurements", "weights", "weight"].each do |key|
      if payload[key].is_a?(Array)
        return payload[key].select { |i| i.is_a?(Hash) }
      end
    end
    payload.values.each do |val|
      if val.is_a?(Array) && val.first.is_a?(Hash)
        return val
      end
    end
    []
  end

  def resync_weight
    unless @options[:dry_run] || @options[:yes]
      puts "Aviso: Dry-run desativado. Use --yes para prosseguir com alterações reais."
      exit 0
    end
    
    client = get_client
    start_date = Date.parse(@options[:start])
    end_date = Date.parse(@options[:end])
    
    ranges = chunk_ranges(start_date, end_date, 120)
    
    processed_ids = {}
    stats = { total: 0, skipped: 0, deleted: 0, added: 0, errors: 0 }
    
    ranges.each do |chunk_start, chunk_end|
      puts "Buscando pesagens #{chunk_start} -> #{chunk_end}"
      begin
        # Fetch detailed range
        payload = client.connection.get(
          "/weight-service/weight/range/#{chunk_start.strftime("%Y-%m-%d")}/#{chunk_end.strftime("%Y-%m-%d")}",
          params: { "includeAll" => true }
        )
      rescue => e
        puts "Falhou ao buscar pesagens: #{e}"
        stats[:errors] += 1
        break
      end
      
      records = extract_weight_records(payload)
      puts "Encontrados #{records.size} registros neste slice."
      
      records.each do |entry|
        stats[:total] += 1
        
        # Determine ID
        rec_id = entry["samplePk"] || entry["id"] || entry["pk"] || entry["weightPk"] || entry["version"]
        
        weight_val = entry["weight"] || entry["value"]
        next if weight_val.nil? || weight_val <= 0
        weight_val /= 1000.0 if weight_val > 1000
        
        # Get timestamps
        ts_local = entry["timestamp"] || entry["timestampLocal"] || entry["dateTimestamp"] || entry["date"]
        ts_gmt = entry["timestampGMT"] || entry["gmtTimestamp"]
        
        # Fallbacks for missing timestamps
        unless ts_local && ts_gmt
          if entry["calendarDate"]
            begin
              dt = Time.parse("#{entry["calendarDate"]} 12:00:00")
              ts_local = dt.to_i * 1000
              ts_gmt = dt.utc.to_i * 1000
            rescue
            end
          end
        end
        
        unless ts_local && ts_gmt
          stats[:skipped] += 1
          next
        end
        
        rec_id ||= "#{entry["calendarDate"]}-#{ts_local}-#{weight_val}"
        next if processed_ids[rec_id]
        processed_ids[rec_id] = true
        
        local_time = Time.at(ts_local / 1000.0)
        gmt_time = Time.at(ts_gmt / 1000.0).utc
        
        date_for_delete = entry["calendarDate"] || local_time.strftime("%Y-%m-%d")
        unit = (entry["unitKey"] || entry["unit"] || "kg").downcase
        unit = "kg" unless ["kg", "lb", "lbs"].include?(unit)
        
        begin
          if rec_id && date_for_delete && !@options[:dry_run]
            client.delete_weigh_in(date_for_delete, rec_id)
            stats[:deleted] += 1
          elsif rec_id && date_for_delete
            stats[:deleted] += 1
          end
          
          if !@options[:dry_run]
            # Formats: 2026-02-11T08:30:00.000
            fmt_local = local_time.strftime("%Y-%m-%dT%H:%M:%S.000")
            fmt_gmt = gmt_time.strftime("%Y-%m-%dT%H:%M:%S.000")
            
            client.add_weigh_in_with_timestamps(
              weight_val,
              date_timestamp: fmt_local,
              gmt_timestamp: fmt_gmt,
              unit_key: unit
            )
          end
          stats[:added] += 1
          puts "Re-added weigh-in #{rec_id} on #{local_time.strftime("%Y-%m-%d")} #{weight_val.round(1)}#{unit}"
        rescue => e
          puts "Failed to resync #{rec_id}: #{e}"
          stats[:errors] += 1
        end
      end
    end
    
    puts "Pronto. Sumário: #{stats}"
  end

  # ==========================================
  # ==========================================
  # GARMIN WORKOUT CREATOR
  # ==========================================
  
  def parse_workout_options!
    @options = {
      name: "Interval Run",
      warmup_min: 10,
      interval_count: 5,
      interval_dist_km: 1.0,
      interval_pace_min: 4,
      interval_pace_sec: 30,
      recovery_min: 2,
      cooldown_min: 10
    }

    OptionParser.new do |opts|
      opts.banner = "Usage: garmin_cli.rb workout [options]"
      opts.on("-n", "--name NAME", "Workout Name") { |v| @options[:name] = v }
      opts.on("-w", "--warmup MINUTES", Integer, "Warmup duration (min)") { |v| @options[:warmup_min] = v }
      opts.on("-c", "--count COUNT", Integer, "Number of intervals") { |v| @options[:interval_count] = v }
      opts.on("-d", "--distance KM", Float, "Interval distance (km)") { |v| @options[:interval_dist_km] = v }
      opts.on("-p", "--pace MIN:SEC", "Target pace (min:sec/km)") do |v|
        m, s = v.split(':').map(&:to_i)
        @options[:interval_pace_min] = m
        @options[:interval_pace_sec] = s
      end
      opts.on("-r", "--recovery MINUTES", Float, "Recovery duration (min)") { |v| @options[:recovery_min] = v }
      opts.on("-l", "--cooldown MINUTES", Integer, "Cooldown duration (min)") { |v| @options[:cooldown_min] = v }
    end.parse!(@args)
  end

  def pace_to_ms(min, sec)
    1000.0 / ((min * 60) + sec)
  end

  def create_workout
    client = get_client
    target_ms = pace_to_ms(@options[:interval_pace_min], @options[:interval_pace_sec])
    target_low = target_ms * 0.95
    target_high = target_ms * 1.05

    steps = []
    step_order = 1

    steps << {
      "type" => "ExecutableStepDTO",
      "stepOrder" => step_order,
      "stepType" => { "stepTypeId" => 1, "stepTypeKey" => "warmup", "displayOrder" => 1 },
      "endCondition" => { "conditionTypeId" => 2, "conditionTypeKey" => "time", "displayOrder" => 2, "displayable" => true },
      "endConditionValue" => @options[:warmup_min] * 60.0
    }
    step_order += 1

    if @options[:interval_count] > 0
      steps << {
        "type" => "RepeatGroupDTO",
        "stepOrder" => step_order,
        "stepType" => { "stepTypeId" => 6, "stepTypeKey" => "repeat", "displayOrder" => 6 },
        "numberOfIterations" => @options[:interval_count],
        "smartRepeat" => false,
        "workoutSteps" => [
          {
            "type" => "ExecutableStepDTO",
            "stepOrder" => step_order + 1,
            "stepType" => { "stepTypeId" => 3, "stepTypeKey" => "interval", "displayOrder" => 3 },
            "endCondition" => { "conditionTypeId" => 3, "conditionTypeKey" => "distance", "displayOrder" => 3, "displayable" => true },
            "endConditionValue" => @options[:interval_dist_km] * 1000.0,
            "targetType" => { "workoutTargetTypeId" => 6, "workoutTargetTypeKey" => "pace.zone", "displayOrder" => 6 },
            "targetValueOne" => target_low,
            "targetValueTwo" => target_high
          },
          {
            "type" => "ExecutableStepDTO",
            "stepOrder" => step_order + 2,
            "stepType" => { "stepTypeId" => 4, "stepTypeKey" => "recovery", "displayOrder" => 4 },
            "endCondition" => { "conditionTypeId" => 2, "conditionTypeKey" => "time", "displayOrder" => 2, "displayable" => true },
            "endConditionValue" => @options[:recovery_min] * 60.0
          }
        ]
      }
      step_order += 3
    end

    steps << {
      "type" => "ExecutableStepDTO",
      "stepOrder" => step_order,
      "stepType" => { "stepTypeId" => 2, "stepTypeKey" => "cooldown", "displayOrder" => 2 },
      "endCondition" => { "conditionTypeId" => 2, "conditionTypeKey" => "time", "displayOrder" => 2, "displayable" => true },
      "endConditionValue" => @options[:cooldown_min] * 60.0
    }

    puts "📡 Enviando treino para o Garmin Connect..."
    res = client.create_running_workout(@options[:name], steps: steps)
    
    puts "✅ Treino criado com sucesso no Garmin Connect!"
    if res && res["workoutId"]
      puts "🔗 https://connect.garmin.com/modern/workout/#{res["workoutId"]}"
    end
  end

  def print_usage
    puts "Garmin CLI v2.0 (Unified Ruby)"
    puts "Usage: garmin_cli.rb <command> [options]"
    puts ""
    puts "Commands:"
    puts "  export          Exporte todo o histórico (activities.csv, weight.csv)"
    puts "  daily           Exporta o resumo diário de saúde (passos, HR, BB, etc)"
    puts "  sleep           Exporta dados diários de sono em CSV"
    puts "  weight          Busca resumo do peso mensal"
    puts "  resync-weight   Ressincroniza as pesagens p/ atualizar o perfil"
    puts "  workout         Gera e envia treino pro Garmin Connect"
    puts ""
    puts "Examples:"
    puts "  garmin_cli.rb export --start 2023-01-01 --outdir ."
    puts "  garmin_cli.rb weight --months 12"
    puts "  garmin_cli.rb resync-weight --start 2020-01-01 --dry-run"
    puts "  garmin_cli.rb workout -n '5x1k' -w 10 -c 5 -d 1.0 -p 4:30 -r 2 -l 10"
  end
end

GarminCLI.new(ARGV).run
