require "./data.cr"
require "./file_handle.cr"

def get_meta
   key_length = 0
   Data.meta.keys.each {|k|
      key_length = k.size if k.size > key_length
   }

   reset_data

   contents = "@setindl{#{key_length+3}} \n\n"
   Data.meta.each {|k, v|
      contents += "@rindl{0} \n"
      contents += k
      contents += "\n@tab{#{key_length - k.size}} "
      contents += "\n@cl{yellow} : \n"
      contents += "@softbindl{1} " + v + "\n"
   }

   process_file "meta", contents

   return Outcome.pages.last.lines
end
