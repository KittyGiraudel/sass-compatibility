#
# Link `spec` directory.
#
directory 'spec' => 'sass-spec' do
  `ln -s sass-spec/spec .`
end

#
# Clone sass-spec repository.
#
directory 'sass-spec' do
  `git clone --depth 1 https://github.com/sass/sass-spec.git`
end
