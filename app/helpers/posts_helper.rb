module PostsHelper

  START  = "#!idiff-start!#"
  FINISH = "#!idiff-finish!#"

  def processing diff_arr
    indexes = _indexes_of_changed_lines diff_arr

    indexes.each do |index|
      first_line = diff_arr[index+1]
      second_line = diff_arr[index+2]
      max_length = [first_line.size, second_line.size].max

      first_the_same_symbols = 0
      (0..max_length + 1).each do |i|
        first_the_same_symbols = i - 1
        if first_line[i] != second_line[i] && i > 0
          break
        end
      end
      first_token = first_line[0..first_the_same_symbols][1..-1]
      diff_arr[index+1].sub!(first_token, first_token + START)
      diff_arr[index+2].sub!(first_token, first_token + START)
      last_the_same_symbols = 0
      (1..max_length + 1).each do |i|
        last_the_same_symbols = -i
        shortest_line = second_line.size > first_line.size ? first_line : second_line
        if ( first_line[-i] != second_line[-i] ) || "#{first_token}#{START}".size == shortest_line[1..-i].size
          break
        end
      end
      last_the_same_symbols += 1
      last_token = first_line[last_the_same_symbols..-1]
      diff_arr[index+1].sub!(/#{Regexp.escape(last_token)}$/, FINISH + last_token)
      diff_arr[index+2].sub!(/#{Regexp.escape(last_token)}$/, FINISH + last_token)
    end
    diff_arr
  end

  def _indexes_of_changed_lines diff_arr
    chain_of_first_symbols = ""
    diff_arr.each_with_index do |line, i|
      chain_of_first_symbols += line[0]
    end
    chain_of_first_symbols.gsub!(/[^\-\+]/, "#")

    offset = 0
    indexes = []
    while index = chain_of_first_symbols.index("#-+#", offset)
      indexes << index
      offset = index + 1
    end
    indexes
  end

  def replace_markers line
    line.gsub!(START, "<span class='idiff'>")
    line.gsub!(FINISH, "</span>")
    line
  end

  def to_diff patch
    # discard lines before the diff
    lines = patch.split("\n")
    while !lines.first.start_with?("diff --git") do
      lines.shift
    end
    lines.pop if lines.last =~ /^[\d.]+$/ # Git version
    lines.pop if lines.last == "-- "      # end of diff
    lines.join("\n")
  end

  def identification_type(line)
    if line[0] == "+"
      "new"
    elsif line[0] == "-"
      "old"
    else
      nil
    end
  end

  def build_line_anchor(diff, line_new, line_old)
    "#{Digest::SHA1.hexdigest(diff.path)}_#{line_old}_#{line_new}"
  end

  def each_diff_line(diff)
    patch_arr = diff.patch.split(/\n/)

    line_old = 1
    line_new = 1
    type = nil

    lines_arr = processing patch_arr
    patch_arr.each do |line|
      next if line.match(/\-\-\- \/dev\/null/)
      next if line.match(/\+\+\+ \/dev\/null/)
      next if line.match(/\-\-\- a/)
      next if line.match(/\+\+\+ b/)
      next if line.match(/^\\/)
      next if line.match(/^diff --git a\/.* b\/.*$/)
      next if line.match(/^index .{7}\.\..{7} \d{5}/)

      full_line = html_escape(line.gsub(/\n/, ''))
      full_line = replace_markers full_line

      if line.match(/^@@ -/)
        type = "match"

        line_old = line.match(/\-[0-9]*/)[0].to_i.abs rescue 0
        line_new = line.match(/\+[0-9]*/)[0].to_i.abs rescue 0

        next if line_old == 1 && line_new == 1 #top of file
        yield(full_line, type, nil, nil, nil)
        next
      else
        type = identification_type(line)
        line_code = build_line_anchor(diff, line_new, line_old)
        yield(full_line, type, line_code, line_new, line_old)
      end


      if line[0] == "+"
        line_new += 1
      elsif line[0] == "-"
        line_old += 1
      else
        line_new += 1
        line_old += 1
      end
    end
  end

  def each_diff_line_near(diff, expected_line_code)
    max_number_of_lines = 16

    prev_match_line = nil
    prev_lines = []

    each_diff_line(diff) do |full_line, type, line_code, line_new, line_old|
      line = [full_line, type, line_code, line_new, line_old]
      if line_code != expected_line_code
        if type == "match"
          prev_lines.clear
          prev_match_line = line
        else
          prev_lines.push(line)
          prev_lines.shift if prev_lines.length >= max_number_of_lines
        end
      else
        yield(prev_match_line) if !prev_match_line.nil?
        prev_lines.each { |ln| yield(ln) }
        yield(line)
        break
      end
    end
  end

  def diff_line_content(line)
    if line.blank?
      " &nbsp;"
    else
      line
    end
  end

end
