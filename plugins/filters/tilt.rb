description 'Tilt filter'
require 'tilt'

class TiltFilter < Filter
  def filter(context, content)
    begin
      opt = Olelo::Config['tilt_options'][name].to_sym_hash.merge(options.to_sym_hash)
    rescue NameError
      opt = options.to_sym_hash
    end
    ::Tilt[name].new(nil, 1, opt) { content }.render
  end
end

[:markdown, :textile, :sass, :scss, :less, :rdoc, :coffee, :mediawiki].each do |name|
  begin
    ::Tilt[name].new { '' } # Force initialization of tilt library
    Filter.register(name, TiltFilter)
  rescue Exception => ex
    Olelo.logger.warn "Could not load Tilt filter #{name}"
  end
end
