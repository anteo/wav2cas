require_relative 'lib/wav2cas/version'

Gem::Specification.new do |spec|
  spec.name          = "wav2cas"
  spec.version       = Wav2cas::VERSION
  spec.authors       = ["Anton Argirov"]
  spec.email         = ["anton.argirov@gmail.com"]

  spec.summary       = %q{TRS-80 (Model I/III) WAV to CAS converter}
  spec.description   = %q{Converts TRS-80 (Model I/III) computer audio records in WAV format to CAS file for use by TRS-80 emulators.}
  spec.homepage      = "https://github.com/anteo/wav2cas"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'wavefile', '~>1.1'
end
