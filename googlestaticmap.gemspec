Gem::Specification.new do |spec|  
  spec.name        = 'googlestaticmap'  
  spec.version     = '1.1.4'
  spec.files       = Dir['lib/**/*', 'test/**/*', 'README', 'History.txt']
  spec.test_files  = Dir.glob('test/tc_*.rb')
  
  spec.summary     = 'Class for retrieving maps from the Google Maps Static API service'  
  spec.description = "Easily retrieve single PNG, GIF, or JPG map images from Google with your own custom markers and paths using the Static Maps API service with this gem.  Simply set the attributes you want for your map and GoogleStaticMap will take care of getting the map for you, or giving your the URL to retrieve the map."
  
  spec.authors           = 'Brent Sowers'  
  spec.email             = 'brent@coordinatecommons.com'  
  spec.extra_rdoc_files  = ['README','History.txt']
  spec.homepage          = 'http://www.coordinatecommons.com/googlestaticmap/'
end
