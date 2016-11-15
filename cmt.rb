require 'fileutils'
require 'uri'

file_path = ARGV[0]
time_periods = ARGV[1..-1]

if file_path =~ URI::regexp
  available_formats = `youtube-dl -F #{file_path}`
  target_format = available_formats.split("\n").slice_after { |s| s.start_with?('format') }.to_a.last.first.split.first
  download_log = `youtube-dl -f #{target_format} #{file_path}`
  destination_marker = '[download] Destination: '
  audio_file_path = download_log.split("\n").find { |s| s.start_with?(destination_marker) }.gsub(destination_marker, '')
  new_audio_file_path = audio_file_path + '.mp3'
  `ffmpeg -v 5 -y -i #{audio_file_path} -acodec libmp3lame -ac 2 -ab 192k #{new_audio_file_path}`
  audio_file_path = new_audio_file_path
end

audio_file_path ||= file_path

periods_and_coolness = time_periods.map do |period|
  start, ent = period.split('-')
  file_name = "#{audio_file_path}_#{period}.mp3"
  `sox '#{audio_file_path}' '#{file_name}' trim #{start} '=#{ent}'`

  stat = `sox '#{file_name}' -n stat 2>&1`
  FileUtils.rm(file_name)

  mean_norm = stat.split("\n").grep(/\AMean\s*norm/).first.split.last.to_f
  [period, mean_norm]
end

puts "    period      coolness"
periods_and_coolness.sort_by { |_period, coolness| -coolness }.each_with_index do |(period, coolness), index|
  puts "#{index + 1}   #{period}   #{(coolness * 1_000).round}"
end
