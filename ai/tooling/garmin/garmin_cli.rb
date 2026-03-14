#!/usr/bin/env ruby

require 'optparse'
require 'json'
require 'fileutils'
require 'builder'
require 'date'

# Tenta carregar a gem. Se falhar e precisar de web fetch, informa o erro de forma amigável
begin
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/ruby_garmin_connect-0.2.1/lib"
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/faraday-2.14.1/lib"
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/faraday-cookie_jar-0.0.8/lib"
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/faraday-follow_redirects-0.5.0/lib"
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/faraday-retry-2.4.0/lib"
  $LOAD_PATH.unshift "/home/abacha/.asdf/installs/ruby/3.3.8/lib/ruby/gems/3.3.0/gems/faraday-net_http-3.4.2/lib"
  require 'garmin_connect'
  HAS_GARMIN_GEM = true
rescue LoadError
  HAS_GARMIN_GEM = false
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
    when "tcx"
      parse_tcx_options!
      generate_tcx
    when "weight"
      parse_weight_options!
      fetch_weight
    else
      print_usage
    end
  end
  
  private

  def check_gem_dependency!
    unless HAS_GARMIN_GEM
      puts "ERRO: A biblioteca `ruby_garmin_connect` não está disponível."
      puts "Por favor, rode: gem install ruby_garmin_connect builder"
      exit 1
    end
  end

  def get_client
    check_gem_dependency!
    
    email = ENV['GARMIN_EMAIL']
    password = ENV['GARMIN_PASSWORD']
    
    unless email && password
      puts "ERRO: Variáveis GARMIN_EMAIL e GARMIN_PASSWORD não definidas."
      puts "Dica: Use 'op item get Garmin --format=json' para extrair."
      exit 1
    end
    
    client = GarminConnect::Client.new(email: email, password: password)
    client.login
    client
  end

  # ==========================================
  # EXPORT COMMAND
  # ==========================================
  
  def parse_export_options!
    @options = { start: "2023-01-01", outdir: "." }
    OptionParser.new do |opts|
      opts.banner = "Usage: garmin_cli.rb export [options]"
      opts.on("--start DATE", "Start date (YYYY-MM-DD)") { |v| @options[:start] = v }
      opts.on("--outdir DIR", "Output directory") { |v| @options[:outdir] = v }
    end.parse!(@args)
  end

  def export_data
    client = get_client
    outdir = File.expand_path(@options[:outdir])
    FileUtils.mkdir_p(outdir)
    
    # Este script de export usa Python puro porque é mais seguro/robusto para paginação gigante
    # Para o wrapper final em Ruby ficar coeso, o recomendável seria portar isso.
    # Mas como já temos os scripts Python validados e funcionais, rodar como comando do sistema é a forma mais rápida de consolidar.
    
    py_script = File.join(File.dirname(__FILE__), "export_garmin_csv.py")
    if File.exist?(py_script)
      puts "Delegando para export_garmin_csv.py..."
      system("python3 #{py_script} --start #{@options[:start]} --outdir #{outdir}")
    else
      puts "ERRO: export_garmin_csv.py não encontrado na mesma pasta."
    end
  end
  
  # ==========================================
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
    py_script = File.join(File.dirname(__FILE__), "fetch_weight_history.py")
    if File.exist?(py_script)
      system("python3 #{py_script} --months #{@options[:months]}")
    else
      puts "ERRO: fetch_weight_history.py não encontrado."
    end
  end

  # ==========================================
  # TCX GENERATOR
  # ==========================================
  
  def parse_tcx_options!
    @options = {
      name: "Interval Run",
      warmup_min: 10,
      interval_count: 5,
      interval_dist_km: 1.0,
      interval_pace_min: 4,
      interval_pace_sec: 30,
      recovery_min: 2,
      cooldown_min: 10,
      output: "workout.tcx"
    }

    OptionParser.new do |opts|
      opts.banner = "Usage: garmin_cli.rb tcx [options]"
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
      opts.on("-o", "--output FILE", "Output filename") { |v| @options[:output] = v }
    end.parse!(@args)
  end

  def min_to_sec(min)
    (min * 60).to_i
  end

  def km_to_m(km)
    (km * 1000).to_i
  end

  def pace_to_speed(min, sec)
    total_seconds = (min * 60) + sec
    return 0 if total_seconds == 0
    1000.0 / total_seconds
  end

  def generate_tcx
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
          xml.Name @options[:name]
          
          xml.Step("xsi:type" => "Step_t") do
            xml.StepId 1
            xml.Name "Warmup"
            xml.Duration("xsi:type" => "Time_t") do
              xml.Seconds min_to_sec(@options[:warmup_min])
            end
            xml.Intensity "Active"
            xml.Target("xsi:type" => "None_t")
          end

          (1..@options[:interval_count]).each do |i|
            xml.Step("xsi:type" => "Step_t") do
              xml.StepId (i * 2)
              xml.Name "Run #{i}"
              xml.Duration("xsi:type" => "Distance_t") do
                xml.Meters km_to_m(@options[:interval_dist_km])
              end
              xml.Intensity "Active"
              xml.Target("xsi:type" => "Speed_t") do
                target_speed = pace_to_speed(@options[:interval_pace_min], @options[:interval_pace_sec])
                xml.SpeedZone("xsi:type" => "CustomSpeedZone_t") do
                  xml.ViewAs "Pace"
                  xml.LowInMetersPerSecond target_speed * 0.95 
                  xml.HighInMetersPerSecond target_speed * 1.05
                end
              end
            end

            xml.Step("xsi:type" => "Step_t") do
              xml.StepId (i * 2) + 1
              xml.Name "Recover #{i}"
              xml.Duration("xsi:type" => "Time_t") do
                xml.Seconds min_to_sec(@options[:recovery_min])
              end
              xml.Intensity "Resting"
              xml.Target("xsi:type" => "None_t")
            end
          end

          xml.Step("xsi:type" => "Step_t") do
            xml.StepId 99
            xml.Name "Cooldown"
            xml.Duration("xsi:type" => "Time_t") do
              xml.Seconds min_to_sec(@options[:cooldown_min])
            end
            xml.Intensity "Active"
            xml.Target("xsi:type" => "None_t")
          end
          
          xml.ScheduledOn(Date.today.to_s)
        end
      end
    end

    File.write(@options[:output], xml.target!)
    puts "✅ TCX gerado em #{@options[:output]}"
    puts "  - #{@options[:name]}"
    puts "  - Warmup: #{@options[:warmup_min]} min"
    puts "  - Intervals: #{@options[:interval_count]} x #{@options[:interval_dist_km]}km @ #{@options[:interval_pace_min]}:#{@options[:interval_pace_sec]}/km"
    puts "  - Recovery: #{@options[:recovery_min]} min"
    puts "  - Cooldown: #{@options[:cooldown_min]} min"
  end

  def print_usage
    puts "Garmin CLI v1.0"
    puts "Usage: garmin_cli.rb <command> [options]"
    puts ""
    puts "Commands:"
    puts "  export    Exporte todo o histórico (activities.csv, weight.csv)"
    puts "  weight    Busca resumo do peso mensal"
    puts "  tcx       Gera treinos intervalados (formato TCX)"
    puts ""
    puts "Examples:"
    puts "  garmin_cli.rb export --start 2023-01-01 --outdir ."
    puts "  garmin_cli.rb weight --months 12"
    puts "  garmin_cli.rb tcx -n '5x1k' -w 10 -c 5 -d 1.0 -p 4:30 -r 2 -l 10 -o treino.tcx"
  end
end

GarminCLI.new(ARGV).run
