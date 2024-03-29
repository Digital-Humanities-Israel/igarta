require 'htmlentities'
require 'hebrew'
require 'action_view'
include ActionView::Helpers::SanitizeHelper

BASE_URL = 'http://benyehuda.org/'

desc 'Ingest a letters file and feed into DB'
task :ingest, [:infile, :outdir] => :environment do |taskname, args|
  unless args.infile.nil? || args.outdir.nil?
    coder = HTMLEntities.new
    puts "reading file..."
    binfile = File.open(args.infile, 'r').read
    puts "transcoding file..."
    utf_html = coder.decode(binfile.encode('utf-8', 'windows-1255', :undef => :replace)) # replace invalid chars (Word...) and don't choke, and literalize all HTML entities
    puts "splitting letters..."
    letters = split_letters(utf_html, args.outdir)
    author = 'TBD'
    puts "processing letters..."
    # TODO: add checking for duplicate ingestion
    letters.each {|l|
      info = parse_letter(l)
      # create letter record
      url = url_from_filename(args.infile)
      letter = Letter.new(:url => url, :seq_no => info[:seqno], :author => author, :recipient => info[:recipient], 
        :from_location => info[:from_location], :to_location => info[:to_location], :letter_date => info[:date], :plaintext_filename => info[:plaintext_filename])
      letter.save!
    }
    puts "done!  #{letters.count} letters ingested and parsed."
  else
    puts "please specify a filename to ingest\ne.g. rake ingest[/home/moose/ginzberg/letters_1898.html]"
  end
end
desc 'Ingest plaintext'
task :ingest_split_plaintext => :environment do
  puts "reading..."
  Dir.foreach('split') {|f|
    puts f
    next if f[0] == '.'
    year = f.scan /\d\d\d\d/
    next if year.empty?
    seqno = $'.scan /\d+/
    buf = File.open('split/'+f,'r').read.lines
    (recipient, to_location) = parse_recipient(buf[0])
    (from_location, letter_date) = parse_date(buf[1])
    from_location = 'אודסה' if from_location == 'אודיסא' # cheating, for demo purposes, since the normalization wasn't ready on time
    letter = Letter.new(:url => 'TBD', :seq_no => seqno, :author => 'אחד העם', :recipient => recipient, :from_location => from_location, :to_location => to_location, :letter_date => letter_date, :plaintext_filename => '/home/abartov/dev/thatcamp/split/'+f)
    letter.save!
  }
end
def url_from_filename(f)
  n = f.rindex('/') # filename
  n = f[0..n-1].rindex('/') # BY author dir
  
  return BASE_URL+f[n+1..-1]
end

def split_letters(buf, outdir)
  # modeling this primitive splitter on the structure of ginzberg/letters_1899; now added letters_1918
  chunks = buf.split('<p class=a9')
  if chunks.size < 5
    chunks = buf.split('<p class=ac')
    puts "chunks.size = #{chunks.size}"
  end
  letters = []
  chunks.shift # ignore first chunk, being the prologue
  seqno = 1
  chunks.each {|c|
    n = c.index('</p>') # first paragraph end mark end of recipient part
    next unless c.any_hebrew? 
    recipient_part = '<p '+c[0..n-1].gsub(/\n/,' ').gsub(/\r/,' ') # restore opening tag, for strip_tags to work later
    next unless recipient_part.any_hebrew?
    c = c[n+4..-1] # leave only the rest
    n = c.index('/p>') # second paragraph end mark end of date part
    
    date_part = c[0..n-2].gsub(/\n/,' ').gsub(/\r/,' ')
    puts "#{seqno} - date_part = #{date_part}" 
    next unless (date_part.any_hebrew? && date_part !~ /תרגום\s*מ/)
    letter_body = to_plaintext(c[n+3..-1].gsub(/\n/,' ').gsub(/\r/,' '))
    plaintext_body_filename = "#{outdir}/#{"%03d" % seqno}.txt"

    letters << { :seqno => seqno, :recipient_part => to_plaintext(recipient_part), :date_part => to_plaintext(date_part), :letter_body => letter_body, :plaintext_filename => plaintext_body_filename }

    File.open(plaintext_body_filename, "wb") {|f| f.write(letter_body) }
    seqno += 1
  }
  return letters
end

def parse_letter(l)
  info = l
  (info[:recipient], info[:to_location]) = parse_recipient(l[:recipient_part])
  (info[:from_location], info[:date]) = parse_date(l[:date_part])
  # TODO: identify additional dates, locations, persons
  return info
end
def parse_date(buf)
  dat = nil
  loc = nil
  n = buf.index(',')
  unless n.nil? # TODO: add fallback for when the comma is missing -- just split by space and pick the first token as the location
    loc = to_plaintext(buf[0..n-1])
    dat = to_plaintext(buf[n+1..-1])
    dat = dat[0..-2] if dat[-1] == '.'
  end
  return [loc, dat]
end
def parse_recipient(buf)
  rec = nil
  loc = nil
  n = buf.index(',')
  unless n.nil?
    rec = to_plaintext(buf[0..n])
    loc = to_plaintext(buf[n+1..-1])
    loc = loc[0..-2] if loc[-1] == '.'
    rec = rec[1..-1] if rec[0] == 'ל' # skip the dative lamed
    rec = rec[0..-2] if rec[-1] == ','
  end
  return [rec, loc] 
end

def to_plaintext(buf)
  return strip_tags(buf.gsub('<![if !supportFootnotes]>','').gsub('<![endif]>','').gsub("\u00a0",'')).strip_nikkud.strip
end
