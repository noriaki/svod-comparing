require 'pp'
class Hash
  def pretty_print(q)
    if empty?
      q.text '{}'
      return
    end
    q.group 2, '{' do
      q.breakable
      q.seplist self do |k,v|
        if k.is_a? Symbol
          if k.inspect[1] === '"'
            q.text %|"#{k}": |
          else
            q.text "#{k}: "
          end
        else
          q.pp k
          q.text ' => '
        end
        if v.is_a? Enumerable
          q.pp v
        else
          q.group 1 do
            q.breakable ''
            q.pp v
          end
        end
      end
    end
    q.breakable
    q.text '}'
  end
end
