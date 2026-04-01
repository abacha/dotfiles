#!/usr/bin/env bash
set -euo pipefail

DB_DEFAULT="/mnt/c/Users/abach/OneDrive/Documents/Jogos/YARG/scores/scores.db"
OUTPUT_DEFAULT=".pi/yarg_music_scores.csv"

db="$DB_DEFAULT"
output="$OUTPUT_DEFAULT"

usage() {
  cat <<EOF
Usage: $0 [--db <path>] [--output <path>]

Options:
  --db <path>       override the default YARG scores.db location (default: $DB_DEFAULT)
  --output <path>   override the CSV destination (default: $OUTPUT_DEFAULT)
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --db)
      shift
      if [[ $# -eq 0 ]]; then
        echo "--db requires a value" >&2
        usage
        exit 1
      fi
      db="$1"
      shift
      continue
      ;;
    --output)
      shift
      if [[ $# -eq 0 ]]; then
        echo "--output requires a value" >&2
        usage
        exit 1
      fi
      output="$1"
      shift
      continue
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

if [[ ! -f "$db" ]]; then
  echo "Score database not found at $db" >&2
  exit 1
fi

query=$(cat <<'SQL'
WITH ranked AS (
  SELECT
    gr.SongName,
    COALESCE(NULLIF(TRIM(gr.SongArtist), ''), 'Unknown') || ' - ' || gr.SongName AS DisplayName,
    ps.Percent,
    gr.GameVersion AS GameVersion,
    ROW_NUMBER() OVER (PARTITION BY gr.SongName ORDER BY ps.Score DESC, ps.Percent DESC, ps.Id ASC) AS rn
  FROM PlayerScores ps
  JOIN GameRecords gr ON gr.Id = ps.GameRecordId
  WHERE ps.Score IS NOT NULL
)
SELECT
  SongName,
  DisplayName,
  Percent,
  GameVersion
FROM ranked
WHERE rn = 1
ORDER BY SongName COLLATE NOCASE;
SQL
)

map_file="scripts/song_source_map.csv"
map_arg=""
if [[ -f "$map_file" ]]; then
  map_arg="$map_file"
fi

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

sqlite3 -header -csv "$db" "$query" > "$tmpfile"
if [[ ! -s "$tmpfile" ]]; then
  echo "No scores were returned from the database." >&2
  exit 1
fi

mkdir -p "$(dirname "$output")"
: > "$output"

printf 'Best per-song YARG highscores:\n\n'
awk -F',' -v csvfile="$output" -v mapfile="$map_arg" '
  BEGIN {
    OFS=",";
    printf "Music name\tPercent\tSource\n";
    print "Music name,Percent,Source" > csvfile;
    if (mapfile != "") {
      if ((getline header_line < mapfile) >= 0) {
        # skip header
      }
      while ((getline line < mapfile) > 0) {
        if (line == "") continue;
        split(line, fields, ",");
        key = fields[1];
        value = fields[2];
        if (key != "" && value != "") {
          source_map[key] = value;
        }
      }
      close(mapfile);
    }
  }
  NR == 1 { next; }
  {
    song = $1;
    display = $2;
    percent = $3;
    source = $4;
    if (song in source_map) source = source_map[song];
    if (percent == "" || percent == "NULL") {
      percent_str = "-";
    } else {
      percent_str = sprintf("%.0f%%", percent * 100);
    }
    printf "%s\t%s\t%s\n", display, percent_str, source;
    print display "," percent_str "," source >> csvfile;
  }
' "$tmpfile" | column -t -s $'\t'

printf '\nCSV written to %s\n' "$output"
