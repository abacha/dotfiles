#!/usr/bin/env ruby

require 'optparse'
require 'json'
require 'fileutils'
require 'csv'
require 'date'

begin
  require 'dotenv/load'
rescue LoadError
end

begin
  require 'faraday'
  require 'faraday/retry'
  HAS_FARADAY = true
rescue LoadError => e
  HAS_FARADAY = false
  @load_error = e.message
end

class HevyCLI
  API_URL = "https://api.hevyapp.com/v1"

  def initialize(args)
    @args = args
    @options = {}
  end

  def run
    command = @args.shift
    
    case command
    when "export-workouts"
      parse_export_options!
      export_workouts
    when "export-routines"
      parse_export_options!
      export_routines
    else
      print_usage
    end
  end

  private

  def check_dependencies!
    unless HAS_FARADAY
      puts "ERRO: Faraday gem is missing (#{@load_error})."
      puts "Run: bundle install"
      exit 1
    end
  end

  def get_api_key
    key = ENV['HEVY_API_KEY']
    
    unless key && !key.empty?
      op_out = `op item get Hevy --format=json 2>/dev/null`
      if $?.success?
        begin
          data = JSON.parse(op_out)
          # Tenta procurar o field onde possivelmente está a API Key
          key_field = data["fields"]&.find { |f| f["id"] == "credential" || f["label"].to_s.downcase.include?("api") }
          key = key_field["value"] if key_field
        rescue
        end
      end
    end

    unless key && !key.empty?
      puts "ERRO: HEVY_API_KEY não encontrada."
      puts "Defina no .env ou no ambiente, ou salve no 1Password (op)."
      exit 1
    end
    key
  end

  def client
    @client ||= begin
      check_dependencies!
      Faraday.new(url: API_URL) do |f|
        f.request :retry, max: 3, interval: 0.5, interval_randomness: 0.5, backoff_factor: 2
        f.headers['api-key'] = get_api_key
        f.headers['Accept'] = 'application/json'
        f.adapter Faraday.default_adapter
      end
    end
  end

  # --- WORKOUTS ---

  def parse_export_options!
    @options = { outdir: "." }
    OptionParser.new do |opts|
      opts.banner = "Usage: hevy_cli.rb [command] [options]"
      opts.on("--outdir DIR", "Directory to save CSVs") { |v| @options[:outdir] = v }
    end.parse!(@args)
  end

  def fetch_workouts
    puts "Buscando histórico de treinos no Hevy..."
    workouts = []
    page = 1
    
    loop do
      puts " Buscando página #{page}..."
      resp = client.get("workouts", { page: page, pageSize: 10 })
      
      unless resp.success?
        puts "Erro ao acessar API (Status #{resp.status}): #{resp.body}"
        exit 1
      end
      
      data = JSON.parse(resp.body)
      items = data["workouts"] || []
      break if items.empty?
      
      workouts.concat(items)
      page_count = data["page_count"] || 1
      break if page >= page_count
      
      page += 1
    end
    
    puts "Total de treinos encontrados: #{workouts.size}"
    workouts
  end

  def export_workouts
    workouts = fetch_workouts
    return if workouts.empty?
    
    outdir = File.expand_path(@options[:outdir])
    FileUtils.mkdir_p(outdir)
    csv_path = File.join(outdir, "hevy_workouts.csv")
    
    CSV.open(csv_path, "wb") do |csv|
      csv << ["date", "workout_name", "duration_minutes", "exercise", "sets", "total_volume_kg", "total_reps"]
      
      workouts.reverse.each do |w|
        start_time = w["start_time"]
        date_str = start_time ? start_time.split("T").first : ""
        
        dur_mins = nil
        if start_time && w["end_time"]
          begin
            st = DateTime.parse(start_time).to_time
            et = DateTime.parse(w["end_time"]).to_time
            dur_mins = ((et - st) / 60.0).round
          rescue
          end
        end

        name = w["name"] || "Treino"
        
        (w["exercises"] || []).each do |ex|
          ex_name = ex["title"]
          sets = ex["sets"] || []
          
          volume_kg = 0.0
          reps_total = 0
          
          sets.each do |s|
            weight = s["weight_kg"] || 0
            reps = s["reps"] || 0
            volume_kg += (weight * reps)
            reps_total += reps
          end

          csv << [date_str, name, dur_mins, ex_name, sets.size, volume_kg.round(1), reps_total]
        end
      end
    end
    puts "✅ CSV de Treinos exportado para: #{csv_path}"
  end

  # --- ROUTINES ---
  
  def fetch_routines
    puts "Buscando rotinas salvas no Hevy..."
    routines = []
    page = 1
    
    loop do
      puts " Buscando rotinas (página #{page})..."
      resp = client.get("routines", { page: page, pageSize: 10 })
      
      unless resp.success?
        puts "Erro ao acessar API (Status #{resp.status}): #{resp.body}"
        exit 1
      end
      
      data = JSON.parse(resp.body)
      items = data["routines"] || []
      break if items.empty?
      
      routines.concat(items)
      page_count = data["page_count"] || 1
      break if page >= page_count
      
      page += 1
    end
    
    puts "Total de rotinas encontradas: #{routines.size}"
    routines
  end

  def export_routines
    routines = fetch_routines
    return if routines.empty?
    
    outdir = File.expand_path(@options[:outdir])
    FileUtils.mkdir_p(outdir)
    csv_path = File.join(outdir, "hevy_routines.csv")
    
    CSV.open(csv_path, "wb") do |csv|
      csv << ["routine_name", "updated_at", "exercise_index", "exercise_name", "sets", "superset_id"]
      
      routines.each do |r|
        name = r["title"] || "Rotina sem nome"
        updated_at = r["updated_at"] ? r["updated_at"].split("T").first : ""
        
        (r["exercises"] || []).sort_by { |e| e["index"].to_i }.each do |ex|
          ex_index = ex["index"]
          ex_name = ex["title"]
          sets_count = (ex["sets"] || []).size
          superset_id = ex["superset_id"] && ex["superset_id"] > 0 ? ex["superset_id"] : nil
          
          csv << [name, updated_at, ex_index, ex_name, sets_count, superset_id]
        end
      end
    end
    puts "✅ CSV de Rotinas exportado para: #{csv_path}"
  end

  def print_usage
    puts "Hevy CLI v1.0 (Unified Ruby)"
    puts "Usage: hevy_cli.rb <command> [options]"
    puts ""
    puts "Commands:"
    puts "  export-workouts   Exporta histórico de treinos concluídos (CSV)"
    puts "  export-routines   Exporta templates/rotinas salvas (CSV)"
    puts ""
    puts "Examples:"
    puts "  hevy_cli.rb export-workouts --outdir ."
    puts "  hevy_cli.rb export-routines"
  end
end

HevyCLI.new(ARGV).run
