require 'csv'
require 'date'

class SecuritiesProcessor
  attr_reader :file, :output, :securities, :months

  # Take in the command line supplied file
  def initialize(securities_file, output_file)
    @file = securities_file
    @output = output_file ||= 'securities.txt'
    @securities = []
    @months = parse_months
  end

  # Process the data and generate a new file
  def process
    csv_to_securities
    output_securities
  end

  private

  # Range of months based on example data
  # Should be made variable timespan from command line args
  def parse_months
    date_from  = Date.parse('2004-05-01')
    date_to    = Date.parse('2014-04-01')
    date_range = date_from..date_to
    date_months = date_range.map {|d| Date.new(d.year, d.month, 1) }.uniq
    date_months.map {|d| d.strftime "%B %Y" }
  end

  # Read in the supplied file and process each line
  def csv_to_securities
    CSV.foreach(file, col_sep: '|') do |row|
      growth_period = max_growth_period(row[2])
      securities << {name: row[0], symbol: row[1], growth: growth(growth_period[:chunk]), percentages: growth_period[:chunk], dates: growth_months(growth_period)}
    end
  end
  
  # Find the largest consecutive period of growth
  # Additionally find the range of months associated with this time period
  def max_growth_period(percentages)
    percentages = percentages.split(",").map { |p| p.to_f }
    percent_chunks = percentages.chunk_while{|i,j| i < j}.to_a
    growths = percent_chunks.map(&:sum)
    largest_chunk_index = growths.index(growths.max)
    months_in = largest_chunk_index > 0 ? (0..largest_chunk_index-1).map{|n| (percent_chunks[n].flatten).length}.sum: 0
    {months_in: months_in, chunk: percent_chunks[largest_chunk_index]}
  end

  # Growth percentage for the supplied period
  def growth(percentages)
    min = percentages[0]
    max = percentages[-1]
    (((max-min)/min)*100).floor(2)
  end

  # Convert growth period to months
  def growth_months(growth)
    "#{months[growth[:months_in]]} - #{months[growth[:months_in]+growth[:chunk].length-1]}"
  end

  # Generate process output file
  def output_securities
    File.open(output, 'w') do |f| 
      securities.sort_by { |k| k[:growth] }.reverse.each do |s|
        f.write(security_to_string(s))
      end
    end
  end

  # Format text for each processed security
  def security_to_string(security)
    <<~EOS
      #{security[:name]} - #{security[:symbol]}
      Percentage Growth: #{security[:growth]}%
      Dates: #{security[:dates]}
      Percentages: #{security[:percentages]} \n
    EOS
  end
end

SecuritiesProcessor.new(ARGV[0],ARGV[1]).process
