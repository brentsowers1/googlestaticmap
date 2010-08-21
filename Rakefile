# It appears as if the state of unit testing gems through gem is in question,
# so I'm just writing a simple rake task here to run the test files one by
# one.
task :test do
  Dir.glob('test/tc_*.rb').each do |tf|
    system("ruby ./#{tf}")
  end
end