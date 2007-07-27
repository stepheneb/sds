module PasModelActivityLib
  require 'spreadsheet/excel'
  
  # Create a worksheet based on a model.activity.data sock
  def create_mad_worksheet(workbook, format, sock)
    @count ? nil : @count = []
    @count[sock.pod.id] ? @count[sock.pod.id] += 1 : @count[sock.pod.id] = 1
    ws = workbook.add_worksheet("#{sock.pod.id}-#{@count[sock.pod.id]}")
    
    ws.format_column(0, 100, format)
    ws.format_column(1, 30, format)
    ws.format_column(2, 16, format)
    ws.format_column(3..6, 20, format)
    
    mad = get_mad(sock)
    
    row_num = 0
    ws.write(row_num, 0, ["Pod id:", sock.pod.id])
    ws.write(row_num += 1, 0, ["Sock entry id:", sock.id])
    ws.write(row_num += 1, 0, ["Bundle id:", sock.bundle.id])
    ws.write(row_num += 1, 0, ["Session start:", sock.bundle.sail_session_start_time.to_s])
    ws.write(row_num += 1, 0, ["Session end:", sock.bundle.sail_session_end_time.to_s])
    if mad
      ws.write(row_num += 1, 0, mad['headers'].collect { |h|  get_header_info(h).join("\n") } )
      @i = 0
      max_column_size = 0
      row_num += 1
      mad['runs'].each do |r|
        
        ws.write(row_num, 0, get_run_info(r).join("\n"))
        
        r['by_time'].keys.sort.each do |timex|
          row = []
          
          event_list = r['by_time'][timex]
          row << timex.to_s
          
          # FIXME nasty embedded loop which allows the data to end up in the right column
          # there's got to be a better way
          mad['headers'].each do |h|
            unless h['name'] == "Run" || h['name'] == "Time"
              column_data = []
              event_list.each do |event|
                if event['name'] == h['name']
                  column_data << get_cell_info(event['value']).join("\n")
                end
              end
              row << column_data
              if column_data.size > max_column_size
                max_column_size = column_data.size
              end
            end
          end
          ws.write(row_num,1,row)
          row_num += (max_column_size)
          max_column_size = 0
        end
      end
    else
      ws.write(row_num += 1, 0, "There was an error rendering the model activity data for this sock entry.")
    end
  end

  def get_mad(sock)
  require 'date'
  
    return_hash = { }
    headers = []
    runs = []
    
    begin
    if ! sock.model_activity_dataset && sock.pod.pas_type == "model_activity_data"
      sock.save
    end
    
    ## Start with the headers
     headers << {
        "name"  => "Run"
     }
     headers << {
        "name"  => "Time",
        "units" => "hh:mm:ss"
     }
    
    sock.model_activity_dataset.computational_input.each do |ci|
      ci_hash = {
        "name"  => ci.name,
        "units" => ci.units,
        "min"   => ci.range_min,
        "max"   => ci.range_max
      }
      
      headers << ci_hash
    end
    
    sock.model_activity_dataset.representational_type.each do |rt|
      # prepend with 'zzz' so that they're sorted to the end of the header columns
      headers << { "name" => rt.name }
    end
    
    ## then runs and their associated data
    sock.model_activity_dataset.model_activity_modelrun.each do |mr|
      time_hash = { }
      civs = { }
      mr.computational_input_value.each do |civ|
        civ_time = ( (civ.time && civ.time != 0) ? Time.at(Float(civ.time)/1000) : "no time")
        civ_hash = {
          "name" => civ.computational_input.name,
          "time"  => civ_time,
          "value" => civ.value
        }
        civs[civ.computational_input.name] = civ_hash
        (time_hash[custom_time_string(civ_time)] ||= [] ) << civ_hash
      end
      
      mrvs = { }
      mr.representational_value.each do |mrv|
        mrv_time = ( (mrv.time && mrv.time != 0) ? Time.at(Float(mrv.time)/1000) : "no time");
        hash = { "name" => mrv.representational_attribute.representational_type.name,
                 "time" => mrv_time,
                 "value" => mrv.representational_attribute.value
               }
        mrvs[mrv.representational_attribute.representational_type.name] = hash
        (time_hash[custom_time_string(mrv_time)]  ||= []) << hash
      end
      
      run = {
        "start" => ( (mr.start_time && mr.start_time != 0) ? Time.at(Float(mr.start_time)/1000) : "no time"),
        "end"   => ( (mr.end_time && mr.end_time != 0) ? Time.at(Float(mr.end_time)/1000) : "no time"),
        "civs"  => civs,
        "mrvs"  => mrvs,
        "by_time" => time_hash
      }
      
      runs.push(run)
    end
    
    return_hash = {"headers" => headers, "runs" => runs}
    return return_hash
		rescue => e
                  flash[:notice] = "<!-- #{$!}<br/><br/>#{e} -->"
		  return nil
		end
  end
  
  def get_run_info(r)
    @i += 1
    begin
      h,m,s,f = DateTime.day_fraction_to_time(DateTime.parse(r['end'].to_s) - DateTime.parse(r['start'].to_s) )
    rescue
      h = m = f = 0
      s = -1
    end
    run_data = []
    run_data << "Run #{@i}"
    run_data << ", Start: #{r['start']}"
    run_data << ", End: #{r['end']}"
    run_data << (", Duration: " << (h == 0 ? "" : "#{h} hours, " ) << (m == 0 ? "" : "#{m} minutes, ") << (s < 0 ? "unknown" : "#{s} seconds"))
    return run_data
  end
  
  def get_header_info(h)
    # need to put the header formatting here so that the xls and html can use the same code
    header = []
    header << "#{h['name']}"
    if h['units']
      header << "(#{h['units']})"
    end
    if h['min'] || h['max']
      header << ((h['min'] ? "#{h['min']}" : "") << (h['min'] && h['max'] ? "-" : "") << (h['max'] ? "#{h['max']}" : ""))
    end
    return header
  end
  
  def get_cell_info(c)
  # need to put the cell formatting here so that the xls and html can use the same code
    cell_data = []
    if c.include? '|'
      start, final, min, max, avg, num = c.split("|")
      cell_data << "Start: #{start}"
      cell_data << "End: #{final}"
      cell_data << "Min: #{min}"
      cell_data << "Max: #{max}"
      cell_data << "Avg: #{avg}"
      cell_data << "Num: #{num}"
    else
      cell_data << c
    end
    return cell_data
  end
  
  protected
  
  def custom_time_string(timex)
    if timex == "no time"
      return timex
    else
      return sprintf("%02d:%02d:%02d",timex.hour.to_s, timex.min.to_s, timex.sec.to_s)
    end
  end
end
