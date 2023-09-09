
# ===============================< Chasm Exchange [CMX] >============================== #

puts "\n[CMX] Chasm Exchange\n\n"

# ==================================< Configuration >================================== #

# The stable version should correspond to the newest chasm binary that is capable of 
# processing the latest development source.
StableBreaking = 0
StableFeature = 0
StablePatch = 0

# Increment for breaking changes.
DevBreaking = 0

# Increment for new development features.
DevFeature = 0

# Increment for minor patches or bugfixes.
DevPatch = 0

# Specify which directories contain chasm files to be included in processing.
Include = [ "src" ]

# Specify which directories contain chasm files used to test processing.
IncludeTest = [ "test" ]

# Specify the output path for chasm files that have been processed into IL.
PathOut = "out"

# Specify the output path for executable chasm binaries.
PathBin = "bin"

# Specify the chasm executable name.
ExecutableName = "chasm"

# Specify the options to use when assembling chasm IL files in debug mode.
OptionsDebug = "/nologo /debug"

# Specify the options to use when assembling chasm IL files in release mode.
OptionsRelease = "/nologo /quiet /optimize /fold /clock"

# .app -> .app.out -> .exe/.dll
Extension    = ".chasm"
ExtensionOut = ".il"

# ===============================< Argument Processing >=============================== #

require 'optparse'

options = {}

options[:process] = false
options[:release] = false
options[:debug] = false
options[:test] = false

OptionParser.new do |opts|

	opts.banner = "Usage: cmx [options]"

	opts.on("-p", "--process", "Process included files using the latest stable chasm.") do |p|
	
		options[:process] = p
	
	end
	
	opts.on("-r", "--release", "Assemble an executable from the development processing output.") do |r|
	
		options[:release] = r
	
	end
	
	opts.on("-d", "--debug", "Assemble an executable with an associated PDB file for debugging.") do |d|
	
		options[:debug] = d
	
	end
	
	opts.on("-t", "--test", "Process included test files using the current development chasm.") do |t|
	
		options[:test] = t
	
	end
	
end.parse!

# ====================================< Execution >==================================== #

# x.y.z
StableVersion = "#{StableBreaking}.#{StableFeature}.#{StablePatch}"
DevVersion = "#{DevBreaking}.#{DevFeature}.#{DevPatch}"

# bin/x.y.z/sample.exe
StableTarget = "#{PathBin}/#{StableVersion}/#{ExecutableName}.exe"
DevTarget = "#{PathBin}/#{DevVersion}/#{ExecutableName}.exe"

# Pass all included chasm files through the stable chasm.
# Chasm files that have been processed into IL are stored in a subfolder of the output 
# path corresponding to the development version.

def replaceFileExtension(file, outExt)

	inExt = File.extname(file)
	return "#{File.basename(file, inExt)}#{outExt}"

end

def findAll(dir, ext)

	return Dir["#{dir}/**/*#{ext}"]

end

def remapFileExtension(file)

	inExtension = File.extname(file)
	outExtension = inExtension
	name = File.basename(file, inExtension)
	
	case inExtension
	when Extension
		outExtension = ExtensionOut
	when ExtensionOut
		
		if name .include? ".lib"
			
			outExtension = ".dll"
			name.sub! ".lib", ""
		
		else 
		
			outExtension = ".exe"
		
		end
		
	end
	
	return "#{name}#{outExtension}"
	
end

def getDestinationFile(path, version, file)
	
	# path/version/sample.out
	return "#{path}/#{version}/#{remapFileExtension(file)}"

end

if options[:process]

	Include.each do |dir|
	
		findAll(dir, Extension).each do |file|
			
			out = "#{PathOut}/#{DevVersion}/#{replaceFileExtension(file, ExtensionOut)}"
			p "#{file} -> #{out}"
			
		end
	
	end

end

Out = Dir[PathOut]

def assemble(args = "")

	command = "ilasm"
	
	Out.each do |dir|
	
		# Assemble executable files
	
		findAll(dir, ExtensionOut).each do |file|
		
			# ilasm /exe {args} /output {output}
			
			out = getDestinationFile(PathBin, DevVersion, file)
			
			p file
			p out
			
			command = "#{command} #{file} #{args} /output #{out}"
			
			p command
		
		end
	
	end
	
end

if options[:debug]
	
	assemble(OptionsDebug)

end
	
if options[:release]

	assemble(OptionsRelease)

end
