require "./outcome.cr"

module Insts
   class_property no_arg, with_arg

   @@no_arg : Hash(String, Array(Proc(Nil)))
   @@with_arg : Hash(String, Array(Proc(String, Int32, Nil)))

   # @@no_args["@"] = [
   #       -> {Outcome.append "@"}, # beginning of line
   #       -> {},                   # end of line
   # ]

   @@no_arg = {
      "@" => [                    # name
         -> {Outcome.append "@"}, # beginning of line
         -> {},                   # end of line
      ],
   }

   @@with_arg = {
      "@" => [
         ->(arg : String, line_num : Int32) {

         },
         ->(arg : String, line_num : Int32) {

         },
      ],
   }
end
