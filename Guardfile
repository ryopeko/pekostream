guard :rspec, cmd: "bundle exec rspec" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/pekostream/stream/(.+)\.rb$})   { |m| "spec/stream/#{m[1]}_spec.rb" }
end
