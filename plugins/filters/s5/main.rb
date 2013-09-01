description  'XSLT filter which transforms a html page to a S5 presentation'
dependencies 'filters/xslt', 'utils/assets'
export_assets 'ui/**/*', 'ui/default/*'

raise 'Diascope not found' unless File.exists?(File.join(File.dirname(__FILE__), 'ui'))

Page.attributes do
  group :s5 do
    string :presdate
    string :author
    string :company
    string :theme
    string :transitions
    integer :fadeDuration
    integer :incrDuration
  end
end

class S5 < XSLT
  def configure(options)
    super(options.merge(stylesheet: 's5/s5.xsl'))
  end

  def params(context)
    themes = Dir.glob(File.join(File.dirname(__FILE__), 'ui', '*')).map {|name| File.basename(name) }
    themes.delete('common')
    themes.delete('default')
    themes.unshift(context.page.attributes['theme'] || 'default')
    super.merge(context.page.attributes['s5'] || {}).
      merge('themes' => themes.join(' '), 's5_path' => build_path('_/assets/filters/s5'))
  end
end

Filter.register :s5, S5
