#!/usr/bin/env bash

# tool for dynamic task scheduling:
# when the user is active or the cpu load is high, then dont run any jobs.
# when the user is away and the cpu load is low, then run one job at a time.
# this is useful for long-running cpu-heavy jobs like ffmpeg.
# when a job is running and the user returns, pause the job.

# check dependencies
deps=(
  pactl
  xprintidle
  uptime
)
for d in ${deps[@]}; do
  if ! command -v $d &> /dev/null; then
    echo "error: missing command: $d"
    exit 1
  fi
done

# Define the idle time threshold (e.g., 5 minutes)
#min_idle_time=$((5 * 60 * 1000))  # in milliseconds
min_idle_time=$((5 * 1000))  # in milliseconds

# Define the CPU load threshold
max_cpu_load=1.0

# Function to check if audio is playing
is_audio_playing() {
    pactl list short sink-inputs | grep -q RUNNING
    return $?
}

# Function to check if video is playing
# TODO also check the cpu load, which is zero when paused
is_video_playing() {
    #ps -a -x -o comm,args |
    ps -a -x -o comm |
    grep -q -E '^(vlc|mpv|mplayer|totem|smplayer)$'
    return $?
}

echo "$(date) waiting for user to leave"

# outer loop: wait for user to leave
while true; do

  #sleep 1m
  sleep 2 # debug

  # Check if the user is idle
  idle_time=$(xprintidle)

  if (( idle_time < min_idle_time )); then
    echo "$(date) idle time is too low: $idle_time < $min_idle_time" # debug
    continue
  fi

  # Get the current CPU load
  #cpu_load=$(uptime | awk -F'[a-z]:' '{ print $2 }' | awk '{ print $1 }')
  cpu_load=$(uptime | cut -d, -f3 | cut -d' ' -f5)

  #if (( cpu_load > max_cpu_load )); then
  if (( $(echo "$cpu_load > $max_cpu_load" | bc -l) )); then
    echo "$(date) cpu load is too high: $cpu_load > $max_cpu_load" # debug
    continue
  fi

  echo "$(date) user left"

  # inner loop: wait for user to return
  while true; do

    #sleep 10
    sleep 1 # debug

    # Check if the user is idle
    idle_time=$(xprintidle)

    if (( idle_time < min_idle_time )); then
      echo "$(date) user returned"
      # TODO stop running job
      # User is active, kill the ffmpeg process if it's running
      echo pkill -STOP ffmpeg
      echo "$(date) waiting for user to leave"
      break
    fi

    # CPU load is low, run the job
    if ! pgrep -x "ffmpeg" > /dev/null; then
        # TODO start next job in queue
        # ffmpeg is not running, start it
        echo ffmpeg -i input.mp4 -c:v libx264 output.mp4 &
    fi

  done

done
