module Lita
  class User
    # Monkey patch mention_name to prepend '@' for Hipchat
    def mention_name
      if metadata["mention_name"]
        "@#{metadata['mention_name']}"
      else
        name
      end
    end
  end
end
