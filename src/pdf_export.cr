require "./data.cr"
require "./outcome.cr"
require "./esc_to_pdf.cr"

require "base64"

def pdf_export
   # prepare stream
   streams = outcome_to_pdf

   # number of font object
   font_num = 3 + streams.size * 2

   # fnt = File.read("DejaVuSans.ttf")#.decode("ascii")
   # fnt = Base64.encode(fnt)

   # make rest of pdf and insert 'stream'
   pdf = %{%PDF-1.5
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [#{streams_to_refs streams}] /Count #{streams.size} >>
endobj
#{streams_to_pages streams, font_num}
#{streams_to_contents streams}
#{font_num} 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>
endobj
#{font_num+1} 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Courier-Bold >>
endobj
#{font_num+2} 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Courier-Oblique >>
endobj
#{font_num+3} 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Courier-BoldOblique >>
endobj
trailer
<< /Root 1 0 R >>
%%EOF}
#endobj
##{font_num+1} 0 obj
#<< /Type /FontDescriptor /FontName /F1 /FontBBox [ -168 -218 1000 905 ] /Flags 4 /ItalicAngle 0 /Ascent 905 /Descent -218 /CapHeight 716 /StemV 85 /FontFile2 #{font_num+2} 0 R >>
#endobj
##{font_num+2} 0 obj
#<< /Length #{fnt.bytesize} /Filter /FlateDecode >>
#stream
##{fnt}
#endstream
#endobj
#trailer
#<< /Root 1 0 R >>
#%%EOF}

   # write to file (as latin-1)
File.write(Data.pdf_name, pdf)
end

##################################
# CONVERT Outcome TO PDF STREAMS #
##################################

#                STREAM SECTION EXAMPLE            #
#   BT\n/F1 12 Tf\n10 772 Td\n(some text) Tj\nET\n #
#   ^    ^  ^        ^                        ^    #
# BEGIN  |  |        |                        |    #
#      FONT |     position (left, bottom)    END   #
#       FONT SIZE

def get_y(i : Int32)
   Data.pdf_height - (Data.pdf_v_margin + i * (Data.font_height+Data.font_gap))
end

def line_begin(i : Int32)
   "BT\n/F1 #{Data.font_height} Tf\n#{Data.pdf_h_margin} " + \
   "#{get_y i} Td\n("
end

def line_end
   ") Tj\nET\n"
end

def darkmode_rect
   "0.2 0.2 0.2 rg\n0 0 #{Data.pdf_width} #{Data.pdf_height} re f\n " + \
      "#{Data.pdf_default_color}"
end

def page_begin
   Data.pdf_darkmode ? darkmode_rect : ""
end

def outcome_to_pdf
   streams = [] of String
   c = -1

   Outcome.pages.size.times {|i|
      # add new page
      streams << page_begin

      c += 1

      line_count = 0
      Outcome.pages[i].lines.each { |line|
         if get_y(line_count) < Data.pdf_v_margin
            streams << page_begin
            c += 1
            line_count = 0
         end

         # start line
         streams[c] += line_begin line_count

         # insert lines
         streams[c] += prepare_text line.align

         # end line
         streams[c] += line_end

         line_count += 1
      }
   }

   return streams
end

def prepare_text(txt : String)
   # escape stuff
   txt = txt.gsub('\\', "\\\\").gsub('(', "\\(").gsub(')', "\\)")

   rgx = Regex.new("\x1b\\[(.*?)m")
   while esc = txt.match rgx
      txt = txt.gsub(esc[0], escM_to_pdf(esc[1]))
   end

   return txt
end

##############################
# PDF GENERATION FROM STREAM #
##############################

def streams_to_refs(streams : Array(String))
   txt = ""
   (3..streams.size+2).each { |i|
      txt += "#{i} 0 R "
   }
   return txt.strip
end

def streams_to_pages(streams : Array(String), font_num : Int32)
   txt = ""
   (3..streams.size+2).each { |i|
      txt += "#{i} 0 obj\n"
      txt += "<< /Type /Page /Parent 2 0 R /MediaBox " + \
             "[0 0 #{Data.pdf_width} #{Data.pdf_height}] " + \
             "/Contents #{i + streams.size} 0 R " + \
             "/Resources << /Font " + \
             "<< /F1 #{font_num} 0 R /F2 #{font_num+1} 0 R " + \
             "/F3 #{font_num+2} 0 R /F4 #{font_num+3} 0 R >> >> >>"
      txt += "endobj\n"
   }
   return txt.strip
end

def streams_to_contents(streams : Array(String))
   txt = ""
   streams.size.times { |i|
      txt += "#{i + 3 + streams.size} 0 obj\n"
      txt += "<< /Length #{streams[i].bytesize} >>\n"
      txt += "stream\n#{streams[i]}\nendstream\nendobj\n"
   }
   return txt.strip
end
